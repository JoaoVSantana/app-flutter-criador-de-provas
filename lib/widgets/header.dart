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
    return Container(
      height: 100,
      decoration: const BoxDecoration(
        color: Color.fromARGB(255, 196, 207, 199),
        border: Border(
          bottom: BorderSide(color: Color.fromARGB(31, 32, 31, 31), width: 1),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          Image.asset('assets/images/logo.png', width: 160, height: 100),

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
                Navigator.pushNamed(context, AppRoutes.cadastro);
              },

              child: Row(
                children: [
                  Icon(
                    Icons.person,
                    color: isHover
                        ? const Color.fromARGB(255, 47, 51, 49)
                        : const Color(0xFF4C6B5E),
                    size: 28,
                  ),

                  const SizedBox(width: 8),

                  Text(
                    'Entrar',
                    style: TextStyle(
                      fontSize: 20,
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
  }
}
