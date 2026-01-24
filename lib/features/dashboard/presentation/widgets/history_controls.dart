import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../providers/history_provider.dart';

class HistoryControls extends ConsumerWidget {
  const HistoryControls({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isHistory = ref.watch(historyModeProvider);
    final selectedDate = ref.watch(selectedDateProvider);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
           // Mode Switcher / Indicator
           if (isHistory) 
             _buildBadge("HISTORY", AppColors.warning)
           else
             _buildBadge("LIVE", AppColors.success),
           
           const SizedBox(width: 8),

           // Date Picker Button
           InkWell(
             onTap: () async {
               final picked = await showDatePicker(
                 context: context, 
                 initialDate: selectedDate, 
                 firstDate: DateTime(2023), 
                 lastDate: DateTime.now()
               );
               
               if (picked != null) {
                  ref.read(selectedDateProvider.notifier).state = picked;
                  
                  // Auto-switch to History Mode if not already
                  if (!isHistory) {
                      ref.read(historyModeProvider.notifier).state = true;
                  }
               }
             },
             borderRadius: BorderRadius.circular(4),
             child: Container(
               padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
               decoration: BoxDecoration(
                 border: Border.all(color: AppColors.primary.withOpacity(0.5)),
                 borderRadius: BorderRadius.circular(4),
                 color: Colors.black.withOpacity(0.3)
               ),
               child: Row(
                 children: [
                   const Icon(Icons.calendar_today, size: 14, color: AppColors.primaryText),
                   const SizedBox(width: 8),
                   Text(
                     DateFormat('dd MMM yyyy').format(selectedDate),
                     style: const TextStyle(color: AppColors.primaryText, fontSize: 13, fontWeight: FontWeight.bold),
                   ),
                   const SizedBox(width: 4),
                   const Icon(Icons.arrow_drop_down, size: 16, color: AppColors.secondaryText)
                 ],
               ),
             ),
           ),
           
           // Clear/Live Button (Only visible in History Mode)
           if (isHistory) ...[
               const SizedBox(width: 8),
               IconButton(
                 icon: const Icon(Icons.history_toggle_off, color: AppColors.error),
                 tooltip: "Back to Live",
                 onPressed: () {
                    ref.read(historyModeProvider.notifier).state = false;
                    // Reset date to today? Optional.
                    ref.read(selectedDateProvider.notifier).state = DateTime.now();
                 },
               )
           ]
        ],
      ),
    );
  }

  Widget _buildBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color, width: 1)
      ),
      child: Text(text, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }
}
