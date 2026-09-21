import 'dart:async';

import 'package:flutter/material.dart';
import 'package:tudloapp/core/data/app_data.dart';
import 'package:tudloapp/core/theme/app_theme.dart';

/// Compact battery-style energy indicator for lesson and map headers.
///
/// It listens to [AppData.energyRevision], so it updates immediately when a
/// question spends energy or when elapsed-time recharge is calculated.
class EnergyIndicator extends StatefulWidget {
  final bool light;

  const EnergyIndicator({super.key, this.light = false});

  @override
  State<EnergyIndicator> createState() => _EnergyIndicatorState();
}

class _EnergyIndicatorState extends State<EnergyIndicator> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    AppData.refreshEnergy(save: true);
    _timer = Timer.periodic(const Duration(minutes: 1), (_) async {
      await AppData.refreshEnergy(save: true);
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: AppData.energyRevision,
      builder: (context, _, __) {
        final foreground = TudloColors.forest;
        return Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(999),
            // Popup trigger: tapping the compact header indicator opens the
            // full-screen energy status page shown in the reference.
            onTap: () => showEnergyDetails(context),
            child: Ink(
              height: 46,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: TudloColors.forest, width: 3),
                boxShadow: [
                  BoxShadow(
                    color: TudloColors.forest.withValues(alpha: .18),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.battery_charging_full_rounded,
                    color: foreground,
                    size: 24,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    AppData.developerMode ? '∞' : '${AppData.currentEnergy}',
                    style: TextStyle(
                      color: foreground,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

Future<void> showEnergyDetails(BuildContext context) {
  AppData.refreshEnergy(save: true);
  return Navigator.of(context).push(
    PageRouteBuilder<void>(
      opaque: true,
      pageBuilder: (_, __, ___) => const _EnergyScreen(lowEnergy: false),
      transitionsBuilder: (_, animation, __, child) {
        return FadeTransition(opacity: animation, child: child);
      },
    ),
  );
}

Future<void> showLowEnergyDialog(BuildContext context) {
  AppData.refreshEnergy(save: true);
  return Navigator.of(context).push(
    PageRouteBuilder<void>(
      opaque: true,
      pageBuilder: (_, __, ___) => const _EnergyScreen(lowEnergy: true),
      transitionsBuilder: (_, animation, __, child) {
        return FadeTransition(opacity: animation, child: child);
      },
    ),
  );
}

class _EnergyScreen extends StatefulWidget {
  final bool lowEnergy;

  const _EnergyScreen({required this.lowEnergy});

  @override
  State<_EnergyScreen> createState() => _EnergyScreenState();
}

class _EnergyScreenState extends State<_EnergyScreen> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    AppData.refreshEnergy(save: true);
    // Recharge display refresh: energy restores at +1 every 24 minutes and
    // fully recharges from 0 to 30 in 12 hours, but the countdown text should
    // tick while this screen is open.
    _timer = Timer.periodic(const Duration(minutes: 1), (_) async {
      await AppData.refreshEnergy(save: true);
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: AppData.energyRevision,
      builder: (context, _, __) {
        final next = AppData.timeUntilNextEnergy();
        final full = AppData.timeUntilFullEnergy();
        // Time calculation: CHARGING shows the full-recharge countdown. The
        // next +1 timing still follows the same 24-minute interval in AppData.
        final chargingTime = AppData.developerMode
            ? 'Unlimited'
            : AppData.formatDurationShort(full);

        return Scaffold(
          backgroundColor: Colors.white,
          body: SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final compactHeight = constraints.maxHeight < 620;
                return SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(
                    28,
                    compactHeight ? 18 : 22,
                    28,
                    compactHeight ? 18 : 28,
                  ),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight:
                          (constraints.maxHeight - (compactHeight ? 36 : 50))
                              .clamp(0, double.infinity),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SizedBox(
                          height: 64,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Positioned(
                                left: -8,
                                child: IconButton(
                                  onPressed: () => Navigator.pop(context),
                                  icon: const Icon(
                                    Icons.close_rounded,
                                    color: TudloColors.muted,
                                    size: 52,
                                  ),
                                ),
                              ),
                              const Text(
                                'Energy',
                                textAlign: TextAlign.center,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: TudloColors.ink,
                                  fontSize: 31,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: compactHeight ? 30 : 52),
                        Row(
                          children: [
                            Expanded(
                              child: FittedBox(
                                alignment: Alignment.centerLeft,
                                fit: BoxFit.scaleDown,
                                child: const Text(
                                  'CHARGING',
                                  style: TextStyle(
                                    color: TudloColors.muted,
                                    fontSize: 24,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 2.2,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Flexible(
                              child: FittedBox(
                                alignment: Alignment.centerRight,
                                fit: BoxFit.scaleDown,
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.bolt_rounded,
                                      color: TudloColors.green,
                                      size: 28,
                                    ),
                                    const SizedBox(width: 5),
                                    Text(
                                      chargingTime.toUpperCase(),
                                      style: const TextStyle(
                                        color: TudloColors.muted,
                                        fontSize: 24,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: 1.2,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: compactHeight ? 24 : 34),
                        _EnergyChargeBar(
                          current: AppData.currentEnergy,
                          max: AppData.maxEnergy,
                        ),
                        if (widget.lowEnergy && !AppData.developerMode) ...[
                          SizedBox(height: compactHeight ? 22 : 28),
                          _LowEnergyMessage(
                            nextEnergyIn: AppData.formatDurationShort(next),
                          ),
                        ],
                        SizedBox(height: compactHeight ? 24 : 80),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }
}

class _EnergyChargeBar extends StatelessWidget {
  final int current;
  final int max;

  const _EnergyChargeBar({required this.current, required this.max});

  @override
  Widget build(BuildContext context) {
    // Max energy rule: Tudlo caps energy at 30. A lesson costs 10 energy.
    final fill = max == 0 ? 0.0 : (current / max).clamp(0.0, 1.0);
    final full = current >= max || AppData.developerMode;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: SizedBox(
              height: 46,
              child: Stack(
                children: [
                  // Bar rendering: empty energy is soft gray, and the filled
                  // portion is Tudlo green. The text overlays the boundary so
                  // current/30 remains visible at any energy amount.
                  Positioned.fill(
                    child: ColoredBox(
                      color: full ? TudloColors.green : TudloColors.line,
                    ),
                  ),
                  if (!full)
                    FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: fill,
                      child: const ColoredBox(color: TudloColors.green),
                    ),
                  Positioned.fill(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 18),
                      child: Align(
                        alignment: Alignment.center,
                        child: Text(
                          AppData.developerMode ? 'DEV ∞' : '$current / $max',
                          style: TextStyle(
                            color: full ? Colors.white : TudloColors.ink,
                            fontSize: 23,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 8,
                    left: 12,
                    right: 12,
                    child: Container(
                      height: 7,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: .20),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Container(
          width: 74,
          height: 58,
          decoration: BoxDecoration(
            color: full ? TudloColors.green : const Color(0xFF40535B),
            borderRadius: BorderRadius.circular(15),
          ),
          // Recharge button/icon: this mirrors the small button at the right
          // side of the reference bar. It is visual only until a manual
          // recharge/purchase system exists.
          child: const Icon(Icons.bolt_rounded, color: Colors.white, size: 46),
        ),
        const SizedBox(width: 5),
        Container(
          width: 8,
          height: 20,
          decoration: BoxDecoration(
            color: TudloColors.line,
            borderRadius: BorderRadius.circular(999),
          ),
        ),
      ],
    );
  }
}

class _LowEnergyMessage extends StatelessWidget {
  final String nextEnergyIn;

  const _LowEnergyMessage({required this.nextEnergyIn});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      decoration: BoxDecoration(
        color: TudloColors.softGreen,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: TudloColors.green.withValues(alpha: .24)),
      ),
      child: Text(
        "You're low on energy!\nYou need ${AppData.minimumEnergyToStartUnit} energy to start this lesson.\nNext +1 in $nextEnergyIn.",
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: TudloColors.forest,
          fontSize: 15,
          height: 1.35,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
