import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_tokens.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  double _progress = 0.0;
  Timer? _progressTimer;

  @override
  void initState() {
    super.initState();
    _startLoadingAnimation();
  }

  void _startLoadingAnimation() {
    const totalSteps = 50;
    const interval = Duration(milliseconds: 40);
    _progressTimer = Timer.periodic(interval, (timer) {
      if (mounted) {
        setState(() {
          _progress += 1.0 / totalSteps;
          if (_progress >= 1.0) {
            _progress = 1.0;
            timer.cancel();
            _navigateToHome();
          }
        });
      }
    });
  }

  void _navigateToHome() {
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => const MainNavigationShell(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(
                opacity: CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeInOut,
                ),
                child: child,
              );
            },
            transitionDuration: const Duration(milliseconds: 600),
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _progressTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.racingGreenDeepest : const Color(0xFF0B1F17),
      body: Stack(
        children: [
          // Background Glow Gradient Effect
          Center(
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.wineRedAccent.withOpacity(0.25),
                    blurRadius: 100,
                    spreadRadius: 30,
                  ),
                  BoxShadow(
                    color: AppColors.goldHighlight.withOpacity(0.15),
                    blurRadius: 140,
                    spreadRadius: 40,
                  ),
                ],
              ),
            ),
          ),

          // Main Center Content
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Animated HepsiRadyo Logo Badge
                Image.asset(
                  'assets/images/app_logo.png',
                  width: 170,
                  height: 170,
                  fit: BoxFit.contain,
                )
                    .animate()
                    .scale(
                      duration: const Duration(milliseconds: 700),
                      curve: Curves.easeOutBack,
                    )
                    .shimmer(
                      delay: const Duration(milliseconds: 700),
                      duration: const Duration(milliseconds: 1200),
                      color: Colors.white24,
                    ),

                const SizedBox(height: 32),

                // App Title
                const Text(
                  'HepsiRadyo',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 1.2,
                  ),
                ).animate().fadeIn(delay: const Duration(milliseconds: 300)),

                const SizedBox(height: 6),

                Text(
                  'Kesintisiz Canlı Yayınlar',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.white.withOpacity(0.7),
                    letterSpacing: 0.8,
                  ),
                ).animate().fadeIn(delay: const Duration(milliseconds: 500)),

                const SizedBox(height: 48),

                // Gradient Progress Loading Bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 56),
                  child: Column(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(AppTokens.radiusPill),
                        child: Container(
                          height: 6,
                          width: double.infinity,
                          color: Colors.white12,
                          child: Stack(
                            children: [
                              FractionallySizedBox(
                                widthFactor: _progress,
                                child: Container(
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [
                                        AppColors.wineRedAccent,
                                        AppColors.goldHighlight,
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(AppTokens.radiusPill),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 14),

                      Text(
                        '${(_progress * 100).toInt()}% • Yayınlar Yükleniyor...',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withOpacity(0.6),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ).animate().fadeIn(delay: const Duration(milliseconds: 600)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
