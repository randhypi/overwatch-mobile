import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/api/api_client.dart';
import '../../data/datasources/trace_remote_datasource.dart';
import '../../data/repositories/trace_repository_impl.dart';
import '../../domain/repositories/trace_repository.dart';
import '../../domain/usecases/pairing_usecase.dart';
import '../../domain/usecases/grouping_usecase.dart';
import '../../domain/entities/trace_context.dart';
import '../../domain/entities/transaction_group.dart';
import 'filter_provider.dart';
import 'history_provider.dart';
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

final traceConfigProvider = StateProvider<TraceConfig>(
  (ref) => TraceConfig.all,
); // Default: All

/// State for the currently selected transaction in Master-Detail mode
final selectedTransactionGroupProvider = StateProvider<TransactionGroup?>(
  (ref) => null,
);

final dashboardStreamProvider =
    StreamProvider.autoDispose<List<TransactionGroup>>((ref) {
      final isHistoryMode = ref.watch(historyModeProvider);

      if (isHistoryMode) {
        // HISTORY MODE
        // Convert Future to Stream to unify return type
        return ref.watch(historyGroupsProvider.future).asStream();
      } else {
        // LIVE MODE
        final repository = ref.watch(traceRepositoryProvider);
        final pairingUseCase = ref.watch(pairingUseCaseProvider);
        final filter = ref.watch(filterProvider);
        final config = ref.watch(traceConfigProvider);

        // Get raw stream (List<TraceLog>)
        return repository.getLogStream(config).map((logs) {
          // 1. Enrichment Phase
          final enrichedLogs =
              logs.map((log) => transactionEnricher.enrich(log)).toList();

          // 2. Pairing Phase
          final pairedLogs = pairingUseCase.execute(enrichedLogs);

          // 3. Filtering Phase
          // Filter Pairs BEFORE Grouping? Or Groups?
          // Usually filtering Pairs is safer for search.
          final filteredPairs =
              pairedLogs.where((pair) {
                if (filter.query.isEmpty && !filter.onlyErrors) return true;

                bool matchesQuery = true;
                if (filter.query.isNotEmpty) {
                  final q = filter.query.toLowerCase();
                  matchesQuery =
                      pair.traceNumber.contains(q) ||
                      pair.request.pan.toLowerCase().contains(q) ||
                      pair.request.amount.contains(q) ||
                      pair.request.bankName.toLowerCase().contains(q) ||
                      pair.request.transactionName.toLowerCase().contains(q);
                }

                bool matchesError = true;
                if (filter.onlyErrors) {
                  matchesError = pair.frontStatus != '00';
                }
                return matchesQuery && matchesError;
              }).toList();

          // 4. Grouping Phase (NEW)
          // Group the filtered pairs
          final groupingUseCase = GroupingUseCase();
          return groupingUseCase.execute(filteredPairs);
        });
      }
    });
