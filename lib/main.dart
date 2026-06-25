import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'data/workout_data.dart';
import 'pages/intro_page.dart';
import 'theme/app_theme.dart';

void main() async {
  // init hive
  await Hive.initFlutter();

  // TEMPORARY — run once to wipe old seeded sample data, then remove this line
  await Hive.deleteBoxFromDisk('workout_database');

  // open hive box
  await Hive.openBox('workout_database');

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => WorkoutData(),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: buildAppTheme(),
        home: const IntroPage(),
      ),
    );
  }
}