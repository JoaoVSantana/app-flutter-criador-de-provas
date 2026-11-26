import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/relatorio.dart';
import '../models/turma.dart';

/// Lê do Firestore as correções salvas pela tela "Corrigir" e monta os
/// objetos usados nas telas de Relatórios.
///
/// Estrutura usada no banco:
/// - `correcoes/{id}`: uma por aluno corrigido (nota, respostas, turma...).
/// - `criarProvas/{provaId}`: título, questões (enunciado, assunto) e versões.
/// - `turmas/{turmaId}` e `turmas/{turmaId}/alunos/{alunoId}`.
class RelatorioService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Metadados das provas (criarProvas) já buscados; evita reler a cada
  /// atualização do stream. `null` = prova não existe mais.
  final Map<String, Map<String, dynamic>?> _cacheProvas = {};

  /// Provas corrigidas do professor logado. Uma [ProvaCorrigida] é o conjunto
  /// de correções de uma mesma prova aplicada a uma mesma turma. Atualiza em
  /// tempo real quando uma nova correção é salva.
  Stream<List<ProvaCorrigida>> observarProvasCorrigidas() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return Stream.value([]);

    return _db
        .collection('correcoes')
        .where('professorId', isEqualTo: user.uid)
        .snapshots()
        .asyncMap((snap) => _montar(user.uid, snap.docs));
  }

  /// Quantidade de alunos cadastrados em cada turma.
  Future<int> contarAlunos(String turmaId) async {
    try {
      final agregado = await _db
          .collection('turmas')
          .doc(turmaId)
          .collection('alunos')
          .count()
          .get();
      return agregado.count ?? 0;
    } catch (_) {
      final snap = await _db
          .collection('turmas')
          .doc(turmaId)
          .collection('alunos')
          .get();
      return snap.size;
    }
  }

  // ------------------------------------------------------------ montagem

  Future<List<ProvaCorrigida>> _montar(
    String uid,
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) async {
    final correcoes = docs.map((d) => _Correcao.fromMap(d.id, d.data())).toList();
    if (correcoes.isEmpty) return [];

    // Dados das provas e nomes atuais das turmas
    final idsProvas = correcoes.map((c) => c.provaId).where((i) => i.isNotEmpty);
    await _carregarProvas(idsProvas.toSet());
    final nomesTurmas = await _nomesTurmas(uid);

    // Agrupa por prova + turma
    final grupos = <String, List<_Correcao>>{};
    for (final c in correcoes) {
      final turmaKey = c.turmaId.isNotEmpty
          ? c.turmaId
          : 'nome:${c.turmaNome.toLowerCase()}';
      grupos.putIfAbsent('${c.provaId}|$turmaKey', () => []).add(c);
    }

    final provas = <ProvaCorrigida>[];
    for (final lista in grupos.values) {
      final prova = _montarProva(lista, nomesTurmas);
      if (prova != null) provas.add(prova);
    }
    provas.sort((a, b) => b.dataCorrecao.compareTo(a.dataCorrecao));
    return provas;
  }

  Future<void> _carregarProvas(Set<String> ids) async {
    final faltando = ids.where((id) => !_cacheProvas.containsKey(id)).toList();
    await Future.wait(faltando.map((id) async {
      try {
        final doc = await _db.collection('criarProvas').doc(id).get();
        _cacheProvas[id] = doc.exists ? doc.data() : null;
      } catch (_) {
        // Sem permissão/offline: usa só o que veio na correção.
        _cacheProvas[id] = null;
      }
    }));
  }

  Future<Map<String, String>> _nomesTurmas(String uid) async {
    try {
      final snap = await _db
          .collection('turmas')
          .where('criadoPor', isEqualTo: uid)
          .get();
      return {
        for (final d in snap.docs)
          d.id: Turma.fromFirestore(d).nome,
      };
    } catch (_) {
      return {};
    }
  }

  ProvaCorrigida? _montarProva(
    List<_Correcao> todas,
    Map<String, String> nomesTurmas,
  ) {
    // Se o aluno foi corrigido mais de uma vez na mesma prova, vale a mais recente.
    final porAluno = <String, _Correcao>{};
    for (final c in todas) {
      final chave = c.alunoId.isNotEmpty ? c.alunoId : c.alunoNome;
      final atual = porAluno[chave];
      if (atual == null || c.data.isAfter(atual.data)) porAluno[chave] = c;
    }
    final correcoes = porAluno.values.toList()
      ..sort((a, b) =>
          a.alunoNome.toLowerCase().compareTo(b.alunoNome.toLowerCase()));

    final primeira = correcoes.first;
    final meta = _cacheProvas[primeira.provaId];

    // Número de questões realmente corrigidas
    var total = 0;
    for (final c in correcoes) {
      if (c.totalQuestoes > total) total = c.totalQuestoes;
      if (c.respostas.length > total) total = c.respostas.length;
    }
    if (total == 0) return null;

    final metaQuestoes = <Map<String, dynamic>?>[
      for (final q in (meta?['questoes'] as List?) ?? const [])
        q is Map ? Map<String, dynamic>.from(q) : null,
    ];

    // Gabarito e alternativas de cada posição
    final gabaritos = List<String>.filled(total, '');
    var maiorLetra = 4; // pelo menos A..E
    for (var i = 0; i < total; i++) {
      for (final c in correcoes) {
        if (i < c.respostas.length) {
          final g = c.respostas[i].gabarito;
          if (g.isNotEmpty) {
            gabaritos[i] = g;
            break;
          }
        }
      }
      if (gabaritos[i].isEmpty && i < metaQuestoes.length) {
        final correta = metaQuestoes[i]?['correta'];
        if (correta is num && correta >= 0) {
          gabaritos[i] = String.fromCharCode(65 + correta.toInt());
        }
      }
    }

    int indiceLetra(String l) => l.isEmpty ? -1 : l.codeUnitAt(0) - 65;
    for (final g in gabaritos) {
      if (indiceLetra(g) > maiorLetra) maiorLetra = indiceLetra(g);
    }
    for (final c in correcoes) {
      for (final r in c.respostas) {
        if (indiceLetra(r.marcada) > maiorLetra) {
          maiorLetra = indiceLetra(r.marcada);
        }
      }
    }

    final questoes = List.generate(total, (i) {
      final m = i < metaQuestoes.length ? metaQuestoes[i] : null;
      final nAlt = (m?['alternativas'] as List?)?.length ?? 0;
      final qtd = nAlt > 0 && nAlt - 1 >= maiorLetra ? nAlt : maiorLetra + 1;
      final enunciado = (m?['enunciado'] ?? '').toString().trim();
      return Questao(
        numero: i + 1,
        enunciado: enunciado.isEmpty ? 'Questão ${i + 1}' : enunciado,
        gabarito: gabaritos[i],
        assunto: (m?['assunto'] ?? '').toString().trim(),
        alternativas: List.generate(qtd, (k) => String.fromCharCode(65 + k)),
      );
    });

    final resultados = correcoes.map((c) {
      final marcadas = List<String?>.filled(total, null);
      for (var i = 0; i < c.respostas.length && i < total; i++) {
        final m = c.respostas[i].marcada;
        marcadas[i] = m.isEmpty ? null : m;
      }
      return ResultadoAluno(
        alunoId: c.alunoId,
        nome: c.alunoNome.isEmpty ? 'Aluno não identificado' : c.alunoNome,
        matricula: c.matricula.isEmpty ? '—' : c.matricula,
        respostas: marcadas,
      );
    }).toList();

    // Turma: nome atual do banco, se existir
    final turmaNome = nomesTurmas[primeira.turmaId] ??
        (primeira.turmaNome.isEmpty ? 'Sem turma' : primeira.turmaNome);

    // Disciplina: a da correção ou a matéria mais frequente nas questões
    var disciplina = '';
    for (final c in correcoes) {
      if (c.disciplina.isNotEmpty) disciplina = c.disciplina;
    }
    if (disciplina.isEmpty) disciplina = _materiaMaisFrequente(metaQuestoes);
    if (disciplina.isEmpty) disciplina = 'Geral';

    final tituloMeta = (meta?['titulo'] ?? '').toString().trim();
    final titulo = tituloMeta.isNotEmpty
        ? tituloMeta
        : (primeira.tituloProva.isEmpty ? 'Prova' : primeira.tituloProva);

    final versoesMeta = (meta?['versoes'] as List?)?.length ?? 0;
    final versoes = versoesMeta > 0
        ? versoesMeta
        : correcoes.map((c) => c.versao).toSet().length;

    final data = correcoes
        .map((c) => c.data)
        .reduce((a, b) => a.isAfter(b) ? a : b);

    return ProvaCorrigida(
      id: primeira.provaId,
      titulo: titulo,
      disciplina: disciplina,
      turma: turmaNome,
      turmaId: primeira.turmaId,
      dataCorrecao: data,
      versoes: versoes < 1 ? 1 : versoes,
      questoes: questoes,
      resultados: resultados,
    );
  }

  String _materiaMaisFrequente(List<Map<String, dynamic>?> questoes) {
    final contagem = <String, int>{};
    for (final q in questoes) {
      final m = (q?['materia'] ?? '').toString().trim();
      if (m.isNotEmpty) contagem[m] = (contagem[m] ?? 0) + 1;
    }
    if (contagem.isEmpty) return '';
    return contagem.entries.reduce((a, b) => b.value > a.value ? b : a).key;
  }
}

// ---------------------------------------------------------------- leitura

class _RespostaCorrecao {
  const _RespostaCorrecao({required this.marcada, required this.gabarito});

  final String marcada; // '' = em branco
  final String gabarito;
}

class _Correcao {
  _Correcao({
    required this.provaId,
    required this.tituloProva,
    required this.turmaId,
    required this.turmaNome,
    required this.disciplina,
    required this.alunoId,
    required this.alunoNome,
    required this.matricula,
    required this.versao,
    required this.totalQuestoes,
    required this.respostas,
    required this.data,
  });

  final String provaId;
  final String tituloProva;
  final String turmaId;
  final String turmaNome;
  final String disciplina;
  final String alunoId;
  final String alunoNome;
  final String matricula;
  final int versao;
  final int totalQuestoes;
  final List<_RespostaCorrecao> respostas;
  final DateTime data;

  static String _str(dynamic v) => (v ?? '').toString().trim();

  static int _int(dynamic v) =>
      v is num ? v.toInt() : (int.tryParse(_str(v)) ?? 0);

  factory _Correcao.fromMap(String id, Map<String, dynamic> m) {
    // 'respostas' é salva por posição, mas respeita o campo 'numero' se existir
    final brutas = (m['respostas'] as List?) ?? const [];
    final porPosicao = <int, _RespostaCorrecao>{};
    var posicao = 0;
    for (final item in brutas) {
      if (item is Map) {
        final numero = _int(item['numero']);
        final indice = numero > 0 ? numero - 1 : posicao;
        porPosicao[indice] = _RespostaCorrecao(
          marcada: _str(item['marcada']).toUpperCase(),
          gabarito: _str(item['gabarito']).toUpperCase(),
        );
      }
      posicao++;
    }
    final maior = porPosicao.keys.isEmpty
        ? -1
        : porPosicao.keys.reduce((a, b) => a > b ? a : b);
    final respostas = List.generate(
      maior + 1,
      (i) =>
          porPosicao[i] ?? const _RespostaCorrecao(marcada: '', gabarito: ''),
    );

    final ts = m['dataCorrecao'];

    return _Correcao(
      provaId: _str(m['provaId']),
      tituloProva: _str(m['tituloProva']),
      turmaId: _str(m['turmaId']),
      turmaNome: _str(m['turmaNome']).isNotEmpty
          ? _str(m['turmaNome'])
          : _str(m['turma']),
      disciplina: _str(m['disciplina']),
      alunoId: _str(m['alunoId']),
      alunoNome: _str(m['alunoNome']),
      matricula: _str(m['matricula']),
      versao: _int(m['versao']) == 0 ? 1 : _int(m['versao']),
      totalQuestoes: _int(m['totalQuestoes']),
      respostas: respostas,
      // serverTimestamp ainda pendente (null) = acabou de ser salva
      data: ts is Timestamp ? ts.toDate() : DateTime.now(),
    );
  }
}
