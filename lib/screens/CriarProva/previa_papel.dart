import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../models/provas.dart';

/// Mostra a prova como ela ficaria no papel.
class PreviaPapel extends StatelessWidget {
  final String titulo;
  final String? subtitulo;
  final List<QuestaoMontada> itens;
  final String? nomeAluno;
  final String? turmaNome;

  /// Quando informado, mostra o QR code e o código no fim da prova.
  final String? codigo;

  const PreviaPapel({
    super.key,
    required this.titulo,
    required this.itens,
    this.subtitulo,
    this.nomeAluno,
    this.turmaNome,
    this.codigo,
  });

  @override
  Widget build(BuildContext context) {
    const preto = Colors.black87;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 6, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Text(
              titulo.trim().isEmpty ? 'Título da prova' : titulo.trim(),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: preto,
              ),
            ),
          ),
          if (subtitulo != null)
            Center(
              child: Text(
                subtitulo!,
                style: const TextStyle(fontSize: 13, color: Colors.black54),
              ),
            ),
          const SizedBox(height: 12),
          Text(
            nomeAluno == null
                ? 'Nome: ____________________   Turma: ______   Data: ___/___/___'
                : 'Nome: $nomeAluno   Turma: ${turmaNome ?? ''}   Data: ___/___/___',
            style: const TextStyle(fontSize: 12, color: preto),
          ),
          const Divider(height: 24, color: Colors.black87),
          if (itens.isEmpty)
            const Text(
              'Nenhuma questão adicionada.',
              style: TextStyle(color: Colors.black54),
            ),
          for (var i = 0; i < itens.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${i + 1}. ${itens[i].enunciado}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: preto,
                    ),
                  ),
                  for (var j = 0; j < itens[i].alternativas.length; j++)
                    Padding(
                      padding: const EdgeInsets.only(left: 16, top: 4),
                      child: Text(
                        '${String.fromCharCode(65 + j)}) ${itens[i].alternativas[j]}',
                        style: const TextStyle(fontSize: 13, color: preto),
                      ),
                    ),
                ],
              ),
            ),
          if (codigo != null) ...[
            const Divider(height: 24, color: Colors.black87),
            Center(
              child: Column(
                children: [
                  QrImageView(
                    data: codigo!,
                    version: QrVersions.auto,
                    size: 140,
                    backgroundColor: Colors.white,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    codigo!,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 2,
                      color: preto,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Se a câmera não ler o QR code, digite este código.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: Colors.black54),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
