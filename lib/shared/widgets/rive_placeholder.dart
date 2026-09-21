import 'package:flutter/material.dart';

import 'package:tudloapp/core/theme/app_colors.dart';

class RivePlaceholder extends StatelessWidget {
  const RivePlaceholder({
    required this.label,
    this.height = 210,
    this.iconSize = 88,
    super.key,
  });

  final String label;
  final double height;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: label,
      child: Container(
        height: height,
        width: double.infinity,
        constraints: const BoxConstraints(maxWidth: 340),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.35),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: AppColors.green, width: 3),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.animation_rounded,
              size: iconSize,
              color: AppColors.green,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.darkGreen,
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
