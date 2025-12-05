import 'package:flutter/material.dart';

import 'error_image_placeholder.dart';
import 'generated_tile.dart';
import 'scene.dart';
import 'shimmer_placeholder.dart';

class ResultSection extends StatelessWidget {
  final bool isGenerating;
  final String? originalUrl;
  final List<String> generatedUrls;
  final List<String> currentResultStyles;
  final String focusedScene;
  final double aspectRatio;
  final String Function(String id) labelForStyleId;
  final int Function(String id) styleIndexFor;
  final ValueChanged<String> onFocusScene;
  final void Function(String url, String styleLabel) onShowActions;

  const ResultSection({
    super.key,
    required this.isGenerating,
    required this.originalUrl,
    required this.generatedUrls,
    required this.currentResultStyles,
    required this.focusedScene,
    required this.aspectRatio,
    required this.labelForStyleId,
    required this.styleIndexFor,
    required this.onFocusScene,
    required this.onShowActions,
  });

  @override
  Widget build(BuildContext context) {
    if (isGenerating) {
      return const Center(
        key: ValueKey("loading"),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(height: 12),
            Text(
              "Remixing your photo…",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13),
            ),
          ],
        ),
      );
    }

    if (originalUrl == null && generatedUrls.isEmpty) {
      return Align(
        key: const ValueKey("empty"),
        alignment: Alignment.topLeft,
        child: Text(
          "After you generate, your original photo and selected scenes will appear here.",
          style: TextStyle(fontSize: 12, color: Colors.grey.shade400),
        ),
      );
    }

    return ListView(
      key: const ValueKey("results"),
      children: [
        if (originalUrl != null) ...[
          const Text(
            "Original",
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: AspectRatio(
              aspectRatio: aspectRatio,
              child: Image.network(
                originalUrl!,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return const ShimmerPlaceholder(
                    borderRadius: 18,
                    showLabelSkeleton: false,
                  );
                },
                errorBuilder: (context, error, stackTrace) =>
                    const ErrorImagePlaceholder(),
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
        if (generatedUrls.isNotEmpty) ...[
          Text(
            "${labelForStyleId(focusedScene)} scene",
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          FocusedGeneratedScene(
            url: generatedUrls[styleIndexFor(focusedScene)],
            aspectRatio: aspectRatio,
            label: labelForStyleId(focusedScene),
          ),
          const SizedBox(height: 16),
          const Text(
            "All generated scenes",
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth > 480;
              final crossAxisCount = isWide ? 3 : 2;

              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: generatedUrls.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                  childAspectRatio: aspectRatio,
                ),
                itemBuilder: (context, index) {
                  final url = generatedUrls[index];
                  String? styleId;
                  if (index < currentResultStyles.length) {
                    styleId = currentResultStyles[index];
                  }
                  final styleLabel = styleId != null
                      ? labelForStyleId(styleId)
                      : "Scene ${index + 1}";
                  final isSelectedTile =
                      styleId != null && styleId == focusedScene;

                  return GeneratedTile(
                    url: url,
                    index: index,
                    styleLabel: styleLabel,
                    isSelected: isSelectedTile,
                    styleId: styleId,
                    onFocusScene: onFocusScene,
                    onShowActions: onShowActions,
                  );
                },
              );
            },
          ),
        ],
      ],
    );
  }
}
