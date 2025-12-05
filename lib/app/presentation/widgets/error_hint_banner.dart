import 'package:flutter/material.dart';

class ErrorHintBanner extends StatelessWidget {
  final String? errorMessage;
  final bool hasLocalImage;
  final bool hasScenes;

  const ErrorHintBanner({
    super.key,
    required this.errorMessage,
    required this.hasLocalImage,
    required this.hasScenes,
  });

  @override
  Widget build(BuildContext context) {
    if (errorMessage != null) {
      return Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Colors.redAccent.withValues(alpha: 0.12),
          border: Border.all(color: Colors.redAccent.withValues(alpha: 0.4)),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.error_outline_rounded,
              size: 18,
              color: Colors.redAccent,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                errorMessage!,
                style: const TextStyle(fontSize: 11, color: Colors.redAccent),
              ),
            ),
          ],
        ),
      );
    }

    if (!hasLocalImage) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline_rounded,
            size: 16,
            color: Colors.grey.shade400,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              "Step 1: Upload a portrait photo first.",
              style: TextStyle(fontSize: 11, color: Colors.grey.shade400),
            ),
          ),
        ],
      );
    }

    if (!hasScenes) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Icon(
            Icons.arrow_upward_rounded,
            size: 16,
            color: Colors.orangeAccent,
          ),
          SizedBox(width: 6),
          Expanded(
            child: Text(
              "Step 2: Pick at least one scene above.",
              style: TextStyle(fontSize: 11, color: Colors.orangeAccent),
            ),
          ),
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          Icons.check_circle_outline_rounded,
          size: 16,
          color: Colors.greenAccent.shade200,
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            "Ready. Tap “Generate selected scenes” to create your remixes.",
            style: TextStyle(fontSize: 11, color: Colors.grey.shade300),
          ),
        ),
      ],
    );
  }
}
