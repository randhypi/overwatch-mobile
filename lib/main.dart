import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/theme.dart';
import 'features/dashboard/presentation/screens/dashboard_screen.dart';

void main() {
  runApp(const ProviderScope(child: OverwatchApp()));
}

class OverwatchApp extends ConsumerWidget {
  const OverwatchApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: 'Overwatch Mobile',
      debugShowCheckedModeBanner: false,
      theme: appTheme,
      home: const DashboardScreen(),
    );
  }
}
