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
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
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
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          decoration: BoxDecoration(
            color: ativo ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(28),
            boxShadow: ativo
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          alignment: Alignment.center,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              texto,
              maxLines: 1,
              style: TextStyle(
                fontSize: fontAba,
                fontWeight: ativo ? FontWeight.w700 : FontWeight.w500,
                fontFamily: 'Poppins',
                color: const Color.fromARGB(255, 47, 51, 49),
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
            ? 155
            : isTablet
            ? 190
            : 220;

        final double fontAba = isMobile ? 16 : 19;
        final double paddingFormulario = isMobile ? 6 : 12;

        final seletorAbas = Container(
          constraints: const BoxConstraints(maxWidth: 420),
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: const Color.fromARGB(255, 214, 224, 211),
            borderRadius: BorderRadius.circular(32),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 14,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Row(
            children: [
              _buildAba('Login', 0, fontAba),
              _buildAba('Cadastro', 1, fontAba),
            ],
          ),
        );

        final conteudoCard = Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            seletorAbas,
            const SizedBox(height: 18),
            SizedBox(
              height: _paginaAtual == 0
                  ? (isMobile ? 275 : 290)
                  : (isMobile ? 430 : 450),
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
                  constraints: const BoxConstraints(maxWidth: 920),
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
                      const SizedBox(width: 40),
                      Expanded(child: conteudoCard),
                    ],
                  ),
                ),
              )
            : Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 460),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Image.asset(
                        'assets/images/criar_prova.png',
                        width: tamanhoImagem,
                        height: tamanhoImagem,
                        fit: BoxFit.contain,
                      ),
                      const SizedBox(height: 20),
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
              Expanded(
                child: Container(
                  width: double.infinity,
                  color: const Color.fromARGB(255, 228, 235, 230),
                  child: Stack(
                    children: [
                      Positioned(
                        top: -70,
                        right: -60,
                        child: Container(
                          width: 220,
                          height: 220,
                          decoration: BoxDecoration(
                            color: const Color.fromARGB(255, 214, 224, 211)
                                .withValues(alpha: 0.75),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: -90,
                        left: -70,
                        child: Container(
                          width: 250,
                          height: 250,
                          decoration: BoxDecoration(
                            color: const Color.fromARGB(255, 214, 224, 211)
                                .withValues(alpha: 0.7),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                      Positioned(
                        top: 8,
                        left: 8,
                        child: Builder(
                          builder: (context) => IconButton(
                            icon: const Icon(
                              Icons.menu,
                              color: Color.fromARGB(255, 47, 51, 49),
                            ),
                            onPressed: () => Scaffold.of(context).openDrawer(),
                          ),
                        ),
                      ),
                      Center(
                        child: SingleChildScrollView(
                          padding: EdgeInsets.symmetric(
                            horizontal: isMobile ? 16 : 24,
                            vertical: 28,
                          ),
                          child: conteudoPrincipal,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
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


