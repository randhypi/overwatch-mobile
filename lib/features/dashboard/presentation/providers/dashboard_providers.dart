import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/api/api_client.dart';
import '../../domain/entities/log_pair.dart';
import '../../data/datasources/trace_remote_datasource.dart';
import '../../data/repositories/trace_repository_impl.dart';
import '../../domain/repositories/trace_repository.dart';
import '../../domain/usecases/pairing_usecase.dart';
import 'filter_provider.dart';

// --- DATA LAYER PROVIDERS ---

final traceRemoteDataSourceProvider = Provider<TraceRemoteDataSource>((ref) {
  final dio = ref.watch(apiClientProvider);
  return TraceRemoteDataSource(dio);
});

final traceRepositoryProvider = Provider<TraceRepository>((ref) {
  final dataSource = ref.watch(traceRemoteDataSourceProvider);
  return TraceRepositoryImpl(dataSource);
});

// --- DOMAIN LAYER PROVIDERS ---

final pairingUseCaseProvider = Provider((ref) => PairingUseCase());

// --- PRESENTATION LAYER PROVIDERS ---

final dashboardStreamProvider = StreamProvider.autoDispose<List<LogPair>>((ref) {
  final repository = ref.watch(traceRepositoryProvider);
  final pairingUseCase = ref.watch(pairingUseCaseProvider);
  final filter = ref.watch(filterProvider);
  
  // Get raw stream
  final rawStream = repository.getLogStream();
  
  // Apply Pairing
  return pairingUseCase.execute(rawStream).map((list) {
    // Apply Filtering
    if (filter.query.isEmpty && !filter.onlyErrors) return list;

    return list.where((pair) {
      bool matchesQuery = true;
      if (filter.query.isNotEmpty) {
        final q = filter.query.toLowerCase();
        matchesQuery = pair.traceNumber.contains(q) ||
                       pair.request.pan.toLowerCase().contains(q) ||
                       pair.request.amount.contains(q);
      }

      bool matchesError = true;
      if (filter.onlyErrors) {
        matchesError = pair.frontStatus != '00';
      }

      return matchesQuery && matchesError;
    }).toList();
  });
});
