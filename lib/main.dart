import 'package:flutter/material.dart';
import 'package:operation_brotherhood/core/utils/theme.dart';
import 'package:operation_brotherhood/features/home/presentation/screens/home_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Habit Tracker App',
      theme: AppTheme.lightTheme,
      home: const HomeScreen(),
    );
  }
}
