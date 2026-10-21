import 'package:flutter/material.dart';

import 'breakpoint.dart';
import '../../widgets/header.dart';
import '../../widgets/drawernav.dart';
import '../../widgets/navegar.dart';
import 'cadastro.dart';
import 'login.dart';

class Entrar extends StatefulWidget {
  const Entrar({super.key});

  @override
  State<Entrar> createState() => _EntrarState();
}

class _EntrarState extends State<Entrar> {
  final PageController _pageController = PageController();
  final TextEditingController _loginEmailController = TextEditingController();
  int _paginaAtual = 0;

  void _irParaPagina(int index) {
    setState(() => _paginaAtual = index);
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    _loginEmailController.dispose();
    super.dispose();
  }

  Widget _buildAba(String texto, int index, double fontAba) {
    final ativo = _paginaAtual == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => _irParaPagina(index),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          decoration: BoxDecoration(
            color: ativo ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
          ),
          alignment: Alignment.center,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              texto,
              maxLines: 1,
              style: TextStyle(
                fontSize: fontAba,
                fontWeight: FontWeight.w400,
                fontFamily: 'Poppins',
              ),
            ),
          ),
        ),
      ),
    );
  }

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
            ? 140
            : isTablet
            ? 180
            : 220;

        final double fontAba = isMobile ? 16 : 20;
        final double paddingFormulario = isMobile ? 12 : 24;

        final conteudoCard = Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildAba('Login', 0, fontAba),
                const SizedBox(width: 16),
                _buildAba('Cadastro', 1, fontAba),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: isMobile ? 420 : 460,
              child: PageView(
                controller: _pageController,
                onPageChanged: (index) => setState(() => _paginaAtual = index),
                children: [
                  LoginForm(
                    emailController: _loginEmailController,
                    padding: paddingFormulario,
                  ),
                  CadastroForm(
                    padding: paddingFormulario,
                    onCadastrado: (email) {
                      _loginEmailController.text = email;
                      _irParaPagina(0);
                    },
                  ),
                ],
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
                      Image.asset(
                        'assets/images/criar_prova.png',
                        width: tamanhoImagem,
                        height: tamanhoImagem,
                        fit: BoxFit.contain,
                      ),
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
                      Image.asset(
                        'assets/images/criar_prova.png',
                        width: tamanhoImagem,
                        height: tamanhoImagem,
                        fit: BoxFit.contain,
                      ),
                      const SizedBox(height: 12),
                      conteudoCard,
                    ],
                  ),
                ),
              );

        return Scaffold(
          drawer: const DrawerNav(),
          backgroundColor: const Color.fromARGB(255, 232, 236, 233),
          body: Column(
            children: [
              const Header(),
              Align(
                alignment: Alignment.centerLeft,
                child: Builder(
                  builder: (context) => IconButton(
                    icon: const Icon(Icons.menu),
                    onPressed: () => Scaffold.of(context).openDrawer(),
                  ),
                ),
              ),
              Expanded(
                child: Container(
                  width: double.infinity,
                  color: const Color.fromARGB(255, 228, 235, 230),
                  padding: EdgeInsets.symmetric(
                    horizontal: isMobile ? 8 : 24,
                    vertical: 16,
                  ),
                  child: SingleChildScrollView(child: conteudoPrincipal),
                ),
              ),
              const SizedBox(height: 24),
              Navegar(
                onVoltar: _paginaAtual == 0
                    ? () => Navigator.pop(context)
                    : () => _irParaPagina(0),
                onAvancar: _paginaAtual == 0 ? () => _irParaPagina(1) : null,
              ),
            ],
          ),
        );
      },
    );
  }
}
