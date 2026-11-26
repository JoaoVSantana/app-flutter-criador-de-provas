import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../models/provas.dart';
import 'cartao_resposta_layout.dart';

Future<pw.ThemeData?> _tema() async {
  try {
    return pw.ThemeData.withFont(
      base: await PdfGoogleFonts.robotoRegular(),
      bold: await PdfGoogleFonts.robotoBold(),
    );
  } catch (_) {
    return null;
  }
}

pw.Widget _marcadorPdf() {
  return pw.Container(
    width: CartaoRespostaLayout.markerSize,
    height: CartaoRespostaLayout.markerSize,
    color: PdfColors.black,
  );
}

Future<Uint8List> gerarPdfProvaAluno({
  required ProvaSalva prova,
  required FolhaAluno folha,
}) async {
  final itens = prova.versao(folha.versao).montar(prova.questoes);

  final maiorQuantidadeAlternativas = itens.isEmpty
      ? 0
      : itens
            .map((item) => item.alternativas.length)
            .reduce((a, b) => a > b ? a : b);

  CartaoRespostaLayout.validarQuantidade(
    itens.length,
    maiorQuantidadeAlternativas,
  );

  final doc = pw.Document(
    theme: await _tema(),
    title: '${prova.titulo} - ${folha.alunoNome}',
  );

  doc.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(40),
      footer: (ctx) => pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            'Código ${folha.codigo}',
            style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
          ),
          pw.Text(
            'Página ${ctx.pageNumber} de ${ctx.pagesCount}',
            style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
          ),
        ],
      ),
      build: (ctx) => [
        pw.Center(
          child: pw.Text(
            prova.titulo,
            style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
          ),
        ),
        pw.Center(
          child: pw.Text(
            'Versão ${folha.versao}',
            style: const pw.TextStyle(fontSize: 11, color: PdfColors.grey700),
          ),
        ),
        pw.SizedBox(height: 14),
        pw.Text(
          'Nome: ${folha.alunoNome}    Turma: ${folha.turmaNome}    '
          'Data: ___/___/___',
          style: const pw.TextStyle(fontSize: 11),
        ),
        pw.Divider(height: 24),
        for (var i = 0; i < itens.length; i++)
          pw.Container(
            margin: const pw.EdgeInsets.only(bottom: 14),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  '${i + 1}. ${itens[i].enunciado}',
                  style: pw.TextStyle(
                    fontSize: 12,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                for (var j = 0; j < itens[i].alternativas.length; j++)
                  pw.Padding(
                    padding: const pw.EdgeInsets.only(left: 14, top: 4),
                    child: pw.Text(
                      '${String.fromCharCode(65 + j)}) ${itens[i].alternativas[j]}',
                      style: const pw.TextStyle(fontSize: 11),
                    ),
                  ),
              ],
            ),
          ),
      ],
    ),
  );

  final marcadores = [
    pw.Positioned(
      left: CartaoRespostaLayout.markerMargin,
      top: CartaoRespostaLayout.markerMargin,
      child: _marcadorPdf(),
    ),
    pw.Positioned(
      right: CartaoRespostaLayout.markerMargin,
      top: CartaoRespostaLayout.markerMargin,
      child: _marcadorPdf(),
    ),
    pw.Positioned(
      left: CartaoRespostaLayout.markerMargin,
      bottom: CartaoRespostaLayout.markerMargin,
      child: _marcadorPdf(),
    ),
    pw.Positioned(
      right: CartaoRespostaLayout.markerMargin,
      bottom: CartaoRespostaLayout.markerMargin,
      child: _marcadorPdf(),
    ),
  ];

  final elementos = <pw.Widget>[
    ...marcadores,
    pw.Positioned(
      left: CartaoRespostaLayout.contentLeft,
      top: CartaoRespostaLayout.contentTop,
      child: pw.SizedBox(
        width: 390,
        child: pw.Text(
          prova.titulo,
          maxLines: 2,
          style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
        ),
      ),
    ),
    pw.Positioned(
      left: CartaoRespostaLayout.contentLeft,
      top: 91,
      child: pw.SizedBox(
        width: 390,
        child: pw.Text(
          'Versão ${folha.versao}',
          style: const pw.TextStyle(fontSize: 11, color: PdfColors.grey700),
        ),
      ),
    ),
    pw.Positioned(
      left: CartaoRespostaLayout.contentLeft,
      top: 113,
      child: pw.SizedBox(
        width: 400,
        child: pw.Text(
          'Aluno: ${folha.alunoNome}',
          maxLines: 1,
          style: const pw.TextStyle(fontSize: 10),
        ),
      ),
    ),
    pw.Positioned(
      left: CartaoRespostaLayout.contentLeft,
      top: 130,
      child: pw.SizedBox(
        width: 400,
        child: pw.Text(
          'Turma: ${folha.turmaNome}',
          maxLines: 1,
          style: const pw.TextStyle(fontSize: 10),
        ),
      ),
    ),
    pw.Positioned(
      right: 55,
      top: 58,
      child: pw.BarcodeWidget(
        barcode: pw.Barcode.qrCode(),
        data: folha.codigo,
        width: 76,
        height: 76,
      ),
    ),
    pw.Positioned(
      left: CartaoRespostaLayout.contentLeft,
      top: 148,
      child: pw.Text(
        'CARTÃO-RESPOSTA',
        style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
      ),
    ),
  ];

  for (var i = 0; i < itens.length; i++) {
    final y =
        CartaoRespostaLayout.questionTop + i * CartaoRespostaLayout.rowHeight;

    elementos.add(
      pw.Positioned(
        left: CartaoRespostaLayout.contentLeft,
        top: y + 2,
        child: pw.SizedBox(
          width: CartaoRespostaLayout.questionNumberWidth,
          child: pw.Text(
            '${i + 1}.',
            style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
          ),
        ),
      ),
    );

    for (var j = 0; j < itens[i].alternativas.length; j++) {
      elementos.add(
        pw.Positioned(
          left: CartaoRespostaLayout.bubbleX(j),
          top: CartaoRespostaLayout.bubbleY(i),
          child: pw.Container(
            width: CartaoRespostaLayout.bubbleSize,
            height: CartaoRespostaLayout.bubbleSize,
            alignment: pw.Alignment.center,
            decoration: pw.BoxDecoration(
              shape: pw.BoxShape.circle,
              border: pw.Border.all(color: PdfColors.black, width: 1),
            ),
            child: pw.Text(
              String.fromCharCode(65 + j),
              style: const pw.TextStyle(fontSize: 8),
            ),
          ),
        ),
      );
    }
  }

  elementos.addAll([
    pw.Positioned(
      left: CartaoRespostaLayout.contentLeft,
      top: 700,
      child: pw.SizedBox(
        width: 485,
        child: pw.Text(
          'Código: ${folha.codigo}',
          textAlign: pw.TextAlign.center,
          style: pw.TextStyle(
            fontSize: 12,
            fontWeight: pw.FontWeight.bold,
            letterSpacing: 2,
          ),
        ),
      ),
    ),
    pw.Positioned(
      left: CartaoRespostaLayout.contentLeft,
      top: 720,
      child: pw.SizedBox(
        width: 485,
        child: pw.Text(
          'Preencha completamente apenas uma bolinha por questão.',
          textAlign: pw.TextAlign.center,
          style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
        ),
      ),
    ),
  ]);

  doc.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: pw.EdgeInsets.zero,
      build: (context) => pw.SizedBox(
        width: CartaoRespostaLayout.pageWidth,
        height: CartaoRespostaLayout.pageHeight,
        child: pw.Stack(children: elementos),
      ),
    ),
  );

  return doc.save();
}
