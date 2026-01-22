import 'package:equatable/equatable.dart';

enum LogType { iso, json, unknown }

class TraceLog extends Equatable {
  final DateTime timestamp;
  final String traceNumber; // F11 or json.traceNumber
  final String content;     // Raw or formatted content
  final LogType type;
  final String status;      // '00' or error code
  
  // Basic Fields
  final String pan;         // Masked PAN
  final String amount;
  final String refNum;
  final String serialNumber;
  final String terminalId;
  final String pCode;
  
  // Enriched Fields
  final String transactionName; // from Rules Engine
  final String privateData;     // Field 048
  final String bankName;        // from BIN

  const TraceLog({
    required this.timestamp,
    required this.traceNumber,
    required this.content,
    required this.type,
    this.status = 'unknown',
    this.pan = '',
    this.amount = '',
    this.refNum = '',
    this.serialNumber = '',
    this.terminalId = '',
    this.pCode = '',
    this.transactionName = '',
    this.privateData = '',
    this.bankName = '',
  });

  bool get isSuccess => status == '00';
  
  TraceLog copyWith({
    String? transactionName,
    String? bankName,
  }) {
    return TraceLog(
      timestamp: timestamp,
      traceNumber: traceNumber,
      content: content,
      type: type,
      status: status,
      pan: pan,
      amount: amount,
      refNum: refNum,
      serialNumber: serialNumber,
      terminalId: terminalId,
      pCode: pCode,
      transactionName: transactionName ?? this.transactionName,
      privateData: privateData,
      bankName: bankName ?? this.bankName,
    );
  }

  @override
  List<Object?> get props => [
        timestamp, 
        traceNumber, 
        content, 
        type, 
        status, 
        pan, 
        amount,
        refNum,
        serialNumber,
        terminalId,
        pCode,
        transactionName,
        privateData,
        bankName
      ];
}
