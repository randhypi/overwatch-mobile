import '../entities/log_pair.dart';
import '../entities/transaction_group.dart';
import '../entities/trace_log.dart';

class GroupingUseCase {
  /// Groups a list of Paired Logs into TransactionGroups based on RefNum.
  List<TransactionGroup> execute(List<LogPair> pairs) {
    if (pairs.isEmpty) return [];

    final Map<String, TransactionGroupBuilder> groupMap = {};
    final List<TransactionGroup> orphans = [];

    for (var pair in pairs) {
      final refNum = pair.request.refNum;

      // Check if Valid RefNum (Not empty, not dash)
      if (refNum.isEmpty || refNum == '-' || refNum == 'N/A') {
        // Orphan logic: Treat specific "Orphan Group" per pair?
        // Or grouped orphan? Usually separate.
        orphans.add(TransactionGroup(
             refNum: 'N/A', 
             isoPairs: pair.request.type == LogType.iso ? [pair] : [], 
             jsonPairs: pair.request.type == LogType.json ? [pair] : [], 
             timestamp: pair.request.timestamp
        ));
        continue;
      }

      // Grouping
      if (!groupMap.containsKey(refNum)) {
        groupMap[refNum] = TransactionGroupBuilder(refNum);
      }
      
      final builder = groupMap[refNum]!;
      if (pair.request.type == LogType.iso) {
          builder.isoPairs.add(pair);
      } else {
          builder.jsonPairs.add(pair);
      }
      
      // Update Timestamp (Keep newest)
      if (pair.request.timestamp.isAfter(builder.latestTimestamp)) {
          builder.latestTimestamp = pair.request.timestamp;
      }
    }

    // Convert Builders to Groups
    final groups = groupMap.values.map((b) => b.build()).toList();
    
    // Add Orphans
    groups.addAll(orphans);

    // Sort by Timestamp Descending
    groups.sort((a, b) => b.timestamp.compareTo(a.timestamp));

    return groups;
  }
}

class TransactionGroupBuilder {
  final String refNum;
  final List<LogPair> isoPairs = [];
  final List<LogPair> jsonPairs = [];
  DateTime latestTimestamp = DateTime.fromMillisecondsSinceEpoch(0);

  TransactionGroupBuilder(this.refNum);

  TransactionGroup build() {
    return TransactionGroup(
      refNum: refNum,
      isoPairs: isoPairs,
      jsonPairs: jsonPairs,
      timestamp: latestTimestamp,
    );
  }
}
