import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/log_pair.dart';
import '../../../log_detail/presentation/screens/log_detail_screen.dart';

class LogCard extends StatelessWidget {
  final LogPair logPair;
  
  const LogCard({super.key, required this.logPair});

  @override
  Widget build(BuildContext context) {
    // Status Logic
    final status = logPair.frontStatus;
    final isSuccess = status == '00';
    final isPending = !logPair.isComplete;
    
    Color statusColor;
    if (isPending) {
      statusColor = AppColors.secondaryText;
    } else {
      statusColor = isSuccess ? AppColors.success : AppColors.error;
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => LogDetailScreen(logPair: logPair)),
          );
        },
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.cardBg,
            border: Border(left: BorderSide(color: statusColor, width: 4)),
          ),
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: Trace & Status
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "TRACE: ${logPair.traceNumber}", 
                    style: const TextStyle(
                      fontFamily: 'monospace', 
                      color: AppColors.primary, 
                      fontWeight: FontWeight.bold
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: statusColor.withOpacity(0.5)),
                    ),
                    child: Text(
                      status.toUpperCase(),
                      style: TextStyle(color: statusColor, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              
              // Body: PAN & Info
              Row(
                children: [
                  const Icon(Icons.credit_card, size: 14, color: AppColors.secondaryText),
                  const SizedBox(width: 4),
                  Text(
                    logPair.request.pan.isNotEmpty ? logPair.request.pan : "NO PAN",
                    style: const TextStyle(color: AppColors.primaryText),
                  ),
                  const Spacer(),
                  const Icon(Icons.access_time, size: 14, color: AppColors.secondaryText),
                  const SizedBox(width: 4),
                  Text(
                    _formatTime(logPair.request.timestamp),
                    style: const TextStyle(color: AppColors.secondaryText, fontSize: 12),
                  ),
                ],
              ),
              
              const SizedBox(height: 4),
              // Amount if available
              if (logPair.request.amount.isNotEmpty && logPair.request.amount != '0')
               Text(
                 "AMT: ${logPair.request.amount}",
                 style: const TextStyle(color: AppColors.primaryText, fontFamily: 'monospace'),
               ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime dt) {
    return "${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}:${dt.second.toString().padLeft(2, '0')}";
  }
}
