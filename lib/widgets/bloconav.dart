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
    final ativo = isHover || isPressed;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => isHover = true),
      onExit: (_) => setState(() => isHover = false),
      child: AnimatedScale(
        scale: isPressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 140),
        curve: Curves.easeOutCubic,
        child: InkWell(
          onTap: widget.onPressed,
          onTapDown: (_) => setState(() => isPressed = true),
          onTapUp: (_) => setState(() => isPressed = false),
          onTapCancel: () => setState(() => isPressed = false),
          borderRadius: BorderRadius.circular(24),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 18),
            decoration: BoxDecoration(
              color: ativo
                  ? const Color(0xFF4C6B5E)
                  : const Color.fromARGB(255, 214, 224, 211),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: ativo ? 0.16 : 0.08),
                  blurRadius: ativo ? 20 : 14,
                  offset: Offset(0, ativo ? 10 : 6),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  widget.image,
                  width: 76,
                  height: 76,
                  fit: BoxFit.contain,
                ),
                const SizedBox(height: 14),
                Text(
                  widget.title,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.1,
                    color: ativo
                        ? const Color(0xFFF3F6F2)
                        : const Color(0xFF4C6B5E),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}