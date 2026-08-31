import 'package:flutter/material.dart';

import '../../Routes/routes.dart';

class Home extends StatelessWidget {
  const Home({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Início')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            ElevatedButton(
              onPressed: () => Navigator.pushNamed(context, AppRoutes.cadastro),
              child: const Text('Entrar'),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () =>
                  Navigator.pushNamed(context, AppRoutes.listaQuestoes),
              child: const Text('Banco de questões'),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () =>
                  Navigator.pushNamed(context, AppRoutes.criarProva),
              child: const Text('Criar prova'),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () =>
                  Navigator.pushNamed(context, AppRoutes.listaTurmas),
              child: const Text('Turmas e alunos'),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => Navigator.pushNamed(context, AppRoutes.correcao),
              child: const Text('Corrigir provas'),
            ),
            ElevatedButton(
              onPressed: () =>
                  Navigator.pushNamed(context, AppRoutes.relatorios),
              child: const Text('Banco de questões'),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}
