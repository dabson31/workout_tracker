import 'package:flutter/material.dart';
import 'package:workout_tracker/theme/app_theme.dart';
import 'package:workout_tracker/pages/home_page.dart';

// shown right after the intro animation, lets the person tap through to home
class WelcomePage extends StatefulWidget {
  final String tagline;
  const WelcomePage({super.key, required this.tagline});

  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage> with SingleTickerProviderStateMixin {
  late AnimationController controller;
  late Animation<double> contentFade;
  late Animation<Offset> contentSlide;
  late Animation<double> buttonFade;

  @override
  void initState() {
    super.initState();

    controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    // title and tagline shift slightly upward as they fade in
    contentFade = CurvedAnimation(parent: controller, curve: const Interval(0.0, 0.7, curve: Curves.easeOut));
    contentSlide = Tween<Offset>(begin: const Offset(0, 0.15), end: Offset.zero).animate(
      CurvedAnimation(parent: controller, curve: const Interval(0.0, 0.7, curve: Curves.easeOut)),
    );

    // button settles in last
    buttonFade = CurvedAnimation(parent: controller, curve: const Interval(0.4, 1.0, curve: Curves.easeOut));

    controller.forward();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  void goToHomePage() {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 400),
        pageBuilder: (context, animation, secondaryAnimation) => const HomePage(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
          child: Column(
            children: [
              const Spacer(flex: 3),

              // title and tagline, slid slightly up as they settle
              AnimatedBuilder(
                animation: controller,
                builder: (context, child) {
                  return Opacity(
                    opacity: contentFade.value,
                    child: FractionalTranslation(
                      translation: contentSlide.value,
                      child: Column(
                        children: [
                          Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: RadialGradient(
                                colors: [
                                  AppColors.primary.withValues(alpha: 0.5),
                                  AppColors.primary.withValues(alpha: 0.0),
                                ],
                              ),
                            ),
                            child: const Icon(
                              Icons.fitness_center_rounded,
                              color: AppColors.primary,
                              size: 44,
                            ),
                          ),
                          const SizedBox(height: 20),
                          const Text(
                            'workout tracker',
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.2,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            widget.tagline,
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 14,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),

              const Spacer(flex: 4),

              // get started button, fades in last
              FadeTransition(
                opacity: buttonFade,
                child: SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: goToHomePage,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                    ),
                    child: const Text(
                      'get started',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}