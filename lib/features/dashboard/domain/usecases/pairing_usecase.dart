import '../entities/trace_log.dart';
import '../entities/log_pair.dart';

class PairingUseCase {
  /// Executes Two-Phase Pairing Logic
  /// Input: Mixed List of Requests & Responses
  /// Output: paired LogPair List (Sorted by Timestamp Descending)
  List<LogPair> execute(List<TraceLog> logs) {
    if (logs.isEmpty) return [];

    // Separate Requests (REQ) and Responses (RSP)
    // Assumption: JSON uses 'REQ'/'RSP' type field or derived logic.
    // However, TraceLog currently has 'type' (Iso/Json).
    // Usually Response is identified by MTI (ISO) or content (JSON).
    // For ISO: Request MTI ends in even (0800), Response odd (0810) - simplifying.
    // For JSON: We need to parse content or use a heuristic.
    // Let's assume the upstream (Parser) could tag it, but for now we infer.

    final requests = <TraceLog>[];
    final responses = <TraceLog>[];

    for (var log in logs) {
        if (_isResponse(log)) {
            responses.add(log);
        } else {
            requests.add(log);
        }
    }

    final pairs = <LogPair>[];
    final unmatchedRequests = <TraceLog>[];

    // --- Phase 1: Strict ID Matching ---
    // We iterate responses and try to find their requests? 
    // Or iterate requests and find responses?
    // parser.js iterates REQUESTS first.

    // Index Responses by ID for O(1) lookup
    // Key format: "RefNum" or "Trace"
    // Since IDs might collision, we prioritize RefNum.
    
    // Actually, iterating Requests is safer for ordering.
    // But efficiency matters.
    final responsePool = [...responses]; // Copy to remove matched ones

    for (var req in requests) {
        int matchIndex = -1;

        if (req.type == LogType.iso) {
             // ISO Match: Field 011 (Trace) match
             matchIndex = responsePool.indexWhere((rsp) => 
                 rsp.type == LogType.iso && rsp.traceNumber == req.traceNumber
             );
        } else {
            // JSON Match: RefNum Match
            if (req.refNum.isNotEmpty && req.refNum != '-') {
                 matchIndex = responsePool.indexWhere((rsp) => 
                     rsp.refNum == req.refNum
                 );
            }
            // JSON Fallback: Trace Match
            if (matchIndex == -1 && req.traceNumber != '000000') {
                 matchIndex = responsePool.indexWhere((rsp) => 
                     // Ensure we don't match ISO response to JSON request
                     rsp.type == LogType.json && rsp.traceNumber == req.traceNumber
                 );
            }
        }

        if (matchIndex != -1) {
            pairs.add(LogPair(request: req, response: responsePool[matchIndex]));
            responsePool.removeAt(matchIndex);
        } else {
            unmatchedRequests.add(req);
        }
    }

    // --- Phase 2: Greedy Matching (Anonymous Fallback) ---
    // Match Orphan Requests to Anonymous Error Responses
    // logic: parser.js lines 140-174
    // Condition: Response has NO RefNum and NO Trace (or generic).
    
    final trulyOrphanRequests = <TraceLog>[];

    for (var req in unmatchedRequests) {
        // Find first Anonymous Response
        // An "Anonymous" response is one that wasn't matched strictly.
        // Usually it's an error from the gateway that has no ID.
        // We assume FIFO ordering (First Orphan Req gets First Anon Rsp).
        
        // Note: responsePool only contains unmatched responses now.
        final anonIndex = responsePool.indexWhere((rsp) => 
            rsp.type == req.type && // Must match type (JSON to JSON)
            _isAnonymous(rsp) 
        );

        if (anonIndex != -1) {
             pairs.add(LogPair(request: req, response: responsePool[anonIndex]));
             responsePool.removeAt(anonIndex);
        } else {
            trulyOrphanRequests.add(req);
        }
    }

    // Add remaining Orphans as single Requests
    for (var req in trulyOrphanRequests) {
        pairs.add(LogPair(request: req));
    }

    // Add remaining Unmatched Responses? (Usually junk, but good for debug)
    // parser.js sometimes skips them. We will skip them to keep UI clean.

    // Sort by Timestamp (Newest first)
    pairs.sort((a, b) => b.request.timestamp.compareTo(a.request.timestamp));

    return pairs;
  }

  bool _isResponse(TraceLog log) {
      // 1. Check if explicitly marked by Parser (if parser supports it)
      // Current parser sets type=Iso/Json but not Req/Rsp explicitly in type enum.

      if (log.type == LogType.iso) {
          // ISO Check
          // a. Check text markers
          if (log.content.contains("RSP") || log.content.contains("Response")) return true;
          
          // b. Check MTI (Reliable)
          final mtiMatch = RegExp(r'<(\d{4})>').firstMatch(log.content);
          if (mtiMatch != null) {
              final mti = int.tryParse(mtiMatch.group(1) ?? '0') ?? 0;
              // MTI 2nd digit strategy? 
              // Standard: 0200(Req)->0210(Rsp), 0800(Req)->0810(Rsp). 
              // Even=Req, Odd=Rsp ?? 
              // Actually: 
              // Digits: 1(Ver) 2(Class) 3(Func) 4(Orig)
              // Func: 0=Req, 1=ReqRsp, 2=Adv, 3=AdvRsp ... 
              // Common: 0=Req, 1=Rsp. 
              final func = (mti % 100) ~/ 10; 
              return (func % 2 != 0); // Odd function digit usually means Response/Repeat
          }
          return false;
      } else {
          // JSON Check (Heuristics)
          // a. Explicit Tag
          if (log.content.contains("<RSP>")) return true;
          
          // b. JSON Fields (Success or Error)
          if (log.content.contains('"responseCode"')) return true;
          if (log.content.contains('"responseStatus"')) return true; // Common variation
          if (log.content.contains('"responseMessage"')) return true;
          if (log.content.contains('"error"')) return true; // Error response?
          
          // c. Contextual (RefNum Matches an existing Request?) - Hard to do here without state.
          // We assume "response" fields are present.
          return false;
      }
  }

  bool _isAnonymous(TraceLog log) {
      // Logic: Has no specific ID
      // Treat '000000' and '0' and '-' as empty
      final trace = log.traceNumber;
      final ref = log.refNum;
      
      final inactiveTrace = trace == '000000' || trace == '0' || trace.isEmpty || trace == '-';
      final inactiveRef = ref == '' || ref == '-' || ref == 'N/A';

      return inactiveRef && inactiveTrace;
  }
}
