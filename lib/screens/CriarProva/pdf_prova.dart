import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../models/provas.dart';

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

Future<Uint8List> gerarPdfProvaAluno({
  required ProvaSalva prova,
  required FolhaAluno folha,
}) async {
  final itens = prova.versao(folha.versao).montar(prova.questoes);

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
            style: const pw.TextStyle(
              fontSize: 9,
              color: PdfColors.grey700,
            ),
          ),
          pw.Text(
            'Página ${ctx.pageNumber} de ${ctx.pagesCount}',
            style: const pw.TextStyle(
              fontSize: 9,
              color: PdfColors.grey700,
            ),
          ),
        ],
      ),
      build: (ctx) => [
        pw.Center(
          child: pw.Text(
            prova.titulo,
            style: pw.TextStyle(
              fontSize: 18,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        ),
        pw.Center(
          child: pw.Text(
            'Versão ${folha.versao}',
            style: const pw.TextStyle(
              fontSize: 11,
              color: PdfColors.grey700,
            ),
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

  doc.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(40),
      build: (context) => pw.Center(
        child: pw.Container(
          width: double.infinity,
          padding: const pw.EdgeInsets.all(20),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.grey600),
            borderRadius: pw.BorderRadius.circular(6),
          ),
          child: pw.Column(
            mainAxisSize: pw.MainAxisSize.min,
            children: [
              pw.Text(
                prova.titulo,
                textAlign: pw.TextAlign.center,
                style: pw.TextStyle(
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 6),
              pw.Text(
                'Versão ${folha.versao}',
                style: const pw.TextStyle(
                  fontSize: 11,
                  color: PdfColors.grey700,
                ),
              ),
              pw.SizedBox(height: 14),
              pw.Text(
                'Nome: ${folha.alunoNome}',
                textAlign: pw.TextAlign.center,
                style: const pw.TextStyle(fontSize: 11),
              ),
              pw.Text(
                'Turma: ${folha.turmaNome}',
                textAlign: pw.TextAlign.center,
                style: const pw.TextStyle(fontSize: 11),
              ),
              pw.Divider(height: 30),
              pw.Text(
                'CARTÃO-RESPOSTA',
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 16),
              for (var i = 0; i < itens.length; i++)
                pw.Padding(
                  padding: const pw.EdgeInsets.only(bottom: 10),
                  child: pw.Row(
                    children: [
                      pw.SizedBox(
                        width: 28,
                        child: pw.Text(
                          '${i + 1}.',
                          style: pw.TextStyle(
                            fontSize: 11,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                      ),
                      for (var j = 0;
                      j < itens[i].alternativas.length;
                      j++)
                        pw.Padding(
                          padding: const pw.EdgeInsets.only(right: 12),
                          child: pw.Row(
                            children: [
                              pw.Container(
                                width: 22,
                                height: 22,
                                decoration: pw.BoxDecoration(
                                  shape: pw.BoxShape.circle,
                                  border: pw.Border.all(
                                    color: PdfColors.black,
                                    width: 1,
                                  ),
                                ),
                                alignment: pw.Alignment.center,
                                child: pw.Text(
                                  String.fromCharCode(65 + j),
                                  style: const pw.TextStyle(fontSize: 9),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              pw.SizedBox(height: 20),
              pw.BarcodeWidget(
                barcode: pw.Barcode.qrCode(),
                data: folha.codigo,
                width: 120,
                height: 120,
              ),
              pw.SizedBox(height: 8),
              pw.Text(
                folha.codigo,
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                'Se a câmera não ler o QR code, digite este código.',
                style: const pw.TextStyle(
                  fontSize: 9,
                  color: PdfColors.grey700,
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );

  return doc.save();
}