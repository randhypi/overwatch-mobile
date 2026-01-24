class AppNodeConfig {
  static const Map<String, String> _nodeToApp = {
    'EDC Nobu': 'API EDC Nobu',
    'Nobu': 'API Nobu',
  };

  /// Returns the App Name for a given Node Name.
  /// Defaults to 'API EDC Nobu' if unknown (Fallback).
  static String getAppName(String nodeName) {
    return _nodeToApp[nodeName] ?? 'API EDC Nobu';
  }

  static const List<String> supportedNodes = [
    'EDC Nobu',
    'Nobu'
  ];
}
