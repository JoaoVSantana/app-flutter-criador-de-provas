import 'package:flutter/material.dart';

import '../../widgets/header.dart';
import '../../widgets/drawernav.dart';
import '../../widgets/navegar.dart';

/// Breakpoints usados em todo o app.
class Breakpoints {
  static const double mobile = 600;
  static const double tablet = 1024;
}

class Entrar extends StatefulWidget {
  const Entrar({super.key});

  @override
  State<Entrar> createState() => _EntrarState();
}

class _EntrarState extends State<Entrar> {
  final PageController _pageController = PageController();
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

  InputDecoration _decoracaoCampo(String label) {
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

  Widget _botao(String texto, VoidCallback onPressed) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14),
          backgroundColor: const Color.fromARGB(255, 47, 51, 49),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(
          texto,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _paginaLogin(double paddingFormulario) {
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: paddingFormulario),
      child: Column(
        children: [
          TextField(decoration: _decoracaoCampo('Email')),
          const SizedBox(height: 16),
          TextField(obscureText: true, decoration: _decoracaoCampo('Senha')),
          const SizedBox(height: 24),
          _botao('Entrar', () {}),
        ],
      ),
    );
  }

  Widget _paginaCadastro(double paddingFormulario) {
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: paddingFormulario),
      child: Column(
        children: [
          TextField(decoration: _decoracaoCampo('Nome')),
          const SizedBox(height: 16),
          TextField(decoration: _decoracaoCampo('Sobrenome')),
          const SizedBox(height: 16),
          TextField(decoration: _decoracaoCampo('Email')),
          const SizedBox(height: 16),
          TextField(
            keyboardType: TextInputType.number,
            decoration: _decoracaoCampo('CPF'),
          ),
          const SizedBox(height: 16),
          TextField(obscureText: true, decoration: _decoracaoCampo('Senha')),
          const SizedBox(height: 24),
          _botao('Cadastrar', () {}),
        ],
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

        // Conteúdo do card: abas + formulário deslizante
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
              // Altura fixa para o PageView poder rolar internamente
              height: isMobile ? 420 : 460,
              child: PageView(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() => _paginaAtual = index);
                },
                children: [
                  _paginaLogin(paddingFormulario),
                  _paginaCadastro(paddingFormulario),
                ],
              ),
            ),
          ],
        );

        // Em telas grandes: imagem ao lado do formulário, formulário com
        // largura máxima para não esticar. Em telas pequenas: tudo empilhado.
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
