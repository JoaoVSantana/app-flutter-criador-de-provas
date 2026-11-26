import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../models/provas.dart';
import 'cartao_resposta_layout.dart';

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

    final maiorQuantidadeAlternativas = itens.isEmpty
        ? 0
        : itens
        .map((item) => item.alternativas.length)
        .reduce((a, b) => a > b ? a : b);

    final quantidadeValida = itens.length <=
        CartaoRespostaLayout.maxQuestions &&
        maiorQuantidadeAlternativas <=
            CartaoRespostaLayout.maxAlternatives;

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
          if (!quantidadeValida)
            const Text(
              'O cartão-resposta aceita até 30 questões e 5 alternativas por questão.',
              style: TextStyle(color: Colors.red),
            )
          else
            _buildCartaoResposta(
              titulo: tituloFinal,
              subtitulo: subtitulo,
              nomeAluno: nomeAluno,
              turmaNome: turmaNome,
              codigo: codigo!,
            ),
        ],
      ],
    );
  }

  Widget _buildCartaoResposta({
    required String titulo,
    required String? subtitulo,
    required String? nomeAluno,
    required String? turmaNome,
    required String codigo,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final largura = constraints.maxWidth;
        final escala = largura / CartaoRespostaLayout.pageWidth;
        final altura = CartaoRespostaLayout.pageHeight * escala;

        Widget marcador(double left, double top) {
          return Positioned(
            left: left * escala,
            top: top * escala,
            width: CartaoRespostaLayout.markerSize * escala,
            height: CartaoRespostaLayout.markerSize * escala,
            child: const ColoredBox(color: Colors.black),
          );
        }

        return Container(
          width: largura,
          height: altura,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(4),
            boxShadow: const [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 6,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: ClipRect(
            child: Stack(
              children: [
                marcador(
                  CartaoRespostaLayout.markerMargin,
                  CartaoRespostaLayout.markerMargin,
                ),
                marcador(
                  CartaoRespostaLayout.pageWidth -
                      CartaoRespostaLayout.markerMargin -
                      CartaoRespostaLayout.markerSize,
                  CartaoRespostaLayout.markerMargin,
                ),
                marcador(
                  CartaoRespostaLayout.markerMargin,
                  CartaoRespostaLayout.pageHeight -
                      CartaoRespostaLayout.markerMargin -
                      CartaoRespostaLayout.markerSize,
                ),
                marcador(
                  CartaoRespostaLayout.pageWidth -
                      CartaoRespostaLayout.markerMargin -
                      CartaoRespostaLayout.markerSize,
                  CartaoRespostaLayout.pageHeight -
                      CartaoRespostaLayout.markerMargin -
                      CartaoRespostaLayout.markerSize,
                ),
                Positioned(
                  left: CartaoRespostaLayout.contentLeft * escala,
                  top: CartaoRespostaLayout.contentTop * escala,
                  width: 390 * escala,
                  child: Text(
                    titulo,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 18 * escala,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    ),
                  ),
                ),
                Positioned(
                  left: CartaoRespostaLayout.contentLeft * escala,
                  top: 91 * escala,
                  child: Text(
                    'Versão ${subtitulo ?? ''}',
                    style: TextStyle(
                      fontSize: 11 * escala,
                      color: Colors.black54,
                    ),
                  ),
                ),
                Positioned(
                  left: CartaoRespostaLayout.contentLeft * escala,
                  top: 113 * escala,
                  width: 400 * escala,
                  child: Text(
                    'Aluno: ${nomeAluno ?? '________________'}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 10 * escala),
                  ),
                ),
                Positioned(
                  left: CartaoRespostaLayout.contentLeft * escala,
                  top: 130 * escala,
                  width: 400 * escala,
                  child: Text(
                    'Turma: ${turmaNome ?? '________________'}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 10 * escala),
                  ),
                ),
                Positioned(
                  right: 55 * escala,
                  top: 58 * escala,
                  width: 76 * escala,
                  height: 76 * escala,
                  child: QrImageView(
                    data: codigo,
                    version: QrVersions.auto,
                    backgroundColor: Colors.white,
                    padding: EdgeInsets.zero,
                  ),
                ),
                Positioned(
                  left: CartaoRespostaLayout.contentLeft * escala,
                  top: 148 * escala,
                  child: Text(
                    'CARTÃO-RESPOSTA',
                    style: TextStyle(
                      fontSize: 14 * escala,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                for (var i = 0; i < itens.length; i++) ...[
                  Positioned(
                    left: CartaoRespostaLayout.contentLeft * escala,
                    top: (CartaoRespostaLayout.questionTop +
                        i * CartaoRespostaLayout.rowHeight +
                        2) *
                        escala,
                    width: CartaoRespostaLayout.questionNumberWidth *
                        escala,
                    child: Text(
                      '${i + 1}.',
                      style: TextStyle(
                        fontSize: 10 * escala,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  for (var j = 0;
                  j < itens[i].alternativas.length;
                  j++)
                    Positioned(
                      left: CartaoRespostaLayout.bubbleX(j) * escala,
                      top: CartaoRespostaLayout.bubbleY(i) * escala,
                      width: CartaoRespostaLayout.bubbleSize * escala,
                      height: CartaoRespostaLayout.bubbleSize * escala,
                      child: Container(
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.black,
                            width: 1,
                          ),
                        ),
                        child: Text(
                          String.fromCharCode(65 + j),
                          style: TextStyle(fontSize: 8 * escala),
                        ),
                      ),
                    ),
                ],
                Positioned(
                  left: CartaoRespostaLayout.contentLeft * escala,
                  top: 700 * escala,
                  width: 485 * escala,
                  child: Text(
                    'Código: $codigo',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12 * escala,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 2 * escala,
                    ),
                  ),
                ),
                Positioned(
                  left: CartaoRespostaLayout.contentLeft * escala,
                  top: 720 * escala,
                  width: 485 * escala,
                  child: Text(
                    'Preencha completamente apenas uma bolinha por questão.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 9 * escala,
                      color: Colors.black54,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
