import 'package:equatable/equatable.dart';
import 'trace_log.dart';

class LogPair extends Equatable {
  final TraceLog request;
  final TraceLog? response;
  
  const LogPair({
    required this.request,
    this.response,
  });
  
  String get traceNumber => request.traceNumber;
  
  // Status is Response status if exists, else 'pending' or 'timeout'
  String get frontStatus => response?.status ?? 'waiting';
  
  bool get isComplete => response != null;

  @override
  List<Object?> get props => [request, response];
}
