import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:tudloapp/core/services/app_audio_service.dart';
import 'package:tudloapp/core/models/learner_profile.dart';
import 'package:tudloapp/core/state/app_state.dart';
import 'package:tudloapp/core/theme/app_theme.dart';
import 'package:tudloapp/features/navigation/app_shell.dart';
import 'package:tudloapp/features/onboarding/screens/onboarding_screen.dart';
import 'package:tudloapp/features/onboarding/screens/username_screen.dart';

const _profileNotSetAsset = 'assets/images/profile/profile-notset.jpg';

class ProfileSelectionScreen extends StatelessWidget {
  const ProfileSelectionScreen({super.key});

  void _openCreateProfile(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const UsernameScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = AppStateScope.of(context);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final height = constraints.maxHeight;
            final compact = height < 680 || width < 380;
            final logoWidth = (width * .74).clamp(210.0, 360.0);
            final headWidth = (width * 1.02).clamp(300.0, 560.0);
            final cardSize = (width * (compact ? .30 : .33)).clamp(
              104.0,
              138.0,
            );

            return Stack(
              alignment: Alignment.center,
              children: [
                Positioned(
                  top: compact ? 22 : height * .08,
                  child: Image.asset(
                    'assets/images/onbaording/Tudlo.png',
                    width: logoWidth,
                    fit: BoxFit.contain,
                  ),
                ),
                Positioned(
                  top: compact ? height * .22 : height * .27,
                  left: 20,
                  right: 20,
                  bottom: compact ? height * .28 : height * .24,
                  child: _ProfileGrid(
                    profiles: appState.profiles,
                    cardSize: cardSize,
                    onTap: () => _openCreateProfile(context),
                  ),
                ),
                Positioned(
                  bottom: compact ? -18 : -8,
                  child: IgnorePointer(
                    child: Image.asset(
                      'assets/images/onbaording/head.png',
                      width: headWidth,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _ProfileGrid extends StatelessWidget {
  final List<LearnerProfile> profiles;
  final double cardSize;
  final VoidCallback onTap;

  const _ProfileGrid({
    required this.profiles,
    required this.cardSize,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return _PagedProfileGrid(
      profiles: profiles,
      cardSize: cardSize,
      onCreateTap: onTap,
    );
  }
}

class _PagedProfileGrid extends StatefulWidget {
  final List<LearnerProfile> profiles;
  final double cardSize;
  final VoidCallback onCreateTap;

  const _PagedProfileGrid({
    required this.profiles,
    required this.cardSize,
    required this.onCreateTap,
  });

  @override
  State<_PagedProfileGrid> createState() => _PagedProfileGridState();
}

class _PagedProfileGridState extends State<_PagedProfileGrid> {
  int _page = 0;

  @override
  void didUpdateWidget(covariant _PagedProfileGrid oldWidget) {
    super.didUpdateWidget(oldWidget);
    final lastPage = _lastPage;
    if (_page > lastPage) _page = lastPage;
  }

  int get _lastPage {
    final totalItems = widget.profiles.length + 1;
    return ((totalItems - 1) / AppState.profilesPerSelectionPage).floor();
  }

  @override
  Widget build(BuildContext context) {
    final totalItems = widget.profiles.length + 1;
    final start = _page * AppState.profilesPerSelectionPage;
    final end = math.min(start + AppState.profilesPerSelectionPage, totalItems);
    final visibleIndexes = [
      for (var index = start; index < end; index++) index,
    ];
    final showArrows = totalItems > AppState.profilesPerSelectionPage;

    return LayoutBuilder(
      builder: (context, constraints) {
        final availableHeight = constraints.maxHeight.isFinite
            ? constraints.maxHeight
            : 480.0;
        final arrowBlockHeight = showArrows ? 58.0 : 0.0;
        final reservedHeight = arrowBlockHeight + 18;
        final maxProfileHeight = math.max(
          86.0,
          availableHeight - reservedHeight,
        );
        final cardSize = math
            .min(widget.cardSize, ((maxProfileHeight - 16) / 2) - 30)
            .clamp(82.0, widget.cardSize);

        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: cardSize * 2 + 28,
                child: Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 28,
                  runSpacing: 14,
                  children: [
                    for (final index in visibleIndexes)
                      if (index < widget.profiles.length)
                        _ProfileCard(
                          profile: widget.profiles[index],
                          size: cardSize,
                        )
                      else
                        _CreateAccountButton(
                          size: cardSize,
                          onTap: widget.onCreateTap,
                        ),
                  ],
                ),
              ),
              if (showArrows) ...[
                const SizedBox(height: 12),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _ProfilePageArrow(
                      icon: Icons.arrow_back_rounded,
                      enabled: _page > 0,
                      onTap: () async {
                        await AppAudioService.instance.playTap();
                        setState(() => _page--);
                      },
                    ),
                    const SizedBox(width: 18),
                    _ProfilePageArrow(
                      icon: Icons.arrow_forward_rounded,
                      enabled: _page < _lastPage,
                      onTap: () async {
                        await AppAudioService.instance.playTap();
                        setState(() => _page++);
                      },
                    ),
                  ],
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _ProfilePageArrow extends StatelessWidget {
  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;

  const _ProfilePageArrow({
    required this.icon,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 160),
      opacity: enabled ? 1 : .28,
      child: IconButton.filled(
        onPressed: enabled ? onTap : null,
        style: IconButton.styleFrom(
          backgroundColor: TudloColors.green,
          disabledBackgroundColor: TudloColors.line,
          foregroundColor: Colors.white,
          minimumSize: const Size(56, 56),
        ),
        icon: Icon(icon, size: 34),
      ),
    );
  }
}

class _CreateAccountButton extends StatelessWidget {
  final double size;
  final VoidCallback onTap;

  const _CreateAccountButton({required this.size, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: TudloColors.forest, width: 3),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(18),
                onTap: () async {
                  await AppAudioService.instance.playTap();
                  onTap();
                },
                child: const Center(
                  child: Icon(
                    Icons.add_rounded,
                    color: TudloColors.green,
                    size: 64,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Add Profile',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.black,
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileCard extends StatelessWidget {
  final LearnerProfile profile;
  final double size;

  const _ProfileCard({required this.profile, required this.size});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () async {
          final appState = AppStateScope.of(context);
          final hasSeenOnboarding = profile.hasSeenOnboarding;
          await AppAudioService.instance.playTap();
          await appState.selectProfile(profile.id);
          if (!context.mounted) return;
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => hasSeenOnboarding
                  ? const AppShell(initialIndex: 0)
                  : const OnboardingScreen(),
            ),
          );
        },
        child: SizedBox(
          width: size,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: size,
                height: size,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: TudloColors.forest, width: 3),
                ),
                child: _ProfileSelectionAvatar(asset: profile.avatarAsset),
              ),
              const SizedBox(height: 8),
              Text(
                profile.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileSelectionAvatar extends StatelessWidget {
  final String asset;

  const _ProfileSelectionAvatar({required this.asset});

  @override
  Widget build(BuildContext context) {
    final avatarAsset = asset.trim().isEmpty ? _profileNotSetAsset : asset;
    return _ProfileAvatarImage(asset: avatarAsset);
  }
}

class _ProfileAvatarImage extends StatelessWidget {
  final String asset;

  const _ProfileAvatarImage({required this.asset});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Image.asset(
        asset,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return const ColoredBox(
            color: Color(0xFFF6F9EA),
            child: Center(
              child: Icon(
                Icons.person_rounded,
                color: TudloColors.green,
                size: 54,
              ),
            ),
          );
        },
      ),
    );
  }
}
