import 'package:flutter/material.dart';

import '../../Routes/routes.dart';

class Header extends StatefulWidget {
  const Header({super.key});

  @override
  State<Header> createState() => _HeaderState();
}

class _HeaderState extends State<Header> {
  bool isHover = false;

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

              MouseRegion(
                cursor: SystemMouseCursors.click,

                onEnter: (_) {
                  setState(() {
                    isHover = true;
                  });
                },

                onExit: (_) {
                  setState(() {
                    isHover = false;
                  });
                },

                child: InkWell(
                  onTap: () {
                    Navigator.pushNamed(context, AppRoutes.entrar);
                  },

                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.person,
                        color: isHover
                            ? const Color.fromARGB(255, 47, 51, 49)
                            : const Color(0xFF4C6B5E),
                        size: iconeEntrar,
                      ),

                      const SizedBox(width: 8),

                     //Esconder icone se a tela for muito pequena
                      if (!isMobile)
                        Text(
                          'Entrar',
                          style: TextStyle(
                            fontSize: fontEntrar,
                            color: isHover
                                ? const Color.fromARGB(255, 47, 51, 49)
                                : const Color(0xFF4C6B5E),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
