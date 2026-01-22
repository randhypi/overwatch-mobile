import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/app_colors.dart';
import 'package:overwatch_mobile/features/dashboard/domain/entities/log_pair.dart';
import 'package:overwatch_mobile/features/dashboard/domain/entities/trace_log.dart';

class LogDetailScreen extends StatelessWidget {
  final LogPair logPair;

  const LogDetailScreen({super.key, required this.logPair});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text("Trace #${logPair.traceNumber}"),
          bottom: const TabBar(
            indicatorColor: AppColors.primary,
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.secondaryText,
            tabs: [
              Tab(text: "REQUEST"),
              Tab(text: "RESPONSE"),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.copy),
              tooltip: "Copy Trace ID",
              onPressed: () {
                Clipboard.setData(ClipboardData(text: logPair.traceNumber));
                 ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Trace ID Copied"))
                );
              },
            )
          ],
        ),
        body: TabBarView(
          children: [
            _buildLogContent(context, logPair.request),
            if (logPair.response != null)
              _buildLogContent(context, logPair.response!)
            else
              const Center(child: Text("No Response Logged", style: TextStyle(color: AppColors.secondaryText))),
          ],
        ),
      ),
    );
  }

  Widget _buildLogContent(BuildContext context, TraceLog log) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoRow("Timestamp", log.timestamp.toString()),
          _buildInfoRow("Type", log.type.toString().split('.').last.toUpperCase()),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("RAW CONTENT", style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
              IconButton(
                icon: const Icon(Icons.copy_all, size: 20, color: AppColors.primary),
                onPressed: () {
                   Clipboard.setData(ClipboardData(text: log.content));
                   ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Raw Content Copied"))
                  );
                },
              )
            ],
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.cardBg,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: AppColors.divider),
            ),
            child: SelectableText(
              log.content,
              style: const TextStyle(fontFamily: 'monospace', color: AppColors.primaryText, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(width: 100, child: Text(label, style: const TextStyle(color: AppColors.secondaryText))),
          Expanded(child: Text(value, style: const TextStyle(color: AppColors.primaryText, fontFamily: 'monospace'))),
        ],
      ),
    );
  }
}
