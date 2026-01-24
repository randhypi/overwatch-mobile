import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio_smart_retry/dio_smart_retry.dart';
import 'auth_interceptor.dart';

final apiClientProvider = Provider<Dio>((ref) {
  final dio = Dio(
    BaseOptions(
      // Using HTTP for IP, but usually it should be HTTPS.
      // FSD assumes direct IP access. Ensure server supports HTTPS if pinning.
      // Using HTTP for IP as discovered in PoC.
      // FSD assumes direct IP access.
      baseUrl: "http://103.245.122.241:47023",
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      contentType: Headers.jsonContentType,
    ),
  );

  // Apply Security Logic
  // setupSslPinning(dio); // Disabled: Server uses HTTP

  // Add Interceptors
  dio.interceptors.addAll([
    AuthInterceptor(),
    RetryInterceptor(
      dio: dio,
      logPrint: print, // Use a proper logger in prod
      retries: 3,
      retryDelays: const [
        Duration(seconds: 1),
        Duration(seconds: 2),
        Duration(seconds: 3),
      ],
    ),
    LogInterceptor(
      request: true,
      requestHeader: true,
      requestBody: true,
      responseHeader: true,
      responseBody: false, // Avoid flooding log with Base64
      error: true,
    ),
  ]);

  return dio;
});
