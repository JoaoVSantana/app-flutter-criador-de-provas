import 'package:flutter/material.dart';

import 'estilo_relatorios.dart';

/// Cartão pequeno com um número em destaque (média, total de provas, etc).
class CartaoResumo extends StatelessWidget {
  const CartaoResumo({
    super.key,
    required this.rotulo,
    required this.valor,
    this.icone,
    this.cor,
    this.complemento,
  });

  final String rotulo;
  final String valor;
  final IconData? icone;
  final Color? cor;
  final String? complemento;

  @override
  Widget build(BuildContext context) {
    final corValor = cor ?? CoresRel.verde;

    return Container(
      constraints: const BoxConstraints(minHeight: 96),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: CoresRel.cartao,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: CoresRel.borda),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              if (icone != null) ...[
                Icon(icone, size: 16, color: corValor),
                const SizedBox(width: 6),
              ],
              Expanded(
                child: Text(
                  rotulo,
                  style: rotuloStyle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            valor,
            style: TextStyle(
              fontSize: 22,
              fontFamily: 'Oswald',
              fontWeight: FontWeight.w600,
              color: corValor,
            ),
          ),
          if (complemento != null) ...[
            const SizedBox(height: 2),
            Text(
              complemento!,
              style: const TextStyle(fontSize: 11, color: CoresRel.textoSuave),
            ),
          ],
        ],
      ),
    );
  }
}

/// Barra horizontal simples de aproveitamento (sem dependências externas).
class BarraDesempenho extends StatelessWidget {
  const BarraDesempenho({
    super.key,
    required this.percentual,
    this.cor,
    this.altura = 8,
    this.fundo,
  });

  final double percentual; // 0.0 a 1.0
  final Color? cor;
  final double altura;
  final Color? fundo;

  @override
  Widget build(BuildContext context) {
    final valor = percentual.clamp(0.0, 1.0).toDouble();

    return ClipRRect(
      borderRadius: BorderRadius.circular(altura),
      child: LinearProgressIndicator(
        value: valor,
        minHeight: altura,
        backgroundColor: fundo ?? CoresRel.verdeClaro.withOpacity(0.6),
        valueColor: AlwaysStoppedAnimation<Color>(
          cor ?? corPorAproveitamento(valor),
        ),
      ),
    );
  }
}

/// Cabeçalho interno das telas: botão de menu/voltar + título + subtítulo.
class TituloTela extends StatelessWidget {
  const TituloTela({
    super.key,
    required this.titulo,
    this.subtitulo,
    this.mostrarVoltar = false,
    this.acao,
  });

  final String titulo;
  final String? subtitulo;
  final bool mostrarVoltar;
  final Widget? acao;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 8, 12, 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (mostrarVoltar)
            IconButton(
              icon: const Icon(Icons.arrow_back, color: CoresRel.texto),
              onPressed: () => Navigator.pop(context),
            )
          else
            Builder(
              builder: (context) => IconButton(
                icon: const Icon(Icons.menu, size: 26, color: CoresRel.texto),
                onPressed: () => Scaffold.of(context).openDrawer(),
              ),
            ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(titulo, style: tituloTelaStyle),
                if (subtitulo != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(subtitulo!, style: subtituloStyle),
                  ),
              ],
            ),
          ),
          if (acao != null) acao!,
        ],
      ),
    );
  }
}
