import 'package:dio/dio.dart';
import '../../domain/utils/log_parser.dart';

class TraceRemoteDataSource {
  final Dio _dio;

  TraceRemoteDataSource(this._dio);

  /// 1. Trace List: Returns list of filenames
  Future<List<String>> fetchTraceList(String appName, String nodeName) async {
    try {
      final response = await _dio.post(
        '/api/sdk/trace/list',
        data: {"appName": appName, "nodeName": nodeName},
      );

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
  Future<Map<String, dynamic>> fetchTraceView(
    String appName,
    String fileName,
    int lastPosition,
  ) async {
    try {
      final response = await _dio.post(
        '/api/sdk/trace/view',
        data: {
          "appName": appName,
          "fileName": fileName,
          "lastPosition": lastPosition,
        },
      );

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data['data'];
        if (data != null) {
          final int newPos = data['lastPosition'] ?? lastPosition;
          final String? compressed = data['logCompressed'];

          if (compressed != null && compressed.isNotEmpty) {
            final rawContent = LogParser.decompressData(compressed);
            final logs = LogParser.parseRawContent(rawContent);
            return {"logs": logs, "lastPosition": newPos};
          } else {
            return {"logs": [], "lastPosition": newPos};
          }
        }
      }
      return {"logs": [], "lastPosition": lastPosition};
    } catch (e) {
      print("Fetch View Error: $e");
      return {"logs": [], "lastPosition": lastPosition};
    }
  }

  /// 3. Trace Current: Realtime monitoring
  Future<Map<String, dynamic>> fetchTraceCurrent(
    String appName,
    String nodeName,
    int lastPosition,
  ) async {
    try {
      final response = await _dio.post(
        '/api/sdk/trace/current',
        data: {
          "appName": appName,
          "nodeName": nodeName,
          "lastPosition": lastPosition,
        },
      );

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data['data'];
        if (data != null) {
          final int newPos = data['lastPosition'] ?? lastPosition;
          final String? compressed = data['logCompressed'];

          if (compressed != null && compressed.isNotEmpty) {
            final rawContent = LogParser.decompressData(compressed);
            final logs = LogParser.parseRawContent(rawContent);
            return {"logs": logs, "lastPosition": newPos};
          } else {
            return {"logs": [], "lastPosition": newPos};
          }
        }
      }
      return {"logs": [], "lastPosition": lastPosition};
    } catch (e) {
      print("Fetch Current Error: $e");
      return {"logs": [], "lastPosition": lastPosition};
    }
  }
}
