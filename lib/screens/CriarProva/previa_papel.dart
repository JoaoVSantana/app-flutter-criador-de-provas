import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../models/provas.dart';

class PreviaPapel extends StatelessWidget {
  final String titulo;
  final String? subtitulo;
  final List<QuestaoMontada> itens;
  final String? nomeAluno;
  final String? turmaNome;
  final String? gabarito;
  final String? codigo;

  const PreviaPapel({
    super.key,
    required this.titulo,
    required this.itens,
    this.subtitulo,
    this.nomeAluno,
    this.turmaNome,
    this.codigo,
    this.gabarito,
  });

  @override
  Widget build(BuildContext context) {
    const preto = Colors.black87;

    final tituloFinal =
    titulo.trim().isEmpty ? 'Título da prova' : titulo.trim();

    final identificacao = nomeAluno == null
        ? 'Nome: ____________________   Turma: ______   Data: ___/___/___'
        : 'Nome: $nomeAluno   Turma: ${turmaNome ?? ''}   Data: ___/___/___';

    final estiloPagina = BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(4),
      boxShadow: const [
        BoxShadow(
          color: Colors.black26,
          blurRadius: 6,
          offset: Offset(0, 2),
        ),
      ],
    );

    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: estiloPagina,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Text(
                  tituloFinal,
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
                    style: const TextStyle(
                      fontSize: 13,
                      color: Colors.black54,
                    ),
                  ),
                ),
              const SizedBox(height: 12),
              Text(
                identificacao,
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
                      for (var j = 0;
                      j < itens[i].alternativas.length;
                      j++)
                        Padding(
                          padding: const EdgeInsets.only(left: 16, top: 4),
                          child: Text(
                            '${String.fromCharCode(65 + j)}) ${itens[i].alternativas[j]}',
                            style: const TextStyle(
                              fontSize: 13,
                              color: preto,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        if (codigo != null) ...[
          const SizedBox(height: 24),
          Container(
            width: double.infinity,
            constraints: const BoxConstraints(minHeight: 500),
            padding: const EdgeInsets.all(20),
            decoration: estiloPagina,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Center(
                  child: Text(
                    tituloFinal,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: preto,
                    ),
                  ),
                ),
                if (subtitulo != null)
                  Text(
                    subtitulo!,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Colors.black54,
                    ),
                  ),
                const SizedBox(height: 12),
                Text(
                  identificacao,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 12, color: preto),
                ),
                const Divider(height: 32, color: Colors.black87),
                const SizedBox(height: 12),
                const Text(
                  'CARTÃO-RESPOSTA',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: preto,
                  ),
                ),
                const SizedBox(height: 20),
                for (var i = 0; i < itens.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 32,
                          child: Text(
                            '${i + 1}.',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: preto,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Wrap(
                            spacing: 14,
                            runSpacing: 8,
                            children: [
                              for (var j = 0;
                              j < itens[i].alternativas.length;
                              j++)
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 24,
                                      height: 24,
                                      alignment: Alignment.center,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: Colors.black87,
                                          width: 1.2,
                                        ),
                                      ),
                                      child: Text(
                                        String.fromCharCode(65 + j),
                                        style: const TextStyle(
                                          fontSize: 11,
                                          color: preto,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 24),
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
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.black54,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}