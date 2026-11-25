import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../respostaErro/respostaErro.dart';
import '../Home/home.dart';
import '/service/usuario_service.dart';
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
  final _senhaController = TextEditingController();
  bool _carregando = false;

  @override
  void dispose() {
    _nomeController.dispose();
    _sobrenomeController.dispose();
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
    final sobrenome = _sobrenomeController.text.trim();
    final email = _emailController.text.trim();
    final senha = _senhaController.text;

    if (nome.isEmpty || email.isEmpty || senha.isEmpty) {
      _mostrarErro('Preencha ao menos nome, e-mail e senha.');
      return;
    }
    setState(() => _carregando = true);
    try {
      await UsuarioService().cadastrar(
        nome: nome,
        sobrenome: sobrenome,
        cpf: '',
        email: email,
        senha: senha,
      );
      if (!mounted) return;
      Navigator.push(context, MaterialPageRoute(builder: (_) => const Home()));
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
                  controller: _nomeController,
                  decoration: decoracaoCampo(
                    'Nome',
                    icone: Icons.person_outline,
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _sobrenomeController,
                  decoration: decoracaoCampo(
                    'Sobrenome',
                    icone: Icons.badge_outlined,
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: decoracaoCampo(
                    'Email',
                    icone: Icons.mail_outline,
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _senhaController,
                  obscureText: true,
                  decoration: decoracaoCampo(
                    'Senha',
                    icone: Icons.lock_outline,
                  ),
                ),
                const SizedBox(height: 22),
                BotaoPrincipal(
                  texto: 'Cadastrar  →',
                  carregando: _carregando,
                  onPressed: _fazerCadastro,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}