import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/splash_controller.dart';

// Brand colours from the SellUp design
const _teal = Color(0xFF1B6A78);
const _orange = Color(0xFFC44B1E);
const _subtleText = Color(0xFF6B7E8A);

class SplashScreen extends GetView<SplashController> {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    controller; // trigger onReady → bootstrap session
    return const _SplashAnimationView();
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Internal animated widget — decoupled from GetX so it can own its ticker
// ─────────────────────────────────────────────────────────────────────────────

class _SplashAnimationView extends StatefulWidget {
  const _SplashAnimationView();

  @override
  State<_SplashAnimationView> createState() => _SplashAnimationViewState();
}

class _SplashAnimationViewState extends State<_SplashAnimationView>
    with SingleTickerProviderStateMixin {
  // 4-second looping timeline — mirrors the HTML prototype exactly
  static const _totalMs = 4000;

  late AnimationController _ctrl;

  // Logo
  late Animation<double> _logoOpacity;
  late Animation<double> _logoScale;
  late Animation<double> _logoRotation;

  // Glow rings
  late Animation<double> _ring1Scale;
  late Animation<double> _ring1Opacity;
  late Animation<double> _ring2Scale;
  late Animation<double> _ring2Opacity;

  // "SellUp" wordmark
  late Animation<double> _wordmarkOpacity;
  late Animation<double> _wordmarkSlide;

  // Tagline
  late Animation<double> _taglineOpacity;
  late Animation<double> _taglineSlide;

  // Bottom progress bar
  late Animation<double> _progressValue;
  late Animation<double> _progressOpacity;

  // Global fade-out at end of loop
  late Animation<double> _globalFade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      duration: const Duration(milliseconds: _totalMs),
      vsync: this,
    );
    _buildAnimations();
    _ctrl.repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  // Converts seconds on the 4 s timeline to a normalised Interval (0..1).
  CurvedAnimation _iv(double startSec, double endSec, {Curve curve = Curves.linear}) =>
      CurvedAnimation(
        parent: _ctrl,
        curve: Interval(startSec / 4.0, endSec / 4.0, curve: curve),
      );

  void _buildAnimations() {
    // ── Logo opacity: 0 → 1 over 0–0.22 s ─────────────────────────────────
    _logoOpacity = Tween<double>(begin: 0, end: 1)
        .animate(_iv(0, 0.22, curve: Curves.easeOutCubic));

    // ── Logo rotation: −4° → 0° over 0–0.6 s ──────────────────────────────
    _logoRotation = Tween<double>(begin: -4 * math.pi / 180, end: 0)
        .animate(_iv(0, 0.6, curve: Curves.easeOutCubic));

    // ── Logo scale spring (multi-segment, matches HTML keyframes) ──────────
    // Input times [0.00, 0.35, 0.50, 0.62, 0.70] → scales [0.22, 1.13, 0.93, 1.04, 1.00]
    // TweenSequence weights = time-delta × 100 to preserve proportions.
    _logoScale = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 0.22, end: 1.13)
            .chain(CurveTween(curve: Curves.easeOutCubic)),
        weight: 35, // 0.35 s
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.13, end: 0.93)
            .chain(CurveTween(curve: Curves.easeInOutCubic)),
        weight: 15, // 0.15 s
      ),
      TweenSequenceItem(
        tween: Tween(begin: 0.93, end: 1.04)
            .chain(CurveTween(curve: Curves.easeInOutCubic)),
        weight: 12, // 0.12 s
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.04, end: 1.00)
            .chain(CurveTween(curve: Curves.easeInOutCubic)),
        weight: 8, // 0.08 s
      ),
    ]).animate(
      CurvedAnimation(parent: _ctrl, curve: Interval(0, 0.70 / 4.0)),
    );

    // ── Teal outer ring: scale 0.55 → 2.4 over 0.22–0.9 s ────────────────
    _ring1Scale = Tween<double>(begin: 0.55, end: 2.4)
        .animate(_iv(0.22, 0.9, curve: Curves.easeOutCubic));

    // Teal ring opacity: 0 at 0.18 s → 0.28 at 0.42 s → 0 at 0.9 s
    _ring1Opacity = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 0.28), weight: 24),
      TweenSequenceItem(tween: Tween(begin: 0.28, end: 0.0), weight: 48),
    ]).animate(
      CurvedAnimation(parent: _ctrl, curve: Interval(0.18 / 4.0, 0.9 / 4.0)),
    );

    // ── Orange inner ring: scale 0.4 → 1.9 over 0.28–0.95 s ──────────────
    _ring2Scale = Tween<double>(begin: 0.4, end: 1.9)
        .animate(_iv(0.28, 0.95, curve: Curves.easeOutCubic));

    // Orange ring opacity: 0 at 0.24 s → 0.15 at 0.5 s → 0 at 0.95 s
    _ring2Opacity = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 0.15), weight: 26),
      TweenSequenceItem(tween: Tween(begin: 0.15, end: 0.0), weight: 45),
    ]).animate(
      CurvedAnimation(parent: _ctrl, curve: Interval(0.24 / 4.0, 0.95 / 4.0)),
    );

    // ── "SellUp" wordmark: fade + slide-up over 0.60–0.92 s ──────────────
    _wordmarkOpacity = Tween<double>(begin: 0, end: 1)
        .animate(_iv(0.60, 0.92, curve: Curves.easeOutCubic));
    _wordmarkSlide = Tween<double>(begin: 22, end: 0)
        .animate(_iv(0.60, 0.92, curve: Curves.easeOutCubic));

    // ── Tagline: fade (max 0.52) + slide-up over 0.86–1.22 s ─────────────
    _taglineOpacity = Tween<double>(begin: 0, end: 0.52)
        .animate(_iv(0.86, 1.22, curve: Curves.easeOutCubic));
    _taglineSlide = Tween<double>(begin: 12, end: 0)
        .animate(_iv(0.86, 1.22, curve: Curves.easeOutCubic));

    // ── Progress bar fills 0 → 1 over 0.5–3.1 s ─────────────────────────
    _progressValue = Tween<double>(begin: 0, end: 1)
        .animate(_iv(0.5, 3.1, curve: Curves.easeInOut));

    // Progress opacity: 0 at 0.4 s → 0.35 at 0.6 s → hold → 0 at 3.3 s
    _progressOpacity = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 0.35), weight: 20),
      TweenSequenceItem(tween: ConstantTween(0.35), weight: 240),
      TweenSequenceItem(tween: Tween(begin: 0.35, end: 0.0), weight: 30),
    ]).animate(
      CurvedAnimation(parent: _ctrl, curve: Interval(0.4 / 4.0, 3.3 / 4.0)),
    );

    // ── Global fade-out: 1 → 0 over 3.1–3.72 s ───────────────────────────
    _globalFade = Tween<double>(begin: 1, end: 0)
        .animate(_iv(3.1, 3.72, curve: Curves.easeIn));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: AnimatedBuilder(
        animation: _ctrl,
        builder: (context, _) {
          return Opacity(
            opacity: _globalFade.value,
            child: Stack(
              children: [
                // ── Centred logo + wordmark + tagline ─────────────────────
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Logo with expanding glow rings
                      SizedBox(
                        width: 156,
                        height: 156,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // Teal outer ring
                            Transform.scale(
                              scale: _ring1Scale.value,
                              child: Opacity(
                                opacity: _ring1Opacity.value,
                                child: Container(
                                  width: 156,
                                  height: 156,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(color: _teal, width: 2),
                                  ),
                                ),
                              ),
                            ),
                            // Orange inner ring
                            Transform.scale(
                              scale: _ring2Scale.value,
                              child: Opacity(
                                opacity: _ring2Opacity.value,
                                child: Container(
                                  width: 156,
                                  height: 156,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border:
                                        Border.all(color: _orange, width: 1.5),
                                  ),
                                ),
                              ),
                            ),
                            // App logo with spring scale + rotation
                            Opacity(
                              opacity: _logoOpacity.value,
                              child: Transform.scale(
                                scale: _logoScale.value,
                                child: Transform.rotate(
                                  angle: _logoRotation.value,
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(30),
                                    child: Image.asset(
                                      'assets/logo/invetnory_logo.png',
                                      width: 144,
                                      height: 144,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 30),

                      // "SellUp" wordmark — "Sell" in teal, "Up" in orange
                      Transform.translate(
                        offset: Offset(0, _wordmarkSlide.value),
                        child: Opacity(
                          opacity: _wordmarkOpacity.value,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              Text(
                                'Sell',
                                style: const TextStyle(
                                  fontFamily: 'PlusJakartaSans',
                                  fontSize: 46,
                                  fontWeight: FontWeight.w800,
                                  color: _teal,
                                  letterSpacing: -1.38, // −0.03 em × 46
                                  height: 1,
                                ),
                              ),
                              Text(
                                'Up',
                                style: const TextStyle(
                                  fontFamily: 'PlusJakartaSans',
                                  fontSize: 46,
                                  fontWeight: FontWeight.w800,
                                  color: _orange,
                                  letterSpacing: -1.38,
                                  height: 1,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 10),

                      // Tagline — uppercase, spaced, muted
                      Transform.translate(
                        offset: Offset(0, _taglineSlide.value),
                        child: Opacity(
                          opacity: _taglineOpacity.value,
                          child: const Text(
                            'INVENTORY MANAGEMENT',
                            style: TextStyle(
                              fontFamily: 'PlusJakartaSans',
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: _subtleText,
                              letterSpacing: 2.16, // 0.18 em × 12
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // ── Bottom progress bar ────────────────────────────────────
                Positioned(
                  bottom: 60,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Opacity(
                      opacity: _progressOpacity.value,
                      child: Container(
                        width: 120,
                        height: 2.5,
                        decoration: BoxDecoration(
                          color: const Color(0xFF1B6A78).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(2),
                        ),
                        child: FractionallySizedBox(
                          alignment: Alignment.centerLeft,
                          widthFactor: _progressValue.value,
                          child: Container(
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                colors: [_teal, _orange],
                              ),
                              borderRadius:
                                  BorderRadius.all(Radius.circular(2)),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
