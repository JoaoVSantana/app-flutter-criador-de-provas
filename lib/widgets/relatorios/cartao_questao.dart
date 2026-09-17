import 'package:flutter/material.dart';

import '../../models/relatorio.dart';
import 'estilo_relatorios.dart';

/// Estatística de uma questão: aproveitamento, distribuição das alternativas
/// e destaque para a alternativa mais marcada pela turma.
class CartaoQuestao extends StatelessWidget {
  const CartaoQuestao({super.key, required this.estatistica});

  final EstatisticaQuestao estatistica;

  @override
  Widget build(BuildContext context) {
    final questao = estatistica.questao;
    final cor = corPorAproveitamento(estatistica.percentualAcerto);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: CoresRel.cartao,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: CoresRel.borda),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 34,
                height: 34,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: cor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${questao.numero}',
                  style: TextStyle(
                    fontFamily: 'Oswald',
                    fontWeight: FontWeight.w600,
                    color: cor,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      questao.enunciado,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: CoresRel.texto,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      questao.assunto.isEmpty
                          ? 'Gabarito: ${questao.gabarito}'
                          : '${questao.assunto} · Gabarito: ${questao.gabarito}',
                      style: rotuloStyle,
                    ),
                  ],
                ),
              ),
              _Selo(texto: estatistica.nivel, cor: cor),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Text(
                formatarPercentual(estatistica.percentualAcerto),
                style: TextStyle(
                  fontFamily: 'Oswald',
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: cor,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                'de acerto · ${estatistica.acertos} acertos, '
                '${estatistica.erros} erros, ${estatistica.emBranco} em branco',
                style: const TextStyle(fontSize: 11, color: CoresRel.textoSuave),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...questao.alternativas.map((alt) {
            final marcacoes = estatistica.distribuicao[alt] ?? 0;
            final proporcao = estatistica.totalAlunos == 0
                ? 0.0
                : marcacoes / estatistica.totalAlunos;
            final correta = alt == questao.gabarito;
            final maisMarcada = alt == estatistica.alternativaMaisMarcada;

            return _LinhaAlternativa(
              letra: alt,
              quantidade: marcacoes,
              proporcao: proporcao,
              correta: correta,
              maisMarcada: maisMarcada,
            );
          }),
          if (estatistica.maioriaErrou) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: CoresRel.ruim.withOpacity(0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.lightbulb_outline,
                      size: 16, color: CoresRel.ruim),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'A alternativa mais marcada foi '
                      '"${estatistica.alternativaMaisMarcada}" '
                      '(${estatistica.quantidadeMaisMarcada} alunos), e não o '
                      'gabarito. Vale revisar o conteúdo em sala.',
                      style: const TextStyle(
                          fontSize: 11, color: CoresRel.texto, height: 1.3),
                    ),
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

class _LinhaAlternativa extends StatelessWidget {
  const _LinhaAlternativa({
    required this.letra,
    required this.quantidade,
    required this.proporcao,
    required this.correta,
    required this.maisMarcada,
  });

  final String letra;
  final int quantidade;
  final double proporcao;
  final bool correta;
  final bool maisMarcada;

  @override
  Widget build(BuildContext context) {
    final cor = correta
        ? CoresRel.bom
        : (maisMarcada ? CoresRel.ruim : CoresRel.textoSuave);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Container(
            width: 22,
            height: 22,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: correta ? CoresRel.bom : Colors.transparent,
              border: Border.all(
                color: correta ? CoresRel.bom : CoresRel.borda,
              ),
            ),
            child: Text(
              letra,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: correta ? Colors.white : CoresRel.textoSuave,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: proporcao.clamp(0.0, 1.0).toDouble(),
                minHeight: 10,
                backgroundColor: CoresRel.fundo,
                valueColor: AlwaysStoppedAnimation<Color>(
                  cor.withOpacity(correta || maisMarcada ? 0.85 : 0.4),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 52,
            child: Text(
              '$quantidade (${(proporcao * 100).round()}%)',
              textAlign: TextAlign.right,
              style: const TextStyle(fontSize: 10, color: CoresRel.textoSuave),
            ),
          ),
        ],
      ),
    );
  }
}

class _Selo extends StatelessWidget {
  const _Selo({required this.texto, required this.cor});

  final String texto;
  final Color cor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: cor.withOpacity(0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        texto,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: cor,
        ),
      ),
    );
  }
}
