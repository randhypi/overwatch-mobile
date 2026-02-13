import 'dart:convert';
import 'dart:io';
import '../entities/trace_log.dart';
import 'iso_parser.dart';

class LogParser {
  /// Decompress GZIP Base64 data
  static String decompressData(String base64String) {
    try {
      final bytes = base64Decode(base64String);
      final decoded = GZipCodec().decode(bytes);
      return utf8.decode(decoded);
    } catch (e) {
      print("Decompression Error: $e");
      return "";
    }
  }

  /// Parse raw content into list of TraceLog entities
  static List<TraceLog> parseRawContent(String rawContent) {
    final logs = <TraceLog>[];
    if (rawContent.isEmpty) return logs;

    // Regex to identify start of a log block
    final headerRegex = RegExp(
      r'(?:\[)?(\d{1,2}\s+[A-Za-z]{3}\s+\d{4}\s+[\d:.]+|[\d-]{10}\s+[\d:.]{8,})(?:\])?\s*<([A-Z0-9]+)>?',
    );

    final matches = headerRegex.allMatches(rawContent).toList();
    if (matches.isEmpty) return [];

    for (int i = 0; i < matches.length; i++) {
      final match = matches[i];
      final start = match.start;
      final end =
          (i + 1 < matches.length) ? matches[i + 1].start : rawContent.length;

      final rawBlock = rawContent.substring(start, end).trim();
      final timestampStr = match.group(1) ?? '';
      final typeTag = match.group(2) ?? '';

      if (typeTag == 'REQ' || typeTag == 'RSP') {
        final log = _processJsonBlock(rawBlock, timestampStr, typeTag);
        if (log != null) logs.add(log);
      } else {
        final log = IsoParser.parse(rawBlock);
        logs.add(log);
      }
    }

    return logs;
  }

  static TraceLog? _processJsonBlock(
    String rawBlock,
    String timestampStr,
    String typeTag,
  ) {
    try {
      final startJson = rawBlock.indexOf('{');
      final endJson = rawBlock.lastIndexOf('}');

      if (startJson != -1 && endJson > startJson) {
        final jsonStr = rawBlock.substring(startJson, endJson + 1);
        final map = jsonDecode(jsonStr);
        if (map is! Map) return null;

        return TraceLog(
          timestamp: DateTime.tryParse(timestampStr) ?? DateTime.now(),
          traceNumber: map['traceNumber']?.toString() ?? '000000',
          content: rawBlock,
          type: LogType.json,
          status: map['responseStatus'] ?? map['responseCode'] ?? '00',
          refNum:
              map['referenceNumber']?.toString() ??
              map['refnum']?.toString() ??
              '-',
          serialNumber: map['serialNumber']?.toString() ?? '-',
          terminalId:
              map['terminalId']?.toString() ?? map['tid']?.toString() ?? '-',
          amount: map['amount']?.toString() ?? '0',
          transactionName: 'JSON Transaction',
          pan: map['cardNumber']?.toString() ?? map['pan']?.toString() ?? '',
          pCode:
              map['processingCode']?.toString() ??
              map['pcode']?.toString() ??
              '-',
          privateData: map['privateData']?.toString() ?? '',
        );
      }
      return null;
    } catch (e) {
      print("JSON Parse Error: $e");
      return null;
    }
  }
}
