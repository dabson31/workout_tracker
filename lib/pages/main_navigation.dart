import 'package:flutter/material.dart';
import 'package:workout_tracker/pages/home_page.dart';
import 'package:workout_tracker/pages/weight_page.dart';
import 'package:workout_tracker/theme/app_theme.dart';

// holds the two main tabs, home and bodyweight
class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int selectedIndex = 0;

  final pages = const [
    HomePage(),
    WeightPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return PopScope(
      // only let back actually pop (exit the app) when already on the first tab
      canPop: selectedIndex == 0,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          setState(() => selectedIndex = 0);
        }
      },
      child: Scaffold(
        body: IndexedStack(
          index: selectedIndex,
          children: pages,
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: selectedIndex,
          onDestinationSelected: (index) => setState(() => selectedIndex = index),
          backgroundColor: AppColors.surface,
          indicatorColor: AppColors.primary.withValues(alpha: 0.2),
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.fitness_center_rounded, color: AppColors.textSecondary),
              selectedIcon: Icon(Icons.fitness_center_rounded, color: AppColors.primary),
              label: 'workouts',
            ),
            NavigationDestination(
              icon: Icon(Icons.show_chart_rounded, color: AppColors.textSecondary),
              selectedIcon: Icon(Icons.show_chart_rounded, color: AppColors.primary),
              label: 'weight',
            ),
          ],
        ),
      ),
    );
  }
}