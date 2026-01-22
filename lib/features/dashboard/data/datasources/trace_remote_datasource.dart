import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import '../../domain/entities/trace_log.dart';
import '../../domain/utils/iso_parser.dart';

class TraceRemoteDataSource {
  final Dio _dio;
  
  TraceRemoteDataSource(this._dio);

  Future<List<TraceLog>> fetchLogs() async {
    try {
      final response = await _dio.post('/api/sdk/trace/list', data: {
        "appName": "M5_PLUS", // Default for testing
        "nodeName": "ALL",
        "limit": 50
      });

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data;
        if (data is Map && data.containsKey('data')) {
           final list = data['data'] as List;
           return list.map((e) => _processItem(e)).whereType<TraceLog>().toList();
        }
      }
      return [];
    } catch (e) {
      // Allow empty return on error for stream resilience
      print("Fetch Error: $e");
      return [];
    }
  }

  TraceLog? _processItem(dynamic item) {
    if (item is! Map) return null;
    
    try {
      String rawContent = "";
      
      // 1. Decompress if needed
      if (item['logCompressed'] != null) {
        final compressed = item['logCompressed'] as String;
        final bytes = base64Decode(compressed);
        final decoded = GZipCodec().decode(bytes);
        rawContent = utf8.decode(decoded);
      } else if (item['message'] != null) {
        rawContent = item['message'];
      } else {
        return null;
      }

      // 2. Determine Type & Parse
      // Heuristic: JSON starts with '{', ISO often starts with Header or MTI
      if (rawContent.trim().startsWith('{')) {
        // Parse as JSON Log
        // For now, construct a TraceLog manually or use a JsonParser
        // Using IsoParser as fallback or specialized JSON parser
        // MVP: Treat as generic content with extracted basic fields if possible
        // But for now, let's mark it as JSON type
        return TraceLog(
          timestamp: DateTime.now(), // Extract from JSON body if possible
          traceNumber: _extractJsonTrace(rawContent),
          content: rawContent,
          type: LogType.json,
          status: '00', // Assume success unless parsed otherwise
        );
      } else {
        // Assume ISO
        return IsoParser.parse(rawContent);
      }
    } catch (e) {
      print("Parse Error: $e");
      return null;
    }
  }

  String _extractJsonTrace(String jsonStr) {
    // Quick regex to find traceNumber without full parse
    final match = RegExp(r'"traceNumber"\s*:\s*"(\d+)"').firstMatch(jsonStr);
    return match?.group(1) ?? '000000';
  }
}
