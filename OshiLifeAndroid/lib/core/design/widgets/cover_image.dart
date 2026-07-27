import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';

/// Port of `CoverImageView.swift`: cover art from a file or in-memory
/// bytes, with the diagonal pink→purple→blue gradient + music-note glyph
/// placeholder when absent.
class CoverImage extends StatelessWidget {
  const CoverImage({
    super.key,
    this.file,
    this.bytes,
    this.height,
    this.aspectRatio,
    this.borderRadius,
  });

  final File? file;
  final Uint8List? bytes;
  final double? height;
  final double? aspectRatio;
  final BorderRadius? borderRadius;

  @override
  Widget build(BuildContext context) {
    final bytes = this.bytes;
    final file = this.file;
    Widget child;
    if (bytes != null) {
      child = Image.memory(bytes, fit: BoxFit.cover, width: double.infinity);
    } else if (file != null) {
      child = Image.file(
        file,
        fit: BoxFit.cover,
        width: double.infinity,
        errorBuilder: (context, error, stackTrace) => const _Placeholder(),
      );
    } else {
      child = const _Placeholder();
    }

    if (aspectRatio != null) {
      child = AspectRatio(aspectRatio: aspectRatio!, child: child);
    } else if (height != null) {
      child = SizedBox(height: height, width: double.infinity, child: child);
    }
    return ClipRRect(
      borderRadius: borderRadius ?? BorderRadius.zero,
      child: child,
    );
  }
}

class _Placeholder extends StatelessWidget {
  const _Placeholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFF06292), Color(0xFF9C4DF0), Color(0xFF4D7CF0)],
        ),
      ),
      alignment: Alignment.center,
      child: const Icon(Icons.queue_music, color: Colors.white, size: 40),
    );
  }
}
