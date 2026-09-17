import 'package:flutter/material.dart';

import '../../widgets/header.dart';
import '../../widgets/drawernav.dart';
import '../../widgets/navegar.dart';

class Breakpoints {
  static const double mobile = 600;
  static const double tablet = 1024;
}

class Usuario {
  final String nome;
  final String sobrenome;
  final String email;
  final String cpf;
  final String senha;

  const Usuario({
    required this.nome,
    required this.sobrenome,
    required this.email,
    required this.cpf,
    required this.senha,
  });

  factory Usuario.vazio() {
    return const Usuario(
      nome: '',
      sobrenome: '',
      email: '',
      cpf: '',
      senha: '',
    );
  }

  bool get isVazio => email.isEmpty;
}

class MockDB {
  static final List<Usuario> usuarios = [
    const Usuario(
      nome: 'Maria',
      sobrenome: 'Souza',
      email: 'maria@teste.com',
      cpf: '00000000000',
      senha: '123456',
    ),
  ];

  static void salvar(Usuario usuario) {
    usuarios.add(usuario);
  }

  static Usuario buscarPorLogin(String email, String senha) {
    return usuarios.firstWhere(
      (u) => u.email == email && u.senha == senha,
      orElse: Usuario.vazio,
    );
  }

  static bool existeEmail(String email) {
    return usuarios.any((u) => u.email == email);
  }
}

class Entrar extends StatefulWidget {
  const Entrar({super.key});

  @override
  State<Entrar> createState() => _EntrarState();
}

class _EntrarState extends State<Entrar> {
  final PageController _pageController = PageController();
  int _paginaAtual = 0;

  final TextEditingController _loginEmailController = TextEditingController();
  final TextEditingController _loginSenhaController = TextEditingController();

  final TextEditingController _cadNomeController = TextEditingController();
  final TextEditingController _cadSobrenomeController = TextEditingController();
  final TextEditingController _cadEmailController = TextEditingController();
  final TextEditingController _cadCpfController = TextEditingController();
  final TextEditingController _cadSenhaController = TextEditingController();

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
    _loginSenhaController.dispose();
    _cadNomeController.dispose();
    _cadSobrenomeController.dispose();
    _cadEmailController.dispose();
    _cadCpfController.dispose();
    _cadSenhaController.dispose();
    super.dispose();
  }

  void _mostrarErro(String mensagem) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensagem), backgroundColor: Colors.red.shade700),
    );
  }

  void _mostrarDialogo(
    String titulo,
    String conteudo, {
    VoidCallback? aoFechar,
  }) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(titulo),
        content: Text(conteudo),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              aoFechar?.call();
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _fazerCadastro() {
    final nome = _cadNomeController.text.trim();
    final sobrenome = _cadSobrenomeController.text.trim();
    final email = _cadEmailController.text.trim();
    final cpf = _cadCpfController.text.trim();
    final senha = _cadSenhaController.text;

    if (nome.isEmpty || email.isEmpty || senha.isEmpty) {
      _mostrarErro('Preencha ao menos nome, e-mail e senha.');
      return;
    }

    if (MockDB.existeEmail(email)) {
      _mostrarErro('Já existe um usuário cadastrado com esse e-mail.');
      return;
    }

    final novoUsuario = Usuario(
      nome: nome,
      sobrenome: sobrenome,
      email: email,
      cpf: cpf,
      senha: senha,
    );

    MockDB.salvar(novoUsuario);

    _mostrarDialogo(
      'Usuário cadastrado!',
      'Nome: ${novoUsuario.nome} ${novoUsuario.sobrenome}\n'
          'E-mail: ${novoUsuario.email}\n'
          'CPF: ${novoUsuario.cpf.isEmpty ? "-" : novoUsuario.cpf}\n\n'
          'Agora você já pode fazer login com esses dados.',
      aoFechar: () {
        // Preenche o login com o e-mail recém-cadastrado e manda pra aba de login
        _loginEmailController.text = novoUsuario.email;
        _irParaPagina(0);
      },
    );
  }

  void _fazerLogin() {
    final email = _loginEmailController.text.trim();
    final senha = _loginSenhaController.text;

    if (email.isEmpty || senha.isEmpty) {
      _mostrarErro('Preencha e-mail e senha.');
      return;
    }

    final usuario = MockDB.buscarPorLogin(email, senha);

    if (usuario.isVazio) {
      _mostrarErro('E-mail ou senha inválidos.');
      return;
    }

    _mostrarDialogo(
      'Login realizado!',
      'Bem-vindo(a), ${usuario.nome}!\n'
          'E-mail: ${usuario.email}',
    );
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
          TextField(
            controller: _loginEmailController,
            decoration: _decoracaoCampo('Email'),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _loginSenhaController,
            obscureText: true,
            decoration: _decoracaoCampo('Senha'),
          ),
          const SizedBox(height: 24),
          _botao('Entrar', _fazerLogin),
        ],
      ),
    );
  }

  Widget _paginaCadastro(double paddingFormulario) {
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: paddingFormulario),
      child: Column(
        children: [
          TextField(
            controller: _cadNomeController,
            decoration: _decoracaoCampo('Nome'),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _cadSobrenomeController,
            decoration: _decoracaoCampo('Sobrenome'),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _cadEmailController,
            decoration: _decoracaoCampo('Email'),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _cadCpfController,
            keyboardType: TextInputType.number,
            decoration: _decoracaoCampo('CPF'),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _cadSenhaController,
            obscureText: true,
            decoration: _decoracaoCampo('Senha'),
          ),
          const SizedBox(height: 24),
          _botao('Cadastrar', _fazerCadastro),
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
