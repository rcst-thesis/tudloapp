import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tudloapp/core/constants/app_strings.dart';
import 'package:tudloapp/core/services/app_audio_service.dart';
import 'package:tudloapp/core/theme/app_theme.dart';

/// Floating bottom navigation used by the main app shell.
///
/// AppShell owns which page is active; this widget only renders the shared nav
/// UI and reports taps back to the shell.
class TudloBottomNavBar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onTap;

  const TudloBottomNavBar({
    super.key,
    required this.selectedIndex,
    required this.onTap,
  });

  static const items = [
    _BottomNavDestination(
      label: AppStrings.navHome,
      asset: 'assets/images/navbar/home.png',
    ),
    _BottomNavDestination(
      label: AppStrings.navTranslate,
      asset: 'assets/images/navbar/translate.png',
    ),
    _BottomNavDestination(
      label: AppStrings.navLessons,
      icon: Icons.menu_book_rounded,
    ),
    _BottomNavDestination(
      label: AppStrings.navDictionary,
      asset: 'assets/images/navbar/dictionary.png',
    ),
    _BottomNavDestination(
      label: AppStrings.navProfile,
      asset: 'assets/images/navbar/profile.png',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    const radius = BorderRadius.all(Radius.circular(30));
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .16),
            blurRadius: 30,
            offset: const Offset(0, 14),
          ),
          BoxShadow(
            color: Colors.white.withValues(alpha: .38),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
            height: 82,
            decoration: BoxDecoration(
              borderRadius: radius,
              border: Border.all(
                color: Colors.white.withValues(alpha: .62),
                width: 1.4,
              ),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withValues(alpha: .52),
                  Colors.white.withValues(alpha: .25),
                  TudloColors.brightGreen.withValues(alpha: .10),
                ],
              ),
            ),
            child: Row(
              children: List.generate(items.length, (index) {
                final isSelected = selectedIndex == index;
                return Expanded(
                  child: _BottomNavItem(
                    destination: items[index],
                    selected: isSelected,
                    onTap: () async {
                      await AppAudioService.instance.playTap();
                      onTap(index);
                    },
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}

class _BottomNavDestination {
  final String label;
  final String? asset;
  final IconData? icon;

  const _BottomNavDestination({required this.label, this.asset, this.icon});
}

class _BottomNavItem extends StatefulWidget {
  final _BottomNavDestination destination;
  final bool selected;
  final VoidCallback onTap;

  const _BottomNavItem({
    required this.destination,
    required this.selected,
    required this.onTap,
  });

  @override
  State<_BottomNavItem> createState() => _BottomNavItemState();
}

class _BottomNavItemState extends State<_BottomNavItem> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed == value) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final scale = _pressed ? 1.12 : (widget.selected ? 1.05 : 1.0);

    return AnimatedScale(
      duration: const Duration(milliseconds: 150),
      curve: Curves.easeOutBack,
      scale: scale,
      child: InkWell(
        borderRadius: BorderRadius.circular(30),
        onTap: widget.onTap,
        onTapDown: (_) => _setPressed(true),
        onTapCancel: () => _setPressed(false),
        onTapUp: (_) => _setPressed(false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          height: 68,
          decoration: BoxDecoration(
            color: widget.selected
                ? Colors.white.withValues(alpha: .24)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(24),
            border: widget.selected
                ? Border.all(color: Colors.white.withValues(alpha: .46))
                : null,
            boxShadow: widget.selected
                ? [
                    BoxShadow(
                      color: Colors.white.withValues(alpha: .20),
                      blurRadius: 12,
                    ),
                  ]
                : null,
          ),
          child: Center(
            child: _NavItemArtwork(
              destination: widget.destination,
              selected: widget.selected,
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItemArtwork extends StatelessWidget {
  final _BottomNavDestination destination;
  final bool selected;

  const _NavItemArtwork({required this.destination, required this.selected});

  @override
  Widget build(BuildContext context) {
    final asset = destination.asset;
    if (asset != null) {
      return Image.asset(
        asset,
        width: selected ? 62 : 54,
        height: selected ? 62 : 54,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.high,
      );
    }

    final color = selected ? TudloColors.blue : TudloColors.muted;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(destination.icon, color: color, size: selected ? 32 : 29),
        const SizedBox(height: 1),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            destination.label,
            maxLines: 1,
            style: GoogleFonts.nunito(
              color: color,
              fontSize: 12,
              height: 1,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    );
  }
}
