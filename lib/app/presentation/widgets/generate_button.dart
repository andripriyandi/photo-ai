import 'package:flutter/material.dart';

class GenerateButton extends StatelessWidget {
  final bool isGenerating;
  final bool hasImage;
  final bool hasScenes;
  final bool hasResult;
  final VoidCallback onPressed;

  const GenerateButton({
    super.key,
    required this.isGenerating,
    required this.hasImage,
    required this.hasScenes,
    required this.hasResult,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final isDisabled = !hasImage || isGenerating || !hasScenes;

    return SizedBox(
      height: 50,
      child: ElevatedButton(
        onPressed: isDisabled ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isGenerating) ...[
              const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                "Generating…",
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ] else ...[
              const Icon(Icons.auto_awesome_rounded, size: 18),
              const SizedBox(width: 8),
              Text(
                !hasResult ? "Generate selected scenes" : "Generate again",
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
