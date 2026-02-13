import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class DashboardStatsBar extends StatelessWidget {
  final int total;
  final bool isHistory;

  const DashboardStatsBar({
    super.key,
    required this.total,
    required this.isHistory,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      color: Colors.black,
      child: Row(
        children: [
          Text(
            isHistory ? "ARCHIVE MODE" : "SYSTEM HEALTH CHECK",
            style: TextStyle(
              color: isHistory ? AppColors.warning : AppColors.secondaryText,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 16),
          Text(
            "Total Transactions: $total",
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }
}
