import 'package:flutter/material.dart';

import 'breakpoint.dart';
import 'cadastro.dart';
import 'login.dart';

class Entrar extends StatefulWidget {
  const Entrar({super.key});

  @override
  State<Entrar> createState() => _EntrarState();
}

class _EntrarState extends State<Entrar> {
  final TextEditingController _loginEmailController = TextEditingController();
  bool _modoLogin = true;

  @override
  void dispose() {
    _loginEmailController.dispose();
    super.dispose();
  }

  void _alternarModo() => setState(() => _modoLogin = !_modoLogin);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final larguraTela = constraints.maxWidth;

        final isMobile = larguraTela < Breakpoints.mobile;
        final isTablet =
            larguraTela >= Breakpoints.mobile &&
            larguraTela < Breakpoints.tablet;
        final isDesktop = larguraTela >= Breakpoints.tablet;

        final double tamanhoImagem = isMobile
            ? 200
            : isTablet
            ? 240
            : 300;

        final double fontTitulo = isMobile ? 26 : 32;
        final double paddingFormulario = isMobile ? 12 : 24;

        final imagem = Image.asset(
          'assets/images/criar_prova.png',
          width: tamanhoImagem,
          fit: BoxFit.contain,
          filterQuality: FilterQuality.high,
          isAntiAlias: true,
        );

        final conteudoCard = Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _modoLogin ? 'Bem-vindo ao Test Fast' : 'Criar conta',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: fontTitulo,
                fontFamily: 'Oswald',
                fontWeight: FontWeight.w800,
                color: const Color.fromARGB(255, 58, 95, 73),
              ),
            ),
            const SizedBox(height: 20),
            _modoLogin
                ? LoginForm(
                    emailController: _loginEmailController,
                    padding: paddingFormulario,
                  )
                : CadastroForm(
                    padding: paddingFormulario,
                    onCadastrado: (_) {},
                  ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: _alternarModo,
              child: Text(
                _modoLogin
                    ? 'Não tem conta? Criar conta'
                    : 'Já tem conta? Entrar',
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 15,
                  color: Color.fromARGB(255, 63, 107, 88),
                ),
              ),
            ),
          ],
        );

        final conteudoPrincipal = isDesktop || isTablet
            ? Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 900),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      imagem,
                      const SizedBox(width: 32),
                      Expanded(child: conteudoCard),
                    ],
                  ),
                ),
              )
            : Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 480),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      imagem,
                      const SizedBox(height: 12),
                      conteudoCard,
                    ],
                  ),
                ),
              );

        return Scaffold(
          backgroundColor: const Color.fromARGB(255, 228, 235, 230),
          body: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: isMobile ? 8 : 24,
                  vertical: 16,
                ),
                child: conteudoPrincipal,
              ),
            ),
          ),
        );
      },
    );
  }
}
