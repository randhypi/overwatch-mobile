import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/theme.dart';
import 'features/dashboard/presentation/screens/dashboard_screen.dart';
import 'features/dashboard/data/repositories/bin_repository.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize BIN Data
  await binRepository.initialize();

  runApp(
    const ProviderScope(
      child: OverwatchApp(),
    ),
  );
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
