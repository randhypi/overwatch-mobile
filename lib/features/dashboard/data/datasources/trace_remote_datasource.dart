import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import '../../domain/entities/trace_log.dart';
import '../../domain/utils/iso_parser.dart';

class TraceRemoteDataSource {
  final Dio _dio;
  
  TraceRemoteDataSource(this._dio);

  /// 1. Trace List: Returns list of filenames
  Future<List<String>> fetchTraceList(String appName, String nodeName) async {
    try {
      final response = await _dio.post('/api/sdk/trace/list', data: {
        "appName": appName,
        "nodeName": nodeName
      });
      
      if (response.statusCode == 200 && response.data != null) {
        final data = response.data['data'];
        if (data != null && data['listFiles'] is List) {
          return List<String>.from(data['listFiles']);
        }
      }
      return [];
    } catch (e) {
      print("Fetch List Error: $e");
      return [];
    }
  }

  /// 2. Trace View: Returns specific file content
  Future<List<TraceLog>> fetchTraceView(String appName, String fileName, int lastPosition) async {
    // Implementation for View if needed (History Feature)
    // For now, focusing on Current
    return [];
  }

  /// 3. Trace Current: Realtime monitoring
  /// Returns Tuple: [List<TraceLog>, int newLastPosition]
  Future<Map<String, dynamic>> fetchTraceCurrent(String appName, String nodeName, int lastPosition) async {
    try {
      final response = await _dio.post('/api/sdk/trace/current', data: {
        "appName": appName,
        "nodeName": nodeName,
        "lastPosition": lastPosition
      });

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data['data'];
        if (data != null) {
          final int newPos = data['lastPosition'] ?? lastPosition;
          final String? compressed = data['logCompressed'];
          
          if (compressed != null && compressed.isNotEmpty) {
            final rawContent = _decompressData(compressed);
            final logs = _parseRawContent(rawContent);
            return {
              "logs": logs,
              "lastPosition": newPos
            };
          } else {
             return { "logs": <TraceLog>[], "lastPosition": newPos };
          }
        }
      }
      return { "logs": <TraceLog>[], "lastPosition": lastPosition };
    } catch (e) {
      print("Fetch Current Error: $e");
       // On error, keep same position to retry
      return { "logs": <TraceLog>[], "lastPosition": lastPosition };
    }
  }

  String _decompressData(String base64String) {
    try {
      final bytes = base64Decode(base64String);
      final decoded = GZipCodec().decode(bytes);
      return utf8.decode(decoded);
    } catch (e) {
      print("Decompression Error: $e");
      return "";
    }
  }

  List<TraceLog> _parseRawContent(String rawContent) {
    // Robust Block Parsing (Matching parser.js logic)
    // We search for headers to identify start of messages.
    // JSON Header: [Timestamp] <REQ|RSP>
    // ISO Header: [Timestamp] <MTI>
    
    final logs = <TraceLog>[];
    if (rawContent.isEmpty) return logs;
    
    // Regex to identify start of a log block
    // Matches: [2023-01-01 12:00:00] <REQ> OR [2023...] <0800>
    final headerRegex = RegExp(r'(?:\[)?(\d{1,2}\s+[A-Za-z]{3}\s+\d{4}\s+[\d:.]+|[\d-]{10}\s+[\d:.]{8,})(?:\])?\s*<([A-Z0-9]+)>?');
    
    final matches = headerRegex.allMatches(rawContent).toList();
    if (matches.isEmpty) {
        // Fallback: Try decoding as single JSON or ISO line
        // (Existing fallback logic)
        return []; 
    }

    for (int i = 0; i < matches.length; i++) {
        final match = matches[i];
        final start = match.start;
        final end = (i + 1 < matches.length) ? matches[i + 1].start : rawContent.length;
        
        final rawBlock = rawContent.substring(start, end).trim();
        final timestampStr = match.group(1) ?? '';
        final typeTag = match.group(2) ?? ''; // REQ, RSP, or 0800
        
        // Determine Type
        if (typeTag == 'REQ' || typeTag == 'RSP') {
            // JSON
            final log = _processJsonBlock(rawBlock, timestampStr, typeTag);
            if (log != null) logs.add(log);
        } else {
            // ISO (Numeric MTI)
            // Use IsoParser
            final log = IsoParser.parse(rawBlock);
            // Override timestamp if Regex captured it better? IsoParser does it too.
            logs.add(log);
        }
    }
    
    return logs;
  }
  
  TraceLog? _processJsonBlock(String rawBlock, String timestampStr, String typeTag) {
     try {
       // Extract JSON part within brackets
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
             
             // New Fields
             refNum: map['referenceNumber']?.toString() ?? map['refnum']?.toString() ?? '-',
             serialNumber: map['serialNumber']?.toString() ?? '-',
             terminalId: map['terminalId']?.toString() ?? map['tid']?.toString() ?? '-',
             amount: map['amount']?.toString() ?? '0',
             transactionName: 'JSON Transaction', // Will be enriched later
             pan: map['cardNumber']?.toString() ?? map['pan']?.toString() ?? '',
             pCode: map['processingCode']?.toString() ?? map['pcode']?.toString() ?? '-',
             
             // Populate Private Data if available (rare in JSON but possible)
             privateData: map['privateData']?.toString() ?? '',
           );
       }
       return null;
     } catch (e) {
       print("JSON Parse Error: $e");
       return null;
     }
  }

  // _processIso is no longer needed as we use IsoParser.parse

}
