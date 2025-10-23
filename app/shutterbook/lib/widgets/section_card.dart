import 'package:flutter/material.dart';

class SectionCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double elevation;

  const SectionCard({super.key, required this.child, this.padding = const EdgeInsets.all(12), this.elevation = 1.5});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: elevation,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      color: theme.cardColor,
      child: Padding(
        padding: padding,
        child: child,
      ),
    );
  }
}
