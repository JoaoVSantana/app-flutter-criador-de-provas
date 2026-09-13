//Banco de questoes da professoraclass ListaQuestoesScreen extends StatelessWidget {
import 'package:flutter/material.dart';

class ListaQuestoes extends StatelessWidget {
  const ListaQuestoes({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Banco de questões')),
      body: const Center(child: Text('Lista de questões')),
    );
  }
}
