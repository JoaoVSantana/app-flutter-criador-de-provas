import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../screens/Home/home.dart';
import '../screens/BancoQuestoes/questoes.dart';
import '../screens/CriarProva/prova.dart';
import '../screens/Relatorios/relatorios.dart';
import '../screens/Turmas/turmas.dart';
import '../screens/CorrigirProvas/corrigir.dart';
import '../screens/Entrar/entrar.dart';

class AppRoutes {
  static const home = '/';
  static const listaQuestoes = '/questoes';
  static const criarProva = '/prova';
  static const listaTurmas = '/turmas';
  static const correcao = '/corrigir';
  static const relatorios = '/relatorios';
  static const entrar = '/entrar';
}

// Verifica se existe um usuário autenticado
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        print('AUTH GATE: ${snapshot.connectionState}');
        print('USUÁRIO: ${snapshot.data?.uid}');
        print('TEM DADOS: ${snapshot.hasData}');

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasData) {
          print('DIRECIONANDO PARA HOME');
          return const Home();
        }

        print('DIRECIONANDO PARA LOGIN');
        return const Entrar();
      },
    );
  }
}

class Routes extends StatelessWidget {
  const Routes({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      initialRoute: AppRoutes.home,
      routes: {
        AppRoutes.home: (context) => const AuthGate(),
        AppRoutes.listaQuestoes: (context) => const ListaQuestoes(),
        AppRoutes.criarProva: (context) => const Prova(),
        AppRoutes.correcao: (context) => Corrigir(),
        AppRoutes.entrar: (context) => const Entrar(),
        AppRoutes.listaTurmas: (context) => TurmasScreen(),
        AppRoutes.relatorios: (context) => const Relatorios(),
      },
    );
  }
}
