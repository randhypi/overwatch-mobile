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
    String status = '00';
    String refNum = '-';
    String serialNumber = '-';
    String terminalId = '-';
    String pCode = '-';

    // 1. Extract Fields using Regex for [XXX] : [Value] format
    // Trace (Field 11)
    final traceMatch = RegExp(r'(?:Field\s+)?011[:\s]+(?:\[)?(\d+)(?:\])?').firstMatch(rawLog);
    if (traceMatch != null) trace = traceMatch.group(1) ?? '000000';

    // RefNum (Field 37)
    final refMatch = RegExp(r'(?:Field\s+)?037[:\s]+(?:\[)?(\w+)(?:\])?').firstMatch(rawLog);
    if (refMatch != null) refNum = refMatch.group(1) ?? '-';

    // TID (Field 41)
    final tidMatch = RegExp(r'(?:Field\s+)?041[:\s]+(?:\[)?(\w+)(?:\])?').firstMatch(rawLog);
    if (tidMatch != null) terminalId = tidMatch.group(1) ?? '-';

    // PCode (Field 3)
    final pCodeMatch = RegExp(r'(?:Field\s+)?003[:\s]+(?:\[)?(\d+)(?:\])?').firstMatch(rawLog);
    if (pCodeMatch != null) pCode = pCodeMatch.group(1) ?? '-';

    // Amount (Field 4)
    final amountMatch = RegExp(r'(?:Field\s+)?004[:\s]+(?:\[)?(\d+)(?:\])?').firstMatch(rawLog);
    if (amountMatch != null) amount = amountMatch.group(1) ?? '0';

    // Status (Field 39)
    final statusMatch = RegExp(r'(?:Field\s+)?039[:\s]+(?:\[)?(\w+)(?:\])?').firstMatch(rawLog);
    if (statusMatch != null) status = statusMatch.group(1) ?? '00';
    
    // PAN (Field 2)
    final panMatch = RegExp(r'(?:Field\s+)?002[:\s]+(?:\[)?([\d\*]+)(?:\])?').firstMatch(rawLog);
    if (panMatch != null) pan = _maskPan(panMatch.group(1) ?? '');

    // Private Data (Field 48) - Critical for Network Logic
    String privateData = '';
    final pDataMatch = RegExp(r'(?:Field\s+)?048[:\s]+(?:\[)?([^\]\r\n]+)(?:\])?').firstMatch(rawLog);
    if (pDataMatch != null) privateData = pDataMatch.group(1) ?? '';

    return TraceLog(
      timestamp: DateTime.now(),
      traceNumber: trace,
      content: rawLog,
      type: LogType.iso,
      status: status,
      pan: pan,
      amount: amount,
      refNum: refNum,
      serialNumber: serialNumber,
      terminalId: terminalId,
      pCode: pCode,
      transactionName: "ISO Transaction",
      privateData: privateData,
    );
  }

  static String _maskPan(String rawPan) {
    if (rawPan.length < 10) return rawPan;
    return "${rawPan.substring(0, 6)}******${rawPan.substring(rawPan.length - 4)}";
  }
}
