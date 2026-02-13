import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../providers/dashboard_providers.dart';
import '../providers/history_provider.dart';
import '../widgets/filter_drawer.dart';
import '../../../../core/utils/responsive_util.dart';
import '../widgets/tablet_detail_panel.dart';
import '../widgets/dashboard_header.dart';
import '../widgets/dashboard_stats_bar.dart';
import '../widgets/dashboard_master_list.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final streamAsync = ref.watch(dashboardStreamProvider);
    final isHistoryMode = ref.watch(historyModeProvider);
    final isTablet = context.isTablet;

    return Scaffold(
      backgroundColor: const Color(0xFF1E222A),
      appBar: const DashboardHeader(),
      endDrawer: const FilterDrawer(),
      body: Container(
        decoration: BoxDecoration(
          border:
              isHistoryMode
                  ? Border.all(color: AppColors.warning, width: 2)
                  : null,
        ),
        child: Row(
          children: [
            // 1. Navigation Rail (Tablet Only)
            if (isTablet)
              NavigationRail(
                backgroundColor: const Color(0xFF21252B),
                selectedIndex: 0,
                extended: context.isLargeScreen,
                leading: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Icon(
                    Icons.security,
                    color: AppColors.primary,
                    size: 32,
                  ),
                ),
                unselectedIconTheme: const IconThemeData(color: Colors.grey),
                selectedIconTheme: const IconThemeData(
                  color: AppColors.primary,
                ),
                destinations: const [
                  NavigationRailDestination(
                    icon: Icon(Icons.dashboard_customize_outlined),
                    selectedIcon: Icon(Icons.dashboard_customize),
                    label: Text("Insights"),
                  ),
                  NavigationRailDestination(
                    icon: Icon(Icons.history_outlined),
                    selectedIcon: Icon(Icons.history),
                    label: Text("Archive"),
                  ),
                ],
                onDestinationSelected: (idx) {},
              ),

            // 2. Main Area (Stats + Content)
            Expanded(
              child: Column(
                children: [
                  // Stats bar spans across the remaining width
                  DashboardStatsBar(
                    total: streamAsync.valueOrNull?.length ?? 0,
                    isHistory: isHistoryMode,
                  ),

                  // Content Area (Master or Master-Detail)
                  Expanded(
                    child: Row(
                      children: [
                        // MASTER: List of Transactions
                        const Expanded(flex: 3, child: DashboardMasterList()),

                        // VERTICAL DIVIDER & DETAIL: (Tablet Only)
                        if (isTablet) ...[
                          const VerticalDivider(
                            width: 1,
                            color: Colors.white10,
                          ),
                          const Expanded(flex: 5, child: TabletDetailPanel()),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
