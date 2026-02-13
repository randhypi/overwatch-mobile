import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/responsive_util.dart';
import '../providers/dashboard_providers.dart';
import 'transaction_group_card.dart';
import 'transaction_detail_sheet.dart';

class DashboardMasterList extends ConsumerWidget {
  const DashboardMasterList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final streamAsync = ref.watch(dashboardStreamProvider);
    final isTablet = context.isTablet;

    return streamAsync.when(
      data: (groups) {
        if (groups.isEmpty) {
          return const Center(
            child: Text(
              "No transactions found.",
              style: TextStyle(color: AppColors.secondaryText),
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(8),
          itemCount: groups.length,
          itemBuilder:
              (context, index) => TransactionGroupCard(
                group: groups[index],
                onTap: () {
                  // Update Selected State
                  ref.read(selectedTransactionGroupProvider.notifier).state =
                      groups[index];

                  if (!isTablet) {
                    // Mobile: Open BottomSheet
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder:
                          (context) =>
                              TransactionDetailSheet(group: groups[index]),
                    );
                  }
                },
              ),
        );
      },
      error:
          (err, stack) => Center(
            child: Text(
              "Error: $err",
              style: const TextStyle(color: AppColors.error),
            ),
          ),
      loading: () => const Center(child: CircularProgressIndicator()),
    );
  }
}
