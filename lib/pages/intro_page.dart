import 'dart:math';
import 'package:flutter/material.dart';
import 'package:workout_tracker/pages/welcome_page.dart';
import 'package:workout_tracker/theme/app_theme.dart';

// a few taglines, one picked at random each launch for a bit of personality
const List<String> introTaglines = [
  'do you even read these',
  'lightweight',
  'remember to drink tea',
];

// shown briefly on launch, fades into the home page
class IntroPage extends StatefulWidget {
  const IntroPage({super.key});

  @override
  State<IntroPage> createState() => _IntroPageState();
}

class _IntroPageState extends State<IntroPage> with SingleTickerProviderStateMixin {
  late AnimationController controller;
  late Animation<double> glowFade;
  late Animation<double> iconScale;
  late Animation<double> titleFade;
  late Animation<Offset> titleSlide;
  late Animation<double> taglineFade;

  late String tagline;

  @override
  void initState() {
    super.initState();

    tagline = introTaglines[Random(DateTime.now().millisecondsSinceEpoch).nextInt(introTaglines.length)];

    // total animation length, a bit longer so it can breathe
    controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    // glow appears first
    glowFade = CurvedAnimation(
      parent: controller,
      curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
    );

    // icon pops in with a slight overshoot
    iconScale = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: controller, curve: const Interval(0.1, 0.55, curve: Curves.easeOutBack)),
    );

    // title fades and slides up shortly after
    titleFade = CurvedAnimation(
      parent: controller,
      curve: const Interval(0.35, 0.7, curve: Curves.easeOut),
    );
    titleSlide = Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
      CurvedAnimation(parent: controller, curve: const Interval(0.35, 0.7, curve: Curves.easeOut)),
    );

    // tagline fades in last, giving the personality moment its own beat
    taglineFade = CurvedAnimation(
      parent: controller,
      curve: const Interval(0.6, 1.0, curve: Curves.easeOut),
    );

    controller.forward();

    // hold briefly once settled, then hand off to the welcome/get-started page
    Future.delayed(const Duration(milliseconds: 1900), () {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            transitionDuration: const Duration(milliseconds: 450),
            pageBuilder: (context, animation, secondaryAnimation) => WelcomePage(tagline: tagline),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(opacity: animation, child: child);
            },
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: AnimatedBuilder(
          animation: controller,
          builder: (context, child) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // glowing accent behind the icon, the signature moment
                Opacity(
                  opacity: glowFade.value,
                  child: ScaleTransition(
                    scale: iconScale,
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            AppColors.primary.withValues(alpha: 0.55),
                            AppColors.primary.withValues(alpha: 0.0),
                          ],
                        ),
                      ),
                      child: const Icon(
                        Icons.fitness_center_rounded,
                        color: AppColors.primary,
                        size: 50,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // title
                Opacity(
                  opacity: titleFade.value,
                  child: FractionalTranslation(
                    translation: titleSlide.value,
                    child: const Text(
                      'workout tracker',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),

                // randomized tagline, the personality beat
                Opacity(
                  opacity: taglineFade.value,
                  child: Text(
                    tagline,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}