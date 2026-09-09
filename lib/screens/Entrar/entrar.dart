import 'package:flutter/material.dart';

import '../../widgets/header.dart';
import '../../widgets/drawernav.dart';
import '../../widgets/navegar.dart';

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

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final larguraTela = constraints.maxWidth;

        // Imagem escala com a largura da tela, com limites mín/máx
        final tamanhoImagem = (larguraTela * 0.45).clamp(120.0, 200.0);

        // Fonte das abas Login/Cadastro
        final fontAba = (larguraTela * 0.05).clamp(16.0, 20.0);

        // Padding lateral dos formulários
        final paddingFormulario = larguraTela * 0.03;

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
                  child: Padding(
                    padding: const EdgeInsets.all(5),
                    child: Column(
                      children: [
                        Image.asset(
                          'assets/images/criar_prova.png',
                          width: tamanhoImagem,
                          height: tamanhoImagem,
                          fit: BoxFit.contain,
                        ),
                        const SizedBox(height: 12),

                        // Botões "abas" que também mudam a página
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            GestureDetector(
                              onTap: () => _irParaPagina(0),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: _paginaAtual == 0
                                      ? Colors.white
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  'Login',
                                  style: TextStyle(
                                    fontSize: fontAba,
                                    fontWeight: FontWeight.w400,
                                    fontFamily: 'Poppins',
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            GestureDetector(
                              onTap: () => _irParaPagina(1),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: _paginaAtual == 1
                                      ? Colors.white
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  'Cadastro',
                                  style: TextStyle(
                                    fontSize: fontAba,
                                    fontWeight: FontWeight.w400,
                                    fontFamily: 'Poppins',
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 12),

                        // Conteúdo que desliza
                        Expanded(
                          child: PageView(
                            controller: _pageController,
                            onPageChanged: (index) {
                              setState(() => _paginaAtual = index);
                            },
                            children: [
                              // Página "Login"
                              SingleChildScrollView(
                                padding: EdgeInsets.symmetric(
                                  horizontal: paddingFormulario,
                                ),
                                child: Column(
                                  children: [
                                    TextField(
                                      decoration: InputDecoration(
                                        labelText: 'Email',
                                        filled: true,
                                        fillColor: Colors.white,
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          borderSide: BorderSide.none,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    TextField(
                                      obscureText: true,
                                      decoration: InputDecoration(
                                        labelText: 'Senha',
                                        filled: true,
                                        fillColor: Colors.white,
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          borderSide: BorderSide.none,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 24),
                                    SizedBox(
                                      width: double.infinity,
                                      child: ElevatedButton(
                                        onPressed: () {},
                                        style: ElevatedButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 14,
                                          ),
                                          backgroundColor: const Color.fromARGB(
                                            255,
                                            47,
                                            51,
                                            49,
                                          ),
                                          foregroundColor: Colors.white,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                        ),
                                        child: const Text(
                                          'Entrar',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // Página "Cadastro"
                              SingleChildScrollView(
                                padding: EdgeInsets.symmetric(
                                  horizontal: paddingFormulario,
                                ),
                                child: Column(
                                  children: [
                                    TextField(
                                      decoration: InputDecoration(
                                        labelText: 'Nome',
                                        filled: true,
                                        fillColor: Colors.white,
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          borderSide: BorderSide.none,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    TextField(
                                      decoration: InputDecoration(
                                        labelText: 'Sobrenome',
                                        filled: true,
                                        fillColor: Colors.white,
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          borderSide: BorderSide.none,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    TextField(
                                      decoration: InputDecoration(
                                        labelText: 'Email',
                                        filled: true,
                                        fillColor: Colors.white,
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          borderSide: BorderSide.none,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    TextField(
                                      keyboardType: TextInputType.number,
                                      decoration: InputDecoration(
                                        labelText: 'CPF',
                                        filled: true,
                                        fillColor: Colors.white,
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          borderSide: BorderSide.none,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    TextField(
                                      obscureText: true,
                                      decoration: InputDecoration(
                                        labelText: 'Senha',
                                        filled: true,
                                        fillColor: Colors.white,
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          borderSide: BorderSide.none,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 24),
                                    SizedBox(
                                      width: double.infinity,
                                      child: ElevatedButton(
                                        onPressed: () {},
                                        style: ElevatedButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 14,
                                          ),
                                          backgroundColor: const Color.fromARGB(
                                            255,
                                            47,
                                            51,
                                            49,
                                          ),
                                          foregroundColor: Colors.white,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                        ),
                                        child: const Text(
                                          'Cadastrar',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Setas mudam de comportamento conforme a página ativa
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
