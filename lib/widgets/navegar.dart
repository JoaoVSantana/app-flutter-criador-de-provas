import 'package:flutter/material.dart';

class Navegar extends StatelessWidget {
  final VoidCallback? onVoltar;
  final VoidCallback? onAvancar;

  const Navegar({super.key, required this.onVoltar, required this.onAvancar});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color.fromARGB(255, 150, 194, 176),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: onVoltar,
            icon: const Icon(Icons.arrow_back_ios),
            color: onVoltar == null ? Colors.grey : Colors.black,
          ),
          IconButton(
            onPressed: onAvancar,
            icon: const Icon(Icons.arrow_forward_ios),
            color: onAvancar == null ? Colors.grey : Colors.black,
          ),
        ],
      ),
    );
  }
}
