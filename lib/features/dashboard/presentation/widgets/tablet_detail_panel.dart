import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../providers/dashboard_providers.dart';
import 'transaction_detail_sheet.dart';

class TabletDetailPanel extends ConsumerWidget {
  const TabletDetailPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedGroup = ref.watch(selectedTransactionGroupProvider);

    if (selectedGroup == null) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.analytics_outlined,
              size: 64,
              color: AppColors.secondaryText,
            ),
            SizedBox(height: 16),
            Text(
              "Select a transaction to view details",
              style: TextStyle(color: AppColors.secondaryText, fontSize: 14),
            ),
          ],
        ),
      );
    }

    // Reuse the content from TransactionDetailSheet but displayed as a static panel
    return Container(
      color: Colors.black.withOpacity(0.1),
      child: TransactionDetailSheet(group: selectedGroup, isPanel: true),
    );
  }
}
