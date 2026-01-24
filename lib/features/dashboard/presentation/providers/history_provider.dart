import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/transaction_group.dart';
import '../../domain/utils/transaction_enricher.dart';
import '../../data/repositories/history_repository.dart';
import '../../domain/usecases/grouping_usecase.dart';
import 'dashboard_providers.dart';

// 1. History Mode Toggle
final historyModeProvider = StateProvider<bool>((ref) => false);

// 2. Selected Date
final selectedDateProvider = StateProvider<DateTime>((ref) => DateTime.now());

// 3. Selected Node (Reuse TraceConfig or separate?)
// For now, let's look at traceConfigProvider, assuming it has the Node selected.

// 4. History Logs Fetcher (The Heavy Lifter)
final historyGroupsProvider = FutureProvider<List<TransactionGroup>>((
  ref,
) async {
  final date = ref.watch(selectedDateProvider);
  final config = ref.watch(traceConfigProvider);

  // Repo
  final historyRepo = HistoryRepository(
    ref.read(traceRemoteDataSourceProvider),
  );

  // 1. Fetch Raw Logs (Aggregated 00-23)
  final rawLogs = await historyRepo.getLogsByDate(date, config.nodeName);

  // 2. Enrich
  final enrichedLogs =
      rawLogs.map((log) => transactionEnricher.enrich(log)).toList();

  // 3. Pair
  final pairingUseCase = ref.read(pairingUseCaseProvider);
  final pairs = pairingUseCase.execute(enrichedLogs);

  // 4. Group
  final groupingUseCase = GroupingUseCase(); // Usually stateless
  final groups = groupingUseCase.execute(pairs);

  return groups;
});
