import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:vector_graphics/vector_graphics_compat.dart'
    show RenderingStrategy;

import 'package:tudloapp/features/settings/domain/app_settings_scope.dart';

/// A restrained 2.5D presentation layer for the Welcome Aboard farm artwork.
///
/// The source SVG is exported as a single visual group, so this component uses
/// camera perspective, overscan, and responsive pointer tilt.
/// Its API leaves the foreground free for separately animated screen content.
class FarmDepthBackground extends StatefulWidget {
  const FarmDepthBackground({
    this.assetName = 'assets/images/welcome_farm_background.svg',
    this.enableHardwareTilt = true,
    this.enableTouchTilt = true,
    this.tiltTarget,
    this.layerAssets,
    this.skyIdleAssets,
    super.key,
  });

  final String assetName;
  final bool enableHardwareTilt;
  final bool enableTouchTilt;
  final Offset? tiltTarget;
  final List<String>? layerAssets;
  final List<String>? skyIdleAssets;

  @override
  State<FarmDepthBackground> createState() => _FarmDepthBackgroundState();
}

class _FarmDepthBackgroundState extends State<FarmDepthBackground>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  late final AnimationController _ambientController = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 10),
  );
  late final AnimationController _sensorController = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 1),
  )..addListener(_smoothHardwareTilt);

  Offset _target = Offset.zero;
  Offset _sensorTarget = Offset.zero;
  Offset _displayedSensor = Offset.zero;
  Offset? _sensorBaseline;
  StreamSubscription<AccelerometerEvent>? _accelerometerSubscription;
  Timer? _recenterTimer;
  bool _reduceMotion = false;

  bool get _supportsHardwareTilt =>
      widget.enableHardwareTilt &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduceMotion = !effectiveAmbientMotionEnabled(context);
    if (_reduceMotion) {
      _ambientController
        ..stop()
        ..value = 0;
      _sensorController
        ..stop()
        ..value = 0;
      _target = Offset.zero;
      _sensorTarget = Offset.zero;
      _displayedSensor = Offset.zero;
      _stopHardwareTilt();
    } else {
      if (!_ambientController.isAnimating) _ambientController.repeat();
      if (_supportsHardwareTilt) {
        if (!_sensorController.isAnimating) _sensorController.repeat();
        _startHardwareTilt();
      } else {
        _sensorController
          ..stop()
          ..value = 0;
        _sensorTarget = Offset.zero;
        _displayedSensor = Offset.zero;
        _stopHardwareTilt();
      }
    }
  }

  void _startHardwareTilt() {
    if (!_supportsHardwareTilt ||
        _reduceMotion ||
        _accelerometerSubscription != null) {
      return;
    }
    _sensorBaseline = null;
    try {
      _accelerometerSubscription =
          accelerometerEventStream(
            samplingPeriod: SensorInterval.uiInterval,
          ).listen(
            _handleAccelerometer,
            onError: (_) => _stopHardwareTilt(),
            cancelOnError: false,
          );
    } catch (_) {
      _stopHardwareTilt();
    }
  }

  void _handleAccelerometer(AccelerometerEvent event) {
    if (!mounted || _reduceMotion) return;
    final measured = Offset(event.x, event.y);
    final baseline = _sensorBaseline;
    if (baseline == null) {
      _sensorBaseline = measured;
      return;
    }
    _sensorTarget = Offset(
      _applyDeadZone((measured.dx - baseline.dx) / 5.5),
      _applyDeadZone(-(measured.dy - baseline.dy) / 5.5),
    );
  }

  double _applyDeadZone(double value) {
    const deadZone = 0.055;
    final limited = value.clamp(-0.72, 0.72);
    if (limited.abs() <= deadZone) return 0;
    return (limited.sign * (limited.abs() - deadZone) / (1 - deadZone)).clamp(
      -0.70,
      0.70,
    );
  }

  void _smoothHardwareTilt() {
    if (!mounted) return;
    final next = Offset.lerp(_displayedSensor, _sensorTarget, 0.055)!;
    _displayedSensor = next.distanceSquared < 0.000001 ? Offset.zero : next;
  }

  void _stopHardwareTilt() {
    _sensorTarget = Offset.zero;
    final subscription = _accelerometerSubscription;
    _accelerometerSubscription = null;
    if (subscription != null) unawaited(subscription.cancel());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      if (!_reduceMotion && !_ambientController.isAnimating) {
        _ambientController.repeat();
      }
      if (!_reduceMotion &&
          _supportsHardwareTilt &&
          !_sensorController.isAnimating) {
        _sensorController.repeat();
      }
      _startHardwareTilt();
    } else if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached ||
        state == AppLifecycleState.hidden) {
      _ambientController.stop();
      _sensorController.stop();
      _stopHardwareTilt();
    }
  }

  void _updateTarget(PointerEvent event) {
    if (_reduceMotion) return;
    _recenterTimer?.cancel();
    final box = context.findRenderObject()! as RenderBox;
    final local = box.globalToLocal(event.position);
    setState(() {
      _target = Offset(
        ((local.dx / box.size.width) - 0.5).clamp(-0.5, 0.5) * 2,
        ((local.dy / box.size.height) - 0.5).clamp(-0.5, 0.5) * 2,
      );
    });
  }

  void _recenter(PointerEvent event) {
    _recenterTimer?.cancel();
    _recenterTimer = Timer(const Duration(milliseconds: 140), () {
      if (!mounted || _target == Offset.zero) return;
      setState(() => _target = Offset.zero);
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _recenterTimer?.cancel();
    _stopHardwareTilt();
    _ambientController.dispose();
    _sensorController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _buildDepthSurface(widget.tiltTarget ?? _target);
  }

  Widget _buildDepthSurface(Offset target) {
    return Listener(
      key: const Key('welcome-farm-depth-background'),
      behavior: HitTestBehavior.opaque,
      onPointerDown: widget.enableTouchTilt ? _updateTarget : null,
      onPointerMove: widget.enableTouchTilt ? _updateTarget : null,
      onPointerUp: widget.enableTouchTilt ? _recenter : null,
      onPointerCancel: widget.enableTouchTilt ? _recenter : null,
      child: ClipRect(
        child: TweenAnimationBuilder<Offset>(
          tween: Tween(end: target),
          duration: const Duration(milliseconds: 650),
          curve: Curves.easeOutCubic,
          builder: (context, pointer, child) {
            return AnimatedBuilder(
              animation: _sensorController,
              child: child,
              builder: (context, child) {
                final x = (pointer.dx + _displayedSensor.dx).clamp(-0.75, 0.75);
                final y = (pointer.dy + _displayedSensor.dy).clamp(-0.75, 0.75);
                final layerAssets = widget.layerAssets;
                if (layerAssets != null && layerAssets.length == 4) {
                  final skyIdleAssets = widget.skyIdleAssets;
                  return Stack(
                    key: const Key('welcome-farm-svg'),
                    fit: StackFit.expand,
                    children: [
                      if (skyIdleAssets != null && skyIdleAssets.length == 5)
                        _buildAnimatedSky(skyIdleAssets, x, y)
                      else
                        _buildLayer(layerAssets[0], x, y, 0.25),
                      _buildLayer(layerAssets[1], x, y, 0.85),
                      _buildLayer(layerAssets[2], x, y, 1.65),
                      _buildLayer(
                        layerAssets[3],
                        x,
                        y,
                        3.25,
                        key: const Key('welcome-farm-perspective-transform'),
                      ),
                    ],
                  );
                }
                final transform = Matrix4.identity()
                  ..setEntry(3, 2, 0.0008)
                  ..translateByDouble(x * 2.6, y * 2.0, 0, 1)
                  ..rotateX(-y * 0.016)
                  ..rotateY(x * 0.022)
                  ..scaleByDouble(1.035, 1.035, 1.035, 1);
                return Transform(
                  key: const Key('welcome-farm-perspective-transform'),
                  alignment: Alignment.center,
                  transform: transform,
                  filterQuality: FilterQuality.high,
                  child: child,
                );
              },
            );
          },
          child: widget.layerAssets == null
              ? RepaintBoundary(
                  child: SvgPicture.asset(
                    widget.assetName,
                    key: const Key('welcome-farm-svg'),
                    fit: BoxFit.contain,
                    alignment: Alignment.bottomCenter,
                    renderingStrategy: RenderingStrategy.raster,
                    semanticsLabel: 'Tudlo farm landscape',
                  ),
                )
              : SizedBox.expand(
                  child: Semantics(label: 'Tudlo farm landscape'),
                ),
        ),
      ),
    );
  }

  Widget _buildLayer(
    String asset,
    double x,
    double y,
    double depth, {
    Key? key,
  }) {
    final transform = Matrix4.identity()
      ..setEntry(3, 2, 0.00045)
      ..translateByDouble(x * depth, y * depth * 0.62, 0, 1)
      ..rotateX(-y * depth * 0.0008)
      ..rotateY(x * depth * 0.0011)
      ..scaleByDouble(1.025, 1.025, 1.025, 1);
    return Transform(
      key: key,
      alignment: Alignment.center,
      transform: transform,
      filterQuality: FilterQuality.high,
      child: RepaintBoundary(
        child: SvgPicture.asset(
          asset,
          fit: BoxFit.contain,
          alignment: Alignment.bottomCenter,
          renderingStrategy: RenderingStrategy.raster,
        ),
      ),
    );
  }

  Widget _buildAnimatedSky(List<String> assets, double x, double y) {
    Widget skyPart(String asset) => _buildLayer(asset, x, y, 0.25);
    final middleCloud = skyPart(assets[3]);
    final leftCloud = skyPart(assets[4]);

    return LayoutBuilder(
      builder: (context, constraints) {
        final sceneScale = constraints.maxWidth / 412;
        // Figma displays the celestial pair at 84% of the replacement SVG's
        // raw dimensions. Scale both objects together to preserve their
        // overlap and proportions at every viewport width.
        final celestialScale = sceneScale * 0.84;
        final cloudWidth = 219.319 * celestialScale;
        final cloudHeight = cloudWidth * 96.469 / 219.319;
        final skyGroupLeft = 274 * sceneScale;
        final skyGroupTop = constraints.maxHeight * 3 / 552;
        final skyGroupTravel = 3 * celestialScale;
        final sunSize = 88 * celestialScale;
        final sunLeft = 5.5 * celestialScale;
        final cloudTop = 8.231 * celestialScale;
        final sun = RepaintBoundary(
          child: SvgPicture.asset(
            assets[1],
            fit: BoxFit.contain,
            renderingStrategy: RenderingStrategy.raster,
          ),
        );
        final rightCloud = RepaintBoundary(
          child: SvgPicture.asset(
            assets[2],
            fit: BoxFit.contain,
            renderingStrategy: RenderingStrategy.raster,
          ),
        );

        return Stack(
          fit: StackFit.expand,
          clipBehavior: Clip.none,
          children: [
            skyPart(assets[0]),
            RepaintBoundary(
              child: AnimatedBuilder(
                animation: _ambientController,
                builder: (context, child) {
                  final phase = _ambientController.value * math.pi * 2;
                  final cloudDrift = math.sin(phase);
                  return Stack(
                    fit: StackFit.expand,
                    clipBehavior: Clip.none,
                    children: [
                      Positioned(
                        left: skyGroupLeft,
                        top: skyGroupTop,
                        width: cloudWidth,
                        height: math.max(sunSize, cloudTop + cloudHeight),
                        child: Transform.translate(
                          // Sun and cloud share this transform, so responsive
                          // resizing and idle motion cannot separate them.
                          offset: Offset(
                            x * 0.25 + cloudDrift * skyGroupTravel,
                            y * 0.155,
                          ),
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              Positioned(
                                left: sunLeft,
                                top: 0,
                                width: sunSize,
                                height: sunSize,
                                child: Transform.rotate(
                                  key: const Key('welcome-sun-idle-rotation'),
                                  angle: phase,
                                  alignment: Alignment.center,
                                  filterQuality: FilterQuality.medium,
                                  child: sun,
                                ),
                              ),
                              Positioned(
                                left: 0,
                                top: cloudTop,
                                width: cloudWidth,
                                height: cloudHeight,
                                child: KeyedSubtree(
                                  key: const Key('welcome-cloud-right-idle'),
                                  child: rightCloud,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      _smoothTranslate(
                        key: const Key('welcome-cloud-middle-idle'),
                        dx: cloudDrift * -8,
                        child: middleCloud,
                      ),
                      _smoothTranslate(
                        key: const Key('welcome-cloud-left-idle'),
                        dx: cloudDrift * 6,
                        child: leftCloud,
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _smoothTranslate({
    required Key key,
    required double dx,
    required Widget child,
  }) {
    return Transform(
      key: key,
      alignment: Alignment.center,
      transform: Matrix4.translationValues(dx, 0, 0),
      filterQuality: FilterQuality.medium,
      child: child,
    );
  }
}
