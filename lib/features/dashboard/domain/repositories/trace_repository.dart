import '../entities/trace_log.dart';

abstract class TraceRepository {
  /// Stream of logs (ISO & JSON) updated in real-time
  Stream<List<TraceLog>> getLogStream();
  
  /// Manual fetch
  Future<List<TraceLog>> fetchLogs();
}
