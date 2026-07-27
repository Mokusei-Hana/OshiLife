import 'package:flutter/material.dart';
import 'package:oshilife/core/design/design_radius.dart';

/// The OshiLife card surface: tonal fill, hairline stroke, large radius —
/// the Material stand-in for the iOS `.regularMaterial` detail sections
/// (plan §5.1: tonal surfaces instead of glass).
class SectionCard extends StatelessWidget {
  const SectionCard({
    super.key,
    this.header,
    required this.child,
    this.padding = const EdgeInsets.all(16),
  });

  final String? header;
  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // A Material (not a DecoratedBox) so ListTiles inside sections keep
    // their ink effects and pass the framework's debug assertion.
    final card = Material(
      color: theme.colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(DesignRadius.large),
        side: BorderSide(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Padding(
        padding: padding,
        child: SizedBox(width: double.infinity, child: child),
      ),
    );
    if (header == null) return card;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 6),
          child: Text(
            header!,
            style: theme.textTheme.titleSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        card,
      ],
    );
  }
}
