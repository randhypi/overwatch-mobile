import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/transaction_group.dart';
import '../../domain/entities/trace_log.dart';

class TransactionGroupCard extends StatelessWidget {
  final TransactionGroup group;
  final VoidCallback onTap;

  const TransactionGroupCard({super.key, required this.group, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final log = group.primaryRequest;
    
    // Status Logic
    final status = group.status;
    final isSuccess = status == '00';
    final statusColor = isSuccess ? AppColors.success : const Color(0xFFE06C75);
    
    // Border Color: Blue if Hybrid (ISO+JSON), else inherited from Type
    final isHybrid = group.isoPairs.isNotEmpty && group.jsonPairs.isNotEmpty;
    final borderColor = isHybrid ? const Color(0xFFD19A66) : (log.type == LogType.iso ? AppColors.primary : const Color(0xFFE06C75));

    return InkWell(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          border: Border(left: BorderSide(color: borderColor, width: 4)),
          borderRadius: BorderRadius.circular(4),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 4, offset:const Offset(0, 2))
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- HEADER ---
            Container(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.2),
                border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.05))),
              ),
              child: Row(
                children: [
                  Text("Ref: ", style: const TextStyle(color: AppColors.secondaryText, fontSize: 11)),
                  Text(group.refNum, style: const TextStyle(color: AppColors.primaryText, fontWeight: FontWeight.bold, fontSize: 11)),
                  const Spacer(),
                  // Badges
                  if (group.isoPairs.isNotEmpty) _buildMiniBadge("ISO", AppColors.primary),
                  if (group.jsonPairs.isNotEmpty) ...[
                      const SizedBox(width: 4),
                      _buildMiniBadge("JSON", const Color(0xFFE06C75)),
                  ],
                  const Spacer(),
                  Text(_formatTime(log.timestamp), style: const TextStyle(color: AppColors.secondaryText, fontSize: 11)),
                ],
              ),
            ),

            // --- BODY ---
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   // Status & Name
                   Expanded(
                    flex: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                         Text(status, style: TextStyle(color: statusColor, fontSize: 18, fontWeight: FontWeight.bold)),
                         const SizedBox(height: 4),
                         Text(log.transactionName, 
                             style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                             maxLines: 1, overflow: TextOverflow.ellipsis
                         ),
                         if (log.bankName.isNotEmpty) ...[
                             const SizedBox(height: 2),
                             Text(log.bankName, style: TextStyle(color: AppColors.primary.withOpacity(0.8), fontSize: 10)),
                         ]
                      ],
                    ),
                   ),
                   
                   // Amount
                   Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text("Amount", style: TextStyle(color: AppColors.secondaryText, fontSize: 10)),
                        Text("Rp ${log.amount}", style: const TextStyle(color: AppColors.primaryText, fontWeight: FontWeight.bold, fontSize: 13)),
                      ],
                    ),
                   )
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildMiniBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(2),
        border: Border.all(color: color.withOpacity(0.5), width: 0.5)
      ),
      child: Text(text, style: TextStyle(color: color, fontSize: 9)),
    );
  }

  String _formatTime(DateTime dt) {
    return "${dt.hour.toString().padLeft(2,'0')}:${dt.minute.toString().padLeft(2,'0')}:${dt.second.toString().padLeft(2,'0')}";
  }
}
