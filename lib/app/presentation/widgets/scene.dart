import 'package:flutter/material.dart';

import 'error_image_placeholder.dart';
import 'shimmer_placeholder.dart';

class SceneSelectorRow extends StatelessWidget {
  final List<SceneOption> sceneOptions;
  final Set<String> selectedScenes;
  final int selectedCount;
  final ValueChanged<String> onToggleScene;
  final VoidCallback onSelectRecommended;
  final VoidCallback onClearAll;

  const SceneSelectorRow({
    super.key,
    required this.sceneOptions,
    required this.selectedScenes,
    required this.selectedCount,
    required this.onToggleScene,
    required this.onSelectRecommended,
    required this.onClearAll,
  });

  @override
  Widget build(BuildContext context) {
    final hasSelection = selectedScenes.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              "Scenes",
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
            const SizedBox(width: 8),
            Text(
              hasSelection ? "$selectedCount selected" : "None selected",
              style: TextStyle(fontSize: 11, color: Colors.grey.shade400),
            ),
            const Spacer(),
            TextButton(
              onPressed: hasSelection ? onClearAll : onSelectRecommended,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                minimumSize: Size.zero,
              ),
              child: Text(
                hasSelection ? "Clear all" : "Recommended",
                style: const TextStyle(fontSize: 11),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        SizedBox(
          height: 64,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: sceneOptions.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final scene = sceneOptions[index];
              final isSelected = selectedScenes.contains(scene.id);

              return GestureDetector(
                onTap: () => onToggleScene(scene.id),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  curve: Curves.easeOutCubic,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color: isSelected
                        ? Colors.white
                        : Colors.white.withValues(alpha: 0.04),
                    border: Border.all(
                      color: isSelected
                          ? Colors.white
                          : Colors.white.withValues(alpha: 0.15),
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.25),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ]
                        : null,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        scene.icon,
                        size: 18,
                        color: isSelected ? Colors.black : Colors.white,
                      ),
                      const SizedBox(width: 8),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            scene.label,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: isSelected ? Colors.black : Colors.white,
                            ),
                          ),
                          Text(
                            scene.description,
                            style: TextStyle(
                              fontSize: 10,
                              color: isSelected
                                  ? Colors.black.withValues(alpha: 0.7)
                                  : Colors.grey.shade400,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class FocusedGeneratedScene extends StatelessWidget {
  final String url;
  final double aspectRatio;
  final String label;

  const FocusedGeneratedScene({
    super.key,
    required this.url,
    required this.aspectRatio,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: Stack(
        children: [
          AspectRatio(
            aspectRatio: aspectRatio,
            child: Image.network(
              url,
              fit: BoxFit.cover,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return const ShimmerPlaceholder(
                  borderRadius: 18,
                  showLabelSkeleton: true,
                );
              },
              errorBuilder: (context, error, stackTrace) =>
                  const ErrorImagePlaceholder(),
            ),
          ),
          Positioned(
            top: 8,
            left: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(999),
                color: Colors.black.withValues(alpha: .45),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.style_rounded,
                    size: 14,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class SceneOption {
  final String id;
  final String label;
  final String description;
  final IconData icon;

  const SceneOption({
    required this.id,
    required this.label,
    required this.description,
    required this.icon,
  });
}
