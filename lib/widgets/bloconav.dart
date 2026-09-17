import 'package:flutter/material.dart';

class BlocoNav extends StatefulWidget {
  const BlocoNav({
    super.key,
    required this.title,
    required this.onPressed,
    required this.image,
  });

  final String title;
  final VoidCallback onPressed;
  final String image;

  @override
  State<BlocoNav> createState() => _BlocoNavState();
}

class _BlocoNavState extends State<BlocoNav> {
  bool isHover = false;
  bool isPressed = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
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
        onTap: widget.onPressed,
        onTapDown: (_) {
          setState(() {
            isPressed = true;
          });
        },
        onTapUp: (_) {
          setState(() {
            isPressed = false;
          });
        },
        onTapCancel: () {
          setState(() {
            isPressed = false;
          });
        },
        borderRadius: BorderRadius.circular(20),

        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),

          decoration: BoxDecoration(
            color: isHover || isPressed
                ? const Color(0xFF4C6B5E)
                : const Color.fromARGB(255, 214, 224, 211),

            borderRadius: BorderRadius.circular(20),

            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.10),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),

          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                widget.image,
                width: 80,
                height: 80,
                fit: BoxFit.contain, //serve para ajustar a imagem dentro do container, mantendo a proporção
              ),

              const SizedBox(height: 15),

              Text(
                widget.title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w100,
                  fontFamily: 'Oswald',
                  color: isHover || isPressed
                      ? const Color(0xFFF3F6F2)
                      : const Color(0xFF4C6B5E),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
