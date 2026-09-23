import 'package:flutter/material.dart';

import 'package:tudloapp/core/theme/app_colors.dart';
import 'package:tudloapp/shared/widgets/design_navigation_button.dart';
import 'package:tudloapp/shared/widgets/rive_placeholder.dart';

class PlaceholderScreen extends StatelessWidget {
  const PlaceholderScreen({
    required this.title,
    required this.description,
    required this.icon,
    this.bottomNavigationBar,
    this.showBackButton = true,
    super.key,
  });

  final String title;
  final String description;
  final IconData icon;
  final Widget? bottomNavigationBar;
  final bool showBackButton;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: bottomNavigationBar,
      body: ColoredBox(
        color: AppColors.mint,
        child: SafeArea(
          bottom: bottomNavigationBar == null,
          child: Stack(
            children: [
              Positioned.fill(
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(28, 100, 28, 28),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 520),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          RivePlaceholder(label: '$title\nRive placeholder'),
                          const SizedBox(height: 28),
                          Icon(icon, size: 42, color: AppColors.darkGreen),
                          const SizedBox(height: 12),
                          Text(
                            description,
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 17, height: 1.4),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              if (showBackButton)
                AdaptiveBackButtonPlacement(
                  onPressed: () => Navigator.of(context).pop(),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
