import 'package:flutter/material.dart';

class HoverPop extends StatefulWidget {
  const HoverPop({
    super.key,
    required this.child,
    this.onTap,
    this.borderRadius = const BorderRadius.all(Radius.circular(18)),
  });

  final Widget child;
  final VoidCallback? onTap;
  final BorderRadius borderRadius;

  @override
  State<HoverPop> createState() => _HoverPopState();
}

class _HoverPopState extends State<HoverPop> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        transform: Matrix4.translationValues(0, _hover ? -6 : 0, 0),
        transformAlignment: Alignment.center,
        child: AnimatedScale(
          scale: _hover ? 1.03 : 1,
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: widget.borderRadius,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF0E1A2B)
                      .withValues(alpha: _hover ? 0.18 : 0.06),
                  blurRadius: _hover ? 24 : 12,
                  offset: Offset(0, _hover ? 14 : 6),
                ),
              ],
            ),
            child: Material(
              color: Colors.white,
              borderRadius: widget.borderRadius,
              clipBehavior: Clip.antiAlias,
              child: InkWell(onTap: widget.onTap, child: widget.child),
            ),
          ),
        ),
      ),
    );
  }
}
