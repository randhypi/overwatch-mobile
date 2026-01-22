import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';

import '../providers/dashboard_providers.dart';
import '../widgets/filter_drawer.dart';
import '../widgets/log_card.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final streamAsync = ref.watch(dashboardStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Overwatch Matrix"),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
               ref.invalidate(dashboardStreamProvider);
            },
          ),
          Builder(
            builder: (context) => IconButton(
              icon: const Icon(Icons.filter_list),
              onPressed: () {
                Scaffold.of(context).openEndDrawer();
              },
            ),
          )
        ],
      ),
      endDrawer: const FilterDrawer(),
      body: streamAsync.when(
        data: (logs) {
          if (logs.isEmpty) {
            return const Center(child: Text("No transactions detected...", style: TextStyle(color: AppColors.secondaryText)));
          }
          return ListView.builder(
            itemCount: logs.length,
            itemBuilder: (context, index) {
              return LogCard(logPair: logs[index]);
            },
          );
        },
        error: (err, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: AppColors.error, size: 48),
              const SizedBox(height: 16),
              Text("Stream Error: $err", style: const TextStyle(color: AppColors.error), textAlign: TextAlign.center),
              TextButton(
                onPressed: () => ref.invalidate(dashboardStreamProvider),
                child: const Text("Retry Connection"),
              )
            ],
          ),
        ),
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      ),
    );
  }
}
