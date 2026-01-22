import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/trace_log.dart';
import '../../domain/repositories/trace_repository.dart';
import '../datasources/trace_remote_datasource.dart';

class TraceRepositoryImpl implements TraceRepository {
  final TraceRemoteDataSource _dataSource;
  
  TraceRepositoryImpl(this._dataSource);

  @override
  Future<List<TraceLog>> fetchLogs() {
    return _dataSource.fetchLogs();
  }

  @override
  Stream<List<TraceLog>> getLogStream() {
    // Simple polling every 2 seconds
    return Stream.periodic(const Duration(seconds: 2))
        .asyncMap((_) => fetchLogs());
  }
}
