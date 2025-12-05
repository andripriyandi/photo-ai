import 'package:flutter/material.dart';

class ErrorImagePlaceholder extends StatelessWidget {
  const ErrorImagePlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Icon(
        Icons.broken_image_outlined,
        color: Colors.redAccent,
        size: 32,
      ),
    );
  }
}
