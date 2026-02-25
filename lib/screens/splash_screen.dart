import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/theme.dart';

class SplashScreen extends StatefulWidget {
  final VoidCallback onComplete;
  const SplashScreen({super.key, required this.onComplete});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _orbitCtrl;
  late AnimationController _pulseCtrl;
  late AnimationController _shimmerCtrl;

  @override
  void initState() {
    super.initState();

    _orbitCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    )..repeat();

    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    _shimmerCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();

    Future.delayed(const Duration(milliseconds: 2800), widget.onComplete);
  }

  @override
  void dispose() {
    _orbitCtrl.dispose();
    _pulseCtrl.dispose();
    _shimmerCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0, -0.2),
            radius: 1.4,
            colors: [Color(0xFF0D1020), T.bg],
          ),
        ),
        child: Stack(
          children: [
            // Ambient glow blobs
            _GlowBlob(
              color: T.accentBlue,
              alignment: const Alignment(-0.7, -0.6),
              size: 320,
            ),
            _GlowBlob(
              color: T.purple,
              alignment: const Alignment(0.8, 0.6),
              size: 260,
            ),
            _GlowBlob(
              color: T.active,
              alignment: const Alignment(0.3, -0.85),
              size: 180,
            ),

            // Orbit ring
            Center(
              child: AnimatedBuilder(
                animation: _orbitCtrl,
                builder: (_, __) => SizedBox(
                  width: 200,
                  height: 200,
                  child: Stack(
                    alignment: Alignment.center,
                    children: List.generate(8, (i) {
                      final angle = (_orbitCtrl.value * 2 * pi) + (i * pi / 4);
                      final radius = 88.0 + (i.isEven ? 0 : 12);
                      final color = [
                        T.accentBlue,
                        T.purple,
                        T.active,
                        T.waiting,
                      ][i % 4];
                      return Positioned(
                        left: 100 + radius * cos(angle) - 4,
                        top: 100 + radius * sin(angle) - 4,
                        child: AnimatedBuilder(
                          animation: _pulseCtrl,
                          builder: (_, __) => Container(
                            width: i % 3 == 0 ? 9 : 5,
                            height: i % 3 == 0 ? 9 : 5,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: color.withOpacity(
                                0.35 + _pulseCtrl.value * 0.45,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: color.withOpacity(0.5),
                                  blurRadius: 10,
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ),
              ),
            ),

            // Main content
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Logo
                  _LogoIcon(pulseCtrl: _pulseCtrl)
                      .animate()
                      .fadeIn(duration: 500.ms)
                      .scale(
                        begin: const Offset(0.4, 0.4),
                        duration: 700.ms,
                        curve: Curves.elasticOut,
                      ),

                  const SizedBox(height: 30),

                  // App name shimmer
                  AnimatedBuilder(
                        animation: _shimmerCtrl,
                        builder: (_, child) => ShaderMask(
                          shaderCallback: (bounds) => LinearGradient(
                            colors: const [
                              T.accentBlue,
                              T.purple,
                              T.active,
                              T.accentBlue,
                            ],
                            stops: const [0.0, 0.33, 0.66, 1.0],
                            begin: Alignment((_shimmerCtrl.value * 2) - 1, 0),
                            end: Alignment((_shimmerCtrl.value * 2) + 1, 0),
                          ).createShader(bounds),
                          child: child!,
                        ),
                        child: Text(
                          'ChatFlow',
                          style: GoogleFonts.syne(
                            fontSize: 44,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: -2,
                          ),
                        ),
                      )
                      .animate()
                      .fadeIn(delay: 350.ms, duration: 500.ms)
                      .slideY(begin: 0.3, end: 0, delay: 350.ms),

                  const SizedBox(height: 8),

                  Text(
                    'SUPPORT DASHBOARD',
                    style: GoogleFonts.dmSans(
                      color: T.textMuted,
                      fontSize: 11,
                      letterSpacing: 4,
                      fontWeight: FontWeight.w500,
                    ),
                  ).animate().fadeIn(delay: 650.ms, duration: 400.ms),

                  const SizedBox(height: 52),

                  _LoadingDots().animate().fadeIn(
                    delay: 950.ms,
                    duration: 300.ms,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Glow blob ──────────────────────────────────────────────────
class _GlowBlob extends StatelessWidget {
  final Color color;
  final Alignment alignment;
  final double size;
  const _GlowBlob({
    required this.color,
    required this.alignment,
    required this.size,
  });

  @override
  Widget build(BuildContext context) => Align(
    alignment: alignment,
    child: Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [color.withOpacity(0.09), Colors.transparent],
        ),
      ),
    ),
  );
}

// ── Logo icon ──────────────────────────────────────────────────
class _LogoIcon extends StatelessWidget {
  final AnimationController pulseCtrl;
  const _LogoIcon({required this.pulseCtrl});

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: pulseCtrl,
    builder: (_, child) => Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        gradient: const LinearGradient(
          colors: [T.accentBlue, T.purple],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: T.accentBlue.withOpacity(0.28 + pulseCtrl.value * 0.22),
            blurRadius: 28 + pulseCtrl.value * 22,
            spreadRadius: 2,
          ),
        ],
      ),
      child: const Icon(
        Icons.chat_bubble_rounded,
        color: Colors.white,
        size: 48,
      ),
    ),
  );
}

// ── Loading dots ───────────────────────────────────────────────
class _LoadingDots extends StatefulWidget {
  @override
  State<_LoadingDots> createState() => _LoadingDotsState();
}

class _LoadingDotsState extends State<_LoadingDots>
    with TickerProviderStateMixin {
  late List<AnimationController> _ctrls;

  @override
  void initState() {
    super.initState();
    _ctrls = List.generate(
      3,
      (i) => AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 550),
      ),
    );
    for (var i = 0; i < 3; i++) {
      Future.delayed(Duration(milliseconds: i * 160), () {
        if (mounted) _ctrls[i].repeat(reverse: true);
      });
    }
  }

  @override
  void dispose() {
    for (final c in _ctrls) c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: List.generate(
      3,
      (i) => AnimatedBuilder(
        animation: _ctrls[i],
        builder: (_, __) => Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: 9,
          height: 9,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(colors: [T.accentBlue, T.purple]),
            boxShadow: [
              BoxShadow(
                color: T.accentBlue.withOpacity(_ctrls[i].value * 0.55),
                blurRadius: 10,
              ),
            ],
          ),
          transform: Matrix4.translationValues(0, -(_ctrls[i].value * 9), 0),
        ),
      ),
    ),
  );
}
