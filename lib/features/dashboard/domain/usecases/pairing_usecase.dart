import 'package:rxdart/rxdart.dart';
import '../entities/trace_log.dart';
import '../entities/log_pair.dart';

class PairingUseCase {
  // Config: Expire pending requests after 60s
  static const Duration pendingTimeout = Duration(seconds: 60);

  Stream<List<LogPair>> execute(Stream<TraceLog> incomingLogs) {
    // This is a simplified version. A real production version needs
    // a persistent buffer and cleanup timer.
    // For MVP, we scan a list or use scan in RxDart.
    
    // Using scan to accumulate state
    return incomingLogs.scan<Map<String, LogPair>>((accumulated, log, index) {
      final key = log.traceNumber;
      
      if (accumulated.containsKey(key)) {
        // We have a pending entry for this trace
        final existing = accumulated[key]!;
        if (existing.response == null) {
          // This must be the response (simplification: assume 2nd is response)
          // Ideally check message type (MTI)
          accumulated[key] = LogPair(request: existing.request, response: log);
        }
      } else {
        // New entry (Assume it's a request)
        accumulated[key] = LogPair(request: log);
      }
      
      return accumulated;
    }, {}).map((map) => map.values.toList().reversed.toList()); // Newest first
  }
}
