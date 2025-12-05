import 'package:flutter/material.dart';

import 'error_image_placeholder.dart';
import 'shimmer_placeholder.dart';

class GeneratedTile extends StatelessWidget {
  final String url;
  final int index;
  final String styleLabel;
  final bool isSelected;
  final String? styleId;
  final ValueChanged<String> onFocusScene;
  final void Function(String url, String styleLabel) onShowActions;

  const GeneratedTile({
    super.key,
    required this.url,
    required this.index,
    required this.styleLabel,
    required this.isSelected,
    required this.styleId,
    required this.onFocusScene,
    required this.onShowActions,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (styleId != null) {
          onFocusScene(styleId!);
        }
      },
      onLongPress: () {
        onShowActions(url, styleLabel);
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.network(
              url,
              fit: BoxFit.cover,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return const ShimmerPlaceholder(
                  borderRadius: 16,
                  showLabelSkeleton: true,
                );
              },
              errorBuilder: (context, error, stackTrace) =>
                  const ErrorImagePlaceholder(),
            ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Colors.black.withValues(alpha: .55),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
            Positioned(
              top: 6,
              right: 6,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  color: Colors.black.withValues(alpha: .45),
                  border: isSelected
                      ? Border.all(
                          color: Colors.white.withValues(alpha: .9),
                          width: 1,
                        )
                      : null,
                ),
                child: Text(
                  "#${index + 1}",
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            Positioned(
              left: 6,
              bottom: 6,
              right: 6,
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(999),
                      color: Colors.black.withValues(alpha: .55),
                      border: isSelected
                          ? Border.all(
                              color: Colors.white.withValues(alpha: .9),
                              width: 1,
                            )
                          : null,
                    ),
                    child: Text(
                      styleLabel,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const Spacer(),
                  if (isSelected)
                    const Icon(
                      Icons.check_circle_rounded,
                      size: 16,
                      color: Colors.white,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
