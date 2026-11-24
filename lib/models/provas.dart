import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';

class ProvaQuestao {
  final String questaoId;
  final String codigo;
  final String materia;
  final String assunto;
  final String enunciado;
  final List<String> alternativas;
  final int correta; // índice (na ordem original) da alternativa correta

  const ProvaQuestao({
    required this.questaoId,
    required this.codigo,
    required this.materia,
    required this.assunto,
    required this.enunciado,
    required this.alternativas,
    required this.correta,
  });

  Map<String, dynamic> toMap() => {
    'questaoId': questaoId,
    'codigo': codigo,
    'materia': materia,
    'assunto': assunto,
    'enunciado': enunciado,
    'alternativas': alternativas,
    'correta': correta,
  };

  factory ProvaQuestao.fromMap(Map<String, dynamic> m) => ProvaQuestao(
    questaoId: m['questaoId'] ?? '',
    codigo: m['codigo'] ?? '',
    materia: m['materia'] ?? '',
    assunto: m['assunto'] ?? '',
    enunciado: m['enunciado'] ?? '',
    alternativas: List<String>.from(m['alternativas'] ?? []),
    correta: ((m['correta'] ?? 0) as num).toInt(),
  );
}

class ItemVersao {
  final int q;
  final List<int> alts;

  const ItemVersao({required this.q, required this.alts});

  Map<String, dynamic> toMap() => {'q': q, 'alts': alts};

  factory ItemVersao.fromMap(Map<String, dynamic> m) => ItemVersao(
    q: ((m['q'] ?? 0) as num).toInt(),
    alts: ((m['alts'] as List?) ?? []).map((e) => (e as num).toInt()).toList(),
  );
}

class QuestaoMontada {
  final String enunciado;
  final List<String> alternativas;
  final int correta; // 0 = A, 1 = B...

  const QuestaoMontada({
    required this.enunciado,
    required this.alternativas,
    required this.correta,
  });
}

List<QuestaoMontada> montarOriginal(List<ProvaQuestao> questoes) => questoes
    .map(
      (q) => QuestaoMontada(
        enunciado: q.enunciado,
        alternativas: q.alternativas,
        correta: q.correta,
      ),
    )
    .toList();

class VersaoProva {
  final int numero;
  final List<ItemVersao> itens;

  const VersaoProva({required this.numero, required this.itens});

  List<QuestaoMontada> montar(List<ProvaQuestao> questoes) {
    return itens.map((item) {
      final q = questoes[item.q];
      return QuestaoMontada(
        enunciado: q.enunciado,
        alternativas: item.alts.map((i) => q.alternativas[i]).toList(),
        correta: item.alts.indexOf(q.correta),
      );
    }).toList();
  }

  /// Letra correta de cada questão (0 = A, 1 = B...), na ordem desta versão.
  List<int> gabarito(List<ProvaQuestao> questoes) =>
      montar(questoes).map((m) => m.correta).toList();

  Map<String, dynamic> toMap(List<ProvaQuestao> questoes) => {
    'numero': numero,
    'itens': itens.map((i) => i.toMap()).toList(),
    'gabarito': montar(questoes).map((m) => m.correta).toList(),
  };

  factory VersaoProva.fromMap(Map<String, dynamic> m) => VersaoProva(
    numero: ((m['numero'] ?? 1) as num).toInt(),
    itens: ((m['itens'] as List?) ?? [])
        .map((e) => ItemVersao.fromMap(Map<String, dynamic>.from(e as Map)))
        .toList(),
  );
}

String _assinatura(List<ItemVersao> itens) =>
    itens.map((i) => '${i.q}:${i.alts.join(",")}').join('|');

List<VersaoProva> gerarVersoes(List<ProvaQuestao> questoes, int quantidade) {
  final rnd = Random();
  final versoes = <VersaoProva>[];
  final vistas = <String>{};

  final original = [
    for (var i = 0; i < questoes.length; i++)
      ItemVersao(
        q: i,
        alts: List.generate(questoes[i].alternativas.length, (k) => k),
      ),
  ];
  versoes.add(VersaoProva(numero: 1, itens: original));
  vistas.add(_assinatura(original));

  var tentativas = 0;
  while (versoes.length < quantidade && tentativas < quantidade * 60) {
    tentativas++;
    final ordem = List.generate(questoes.length, (i) => i)..shuffle(rnd);
    final itens = [
      for (final q in ordem)
        ItemVersao(
          q: q,
          alts: List.generate(questoes[q].alternativas.length, (k) => k)
            ..shuffle(rnd),
        ),
    ];
    if (vistas.add(_assinatura(itens))) {
      versoes.add(VersaoProva(numero: versoes.length + 1, itens: itens));
    }
  }
  return versoes;
}

String formatarData(DateTime? d) {
  if (d == null) return '';
  final dia = d.day.toString().padLeft(2, '0');
  final mes = d.month.toString().padLeft(2, '0');
  return '$dia/$mes/${d.year}';
}

class ProvaSalva {
  final String id;
  final String titulo;
  final String criadoPorNome;
  final List<ProvaQuestao> questoes;
  final List<VersaoProva> versoes;
  final DateTime? criadoEm;

  const ProvaSalva({
    required this.id,
    required this.titulo,
    this.criadoPorNome = '',
    required this.questoes,
    required this.versoes,
    this.criadoEm,
  });

  factory ProvaSalva.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final ts = data['criadoEm'];
    return ProvaSalva(
      id: doc.id,
      titulo: data['titulo'] ?? '',
      criadoPorNome: data['criadoPorNome'] ?? '',
      questoes: ((data['questoes'] as List?) ?? [])
          .map((e) => ProvaQuestao.fromMap(Map<String, dynamic>.from(e as Map)))
          .toList(),
      versoes: ((data['versoes'] as List?) ?? [])
          .map((e) => VersaoProva.fromMap(Map<String, dynamic>.from(e as Map)))
          .toList(),
      criadoEm: ts is Timestamp ? ts.toDate() : null,
    );
  }

  VersaoProva versao(int numero) => versoes.firstWhere(
    (v) => v.numero == numero,
    orElse: () => versoes.first,
  );
}

/// A folha de um aluno numa prova: versão, código (QR) e gabarito.
class FolhaAluno {
  final String alunoId;
  final String alunoNome;
  final String turmaId;
  final String turmaNome;
  final int versao;
  final String codigo;
  final List<int> gabarito;
  final String criadoPorNome;
  final DateTime? criadoEm;

  const FolhaAluno({
    required this.alunoId,
    required this.alunoNome,
    required this.turmaId,
    required this.turmaNome,
    required this.versao,
    required this.codigo,
    required this.gabarito,
    this.criadoPorNome = '',
    this.criadoEm,
  });

  factory FolhaAluno.fromMap(String alunoId, Map<String, dynamic> m) {
    final ts = m['criadoEm'];
    return FolhaAluno(
      alunoId: alunoId,
      alunoNome: m['alunoNome'] ?? '',
      turmaId: m['turmaId'] ?? '',
      turmaNome: m['turmaNome'] ?? '',
      versao: ((m['versao'] ?? 1) as num).toInt(),
      codigo: m['codigo'] ?? '',
      gabarito: ((m['gabarito'] as List?) ?? [])
          .map((e) => (e as num).toInt())
          .toList(),
      criadoPorNome: m['criadoPorNome'] ?? '',
      criadoEm: ts is Timestamp ? ts.toDate() : null,
    );
  }
}
