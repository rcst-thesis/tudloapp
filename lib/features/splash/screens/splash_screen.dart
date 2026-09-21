import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tudloapp/core/theme/app_theme.dart';
import 'package:tudloapp/core/widgets/mascot_widget.dart';
import 'package:tudloapp/features/profile/screens/profile_selection_screen.dart';

class SplashScreen extends StatefulWidget {
  final Future<void> loadFuture;

  const SplashScreen({super.key, required this.loadFuture});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();
    _scale = CurvedAnimation(parent: _controller, curve: Curves.easeOutBack);
    unawaited(_openProfileSelection());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _openProfileSelection() async {
    try {
      await Future.wait([
        widget.loadFuture,
        Future<void>.delayed(const Duration(seconds: 7)),
      ]);
    } catch (_) {
      await Future<void>.delayed(const Duration(milliseconds: 300));
    }
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const ProfileSelectionScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final logoWidth = (constraints.maxWidth * .70).clamp(230.0, 340.0);
            return Center(
              child: ScaleTransition(
                scale: _scale,
                child: Transform.translate(
                  offset: const Offset(0, -18),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Image.asset(
                        'assets/images/onbaording/Tudlo.png',
                        width: logoWidth,
                        fit: BoxFit.contain,
                      ),
                      const SizedBox(height: 22),
                      const TudloMascot(size: 154, mood: KokaMood.hi),
                      const SizedBox(height: 24),
                      Text(
                        'Magtuon kita!',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.nunito(
                          color: TudloColors.forest,
                          fontSize: 32,
                          height: 1,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
