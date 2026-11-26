import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../screens/Home/home.dart';
import '../screens/BancoQuestoes/questoes.dart';
import '../screens/CriarProva/prova.dart';
import '../screens/Relatorios/relatorios.dart';
import '../screens/Turmas/turmas.dart';
import '../screens/CorrigirProvas/corrigir.dart';
import '../screens/Entrar/entrar.dart';
import '../widgets/perfil.dart';

class AppRoutes {
  static const home = '/';
  static const listaQuestoes = '/questoes';
  static const criarProva = '/prova';
  static const listaTurmas = '/turmas';
  static const correcao = '/corrigir';
  static const relatorios = '/relatorios';
  static const entrar = '/entrar';
  static const perfil = '/perfil';
}

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> with WidgetsBindingObserver {
  // Erros que significam "essa conta não vale mais"
  static const _sessaoInvalida = {
    'user-not-found',
    'user-disabled',
    'user-token-expired',
    'invalid-user-token',
    'invalid-credential',
  };

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _validarSessao();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _validarSessao();
  }

  Future<void> _validarSessao() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      await user.reload(); // pergunta ao servidor se a conta ainda existe
    } on FirebaseAuthException catch (e) {
      if (_sessaoInvalida.contains(e.code)) {
        await FirebaseAuth.instance.signOut();
        // Fecha telas abertas por cima; o gate volta para o login
        if (mounted) Navigator.of(context).popUntil((r) => r.isFirst);
      }
    } catch (_) {
      // Sem internet ou erro passageiro: mantém a sessão
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      initialData: FirebaseAuth.instance.currentUser,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return const Scaffold(
            backgroundColor: Color.fromARGB(255, 228, 235, 230),
            body: Center(child: CircularProgressIndicator()),
          );
        }
        return snapshot.data != null ? const Home() : const Entrar();
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
        AppRoutes.perfil: (context) => const PerfilScreen(),
      },
    );
  }
}
