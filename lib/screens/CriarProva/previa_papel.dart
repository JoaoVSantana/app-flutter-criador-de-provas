import 'package:flutter/material.dart';

import '../../models/provas.dart';

class PreviaPapel extends StatelessWidget {
  final String titulo;
  final String? subtitulo;
  final List<QuestaoMontada> itens;

  const PreviaPapel({
    super.key,
    required this.titulo,
    required this.itens,
    this.subtitulo,
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
          const Text(
            'Nome: ____________________   Turma: ______   Data: ___/___/___',
            style: TextStyle(fontSize: 12, color: preto),
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
        ],
      ),
    );
  }
}
