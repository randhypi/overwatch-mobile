enum TraceTargetType { 
  edcNobu, 
  nobu, 
  all 
}

class TraceConfig {
  final String appName;
  final String nodeName;
  final String label;
  final TraceTargetType type;

  const TraceConfig({
    required this.appName,
    required this.nodeName,
    required this.label,
    required this.type,
  });
  
  static const edc = TraceConfig(
    appName: "API EDC Nobu", 
    nodeName: "EDC Nobu", 
    label: "API EDC Nobu (JSON)",
    type: TraceTargetType.edcNobu,
  );
  
  static const nobu = TraceConfig(
    appName: "API Nobu", 
    nodeName: "Nobu", 
    label: "API Nobu (ISO)",
    type: TraceTargetType.nobu,
  );
  
  static const all = TraceConfig(
    appName: "ALL", 
    nodeName: "ALL", 
    label: "All Sources", 
    type: TraceTargetType.all
  );
}
