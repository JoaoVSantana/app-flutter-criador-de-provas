import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'login.dart' show decoracaoCampo, BotaoPrincipal;

class CadastroForm extends StatefulWidget {
  final double padding;

  /// Chame quando o cadastro der certo (volta para a aba de login).
  final void Function(String email) onCadastrado;

  const CadastroForm({
    super.key,
    required this.padding,
    required this.onCadastrado,
  });

  @override
  State<CadastroForm> createState() => _CadastroFormState();
}

class _CadastroFormState extends State<CadastroForm> {
  final _nomeController = TextEditingController();
  final _sobrenomeController = TextEditingController();
  final _emailController = TextEditingController();
  final _cpfController = TextEditingController();
  final _senhaController = TextEditingController();
  bool _carregando = false;

  @override
  void dispose() {
    _nomeController.dispose();
    _sobrenomeController.dispose();
    _emailController.dispose();
    _cpfController.dispose();
    _senhaController.dispose();
    super.dispose();
  }

  void _mostrarErro(String mensagem) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensagem), backgroundColor: Colors.red.shade700),
    );
  }

  Future<void> _fazerCadastro() async {
    final nome = _nomeController.text.trim();
    final sobrenome = _sobrenomeController.text.trim();
    final email = _emailController.text.trim();
    final cpf = _cpfController.text.trim();
    final senha = _senhaController.text;

    if (nome.isEmpty || email.isEmpty || senha.isEmpty) {
      _mostrarErro('Preencha ao menos nome, e-mail e senha.');
      return;
    }

    setState(() => _carregando = true);
    try {
      // TODO: sua lógica de cadastro aqui
      // (use nome, sobrenome, email, cpf e senha)
      //
      // Quando o cadastro der certo, chame:
      // widget.onCadastrado(email);
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: widget.padding),
      child: Column(
        children: [
          TextField(
            controller: _nomeController,
            decoration: decoracaoCampo('Nome'),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _sobrenomeController,
            decoration: decoracaoCampo('Sobrenome'),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: decoracaoCampo('Email'),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _cpfController,
            keyboardType: TextInputType.number,
            decoration: decoracaoCampo('CPF'),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _senhaController,
            obscureText: true,
            decoration: decoracaoCampo('Senha'),
          ),
          const SizedBox(height: 24),
          BotaoPrincipal(
            texto: 'Cadastrar',
            carregando: _carregando,
            onPressed: _fazerCadastro,
          ),
        ],
      ),
    );
  }
}
