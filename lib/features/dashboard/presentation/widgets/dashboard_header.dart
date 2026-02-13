import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/trace_context.dart';
import '../providers/dashboard_providers.dart';
import 'history_controls.dart';

class DashboardHeader extends ConsumerWidget implements PreferredSizeWidget {
  const DashboardHeader({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentConfig = ref.watch(traceConfigProvider);

    return AppBar(
      backgroundColor: const Color(0xFF282C34),
      title: const Text(
        "Log Analysis Dashboard",
        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
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

  @override
  Size get preferredSize => const Size.fromHeight(116); // AppBar (56) + Controls (60)
}
