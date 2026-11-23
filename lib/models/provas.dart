import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';

/// Cópia da questão no momento em que entrou na prova.
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

/// Uma questão dentro de uma versão: qual questão (posição na lista da prova)
/// e em que ordem as alternativas aparecem.
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

/// Questão pronta para mostrar na tela (já na ordem da versão).
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

/// Prévia na ordem em que o professor montou, sem embaralhar.
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

/// A versão 1 é a ordem do professor. As demais embaralham a ordem das
/// questões e das alternativas, sem repetir nenhuma. Se não houver
/// combinações suficientes, devolve menos versões do que o pedido.
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

class ProvaSalva {
  final String id;
  final String titulo;
  final List<ProvaQuestao> questoes;
  final List<VersaoProva> versoes;
  final DateTime? criadoEm;

  const ProvaSalva({
    required this.id,
    required this.titulo,
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

/// Ligação entre uma prova, uma versão e um aluno (o "versao_aluno").
class VinculoProva {
  final String id; // provaId_alunoId
  final String alunoId;
  final String alunoNome;
  final String turmaNome;
  final int versao;

  const VinculoProva({
    required this.id,
    required this.alunoId,
    required this.alunoNome,
    required this.turmaNome,
    required this.versao,
  });

  factory VinculoProva.fromMap(String id, Map<String, dynamic> m) =>
      VinculoProva(
        id: id,
        alunoId: m['alunoId'] ?? '',
        alunoNome: m['alunoNome'] ?? '',
        turmaNome: m['turmaNome'] ?? '',
        versao: ((m['versao'] ?? 1) as num).toInt(),
      );
}
