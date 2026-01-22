import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/log_pair.dart';
import '../../domain/entities/trace_log.dart';

class LogCard extends StatefulWidget {
  final LogPair logPair;
  final VoidCallback? onTap;

  const LogCard({super.key, required this.logPair, this.onTap});

  @override
  State<LogCard> createState() => _LogCardState();
}

class _LogCardState extends State<LogCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    // Use the request log as the primary source of info
    final log = widget.logPair.request;
    
    // Status Logic (Use Pair status which considers Response)
    final status = widget.logPair.frontStatus;
    final isSuccess = status == '00';
    final statusColor = isSuccess ? AppColors.success : const Color(0xFFE06C75);
    
    // Config based on Type
    final isIso = log.type == LogType.iso;
    final borderColor = isIso ? AppColors.primary : const Color(0xFFE06C75); 

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        border: Border(left: BorderSide(color: borderColor, width: 4)),
        borderRadius: BorderRadius.circular(4),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 4, offset: const Offset(0, 2))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- HEADER: Refnum | SN | PAN | Time ---
          Container(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.2),
              border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.05))),
            ),
            child: Row(
              children: [
                // Refnum
                Text("Refnum: ", style: const TextStyle(color: AppColors.secondaryText, fontSize: 11)),
                Text(log.refNum, style: const TextStyle(color: AppColors.primaryText, fontWeight: FontWeight.bold, fontSize: 11)),
                const Spacer(),
                
                // SN
                if (log.serialNumber != '-') ...[
                  Text("SN: ${log.serialNumber}", style: const TextStyle(color: AppColors.secondaryText, fontSize: 11)),
                  const SizedBox(width: 8),
                ],

                // PAN (Masked)
                const Icon(Icons.credit_card, size: 12, color: AppColors.primary),
                const SizedBox(width: 4),
                Text(log.pan.isNotEmpty ? log.pan : '****', style: const TextStyle(color: AppColors.secondaryText, fontSize: 11, fontFamily: 'monospace')),
                
                const Spacer(),
                // Time
                Text(_formatTime(log.timestamp), style: const TextStyle(color: AppColors.secondaryText, fontSize: 11)),
              ],
            ),
          ),

          // --- BODY: Status | Amount | Trace | TID ---
          InkWell(
            onTap: widget.onTap,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Left Column: Status & Code
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Status:", style: TextStyle(color: AppColors.secondaryText, fontSize: 10)),
                        const SizedBox(height: 2),
                        Text(status, 
                          style: TextStyle(color: statusColor, fontSize: 18, fontWeight: FontWeight.bold)
                        ),
                        // Transaction Name (Enriched)
                         const SizedBox(height: 4),
                         Text(log.transactionName.isNotEmpty ? log.transactionName : "Transaction", 
                             style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600), // Increased visibility
                             maxLines: 1, overflow: TextOverflow.ellipsis
                         ),
                         // Bank Name (Enriched)
                         if (log.bankName.isNotEmpty && log.bankName != 'Unknown Bank') ...[
                            const SizedBox(height: 2),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(color: AppColors.primary.withOpacity(0.5), width: 0.5)
                              ),
                              child: Text(log.bankName, style: const TextStyle(color: AppColors.primary, fontSize: 10, fontWeight: FontWeight.bold)),
                            )
                         ]
                      ],
                    ),
                  ),
                  
                  // Middle: Amount
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Amount:", style: TextStyle(color: AppColors.secondaryText, fontSize: 10)),
                        const SizedBox(height: 2),
                        Text("Rp ${log.amount}", style: const TextStyle(color: AppColors.primaryText, fontWeight: FontWeight.bold, fontSize: 13)),
                      ],
                    ),
                  ),

                   // Right: Trace & TID
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                         // Trace
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            const Text("Trace:", style: TextStyle(color: AppColors.secondaryText, fontSize: 10)),
                            const SizedBox(width: 4),
                             Flexible( // Fix Overflow
                               child: Text(log.traceNumber, 
                                 style: const TextStyle(color: AppColors.primaryText, fontFamily: 'monospace', fontSize: 11),
                                 overflow: TextOverflow.ellipsis,
                               ),
                             ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        // TID
                         Row(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            const Text("TID:", style: TextStyle(color: AppColors.secondaryText, fontSize: 10)),
                            const SizedBox(width: 4),
                             Flexible( // Fix Overflow
                               child: Text(log.terminalId, 
                                 style: const TextStyle(color: AppColors.primaryText, fontFamily: 'monospace', fontSize: 11),
                                 overflow: TextOverflow.ellipsis,
                               ),
                             ),
                          ],
                        ),
                         // PCode if ISO
                         if (isIso) ...[
                            const SizedBox(height: 4),
                            Text("PCode: ${log.pCode}", style: const TextStyle(color: AppColors.secondaryText, fontSize: 10)),
                         ]
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // --- FOOTER: Raw Data Expander ---
          GestureDetector(
            onTap: () => setState(() => _expanded = !_expanded),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              color: Colors.black.withOpacity(0.1),
              child: Row(
                children: [
                  Icon(_expanded ? Icons.arrow_drop_down : Icons.arrow_right, color: AppColors.secondaryText, size: 16),
                  const Text("Show Raw Data", style: TextStyle(color: AppColors.secondaryText, fontSize: 11)),
                ],
              ),
            ),
          ),
          
          if (_expanded)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              color: const Color(0xFF1E222A), // Darker for code block
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   const Text("--- Request ---", style: TextStyle(color: AppColors.secondaryText, fontSize: 10, fontWeight: FontWeight.bold)),
                   const SizedBox(height: 4),
                   SelectableText(
                    log.content,
                    style: const TextStyle(
                      fontFamily: 'monospace', 
                      fontSize: 10, 
                      color: AppColors.primaryText
                    ),
                  ),
                  if (widget.logPair.response != null) ...[
                      const SizedBox(height: 12),
                      const Text("--- Response ---", style: TextStyle(color: AppColors.secondaryText, fontSize: 10, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      SelectableText(
                        widget.logPair.response!.content, // Use Response Content
                        style: const TextStyle(
                          fontFamily: 'monospace', 
                          fontSize: 10, 
                          color: AppColors.primaryText
                        ),
                      ),
                  ]
                ],
              ),
            )
        ],
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];
    return "${dt.day} ${months[dt.month - 1]} ${dt.year} ${dt.hour.toString().padLeft(2,'0')}:${dt.minute.toString().padLeft(2,'0')}:${dt.second.toString().padLeft(2,'0')}.${dt.millisecond}";
  }
}
