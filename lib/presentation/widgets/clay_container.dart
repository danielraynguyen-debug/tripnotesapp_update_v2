import 'package:flutter/material.dart';

class ClayContainer extends StatelessWidget {
  final Widget? child;
  final double borderRadius;
  final Color color;
  final EdgeInsetsGeometry? padding;
  final double spread;
  final Offset offset;

  const ClayContainer({
    super.key,
    this.child,
    this.borderRadius = 20,
    this.color = const Color(0xFFF2F9F8),
    this.padding,
    this.spread = 1,
    this.offset = const Offset(8, 8),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            offset: offset,
            blurRadius: 15,
            spreadRadius: spread,
          ),
          BoxShadow(
            color: Colors.white,
            offset: -offset,
            blurRadius: 15,
            spreadRadius: spread,
          ),
        ],
      ),
      child: child,
    );
  }
}
