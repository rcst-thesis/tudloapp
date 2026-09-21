import 'package:flutter/material.dart';
import 'package:rive/rive.dart' as rive;

enum KokaMood { idle, curious, hi, annoyed, talking, tapped }

/// Shared animated Koka mascot wrapper.
///
/// The old `asset` parameter is kept so older call sites do not break, but all
/// mascot renders now use the Koka Rive file.
class TudloMascot extends StatefulWidget {
  final double size;
  final String? asset;
  final KokaMood mood;

  static const riveAsset = 'assets/data/koka_curious_hi_annoyed.riv';

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
  rive.ArtboardPainter? _painter;
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
      _setPainter();
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
      setState(() {
        _file = file;
        _setPainter();
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = error);
    }
  }

  void _setPainter() {
    _painter?.dispose();
    final file = _file;
    if (file == null) {
      _painter = null;
      return;
    }
    _painter = rive.RivePainter.animation(
      _animationName(file, widget.mood),
      fit: rive.Fit.contain,
    );
  }

  String _animationName(rive.File file, KokaMood mood) {
    final names = switch (mood) {
      KokaMood.idle => const [
        'idle',
        'Idle',
        'breathing',
        'Breathing',
        'Sitting',
        'sitting',
        'curious',
      ],
      KokaMood.curious => const [
        'curious',
        'Curious',
        'idle',
        'Idle',
        'Sitting',
        'sitting',
        'hi',
      ],
      KokaMood.hi => const ['hi', 'Hi', 'wave', 'Wave', 'Sitting', 'sitting'],
      KokaMood.talking => const [
        'talking',
        'Talking',
        'speak',
        'Speak',
        'hi',
        'idle',
      ],
      KokaMood.tapped => const ['tapped', 'Tapped', 'tap', 'Tap', 'hi', 'idle'],
      KokaMood.annoyed => const [
        'annoyed',
        'Annoyed',
        'wrong',
        'Wrong',
        'angry',
        'Angry',
        'sad',
        'Sad',
        'hi',
      ],
    };

    final artboard = file.defaultArtboard();
    if (artboard == null) return names.last;
    try {
      for (final name in names) {
        final animation = artboard.animationNamed(name);
        if (animation != null) {
          animation.dispose();
          return name;
        }
      }
      return names.last;
    } finally {
      artboard.dispose();
    }
  }

  @override
  void dispose() {
    _painter?.dispose();
    _file?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final file = _file;
    final painter = _painter;

    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: file != null && painter != null
          ? rive.RiveFileWidget(file: file, painter: painter)
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
