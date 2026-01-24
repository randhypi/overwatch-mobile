import 'log_pair.dart';
import 'trace_log.dart';

/// Aggregates logs for a single Business Transaction (ISO + JSON).
/// Keyed by RefNum.
class TransactionGroup {
  final String refNum;
  final List<LogPair> isoPairs;
  final List<LogPair> jsonPairs;
  final DateTime timestamp;

  TransactionGroup({
    required this.refNum,
    required this.isoPairs,
    required this.jsonPairs,
    required this.timestamp,
  });

  /// Helper to get the best Request to display in the card header.
  TraceLog get primaryRequest {
    // Prefer ISO Request if available, else JSON Request
    if (isoPairs.isNotEmpty) return isoPairs.first.request;
    if (jsonPairs.isNotEmpty) return jsonPairs.first.request;
    
    // Should not happen for valid group
    throw Exception("Empty Group");
  }
  
  /// Helper to get overall status
  String get status {
      // Logic: if ANY pair is failed -> Group is failed?
      // Or primary status?
      // Use Primary
      if (isoPairs.isNotEmpty) return isoPairs.first.frontStatus;
      if (jsonPairs.isNotEmpty) return jsonPairs.first.frontStatus;
      return 'unknown';
  }
}
