import 'package:flutter/material.dart';
import 'package:workout_tracker/pages/goals_page.dart';
import 'package:workout_tracker/pages/home_page.dart';
import 'package:workout_tracker/pages/stats_page.dart';
import 'package:workout_tracker/pages/weight_page.dart';
import 'package:workout_tracker/pages/workouts_list_page.dart';
import 'package:workout_tracker/theme/app_theme.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int selectedIndex = 0;

  final pages = const [
    HomePage(),
    WorkoutsListPage(),
    StatsPage(),
    WeightPage(),
    GoalsPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: selectedIndex == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) setState(() => selectedIndex = 0);
      },
      child: Scaffold(
        body: IndexedStack(index: selectedIndex, children: pages),
        bottomNavigationBar: NavigationBar(
          selectedIndex: selectedIndex,
          onDestinationSelected: (i) => setState(() => selectedIndex = i),
          backgroundColor: AppColors.surface,
          indicatorColor: AppColors.primary.withValues(alpha: 0.2),
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_rounded, color: AppColors.textSecondary),
              selectedIcon: Icon(Icons.home_rounded, color: AppColors.primary),
              label: 'home',
            ),
            NavigationDestination(
              icon: Icon(Icons.fitness_center_rounded, color: AppColors.textSecondary),
              selectedIcon: Icon(Icons.fitness_center_rounded, color: AppColors.primary),
              label: 'workouts',
            ),
            NavigationDestination(
              icon: Icon(Icons.bar_chart_rounded, color: AppColors.textSecondary),
              selectedIcon: Icon(Icons.bar_chart_rounded, color: AppColors.primary),
              label: 'stats',
            ),
            NavigationDestination(
              icon: Icon(Icons.show_chart_rounded, color: AppColors.textSecondary),
              selectedIcon: Icon(Icons.show_chart_rounded, color: AppColors.primary),
              label: 'weight',
            ),
            NavigationDestination(
              icon: Icon(Icons.flag_rounded, color: AppColors.textSecondary),
              selectedIcon: Icon(Icons.flag_rounded, color: AppColors.primary),
              label: 'goals',
            ),
          ],
        ),
      ),
    );
  }
}
