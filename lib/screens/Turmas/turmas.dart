import 'package:flutter/material.dart';

class Turmas extends StatelessWidget {
  const Turmas({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Turmas e Alunos')),
      body: const Center(child: Text('Lista de turmas e alunos')),
    );
  }
}
