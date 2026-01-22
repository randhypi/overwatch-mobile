import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import '../security/native_secrets.dart';

class AuthInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    try {
      final secretKey = NativeSecrets.apiKey;
      if (secretKey.isEmpty) {
        // Fallback or error if key load fails
        // handler.reject(...)
      }

      final now = DateTime.now();
      final timestamp = _formatTimestamp(now);
      
      final clientId = options.headers['X-client-id'] ?? 'OVERWATCH_MOBILE'; // Default or from env
      final path = options.path;
      final payload = options.data != null ? jsonEncode(options.data) : "";

      // Signature: path:client_id:timestamp:json_body
      final strToSign = "$path:$clientId:$timestamp:$payload";

      final hmac = Hmac(sha512, base64Decode(secretKey));
      final digest = hmac.convert(utf8.encode(strToSign));
      final signature = base64Encode(digest.bytes);

      options.headers.addAll({
        'Content-Type': 'application/json',
        'X-client-id': clientId,
        'x-timestamp': timestamp,
        'x-signature': signature,
      });

      handler.next(options);
    } catch (e) {
      handler.reject(DioException(requestOptions: options, error: "Auth Signature Failed: $e"));
    }
  }

  String _formatTimestamp(DateTime date) {
    // yyyy-MM-dd HH:mm:ss.fff
    String pad(int n, [int w = 2]) => n.toString().padLeft(w, '0');
    return "${date.year}-${pad(date.month)}-${pad(date.day)} "
           "${pad(date.hour)}:${pad(date.minute)}:${pad(date.second)}.${pad(date.millisecond, 3)}";
  }
}
