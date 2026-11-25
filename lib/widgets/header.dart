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

        final double alturaHeader = (larguraTela * 0.14).clamp(64.0, 96.0);
        final double larguraLogo = (larguraTela * 0.22).clamp(100.0, 156.0);
        final double alturaLogo = (alturaHeader * 0.78).clamp(44.0, 74.0);

        final double fontEntrar = (larguraTela * 0.035).clamp(14.0, 18.0);
        final double iconeEntrar = (larguraTela * 0.05).clamp(20.0, 26.0);
        final double paddingHorizontal = (larguraTela * 0.04).clamp(14.0, 28.0);

        final corAtual = isHover
            ? const Color.fromARGB(255, 47, 51, 49)
            : _corPadrao;

        Widget botao({required bool logado, required String texto}) {
          return MouseRegion(
            cursor: logado
                ? SystemMouseCursors.basic
                : SystemMouseCursors.click,
            onEnter: (_) => setState(() => isHover = true),
            onExit: (_) => setState(() => isHover = false),
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: logado
                  ? null
                  : () => Navigator.pushNamed(context, AppRoutes.entrar),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.person_rounded, color: corAtual, size: iconeEntrar),
                    const SizedBox(width: 8),
                    if (logado ? texto.isNotEmpty : !isMobile)
                      ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth: isMobile ? 120 : 260,
                        ),
                        child: Text(
                          texto,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: fontEntrar,
                            fontWeight: FontWeight.w600,
                            color: corAtual,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          );
        }

        final botaoSair = IconButton(
          tooltip: 'Sair',
          onPressed: _confirmarSaida,
          style: IconButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          icon: Icon(Icons.logout_rounded, color: _corPadrao, size: iconeEntrar),
        );

        return Container(
          height: alturaHeader,
          decoration: BoxDecoration(
            color: const Color.fromARGB(255, 232, 236, 233),
            border: const Border(
              bottom: BorderSide(color: Color.fromARGB(22, 0, 0, 0), width: 1),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
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
              StreamBuilder<User?>(
                stream: FirebaseAuth.instance.authStateChanges(),
                initialData: FirebaseAuth.instance.currentUser,
                builder: (context, authSnap) {
                  final user = authSnap.data;

                  if (user == null) {
                    return botao(logado: false, texto: 'Entrar');
                  }

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