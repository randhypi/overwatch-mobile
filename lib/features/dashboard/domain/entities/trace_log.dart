import 'package:equatable/equatable.dart';

enum LogType { iso, json, unknown }

class TraceLog extends Equatable {
  final DateTime timestamp;
  final String traceNumber; // F11 or json.traceNumber
  final String content; // Raw or formatted content
  final LogType type;
  final String status; // '00' or error code
  final String pan; // Masked PAN
  final String amount;
  
  const TraceLog({
    required this.timestamp,
    required this.traceNumber,
    required this.content,
    required this.type,
    this.status = 'unknown',
    this.pan = '',
    this.amount = '',
  });

  @override
  List<Object?> get props => [timestamp, traceNumber, content, type, status, pan, amount];
  
  // Setup convenient copyWith if needed
}
