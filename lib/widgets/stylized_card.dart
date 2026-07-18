import 'package:flutter/material.dart';

class StylizedCard extends StatelessWidget {
  final Widget child;
  final double blurRadius;
  final Color? shadowColor;
  final EdgeInsetsGeometry? margin;

  const StylizedCard({
    super.key,
    required this.child,
    this.blurRadius = 0.0,      // Controls how soft and spread out the glow looks
    this.shadowColor,          // Custom overridable glowing color
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    final finalShadowColor = shadowColor ?? Theme.of(context).colorScheme.primary;

    return Container(
      margin: margin ?? const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer, 
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline, // Dynamic theme border color
          width: 1.0, // Thinline border thickness
        ),
        boxShadow: [
          BoxShadow(
            // High opacity color that softens as it blurs outwards
            color: finalShadowColor, 
            blurRadius: blurRadius,
            spreadRadius: -1, // Shrinks the shadow slightly so it doesn't peek over the top/bottom
            // Shift x by -5 to cast the glow left. Keep y at 0 to anchor vertically.
            offset: const Offset(-5, 0), 
          ),
        ],
      ),
      // Clip ensures content behaves correctly if it extends to the border edge
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Material(
          color: Colors.transparent,
          child: child,
        ),
      ),
    );
  }
}