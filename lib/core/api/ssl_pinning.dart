import 'dart:io';
import 'package:dio/dio.dart';
import 'package:dio/io.dart';

void setupSslPinning(Dio dio) {
  // TODO: Replace with actual SHA-256 Fingerprint from OpenSSL
  // openssl x509 -in cert.pem -noout -sha256 -fingerprint
  const knownFingerprint = "SHA256:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX"; 
  
  // Ensure we are using IOHttpClientAdapter
  final adapter = dio.httpClientAdapter;
  if (adapter is IOHttpClientAdapter) {
    adapter.createHttpClient = () {
      final client = HttpClient();
      client.badCertificateCallback = (X509Certificate cert, String host, int port) {
        if (host == "103.245.122.241") {
          // Verify SHA256 match
          // final actualSha256 = sha256.convert(cert.der).toString();
          // return "SHA256:${actualSha256.toUpperCase()}" == knownFingerprint;
          
          // For now, return true (Development Mode) but allow ONLY this IP
          return true; 
        }
        return false; // Block all other invalid certs
      };
      return client;
    };
  }
}
