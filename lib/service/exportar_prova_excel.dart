import 'dart:typed_data';
import 'dart:ui' show Rect;

import 'package:share_plus/share_plus.dart';
import 'package:syncfusion_flutter_xlsio/xlsio.dart' as xlsio;

import '../models/relatorio.dart';

/// Gera uma planilha .xlsx com os dados de uma prova corrigida e abre o
/// compartilhamento do sistema (salvar no Drive, enviar por e-mail, abrir no
/// Excel etc.).
///
/// Abas geradas:
/// - Resumo: dados da prova e indicadores da turma.
/// - Notas: uma linha por aluno (acertos, nota, situação).
/// - Questões: desempenho e alternativa mais marcada de cada questão.
/// - Respostas: alternativa marcada por cada aluno em cada questão.
class ExportadorProvaExcel {
  static const String _mimeXlsx =
      'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';

  /// Monta o arquivo e abre a tela de compartilhamento.
  static Future<void> exportar(
    ProvaCorrigida prova, {
    Rect? origemCompartilhamento,
  }) async {
    final bytes = gerarBytes(prova);
    final nome = '${_nomeSeguro('${prova.titulo} - ${prova.turma}')}.xlsx';

    await SharePlus.instance.share(
      ShareParams(
        title: 'Notas de ${prova.titulo}',
        files: [XFile.fromData(bytes, mimeType: _mimeXlsx)],
        fileNameOverrides: [nome],
        sharePositionOrigin: origemCompartilhamento,
      ),
    );
  }

  /// Conteúdo do arquivo .xlsx (separado para facilitar testes).
  static Uint8List gerarBytes(ProvaCorrigida prova) {
    final wb = xlsio.Workbook();

    final resumo = wb.worksheets[0];
    resumo.name = 'Resumo';
    _abaResumo(resumo, prova);

    _abaNotas(wb.worksheets.addWithName('Notas'), prova);
    _abaQuestoes(wb.worksheets.addWithName('Questões'), prova);
    _abaRespostas(wb.worksheets.addWithName('Respostas'), prova);

    final saida = wb.saveAsStream();
    wb.dispose();
    return Uint8List.fromList(saida);
  }

  // ------------------------------------------------------------- abas

  static void _abaResumo(xlsio.Worksheet aba, ProvaCorrigida prova) {
    var linha = 1;
    void item(String rotulo, Object valor) {
      _celula(aba, linha, 1, rotulo, negrito: true);
      _celula(aba, linha, 2, valor);
      linha++;
    }

    item('Prova', prova.titulo);
    item('Disciplina', prova.disciplina);
    item('Turma', prova.turma);
    item('Corrigida em', prova.dataFormatada);
    item('Versões da prova', prova.versoes);
    item('Questões', prova.totalQuestoes);
    item('Alunos corrigidos', prova.totalAlunos);
    linha++; // linha em branco
    item('Média da turma', _arredonda(prova.media));
    item('Mediana', _arredonda(prova.mediana));
    item('Maior nota', _arredonda(prova.maiorNota));
    item('Menor nota', _arredonda(prova.menorNota));
    item('Nota mínima de aprovação', _arredonda(prova.notaMinimaAprovacao));
    item('Aprovados', prova.aprovados);
    item('Reprovados', prova.reprovados);
    item('Taxa de aprovação (%)', _arredonda(prova.taxaAprovacao * 100));
    item('Aproveitamento geral (%)',
        _arredonda(prova.percentualAcertoGeral * 100));

    aba.getRangeByIndex(1, 1).columnWidth = 28;
    aba.getRangeByIndex(1, 2).columnWidth = 36;
  }

  static void _abaNotas(xlsio.Worksheet aba, ProvaCorrigida prova) {
    _linha(aba, 1, [
      'Aluno',
      'Matrícula',
      'Acertos',
      'Erros',
      'Em branco',
      'Nota',
      'Aproveitamento (%)',
      'Situação',
    ], cabecalho: true);

    var linha = 2;
    for (final r in _porNome(prova)) {
      final acertos = r.acertos(prova.questoes);
      final brancos = r.emBranco();
      final nota = r.nota(prova.questoes);
      _linha(aba, linha++, [
        r.nome,
        r.matricula,
        acertos,
        prova.totalQuestoes - acertos - brancos,
        brancos,
        _arredonda(nota),
        _arredonda(r.percentual(prova.questoes) * 100),
        nota >= prova.notaMinimaAprovacao ? 'Aprovado' : 'Reprovado',
      ]);
    }

    aba.getRangeByIndex(1, 1).columnWidth = 34;
    aba.getRangeByIndex(1, 2).columnWidth = 14;
    for (var c = 3; c <= 8; c++) {
      aba.getRangeByIndex(1, c).columnWidth = 18;
    }
  }

  static void _abaQuestoes(xlsio.Worksheet aba, ProvaCorrigida prova) {
    // Uma coluna por alternativa (A, B, C...) com a quantidade de marcações
    final letras = <String>{
      for (final q in prova.questoes) ...q.alternativas,
    }.toList()
      ..sort();

    _linha(aba, 1, [
      'Questão',
      'Assunto',
      'Enunciado',
      'Gabarito',
      'Acertos',
      'Erros',
      'Em branco',
      'Acerto (%)',
      'Dificuldade',
      'Mais marcada',
      for (final l in letras) 'Marcações $l',
    ], cabecalho: true);

    var linha = 2;
    for (final e in prova.estatisticas) {
      _linha(aba, linha++, [
        e.questao.numero,
        e.questao.assunto,
        e.questao.enunciado,
        e.questao.gabarito,
        e.acertos,
        e.erros,
        e.emBranco,
        _arredonda(e.percentualAcerto * 100),
        e.nivel,
        e.alternativaMaisMarcada,
        for (final l in letras) e.distribuicao[l] ?? 0,
      ]);
    }

    aba.getRangeByIndex(1, 1).columnWidth = 10;
    aba.getRangeByIndex(1, 2).columnWidth = 22;
    aba.getRangeByIndex(1, 3).columnWidth = 60;
    for (var c = 4; c <= 10 + letras.length; c++) {
      aba.getRangeByIndex(1, c).columnWidth = 15;
    }
  }

  static void _abaRespostas(xlsio.Worksheet aba, ProvaCorrigida prova) {
    _linha(aba, 1, [
      'Aluno',
      'Matrícula',
      for (final q in prova.questoes) 'Q${q.numero}',
    ], cabecalho: true);

    // Linha do gabarito logo abaixo do cabeçalho
    _linha(aba, 2, [
      'GABARITO',
      '',
      for (final q in prova.questoes) q.gabarito,
    ], negrito: true);

    var linha = 3;
    for (final r in _porNome(prova)) {
      _linha(aba, linha++, [
        r.nome,
        r.matricula,
        for (var i = 0; i < prova.totalQuestoes; i++)
          i < r.respostas.length ? (r.respostas[i] ?? '-') : '-',
      ]);
    }

    aba.getRangeByIndex(1, 1).columnWidth = 34;
    aba.getRangeByIndex(1, 2).columnWidth = 14;
    for (var c = 3; c <= prova.totalQuestoes + 2; c++) {
      aba.getRangeByIndex(1, c).columnWidth = 7;
    }
  }

  // ---------------------------------------------------------- utilidades

  static List<ResultadoAluno> _porNome(ProvaCorrigida prova) {
    return [...prova.resultados]
      ..sort((a, b) => a.nome.toLowerCase().compareTo(b.nome.toLowerCase()));
  }

  /// Escreve uma linha inteira (colunas a partir da 1).
  static void _linha(
    xlsio.Worksheet aba,
    int linha,
    List<Object> valores, {
    bool cabecalho = false,
    bool negrito = false,
  }) {
    for (var c = 0; c < valores.length; c++) {
      _celula(
        aba,
        linha,
        c + 1,
        valores[c],
        cabecalho: cabecalho,
        negrito: negrito,
      );
    }
  }

  static void _celula(
    xlsio.Worksheet aba,
    int linha,
    int coluna,
    Object valor, {
    bool cabecalho = false,
    bool negrito = false,
  }) {
    final cel = aba.getRangeByIndex(linha, coluna);
    if (valor is num) {
      cel.setNumber(valor.toDouble());
    } else {
      cel.setText(valor.toString());
    }
    if (cabecalho) {
      cel.cellStyle.bold = true;
      cel.cellStyle.fontColor = '#FFFFFF';
      cel.cellStyle.backColor = '#2E7D32';
    } else if (negrito) {
      cel.cellStyle.bold = true;
    }
  }

  static double _arredonda(double v) => (v * 10).round() / 10;

  /// Remove caracteres que não podem ir em nome de arquivo.
  static String _nomeSeguro(String texto) {
    final limpo = texto
        .replaceAll(RegExp(r'[\\/:*?"<>|]'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    final nome = limpo.isEmpty ? 'prova' : limpo;
    return nome.length > 80 ? nome.substring(0, 80).trim() : nome;
  }
}
