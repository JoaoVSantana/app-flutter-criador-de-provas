import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

// MANTENHA os imports abaixo como já estão no seu projeto (caminhos ajustados)
import '../../Routes/routes.dart';
import '../models/usuario.dart';
import '../service/usuario_service.dart';

class Header extends StatefulWidget {
  const Header({super.key});

  @override
  State<Header> createState() => _HeaderState();
}

class _HeaderState extends State<Header> {
  bool isHover = false;

  static const _corPadrao = Color(0xFF4C6B5E);

  Future<void> _confirmarSaida() async {
    final sair = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Sair da conta'),
        content: const Text('Deseja realmente sair?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sair'),
          ),
        ],
      ),
    );
    if (sair != true) return;

    await FirebaseAuth.instance.signOut();
    if (!mounted) return;

    // Mantém só a primeira tela da pilha e abre o login por cima,
    // assim as telas do usuário anterior deixam de existir
    Navigator.pushNamedAndRemoveUntil(
      context,
      AppRoutes.entrar,
      (route) => route.isFirst,
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final larguraTela = constraints.maxWidth;
        final isMobile = larguraTela < 600;

        //ajusta a tela conforme tamanho
        final double alturaHeader = (larguraTela * 0.14).clamp(64.0, 100.0);
        final double larguraLogo = (larguraTela * 0.22).clamp(100.0, 160.0);
        final double alturaLogo = alturaHeader;

        final double fontEntrar = (larguraTela * 0.035).clamp(14.0, 20.0);
        final double iconeEntrar = (larguraTela * 0.05).clamp(20.0, 28.0);
        final double paddingHorizontal = (larguraTela * 0.04).clamp(12.0, 24.0);

        final corAtual = isHover
            ? const Color.fromARGB(255, 47, 51, 49)
            : _corPadrao;

        // Monta o botão: logado mostra "Olá, nome", deslogado mostra "Entrar"
        Widget botao({required bool logado, required String texto}) {
          return MouseRegion(
            cursor: logado
                ? SystemMouseCursors.basic
                : SystemMouseCursors.click,
            onEnter: (_) => setState(() => isHover = true),
            onExit: (_) => setState(() => isHover = false),
            child: InkWell(
              // logado: sem ação (o botão de sair fica ao lado)
              onTap: logado
                  ? null
                  : () => Navigator.pushNamed(context, AppRoutes.entrar),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.person, color: corAtual, size: iconeEntrar),
                  const SizedBox(width: 8),
                  // "Entrar" some no mobile; a saudação continua aparecendo
                  if (logado ? texto.isNotEmpty : !isMobile)
                    ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: isMobile ? 120 : 260,
                      ),
                      child: Text(
                        texto,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: fontEntrar, color: corAtual),
                      ),
                    ),
                ],
              ),
            ),
          );
        }

        // Ícone de sair, só aparece quando há alguém logado
        final botaoSair = IconButton(
          tooltip: 'Sair',
          onPressed: _confirmarSaida,
          icon: Icon(Icons.logout, color: _corPadrao, size: iconeEntrar),
        );

        return Container(
          height: alturaHeader,
          decoration: const BoxDecoration(
            color: Color.fromARGB(255, 232, 236, 233),
            border: Border(
              bottom: BorderSide(color: Color.fromARGB(31, 0, 0, 0), width: 1),
            ),
          ),
          padding: EdgeInsets.symmetric(horizontal: paddingHorizontal),
          child: Row(
            children: [
              Image.asset(
                'assets/images/logo.png',
                width: larguraLogo,
                height: alturaLogo,
                fit: BoxFit.contain,
              ),

              const Spacer(),

              // 1º stream: quem está logado (muda no login, cadastro e logout)
              StreamBuilder<User?>(
                stream: FirebaseAuth.instance.authStateChanges(),
                initialData: FirebaseAuth.instance.currentUser,
                builder: (context, authSnap) {
                  final user = authSnap.data;

                  if (user == null) {
                    return botao(logado: false, texto: 'Entrar');
                  }

                  // 2º stream: o perfil dessa pessoa no Firestore
                  return StreamBuilder<Usuario?>(
                    stream: UsuarioService().observar(user.uid),
                    builder: (context, snap) {
                      final nome = snap.data?.nome ?? '';
                      return Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          botao(
                            logado: true,
                            texto: nome.isEmpty ? '' : 'Olá, $nome',
                          ),
                          const SizedBox(width: 4),
                          botaoSair,
                        ],
                      );
                    },
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
