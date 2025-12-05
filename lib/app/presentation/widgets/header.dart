import 'package:flutter/material.dart';

class Header extends StatelessWidget {
  final bool hasResult;

  const Header({super.key, required this.hasResult});

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 250),
      child: Column(
        key: ValueKey(hasResult),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            hasResult
                ? "Your remixed scenes"
                : "Turn one portrait into multiple scenes",
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            hasResult
                ? "Tap a scene to focus it. Long-press any tile to view or copy the image link."
                : "Upload a portrait, select which scenes you want (travel, café, car, office, gym), then generate only those scenes.",
            style: TextStyle(
              fontSize: 13,
              height: 1.4,
              color: Colors.grey.shade300,
            ),
          ),
        ],
      ),
    );
  }
}
