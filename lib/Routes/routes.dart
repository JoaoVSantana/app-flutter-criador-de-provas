// lib/app.dart
import 'package:flutter/material.dart';

import '../screens/Home/home.dart';
import '../screens/BancoQuestoes/questoes.dart';
import '../screens/CriarProva/prova.dart';
import '../screens/Relatórios/relatorios.dart';
import '../screens/Turmas/turmas.dart';
import '../screens/CorrigirProvas/corrigir.dart';
import '../screens/Cadastro/cadastro.dart';

class AppRoutes {
  static const home = '/';
  static const listaQuestoes = '/questoes';
  static const criarProva = '/prova';
  static const listaTurmas = '/turmas';
  static const correcao = '/corrigir';
  static const relatorios = '/relatorios';
  static const cadastro = '/cadastro';
}

class Routes extends StatelessWidget {
  const Routes({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      initialRoute: AppRoutes.home,
      routes: {
        AppRoutes.home: (context) => Home(),
        AppRoutes.listaQuestoes: (context) => const ListaQuestoes(),
        AppRoutes.criarProva: (context) => const Prova(),
        AppRoutes.correcao: (context) => Corrigir(),
        AppRoutes.cadastro: (context) => const Cadastro(),
        AppRoutes.listaTurmas: (context) => const Turmas(),
        AppRoutes.relatorios: (context) => const Relatorios(),
      },
    );
  }
}
