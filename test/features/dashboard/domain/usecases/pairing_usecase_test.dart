import 'package:flutter_test/flutter_test.dart';
import 'package:overwatch_mobile/features/dashboard/domain/entities/trace_log.dart';
import 'package:overwatch_mobile/features/dashboard/domain/usecases/pairing_usecase.dart';

void main() {
  late PairingUseCase useCase;

  setUp(() {
    useCase = PairingUseCase();
  });

  group('PairingUseCase Tests', () {
    test('Should pair ISO Request and Response via TraceNumber', () {
      final now = DateTime.now();
      final logs = [
        TraceLog(
          timestamp: now.subtract(const Duration(seconds: 1)),
          traceNumber: '123456',
          content: '<0800> Request',
          type: LogType.iso,
        ),
        TraceLog(
          timestamp: now,
          traceNumber: '123456',
          content: '<0810> Response',
          type: LogType.iso,
        ),
      ];

      final result = useCase.execute(logs);

      expect(result.length, 1);
      expect(result.first.request.traceNumber, '123456');
      expect(result.first.response?.traceNumber, '123456');
    });

    test('Should pair JSON Request and Response via RefNum', () {
      final now = DateTime.now();
      final logs = [
        TraceLog(
          timestamp: now.subtract(const Duration(seconds: 1)),
          traceNumber: '000001',
          refNum: 'REF001',
          content:
              '<REQ> {"traceNumber": "000001", "referenceNumber": "REF001"}',
          type: LogType.json,
        ),
        TraceLog(
          timestamp: now,
          traceNumber: '000001',
          refNum: 'REF001',
          content:
              '<RSP> {"traceNumber": "000001", "referenceNumber": "REF001", "responseCode": "00"}',
          type: LogType.json,
        ),
      ];

      final result = useCase.execute(logs);

      expect(result.length, 1);
      expect(result.first.request.refNum, 'REF001');
      expect(result.first.response?.refNum, 'REF001');
    });

    test(
      'Should perform Anonymous Matching for Error Responses without IDs',
      () {
        final now = DateTime.now();
        final logs = [
          TraceLog(
            timestamp: now.subtract(const Duration(seconds: 2)),
            traceNumber: '111111',
            content: '<REQ> {"traceNumber": "111111"}',
            type: LogType.json,
          ),
          TraceLog(
            timestamp: now.subtract(const Duration(seconds: 1)),
            traceNumber: '000000',
            refNum: '-',
            content: '<RSP> {"error": "Timeout"}',
            type: LogType.json,
            status: 'TO',
          ),
        ];

        final result = useCase.execute(logs);

        expect(result.length, 1);
        expect(result.first.request.traceNumber, '111111');
        expect(result.first.response?.status, 'TO');
        expect(result.first.isComplete, isTrue);
      },
    );

    test('Should handle Orphan Requests (No Response)', () {
      final logs = [
        TraceLog(
          timestamp: DateTime.now(),
          traceNumber: '999999',
          content: '<0800> Orphan Request',
          type: LogType.iso,
        ),
      ];

      final result = useCase.execute(logs);

      expect(result.length, 1);
      expect(result.first.response, isNull);
      expect(result.first.request.traceNumber, '999999');
    });
  });
}
