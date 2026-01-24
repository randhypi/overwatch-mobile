import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/trace_context.dart';
import '../providers/dashboard_providers.dart';
import '../providers/history_provider.dart';
import '../widgets/filter_drawer.dart';
import '../widgets/history_controls.dart';
import '../widgets/transaction_group_card.dart';
import '../widgets/transaction_detail_sheet.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 1. Watch Data
    final streamAsync = ref.watch(dashboardStreamProvider);
    final currentConfig = ref.watch(traceConfigProvider);
    final isHistoryMode = ref.watch(historyModeProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF1E222A), // Dark Background
      appBar: AppBar(
        backgroundColor: const Color(0xFF282C34),
        title: const Text(
          "Log Analysis Dashboard",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: _buildControls(ref, currentConfig),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(dashboardStreamProvider),
            tooltip: 'Refresh Logs',
          ),
          Builder(
            builder:
                (ctx) => IconButton(
                  icon: const Icon(Icons.filter_list),
                  onPressed: () => Scaffold.of(ctx).openEndDrawer(),
                ),
          ),
        ],
      ),
      endDrawer: const FilterDrawer(),
      body: Container(
        decoration: BoxDecoration(
          border:
              isHistoryMode
                  ? Border.all(color: AppColors.warning, width: 2)
                  : null,
        ),
        child: Column(
          children: [
            // 2. Stats Header
            _buildStatsHeader(
              streamAsync.valueOrNull?.length ?? 0,
              isHistoryMode,
            ),

            // 3. Log List
            Expanded(
              child: streamAsync.when(
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
                            showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              backgroundColor: Colors.transparent,
                              builder:
                                  (context) => TransactionDetailSheet(
                                    group: groups[index],
                                  ),
                            );
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
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControls(WidgetRef ref, TraceConfig currentConfig) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: const Color(0xFF323842),
      child: Row(
        children: [
          // Target Selector
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.3),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: AppColors.primary.withOpacity(0.5)),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<TraceConfig>(
                value: currentConfig,
                dropdownColor: const Color(0xFF323842),
                style: const TextStyle(color: Colors.white, fontSize: 13),
                icon: const Icon(
                  Icons.arrow_drop_down,
                  color: AppColors.primary,
                ),
                items:
                    [TraceConfig.all, TraceConfig.nobu, TraceConfig.edc].map((
                      cfg,
                    ) {
                      return DropdownMenuItem(
                        value: cfg,
                        child: Text(cfg.label),
                      );
                    }).toList(),
                onChanged: (newVal) {
                  if (newVal != null) {
                    ref.read(traceConfigProvider.notifier).state = newVal;
                  }
                },
              ),
            ),
          ),

          const Spacer(),

          // History / Calendar Controls
          const HistoryControls(),

          const Spacer(),

          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE06C75),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
            ),
            icon: const Icon(Icons.delete_sweep, size: 16),
            label: const Text("Clear", style: TextStyle(fontSize: 12)),
            onPressed: () {
              ref.invalidate(dashboardStreamProvider);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStatsHeader(int total, bool isHistory) {
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
