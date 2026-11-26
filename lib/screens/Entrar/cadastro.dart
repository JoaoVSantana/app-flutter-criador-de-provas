import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../respostaErro/respostaErro.dart';
import '/service/usuario_service.dart';
import 'login.dart' show decoracaoCampo, BotaoPrincipal;

class CadastroForm extends StatefulWidget {
  final double padding;

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
  final _emailController = TextEditingController();
  final _senhaController = TextEditingController();
  bool _carregando = false;
  bool _mostrarSenha = false;

  @override
  void dispose() {
    _nomeController.dispose();
    _emailController.dispose();
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
    final email = _emailController.text.trim();
    final senha = _senhaController.text;

    if (nome.isEmpty || email.isEmpty || senha.isEmpty) {
      _mostrarErro('Preencha nome, e-mail e senha.');
      return;
    }
    if (senha.length < 6) {
      _mostrarErro('A senha precisa ter pelo menos 6 caracteres.');
      return;
    }

    setState(() => _carregando = true);
    try {
      await UsuarioService().cadastrar(nome: nome, email: email, senha: senha);
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      _mostrarErro(traduzirErro(e.code));
    } on FirebaseException catch (e) {
      if (!mounted) return;
      _mostrarErro('Erro ao salvar dados: ${e.code}');
    } catch (e) {
      if (!mounted) return;
      _mostrarErro('Erro inesperado: $e');
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: widget.padding, vertical: 12),
      child: Column(
        children: [
          TextField(
            controller: _nomeController,
            textCapitalization: TextCapitalization.words,
            autofillHints: const [AutofillHints.givenName],
            decoration: decoracaoCampo('Nome'),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            autofillHints: const [AutofillHints.email],
            decoration: decoracaoCampo('Email'),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _senhaController,
            obscureText: !_mostrarSenha,
            autofillHints: const [AutofillHints.newPassword],
            decoration: decoracaoCampo('Senha').copyWith(
              suffixIcon: IconButton(
                tooltip: _mostrarSenha ? 'Ocultar senha' : 'Mostrar senha',
                icon: Icon(
                  _mostrarSenha
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                ),
                onPressed: () => setState(() => _mostrarSenha = !_mostrarSenha),
              ),
            ),
            onSubmitted: (_) => _fazerCadastro(),
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
