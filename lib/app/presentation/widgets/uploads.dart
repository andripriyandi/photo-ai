import 'dart:io';

import 'package:flutter/material.dart';

class UploadCard extends StatelessWidget {
  final File? localImage;
  final VoidCallback onTap;

  const UploadCard({super.key, required this.localImage, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final hasLocal = localImage != null;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: hasLocal
                ? Colors.blueAccent.withValues(alpha: .7)
                : Colors.white.withValues(alpha: .16),
          ),
          gradient: LinearGradient(
            colors: [
              Colors.white.withValues(alpha: .03),
              Colors.white.withValues(alpha: .02),
            ],
          ),
        ),
        child: Row(
          children: [
            UploadThumbnail(localImage: localImage),
            const SizedBox(width: 12),
            Expanded(child: UploadTexts(localImage: localImage)),
            const SizedBox(width: 8),
            Icon(
              Icons.chevron_right_rounded,
              color: Colors.white.withValues(alpha: .5),
            ),
          ],
        ),
      ),
    );
  }
}

class UploadThumbnail extends StatelessWidget {
  final File? localImage;

  const UploadThumbnail({super.key, required this.localImage});

  @override
  Widget build(BuildContext context) {
    final hasLocal = localImage != null;

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 60,
        height: 60,
        color: Colors.white.withValues(alpha: .04),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: hasLocal
              ? Image.file(
                  localImage!,
                  key: const ValueKey("local"),
                  fit: BoxFit.cover,
                )
              : Icon(
                  Icons.photo_camera_outlined,
                  key: const ValueKey("placeholder"),
                  size: 26,
                  color: Colors.white.withValues(alpha: .7),
                ),
        ),
      ),
    );
  }
}

class UploadTexts extends StatelessWidget {
  final File? localImage;

  const UploadTexts({super.key, required this.localImage});

  @override
  Widget build(BuildContext context) {
    final hasLocal = localImage != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          hasLocal ? "Use a different photo" : "Add a portrait photo",
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 4),
        Text(
          hasLocal
              ? "${localImage!.path.split("/").last}\nTap to replace this photo."
              : "Use a clear, front-facing photo of one person.",
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(fontSize: 12, color: Colors.grey.shade300),
        ),
      ],
    );
  }
}
