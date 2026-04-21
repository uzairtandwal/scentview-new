import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class AppLogo extends StatelessWidget {
  final double size;
  final Color? backgroundColor;
  final Color? tintColor;
  final bool showShadow;
  final EdgeInsets? padding;
  final VoidCallback? onTap;
  final String? heroTag;
  final BorderRadius? borderRadius;

  const AppLogo({
    super.key,
    this.size = 52,
    this.backgroundColor,
    this.tintColor,
    this.showShadow = false,
    this.padding,
    this.onTap,
    this.heroTag,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveRadius = borderRadius ?? BorderRadius.zero; // LUXURY: Default to Square
    final effectivePadding = padding ?? const EdgeInsets.all(4);
    final innerSize = size - effectivePadding.horizontal;

    Widget content = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: backgroundColor ?? Colors.transparent,
        borderRadius: effectiveRadius,
        boxShadow: showShadow
            ? [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      padding: effectivePadding,
      child: Image.asset(
        'assets/logo.png.png',
        width: innerSize,
        height: innerSize,
        fit: BoxFit.contain,
        color: tintColor,
        errorBuilder: (_, __, ___) => Icon(
          Icons.auto_awesome,
          size: innerSize * 0.6,
          color: Colors.black45,
        ),
      ),
    );

    if (heroTag != null) {
      content = Hero(tag: heroTag!, child: content);
    }

    if (onTap != null) {
      return GestureDetector(onTap: onTap, child: content);
    }

    return content;
  }
}
