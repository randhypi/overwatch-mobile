import 'package:intl/intl.dart';
import '../../domain/entities/trace_log.dart';
import '../../domain/entities/app_node_config.dart';
import '../datasources/trace_remote_datasource.dart';

class HistoryRepository {
  final TraceRemoteDataSource _dataSource;

  HistoryRepository(this._dataSource);

  /// Aggregates logs for a specific Date across all 24 hours (00-23).
  /// Uses "Direct Attack" strategy (generating filenames) + "Infinite Loop" (chunking).
  Future<List<TraceLog>> getLogsByDate(DateTime date, String nodeName) async {
    final List<TraceLog> allLogs = [];
    final appName = AppNodeConfig.getAppName(nodeName);
    final dateStr = DateFormat('yyyyMMdd').format(date);

    // Loop Hours 00 to 23
    for (int i = 0; i < 24; i++) {
      // Filename Format: {Node}_{YYYYMMDD}_{HH}.log
      // Example: EDC Nobu_20251224_08.log
      final hourStr = i.toString().padLeft(2, '0');
      final fileName = "${nodeName}_${dateStr}_$hourStr.log";

      // Fetch logs for this file (with chunking)
      final fileLogs = await _fetchFullFile(appName, fileName);
      if (fileLogs.isNotEmpty) {
        allLogs.addAll(fileLogs);
      }
    }

    // Sort Descending (Newest First)
    allLogs.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return allLogs;
  }

  /// Fetches a single file completely, handling chunking/pagination.
  Future<List<TraceLog>> _fetchFullFile(String appName, String fileName) async {
    final List<TraceLog> fileLogs = [];
    int lastPosition = 0;
    bool hasMore = true;
    int emptyResponseCount = 0;

    // Infinite Loop Reader
    while (hasMore) {
      final result = await _dataSource.fetchTraceView(
        appName,
        fileName,
        lastPosition,
      );
      final List<TraceLog> resultLogs =
          (result['logs'] as List<TraceLog>?) ?? <TraceLog>[];
      final int newPosition = result['lastPosition'] ?? lastPosition;

      // Append Logs
      if (resultLogs.isNotEmpty) {
        fileLogs.addAll(resultLogs);
      }

      // Break Condition: EOF
      // If position didn't change, we reached end of file.
      // Or if we got no logs (redundant check but safe).
      if (newPosition == lastPosition) {
        hasMore = false;
      } else {
        // Update position for next chunk
        lastPosition = newPosition;
      }

      // Safety break for stuck loops?
      // If server returns newPosition > lastPosition but EMPTY logs over and over?
      // We trust newPosition only advances if data exists (byte length).
    }

    return fileLogs;
  }
}
