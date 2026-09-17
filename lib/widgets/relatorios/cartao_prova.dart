import 'package:flutter/material.dart';

import '../../models/relatorio.dart';
import 'cartao_resumo.dart';
import 'estilo_relatorios.dart';

/// Item da lista de provas já corrigidas.
class CartaoProva extends StatelessWidget {
  const CartaoProva({
    super.key,
    required this.prova,
    required this.onTap,
    this.margemHorizontal = 16,
  });

  final ProvaCorrigida prova;
  final VoidCallback onTap;
  final double margemHorizontal;

  @override
  Widget build(BuildContext context) {
    final media = prova.media;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: margemHorizontal, vertical: 6),
      child: Material(
        color: CoresRel.cartao,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: CoresRel.borda),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            prova.titulo,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: CoresRel.texto,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            '${prova.disciplina} · ${prova.turma} · ${prova.dataFormatada}',
                            style: rotuloStyle,
                          ),
                        ],
                      ),
                    ),
                    _SeloNota(nota: media),
                  ],
                ),
                const SizedBox(height: 12),
                BarraDesempenho(percentual: prova.percentualAcertoGeral),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 12,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    _Etiqueta(
                      icone: Icons.groups_outlined,
                      texto: '${prova.totalAlunos} alunos',
                    ),
                    _Etiqueta(
                      icone: Icons.help_outline,
                      texto: '${prova.totalQuestoes} questões',
                    ),
                    _Etiqueta(
                      icone: Icons.check_circle_outline,
                      texto:
                          '${formatarPercentual(prova.percentualAcertoGeral)} de acerto',
                    ),
                    _Etiqueta(
                      icone: Icons.layers_outlined,
                      texto: '${prova.versoes} versão(ões)',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SeloNota extends StatelessWidget {
  const _SeloNota({required this.nota});

  final double nota;

  @override
  Widget build(BuildContext context) {
    final cor = corPorNota(nota);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: cor.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            formatarNota(nota),
            style: TextStyle(
              fontFamily: 'Oswald',
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: cor,
            ),
          ),
          Text(
            'média',
            style: TextStyle(fontSize: 10, color: cor.withOpacity(0.9)),
          ),
        ],
      ),
    );
  }
}

class _Etiqueta extends StatelessWidget {
  const _Etiqueta({required this.icone, required this.texto});

  final IconData icone;
  final String texto;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icone, size: 13, color: CoresRel.textoSuave),
        const SizedBox(width: 4),
        Text(texto, style: const TextStyle(fontSize: 11, color: CoresRel.textoSuave)),
      ],
    );
  }
}
