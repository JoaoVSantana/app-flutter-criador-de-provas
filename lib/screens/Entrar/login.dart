import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../Home/home.dart';
import '/service/usuario_service.dart';
import '../../respostaErro/respostaErro.dart';

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
      await UsuarioService().entrar(email: email, senha: senha);
      if (!mounted) return;
      Navigator.push(context, MaterialPageRoute(builder: (_) => const Home()));
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      _mostrarErro(traduzirErro(e.code));
    } catch (e) {
      if (!mounted) return;
      _mostrarErro('Erro inesperado: $e');
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: widget.padding,
          vertical: 16,
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.78),
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 24,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: widget.emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: decoracaoCampo(
                    'Email',
                    icone: Icons.mail_outline,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _senhaController,
                  obscureText: true,
                  decoration: decoracaoCampo(
                    'Senha',
                    icone: Icons.lock_outline,
                  ),
                  onSubmitted: (_) => _fazerLogin(),
                ),
                const SizedBox(height: 22),
                BotaoPrincipal(
                  texto: 'Entrar  →',
                  carregando: _carregando,
                  onPressed: _fazerLogin,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

InputDecoration decoracaoCampo(String label, {IconData? icone}) {
  return InputDecoration(
    hintText: label,
    prefixIcon: icone != null
        ? Padding(
            padding: const EdgeInsets.only(left: 18, right: 12),
            child: Icon(
              icone,
              color: const Color.fromARGB(255, 47, 51, 49),
              size: 20,
            ),
          )
        : null,
    prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
    filled: true,
    fillColor: Colors.white,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(28),
      borderSide: BorderSide(
        color: Colors.black.withValues(alpha: 0.14),
        width: 1,
      ),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(28),
      borderSide: BorderSide(
        color: Colors.black.withValues(alpha: 0.14),
        width: 1,
      ),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(28),
      borderSide: const BorderSide(
        color: Color(0xFF4C6B5E),
        width: 1.5,
      ),
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
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: const Color.fromARGB(255, 47, 51, 49).withValues(alpha: 0.22),
              blurRadius: 16,
              offset: const Offset(0, 7),
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: carregando ? null : onPressed,
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            backgroundColor: const Color.fromARGB(255, 47, 51, 49),
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(28),
            ),
          ),
          child: carregando
              ? const SizedBox(
                  height: 22,
                  width: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.2,
                    color: Colors.white,
                  ),
                )
              : Text(
                  texto,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.2,
                  ),
                ),
        ),
      ),
    );
  }
}