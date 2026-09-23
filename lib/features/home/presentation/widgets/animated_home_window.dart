import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:vector_graphics/vector_graphics_compat.dart'
    show RenderingStrategy;

import 'package:tudloapp/features/settings/domain/app_settings_scope.dart';

class AnimatedHomeWindow extends StatefulWidget {
  const AnimatedHomeWindow({super.key});

  @override
  State<AnimatedHomeWindow> createState() => _AnimatedHomeWindowState();
}

class _AnimatedHomeWindowState extends State<AnimatedHomeWindow>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ambientController = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 10),
  );
  bool _reduceMotion = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduceMotion = !effectiveAmbientMotionEnabled(context);
    if (_reduceMotion == reduceMotion && _ambientController.isAnimating) return;
    _reduceMotion = reduceMotion;
    if (_reduceMotion) {
      _ambientController
        ..stop()
        ..value = 0;
    } else if (!_ambientController.isAnimating) {
      _ambientController.repeat();
    }
  }

  @override
  void dispose() {
    _ambientController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1,
      child: ClipPath(
        clipper: _WindowCircleClipper(),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final sceneScale =
                math.min(constraints.maxWidth, constraints.maxHeight) / 128;
            return Stack(
              fit: StackFit.expand,
              children: [
                const ColoredBox(
                  key: Key('home-window-sky-backing'),
                  color: Color(0xFFA8D8E7),
                ),
                AnimatedBuilder(
                  animation: _ambientController,
                  child: _windowLayer('assets/images/home_window_back.svg'),
                  builder: (context, child) {
                    final phase = _ambientController.value * math.pi * 2;
                    return Transform.rotate(
                      key: const Key('home-window-sun-rotation'),
                      angle: phase,
                      // The back layer rotates around the exported sun center.
                      // Its oversized flat sky remains visually unchanged.
                      alignment: const Alignment(.4025, -.3252),
                      filterQuality: FilterQuality.medium,
                      child: child,
                    );
                  },
                ),
                AnimatedBuilder(
                  animation: _ambientController,
                  child: _windowLayer('assets/images/home_window_clouds.svg'),
                  builder: (context, child) {
                    final phase = _ambientController.value * math.pi * 2;
                    return Transform.translate(
                      key: const Key('home-window-cloud-motion'),
                      offset: Offset(math.sin(phase) * 3 * sceneScale, 0),
                      child: child,
                    );
                  },
                ),
                _windowLayer('assets/images/home_window_hills.svg'),
                _windowLayer('assets/images/home_window_frame.svg'),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _windowLayer(String asset) {
    return RepaintBoundary(
      child: SvgPicture.asset(
        asset,
        fit: BoxFit.contain,
        renderingStrategy: RenderingStrategy.raster,
        excludeFromSemantics: true,
      ),
    );
  }
}

class _WindowCircleClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final scale = math.min(size.width, size.height) / 128;
    return Path()..addOval(
      Rect.fromCircle(
        center: Offset(63.5802 * scale, 63.5802 * scale),
        radius: 63.5802 * scale,
      ),
    );
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}
