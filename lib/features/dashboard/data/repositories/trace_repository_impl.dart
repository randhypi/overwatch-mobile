import '../../domain/entities/trace_log.dart';
import '../../domain/repositories/trace_repository.dart';
import '../datasources/trace_remote_datasource.dart';

import '../../domain/entities/trace_context.dart';

class TraceRepositoryImpl implements TraceRepository {
  final TraceRemoteDataSource _dataSource;
  final Map<String, int> _lastPositions =
      {}; // Track pos per nodeName matches key

  TraceRepositoryImpl(this._dataSource);

  @override
  Future<List<TraceLog>> fetchLogs(TraceConfig config) async {
    if (config.type == TraceTargetType.all) {
      // Parallel Fetch
      final results = await Future.wait([
        _fetchSingle(TraceConfig.edc),
        _fetchSingle(TraceConfig.nobu),
      ]);
      // Merge and Sort (Newest First)
      final merged = [...results[0], ...results[1]];
      merged.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      return merged;
    } else {
      return _fetchSingle(config);
    }
  }

  Future<List<TraceLog>> _fetchSingle(TraceConfig config) async {
    final key = config.nodeName;
    final lastPos = _lastPositions[key] ?? 0;

    final result = await _dataSource.fetchTraceCurrent(
      config.appName,
      config.nodeName,
      lastPos,
    );

    final logs = result['logs'] as List<TraceLog>;
    final newPos = result['lastPosition'] as int;

    _lastPositions[key] = newPos;
    return logs;
  }

  @override
  Stream<List<TraceLog>> getLogStream(TraceConfig config) {
    // Single fetch stream as requested previously
    return Stream.fromFuture(fetchLogs(config));
  }
}
