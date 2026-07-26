import 'package:flutter/material.dart';
import 'package:oshilife/core/design/design_radius.dart';
import 'package:oshilife/core/design/theme_system.dart';

/// Port of `VenueTag.swift`: location pin + venue name on the semantic
/// location-green wash. Deliberately not accent-tinted — location keeps
/// its own color per docs/DESIGN.md.
class VenueTag extends StatelessWidget {
  const VenueTag({super.key, required this.venue});

  final String venue;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: ThemeSystem.locationColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(DesignRadius.small),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.location_on,
            size: 13,
            color: ThemeSystem.locationColor,
          ),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              venue,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}
