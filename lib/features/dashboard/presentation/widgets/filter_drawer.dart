import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../providers/filter_provider.dart';

class FilterDrawer extends ConsumerWidget {
  const FilterDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filterState = ref.watch(filterProvider);
    final notifier = ref.read(filterProvider.notifier);

    return Drawer(
      backgroundColor: AppColors.background,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Advanced Filters", style: TextStyle(color: AppColors.primary, fontSize: 18, fontWeight: FontWeight.bold)),
              const Divider(color: AppColors.divider),
              
              const SizedBox(height: 16),
              TextField(
                onChanged: notifier.setQuery,
                decoration: const InputDecoration(
                  labelText: "Search (Trace, PAN...)",
                  labelStyle: TextStyle(color: AppColors.secondaryText),
                  enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: AppColors.divider)),
                  focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: AppColors.primary)),
                  prefixIcon: Icon(Icons.search, color: AppColors.secondaryText),
                ),
                style: const TextStyle(color: AppColors.primaryText),
              ),
              
              const SizedBox(height: 16),
              SwitchListTile(
                title: const Text("Show Errors Only (!00)", style: TextStyle(color: AppColors.primaryText)),
                value: filterState.onlyErrors,
                onChanged: notifier.toggleErrors,
                activeColor: AppColors.error,
              ),
              
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text("APPLY", style: TextStyle(color: Colors.white)),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
