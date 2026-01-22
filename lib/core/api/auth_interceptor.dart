import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import '../security/native_secrets.dart';

class AuthInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    try {
      var secretKey = NativeSecrets.apiKey;
      // Sanitize: Remove Null terminators, whitespace, and non-printable chars
      secretKey = secretKey.trim().replaceAll(RegExp(r'[\x00-\x1F\x7F]'), '');

      if (secretKey.isEmpty) {
        // Fallback or error if key load fails
        // handler.reject(...)
      }

      // Use UTC to match Server GMT
      // Safety buffer: 15 seconds behind to ensure we are not "in the future"
      final now = DateTime.now().toUtc().subtract(const Duration(seconds: 15));
      final timestamp = _formatTimestamp(now);
      
      final clientId = options.headers['X-client-id'] ?? 'de15fbe1fa2da4e0'; 
      final path = options.path;

      // PAYLOAD CONSISTENCY FIX:
      // We must sign exactly what we send. Dio serializes distinctively.
      // So we serialize here, sign it, and force Dio to use this string.
      String payloadString = "";
      if (options.data != null) {
         if (options.data is Map || options.data is List) {
           payloadString = jsonEncode(options.data);
           options.data = payloadString; // Force Dio to send this exact string
         } else {
           payloadString = options.data.toString();
         }
      }

      // Signature: path:client_id:timestamp:json_body
      // Normalization: FORCE leading slash
      final cleanPath = path.startsWith('/') ? path : '/$path';

      // Signature: path:client_id:timestamp:json_body
      // Debug:
      print("🔑 Secret Prefix: ${secretKey.substring(0, 5)}...");
      
      final strToSign = "$cleanPath:$clientId:$timestamp:$payloadString";
      print("📝 StringToSign: '$strToSign'"); 

      // FIX: Node.js PoC uses the secret key string directly (UTF-8), not Base64 decoded bytes.
      // crypto.createHmac('sha512', SECRET_KEY) -> uses Buffer.from(SECRET_KEY, 'utf8')
      final hmac = Hmac(sha512, utf8.encode(secretKey)); 
      
      final digest = hmac.convert(utf8.encode(strToSign));
      final signature = base64Encode(digest.bytes);
      print("✍️ Signature: '$signature'");

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
