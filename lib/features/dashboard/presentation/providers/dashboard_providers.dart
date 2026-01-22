import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/api/api_client.dart';
import '../../domain/entities/log_pair.dart';
import '../../data/datasources/trace_remote_datasource.dart';
import '../../data/repositories/trace_repository_impl.dart';
import '../../domain/repositories/trace_repository.dart';
import '../../domain/usecases/pairing_usecase.dart';
import '../../domain/entities/trace_context.dart';
import 'filter_provider.dart';
import '../../domain/utils/transaction_enricher.dart';

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

final traceConfigProvider = StateProvider<TraceConfig>((ref) => TraceConfig.all); // Default: All

final dashboardStreamProvider = StreamProvider.autoDispose<List<LogPair>>((ref) {
  final repository = ref.watch(traceRepositoryProvider);
  final pairingUseCase = ref.watch(pairingUseCaseProvider);
  final filter = ref.watch(filterProvider);
  final config = ref.watch(traceConfigProvider);
  
  // Get raw stream (List<TraceLog>)
  return repository.getLogStream(config).map((logs) {
    // 1. Enrichment Phase
    final enrichedLogs = logs.map((log) => transactionEnricher.enrich(log)).toList();

    // 2. Pairing Phase (Two-Phase Batch Logic)
    final pairedLogs = pairingUseCase.execute(enrichedLogs);

    // 3. Filtering Phase
    if (filter.query.isEmpty && !filter.onlyErrors) return pairedLogs;

    return pairedLogs.where((pair) {
      bool matchesQuery = true;
      if (filter.query.isNotEmpty) {
        final q = filter.query.toLowerCase();
        matchesQuery = pair.traceNumber.contains(q) ||
                       pair.request.pan.toLowerCase().contains(q) ||
                       pair.request.amount.contains(q) ||
                       pair.request.bankName.toLowerCase().contains(q) || // Filter by Bank
                       pair.request.transactionName.toLowerCase().contains(q); // Filter by Type
      }

      bool matchesError = true;
      if (filter.onlyErrors) {
        matchesError = pair.frontStatus != '00';
      }

      return matchesQuery && matchesError;
    }).toList();
  });
});
