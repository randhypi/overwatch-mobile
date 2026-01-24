import '../../data/repositories/bin_repository.dart';
import '../entities/trace_log.dart';

class TransactionEnricher {
  final BinRepository _binRepo;

  TransactionEnricher(this._binRepo);

  /// Main Enrichment Function
  TraceLog enrich(TraceLog log) {
    // 1. Get Detailed Transaction Name
    final detailedType = getDetailedType(
      pcode: log.pCode == '-' ? null : log.pCode,
      mti: _extractMti(log.content),
      privateData: log.privateData.isEmpty ? null : log.privateData,
      cardNum: log.pan,
      networkMgmtCode: null,
    );

    // 2. Get Bank Name
    final bank = getBankName(log.pan);

    return log.copyWith(transactionName: detailedType, bankName: bank);
  }

  String getDetailedType({
    required String? pcode,
    required String? mti,
    required String? privateData,
    required String? cardNum,
    required String? networkMgmtCode,
  }) {
    // 1. Check Network Management (Sign On / Echo)
    if (mti == '0800') {
      if (networkMgmtCode == '301') return 'Echo Test';
      return 'Sign On';
    }

    // 2. Check Private Data (Withdrawal Overrides)
    if (privateData != null) {
      if (privateData.startsWith('0210'))
        return 'Tarik Tunai Bank Lain'; // Off Us
      if (privateData.startsWith('0110')) return 'Tarik Tunai Sesama'; // On Us
    }

    // 3. PCode Mapping
    if (pcode != null) {
      // 301000: Inquiry
      if (pcode.startsWith('301')) {
        return _isOnUs(privateData)
            ? 'Check Saldo Bank Nobu'
            : 'Check Saldo Bank Lain';
      }
      // 401000: Transfer
      if (pcode.startsWith('401')) {
        return _isOnUs(privateData) ? 'Transfer Sesama' : 'Transfer Bank Lain';
      }
      // 011000: Tarik Tunai (Fallback)
      if (pcode.startsWith('011')) {
        return _isOnUs(privateData)
            ? 'Tarik Tunai Sesama'
            : 'Tarik Tunai Bank Lain';
      }
    }

    return pcode ?? 'Unknown Transaction';
  }

  String getBankName(String? pan) {
    if (pan == null || pan.length < 6) return 'Unknown Bank';
    return _binRepo.getBankName(pan) ?? 'Unknown Bank';
  }

  String? _extractMti(String content) {
    final match = RegExp(r'<(\d{4})>').firstMatch(content);
    return match?.group(1);
  }

  bool _isOnUs(String? privateData) {
    if (privateData == null) return false;
    // 01 = ON US Prefix in Private Data
    if (privateData.startsWith('01')) return true;
    return false;
  }
}

// Global Singleton (for simplicity)
final transactionEnricher = TransactionEnricher(binRepository);
