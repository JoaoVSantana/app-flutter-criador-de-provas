import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LoginForm extends StatefulWidget {
  final TextEditingController emailController;
  final double padding;

  const LoginForm({
    super.key,
    required this.emailController,
    required this.padding,
  });

  @override
  State<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  final _senhaController = TextEditingController();
  bool _carregando = false;

  @override
  void dispose() {
    _senhaController.dispose();
    super.dispose();
  }

  void _mostrarErro(String mensagem) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensagem), backgroundColor: Colors.red.shade700),
    );
  }

  Future<void> _fazerLogin() async {
    final email = widget.emailController.text.trim();
    final senha = _senhaController.text;

    if (email.isEmpty || senha.isEmpty) {
      _mostrarErro('Preencha e-mail e senha.');
      return;
    }

    setState(() => _carregando = true);
    try {
      // TODO: sua lógica de login aqui (use `email` e `senha`)
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
            controller: widget.emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: decoracaoCampo('Email'),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _senhaController,
            obscureText: true,
            decoration: decoracaoCampo('Senha'),
            onSubmitted: (_) => _fazerLogin(),
          ),
          const SizedBox(height: 24),
          BotaoPrincipal(
            texto: 'Entrar',
            carregando: _carregando,
            onPressed: _fazerLogin,
          ),
        ],
      ),
    );
  }
}

InputDecoration decoracaoCampo(String label) {
  return InputDecoration(
    labelText: label,
    filled: true,
    fillColor: Colors.white,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide.none,
    ),
  );
}

class BotaoPrincipal extends StatelessWidget {
  final String texto;
  final VoidCallback onPressed;
  final bool carregando;

  const BotaoPrincipal({
    super.key,
    required this.texto,
    required this.onPressed,
    this.carregando = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: carregando ? null : onPressed,
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14),
          backgroundColor: const Color.fromARGB(255, 47, 51, 49),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: carregando
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Text(
                texto,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }
}
