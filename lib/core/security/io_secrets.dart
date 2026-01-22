import 'dart:ffi';
import 'dart:io';
import 'package:ffi/ffi.dart';

typedef GetSecretFunc = Pointer<Utf8> Function();
typedef GetSecretFuncDart = Pointer<Utf8> Function();

class NativeSecrets {
  static String get apiKey {
    try {
      final dylib = Platform.isAndroid
          ? DynamicLibrary.open('libsecrets.so')
          : DynamicLibrary.process();
      
      final getApiSecret = dylib
          .lookup<NativeFunction<GetSecretFunc>>('get_api_secret')
          .asFunction<GetSecretFuncDart>();

      return getApiSecret().toDartString();
    } catch (e) {
      return "";
    }
  }
}
