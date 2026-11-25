import 'package:flutter/material.dart';

class Navegar extends StatelessWidget {
  final VoidCallback? onVoltar;
  final VoidCallback? onAvancar;
  final String? rotuloCentro;

  const Navegar({
    super.key,
    required this.onVoltar,
    required this.onAvancar,
    this.rotuloCentro,
  });

  @override
  Widget build(BuildContext context) {
    final podeVoltar = onVoltar != null;
    final podeAvancar = onAvancar != null;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: const BoxDecoration(
        color: Color.fromARGB(255, 150, 194, 176),
        border: Border(
          top: BorderSide(color: Color.fromARGB(30, 0, 0, 0), width: 1),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          TextButton.icon(
            onPressed: onVoltar,
            icon: Icon(
              Icons.arrow_back_ios_new,
              size: 18,
              color: podeVoltar ? Colors.black87 : Colors.black38,
            ),
            label: Text(
              'Voltar',
              style: TextStyle(
                color: podeVoltar ? Colors.black87 : Colors.black38,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (rotuloCentro != null && rotuloCentro!.isNotEmpty)
            Flexible(
              child: Text(
                rotuloCentro!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ),
          TextButton.icon(
            onPressed: onAvancar,
            iconAlignment: IconAlignment.end,
            icon: Icon(
              Icons.arrow_forward_ios,
              size: 18,
              color: podeAvancar ? Colors.black87 : Colors.black38,
            ),
            label: Text(
              'Avançar',
              style: TextStyle(
                color: podeAvancar ? Colors.black87 : Colors.black38,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}