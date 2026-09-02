import 'package:flutter/material.dart';

class BlocoNav extends StatefulWidget {
  const BlocoNav({
    super.key,
    required this.title,
    required this.onPressed,
    required this.icon,
  });

  final String title;
  final VoidCallback onPressed;
  final IconData icon;

  @override
  State<BlocoNav> createState() => _BlocoNavState();
}

class _BlocoNavState extends State<BlocoNav> {
  bool isHover = false;

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

      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 250,
        width: 200,

        decoration: BoxDecoration(
          color: isHover
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

        child: InkWell(
          onTap: widget.onPressed,

          borderRadius: BorderRadius.circular(20),

          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                widget.icon,
                size: 30,
                color: isHover
                    ? const Color(0xFFF3F6F2)
                    : const Color(0xFF4C6B5E),
              ),

              const SizedBox(height: 15),

              Text(
                widget.title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w100,
                  color: isHover
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
