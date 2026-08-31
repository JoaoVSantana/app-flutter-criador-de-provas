//Montar a prova
import 'package:flutter/material.dart';

class Prova extends StatelessWidget {
  const Prova({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Banco de questões')),
      body: const Center(child: Text('Lista de questões')),
    );
  }
}
