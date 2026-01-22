import 'dart:convert';
import 'package:flutter/services.dart';

class BinRepository {
  Map<String, String> _binMap = {};
  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;
    try {
      final jsonString = await rootBundle.loadString('assets/data/bin_list.json');
      final Map<String, dynamic> rawMap = json.decode(jsonString);
      
      _binMap = {};
      rawMap.forEach((key, value) {
        // value is {code: "014", name: "BCA"}
        if (value is Map && value['name'] != null) {
          _binMap[key] = value['name'].toString();
        }
      });
      _isInitialized = true;
      print("🏦 BIN Repository Initialized: ${_binMap.length} entries.");
    } catch (e) {
      print("⚠️ Failed to load BIN data: $e");
    }
  }

  String? getBankName(String pan) {
    if (pan.length < 6) return null;
    final prefix = pan.substring(0, 6);
    return _binMap[prefix];
  }
}

// Global Singleton (Simple)
final binRepository = BinRepository();
