// Modelos usados pelas telas de Relatórios e Estatísticas.
// Nenhum pacote externo: tudo calculado a partir dos dados de correção.

/// Uma questão da prova, com o gabarito informado pelo professor.
class Questao {
  const Questao({
    required this.numero,
    required this.enunciado,
    required this.gabarito,
    this.assunto = '',
    this.alternativas = const ['A', 'B', 'C', 'D', 'E'],
  });

  final int numero;
  final String enunciado;
  final String gabarito; // alternativa correta: 'A', 'B', ...
  final String assunto;
  final List<String> alternativas;
}

/// Resultado da correção da folha de respostas de um aluno.
class ResultadoAluno {
  const ResultadoAluno({
    required this.nome,
    required this.matricula,
    required this.respostas,
    this.alunoId = '',
  });

  /// Id do aluno no Firestore (turmas/{turmaId}/alunos/{alunoId}).
  final String alunoId;
  final String nome;
  final String matricula;

  /// Alternativa marcada em cada questão, na ordem das questões.
  /// `null` = questão em branco / não identificada na leitura.
  final List<String?> respostas;

  int get totalQuestoes => respostas.length;

  int acertos(List<Questao> questoes) {
    var total = 0;
    for (var i = 0; i < questoes.length && i < respostas.length; i++) {
      if (respostas[i] == questoes[i].gabarito) total++;
    }
    return total;
  }

  int emBranco() => respostas.where((r) => r == null).length;

  /// Nota de 0 a 10.
  double nota(List<Questao> questoes) {
    if (questoes.isEmpty) return 0;
    return acertos(questoes) / questoes.length * 10;
  }

  double percentual(List<Questao> questoes) {
    if (questoes.isEmpty) return 0;
    return acertos(questoes) / questoes.length;
  }
}

/// Estatística consolidada de uma questão dentro de uma prova.
class EstatisticaQuestao {
  EstatisticaQuestao({
    required this.questao,
    required this.distribuicao,
    required this.emBranco,
    required this.totalAlunos,
  });

  final Questao questao;

  /// Quantas vezes cada alternativa foi marcada: {'A': 12, 'B': 3, ...}
  final Map<String, int> distribuicao;
  final int emBranco;
  final int totalAlunos;

  int get acertos => distribuicao[questao.gabarito] ?? 0;
  int get erros => totalAlunos - acertos - emBranco;

  double get percentualAcerto =>
      totalAlunos == 0 ? 0 : acertos / totalAlunos;

  /// Alternativa mais marcada pela turma (o dado que o cliente sentiu falta
  /// no sistema que usa hoje).
  String get alternativaMaisMarcada {
    String maior = questao.gabarito;
    var qtd = -1;
    distribuicao.forEach((alt, valor) {
      if (valor > qtd) {
        qtd = valor;
        maior = alt;
      }
    });
    return maior;
  }

  int get quantidadeMaisMarcada => distribuicao[alternativaMaisMarcada] ?? 0;

  bool get maioriaErrou => alternativaMaisMarcada != questao.gabarito;

  /// Classificação simples de dificuldade, útil para a análise pedagógica.
  String get nivel {
    if (percentualAcerto >= 0.75) return 'Fácil';
    if (percentualAcerto >= 0.45) return 'Média';
    return 'Difícil';
  }
}

/// Uma prova já corrigida pelo aplicativo.
class ProvaCorrigida {
  const ProvaCorrigida({
    required this.id,
    required this.titulo,
    required this.disciplina,
    required this.turma,
    required this.dataCorrecao,
    required this.questoes,
    required this.resultados,
    this.turmaId = '',
    this.versoes = 1,
    this.notaMinimaAprovacao = 6.0,
  });

  final String id;
  final String titulo;
  final String disciplina;
  final String turma;

  /// Id da turma no Firestore (vazio se a correção não guardou o id).
  final String turmaId;
  final DateTime dataCorrecao;
  final List<Questao> questoes;
  final List<ResultadoAluno> resultados;
  final int versoes;
  final double notaMinimaAprovacao;

  int get totalAlunos => resultados.length;
  int get totalQuestoes => questoes.length;

  List<double> get notas =>
      resultados.map((r) => r.nota(questoes)).toList();

  double get media {
    if (resultados.isEmpty) return 0;
    final soma = notas.fold<double>(0, (a, b) => a + b);
    return soma / resultados.length;
  }

  double get maiorNota =>
      notas.isEmpty ? 0 : notas.reduce((a, b) => a > b ? a : b);

  double get menorNota =>
      notas.isEmpty ? 0 : notas.reduce((a, b) => a < b ? a : b);

  double get mediana {
    if (notas.isEmpty) return 0;
    final ordenadas = [...notas]..sort();
    final meio = ordenadas.length ~/ 2;
    if (ordenadas.length.isOdd) return ordenadas[meio];
    return (ordenadas[meio - 1] + ordenadas[meio]) / 2;
  }

  int get aprovados =>
      resultados.where((r) => r.nota(questoes) >= notaMinimaAprovacao).length;

  int get reprovados => totalAlunos - aprovados;

  double get taxaAprovacao =>
      totalAlunos == 0 ? 0 : aprovados / totalAlunos;

  /// Percentual médio de acerto considerando todas as respostas da turma.
  double get percentualAcertoGeral {
    if (resultados.isEmpty || questoes.isEmpty) return 0;
    final totalAcertos =
        resultados.fold<int>(0, (soma, r) => soma + r.acertos(questoes));
    return totalAcertos / (resultados.length * questoes.length);
  }

  /// Resultados ordenados da maior para a menor nota.
  List<ResultadoAluno> get ranking {
    final lista = [...resultados];
    lista.sort((a, b) => b.nota(questoes).compareTo(a.nota(questoes)));
    return lista;
  }

  EstatisticaQuestao estatisticaDaQuestao(int indice) {
    final questao = questoes[indice];
    final distribuicao = <String, int>{
      for (final alt in questao.alternativas) alt: 0,
    };
    var brancos = 0;

    for (final resultado in resultados) {
      final marcada =
          indice < resultado.respostas.length ? resultado.respostas[indice] : null;
      if (marcada == null) {
        brancos++;
      } else {
        distribuicao[marcada] = (distribuicao[marcada] ?? 0) + 1;
      }
    }

    return EstatisticaQuestao(
      questao: questao,
      distribuicao: distribuicao,
      emBranco: brancos,
      totalAlunos: resultados.length,
    );
  }

  List<EstatisticaQuestao> get estatisticas => List.generate(
        questoes.length,
        (i) => estatisticaDaQuestao(i),
      );

  /// Questões com maior índice de erro — base da análise pedagógica.
  List<EstatisticaQuestao> questoesMaisErradas({int limite = 3}) {
    final lista = estatisticas
      ..sort((a, b) => a.percentualAcerto.compareTo(b.percentualAcerto));
    return lista.take(limite).toList();
  }

  /// Distribuição das notas em faixas (0-2, 2-4, 4-6, 6-8, 8-10).
  Map<String, int> get faixasDeNota {
    final faixas = <String, int>{
      '0 a 2': 0,
      '2 a 4': 0,
      '4 a 6': 0,
      '6 a 8': 0,
      '8 a 10': 0,
    };
    for (final nota in notas) {
      if (nota < 2) {
        faixas['0 a 2'] = faixas['0 a 2']! + 1;
      } else if (nota < 4) {
        faixas['2 a 4'] = faixas['2 a 4']! + 1;
      } else if (nota < 6) {
        faixas['4 a 6'] = faixas['4 a 6']! + 1;
      } else if (nota < 8) {
        faixas['6 a 8'] = faixas['6 a 8']! + 1;
      } else {
        faixas['8 a 10'] = faixas['8 a 10']! + 1;
      }
    }
    return faixas;
  }

  String get dataFormatada {
    String doisDigitos(int valor) => valor.toString().padLeft(2, '0');
    return '${doisDigitos(dataCorrecao.day)}/'
        '${doisDigitos(dataCorrecao.month)}/${dataCorrecao.year}';
  }
}

/// Consolidado de uma turma (ou de qualquer conjunto de provas filtrado)
/// somando todas as provas já corrigidas dela.
class ResumoTurma {
  ResumoTurma({
    required this.turma,
    required this.provas,
    this.turmaId = '',
    this.alunosCadastrados,
  });

  final String turma;
  final String turmaId;
  final List<ProvaCorrigida> provas;

  /// Quantidade de alunos cadastrados na turma (vinda do banco), quando
  /// conhecida. Sem ela, usa o maior número de alunos corrigidos numa prova.
  final int? alunosCadastrados;

  int get totalProvas => provas.length;

  /// Total de folhas corrigidas (soma dos alunos de todas as provas).
  int get totalCorrecoes =>
      provas.fold<int>(0, (a, p) => a + p.totalAlunos);

  int get totalAlunos {
    if (alunosCadastrados != null) return alunosCadastrados!;
    return provas.isEmpty
        ? 0
        : provas.map((p) => p.totalAlunos).reduce((a, b) => a > b ? a : b);
  }

  /// Média de todas as notas lançadas (cada correção pesa igual).
  double get media {
    final total = totalCorrecoes;
    if (total == 0) return 0;
    final soma = provas.fold<double>(
      0,
      (a, p) => a + p.notas.fold<double>(0, (x, y) => x + y),
    );
    return soma / total;
  }

  double get taxaAprovacao {
    final total = totalCorrecoes;
    if (total == 0) return 0;
    final aprovados = provas.fold<int>(0, (a, p) => a + p.aprovados);
    return aprovados / total;
  }

  /// Percentual de acerto considerando todas as respostas lidas.
  double get percentualAcerto {
    var acertos = 0;
    var respostas = 0;
    for (final p in provas) {
      for (final r in p.resultados) {
        acertos += r.acertos(p.questoes);
        respostas += p.questoes.length;
      }
    }
    return respostas == 0 ? 0 : acertos / respostas;
  }

  /// Provas da turma em ordem cronológica, para acompanhar a evolução.
  List<ProvaCorrigida> get porData {
    final lista = [...provas];
    lista.sort((a, b) => a.dataCorrecao.compareTo(b.dataCorrecao));
    return lista;
  }
}
