import 'package:flutter/material.dart';
import 'package:iron_mind/core/utils/theme.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iron_mind/core/services/hive_service.dart';
import 'package:iron_mind/core/services/notification_service.dart';
import 'package:iron_mind/features/main_screen.dart';
import 'package:iron_mind/core/providers/theme_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await HiveService.init();
  try {
    await NotificationService.init();
    debugPrint('NotificationService initialized successfully');
  } catch (e, stack) {
    debugPrint('NotificationService init FAILED: $e');
    debugPrint('Stack: $stack');
  }
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'IronMind',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      home: const MainScreen(),
    );
  }
}
