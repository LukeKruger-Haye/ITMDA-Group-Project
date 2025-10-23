import 'package:flutter/material.dart';

class StatItem {
  final String label;
  final String value;
  final IconData icon;

  StatItem({required this.label, required this.value, required this.icon});
}

class StatCard extends StatelessWidget {
  final StatItem item;
  final bool compact;

  const StatCard({super.key, required this.item, this.compact = false});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final pad = compact ? 6.0 : 10.0;
    final iconSize = compact ? 20.0 : 26.0;
    final titleStyle = compact ? theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold) : theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold);
    final labelStyle = theme.textTheme.bodySmall;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: pad, vertical: pad),
        child: Row(
          children: [
            Icon(item.icon, size: iconSize, color: theme.colorScheme.primary),
            SizedBox(width: compact ? 8 : 12),
            Flexible(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.value, style: titleStyle),
                  SizedBox(height: compact ? 2 : 4),
                  Text(item.label, style: labelStyle, overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class StatGrid extends StatelessWidget {
  final List<StatItem> items;

  const StatGrid({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final width = constraints.maxWidth;
      // Be more aggressive about compacting stats on narrow screens.
      final crossAxisCount = width >= 700 ? 4 : (width >= 360 ? 2 : 2);

      // Calculate a target width for each card so they fit neatly.
      final spacing = 8.0;
      final cols = crossAxisCount;
      final itemWidth = (width - (cols - 1) * spacing) / cols;

      return Wrap(
        spacing: spacing,
        runSpacing: spacing,
        children: items.map((it) {
          return SizedBox(
            width: itemWidth.clamp(120.0, width),
            child: StatCard(item: it, compact: cols >= 3),
          );
        }).toList(),
      );
    });
  }
}
