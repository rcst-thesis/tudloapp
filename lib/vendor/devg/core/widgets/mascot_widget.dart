import 'package:flutter/material.dart';
import 'package:rive/rive.dart' as rive;

enum KokaMood { idle, curious, hi, annoyed, talking, tapped }

/// Shared animated Koka mascot wrapper.
///
/// The old `asset` parameter is kept so older call sites do not break, but all
/// mascot renders now use the same Koka Rive file as Home
/// (`HomeKokaMascot`): `assets/images/koka_mascot.riv`, State Machine 1,
/// driven by the confirmed 'Hi'/'Curious'/'Annoyed' triggers rather than
/// timeline animation names.
class TudloMascot extends StatefulWidget {
  final double size;
  final String? asset;
  final KokaMood mood;

  static const riveAsset = 'assets/images/koka_mascot.riv';

  const TudloMascot({
    super.key,
    this.size = 118,
    this.asset,
    this.mood = KokaMood.idle,
  });

  @override
  State<TudloMascot> createState() => _TudloMascotState();
}

class _TudloMascotState extends State<TudloMascot> {
  rive.File? _file;
  rive.RiveWidgetController? _controller;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _loadKoka();
  }

  @override
  void didUpdateWidget(covariant TudloMascot oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.mood != widget.mood) {
      _restartStateMachineForMood();
    }
  }

  Future<void> _loadKoka() async {
    try {
      final file = await rive.File.asset(
        TudloMascot.riveAsset,
        riveFactory: rive.Factory.flutter,
      );
      if (!mounted) {
        file?.dispose();
        return;
      }
      if (file == null) {
        setState(() => _error = 'missing koka_mascot.riv');
        return;
      }
      setState(() {
        _file = file;
        _controller = _buildController(file, widget.mood);
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = error);
    }
  }

  // Mirrors HomeKokaMascot: this state machine keeps reporting its triggered
  // reaction after the timeline settles, so returning to idle (or firing a
  // new reaction) means recreating the state machine rather than re-firing.
  rive.RiveWidgetController _buildController(rive.File file, KokaMood mood) {
    final controller = rive.RiveWidgetController(
      file,
      stateMachineSelector: rive.StateMachineSelector.byName('State Machine 1'),
    );
    final trigger = switch (mood) {
      KokaMood.curious => 'Curious',
      KokaMood.hi || KokaMood.tapped || KokaMood.talking => 'Hi',
      KokaMood.annoyed => 'Annoyed',
      KokaMood.idle => null,
    };
    if (trigger != null) {
      // ignore: deprecated_member_use
      controller.stateMachine.trigger(trigger)?.fire();
    }
    return controller;
  }

  void _restartStateMachineForMood() {
    final file = _file;
    if (file == null) return;
    final previousController = _controller;
    setState(() => _controller = _buildController(file, widget.mood));
    previousController?.dispose();
  }

  @override
  void dispose() {
    _controller?.dispose();
    _file?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;

    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: controller != null
          ? rive.RiveWidget(
              controller: controller,
              fit: rive.Fit.contain,
              alignment: Alignment.center,
            )
          : _KokaPlaceholder(hasError: _error != null),
    );
  }
}

class _KokaPlaceholder extends StatelessWidget {
  final bool hasError;

  const _KokaPlaceholder({required this.hasError});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: hasError
            ? const Color(0xFFFFE2E2)
            : const Color(0xFFE7FFD1).withValues(alpha: .65),
        shape: BoxShape.circle,
      ),
      child: Icon(
        hasError ? Icons.error_outline_rounded : Icons.hourglass_empty_rounded,
        color: const Color(0xFF2BAA10),
        size: 42,
      ),
    );
  }
}
