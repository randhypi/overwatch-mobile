import '../entities/trace_log.dart';

class IsoParser {
  // Regex from FSD to capture Timestamp and MTI
  static final headerRegex = RegExp(r'(?:\[)?(\d{1,2}\s+[A-Za-z]{3}\s+\d{4}\s+[\d:.]+|[\d-]{10}\s+[\d:.]{8,})(?:\])?(?:\s*<(\d{4})>)?');
  
  // Field Extractor: Captured Group 1 = Field ID, Group 2 = Value
  static final fieldRegex = RegExp(r'(?:Field\s+)?(\d{3})[:\s]+(?:\[)?([^\]\r\n]+)(?:\])?');

  static TraceLog parse(String rawLog) {
    String trace = '000000';
    String pan = '';
    String amount = '0';
    String status = 'unknown'; // Usually F39
    
    // 1. Extract Fields
    final matches = fieldRegex.allMatches(rawLog);
    for (final m in matches) {
      final fieldId = m.group(1);
      final value = m.group(2)?.trim() ?? '';
      
      switch (fieldId) {
        case '002': // PAN
          pan = _maskPan(value);
          break;
        case '004': // Amount
          amount = value;
          break;
        case '011': // Trace
          trace = value;
          break;
        case '039': // Response Code
          status = value;
          break;
      }
    }
    
    // 2. Extract Timestamp (Naive approach, usually depends on log format)
    // For now, use current time if regex fails, or try to parse match
    DateTime timestamp = DateTime.now();
    final headerMatch = headerRegex.firstMatch(rawLog);
    if (headerMatch != null) {
      // Parsing logic would go here, skipping for MVP to avoid timezone hell
      // timestamp = ...
    }

    return TraceLog(
      timestamp: timestamp,
      traceNumber: trace,
      content: rawLog,
      type: LogType.iso,
      status: status,
      pan: pan,
      amount: amount,
    );
  }

  static String _maskPan(String rawPan) {
    if (rawPan.length < 10) return rawPan;
    return "${rawPan.substring(0, 6)}******${rawPan.substring(rawPan.length - 4)}";
  }
}
