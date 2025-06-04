import 'package:flutter/material.dart';

/// UI utility class
/// Regroups extended card functionalities such as gradients,
/// shadows, padding, ...
class FancyCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  final double borderRadius;
  final BoxShadow boxShadow;
  final Color? backgroundColor;
  final Gradient? gradient;
  final EdgeInsets? margin;
  final double? height;

  const FancyCard({
    super.key,
    required this.child,
    required this.padding,
    required this.borderRadius,
    required this.boxShadow,
    this.backgroundColor,
    this.gradient,
    this.margin,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          boxShadow,
        ],
        borderRadius: BorderRadius.circular(borderRadius),
        gradient: gradient,
        color: backgroundColor,
      ),
      margin: margin,
      height: height,
      child: Padding(
        padding: padding,
        child: child,
      ),
    );
  }
}
