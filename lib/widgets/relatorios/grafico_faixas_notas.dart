import 'package:flutter/material.dart';

import 'estilo_relatorios.dart';

/// Gráfico de barras verticais com a distribuição das notas da turma.
/// Feito com widgets puros para não adicionar dependências ao projeto.
class GraficoFaixasNotas extends StatelessWidget {
  const GraficoFaixasNotas({
    super.key,
    required this.faixas,
    this.altura = 150,
  });

  /// Ex.: {'0 a 2': 1, '2 a 4': 3, ...}
  final Map<String, int> faixas;
  final double altura;

  @override
  Widget build(BuildContext context) {
    final valores = faixas.values.toList();
    final maior = valores.isEmpty
        ? 0
        : valores.reduce((a, b) => a > b ? a : b);
    final chaves = faixas.keys.toList();

    return SizedBox(
      height: altura,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(chaves.length, (i) {
          final rotulo = chaves[i];
          final valor = faixas[rotulo] ?? 0;
          final proporcao = maior == 0 ? 0.0 : valor / maior;
          // A cor acompanha a faixa: notas baixas em vermelho, altas em verde.
          final cor = corPorAproveitamento((i + 0.5) / chaves.length);

          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    '$valor',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: valor == 0 ? CoresRel.textoSuave : cor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final double alturaBarra =
                            (constraints.maxHeight * proporcao)
                                .clamp(valor == 0 ? 2.0 : 8.0,
                                    constraints.maxHeight)
                                .toDouble();
                        return Align(
                          alignment: Alignment.bottomCenter,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 350),
                            height: alturaBarra,
                            decoration: BoxDecoration(
                              color: valor == 0
                                  ? CoresRel.borda
                                  : cor.withOpacity(0.85),
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(6),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    rotulo,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 10,
                      color: CoresRel.textoSuave,
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}
