import 'package:flutter/foundation.dart';

/// Holds all parsed fields from a UPI QR code.
class UpiQrData {
  final bool isValid;
  final String rawUri;
  final String? upiId; // pa
  final String? merchantName; // pn
  final String? categoryCode; // mc
  final String? transactionRef; // tr
  final String? transactionNote; // tn
  final double? amount; // am
  final String currency; // cu

  /// Raw query parameters parsed exactly once (URL-decoded values with
  /// literal @ preserved). Safe to stitch back into a URI without
  /// further encoding of the @ symbol in VPA values.
  final Map<String, String> rawQueryParams;

  /// True when the VPA looks like a payment-gateway dynamic VPA
  /// (e.g. Razorpay *.rzp@*, Cashfree *.cf@*, BharatPe, etc.).
  /// These are session-bound and expire in 10–15 minutes.
  final bool isDynamicGatewayVpa;

  final String? errorMessage;

  const UpiQrData({
    required this.isValid,
    required this.rawUri,
    this.upiId,
    this.merchantName,
    this.categoryCode,
    this.transactionRef,
    this.transactionNote,
    this.amount,
    this.currency = 'INR',
    this.rawQueryParams = const {},
    this.isDynamicGatewayVpa = false,
    this.errorMessage,
  });

  bool get hasAmount => amount != null && amount! > 0;
}

class UpiQrParser {
  /// Handle sub-strings that identify payment-gateway dynamic VPAs.
  /// These VPAs expire and cannot be initiated by third-party apps.
  static const _gatewayHandleSuffixes = <String>[
    '.rzp@', // Razorpay
    '.cf@', // Cashfree
    '.paytm@', // Paytm PG
    '.pe@', // PhonePe PG
    '.bpe@', // BharatPe PG
    '.isg@', // ISG / Pine Labs
    '.pinelab@',
    '.eazypay@', // ICICI EazyPay
    '.upi@', // generic aggregator handles
  ];

  /// Parses a raw QR code string into [UpiQrData].
  static UpiQrData parse(String rawData) {
    final trimmed = rawData.trim();
    // Debug logging
    debugPrint('[FamLedger QR Debug] Raw QR string: "$trimmed"');

    if (trimmed.isEmpty) {
      return const UpiQrData(
        isValid: false,
        rawUri: '',
        errorMessage: 'Empty QR code data',
      );
    }

    Uri? uri;
    try {
      uri = Uri.parse(trimmed);
    } catch (e) {
      return UpiQrData(
        isValid: false,
        rawUri: trimmed,
        errorMessage: 'Invalid URI format: ${e.toString()}',
      );
    }

    // Check scheme
    final scheme = uri.scheme.toLowerCase();
    if (scheme != 'upi') {
      return UpiQrData(
        isValid: false,
        rawUri: trimmed,
        errorMessage: 'Not a UPI QR code (scheme is "$scheme")',
      );
    }

    // -----------------------------------------------------------------------
    // Parse query string manually — decode values exactly ONCE so that the
    // '@' in VPA values is never percent-encoded when we later rebuild the URI.
    // Dart's Uri.queryParameters is NOT used here because it re-encodes '@'
    // to '%40' when iterated, breaking pa= on PhonePe / Paytm / GPay.
    // -----------------------------------------------------------------------
    final rawParams = _parseQueryOnce(uri.query);

    final pa = rawParams['pa']?.trim();

    if (pa == null || pa.isEmpty) {
      return UpiQrData(
        isValid: false,
        rawUri: trimmed,
        errorMessage: 'Missing UPI Payee VPA (pa)',
      );
    }

    if (!pa.contains('@')) {
      return UpiQrData(
        isValid: false,
        rawUri: trimmed,
        errorMessage: 'Invalid UPI ID format (must contain @)',
      );
    }

    // Detect gateway / aggregator dynamic VPA
    final paLower = pa.toLowerCase();
    final isDynamic =
        _gatewayHandleSuffixes.any((s) => paLower.contains(s));

    // Merchant name
    String? pn = rawParams['pn']?.trim();
    if (pn != null && pn.isEmpty) pn = null;

    // Amount
    double? am;
    final rawAm = rawParams['am']?.trim();
    if (rawAm != null && rawAm.isNotEmpty) {
      am = double.tryParse(rawAm);
    }

    // Currency
    final cu = (rawParams['cu']?.trim() ?? 'INR').toUpperCase();

    // Transaction note
    String? tn = rawParams['tn']?.trim();
    if (tn != null && tn.isEmpty) tn = null;

    // Transaction ref
    String? tr = rawParams['tr']?.trim();
    if (tr != null && tr.isEmpty) tr = null;

    // Merchant category code
    String? mc = rawParams['mc']?.trim();
    if (mc != null && mc.isEmpty) mc = null;

    debugPrint('[FamLedger QR Debug] Parsed -> pa: "$pa", pn: "$pn", am: $am, tr: "$tr", isDynamicGatewayVpa: $isDynamic, rawParams: $rawParams');

    return UpiQrData(
      isValid: true,
      rawUri: trimmed,
      upiId: pa,
      merchantName: pn,
      categoryCode: mc,
      transactionRef: tr,
      transactionNote: tn,
      amount: am,
      currency: cu,
      rawQueryParams: rawParams,
      isDynamicGatewayVpa: isDynamic,
    );
  }

  /// Splits `key=value&key=value...` and decodes values exactly ONCE.
  /// Keys are lowercased so query parameter lookups are case-insensitive.
  /// Does NOT use [Uri.queryParameters] to avoid Dart's re-encoding behaviour.
  static Map<String, String> _parseQueryOnce(String query) {
    final result = <String, String>{};
    if (query.isEmpty) return result;
    for (final pair in query.split('&')) {
      final idx = pair.indexOf('=');
      if (idx <= 0) continue;
      final key = pair.substring(0, idx).trim().toLowerCase();
      final encoded = pair.substring(idx + 1);
      try {
        result[key] = Uri.decodeComponent(encoded);
      } catch (_) {
        result[key] = encoded; // keep raw on decode failure
      }
    }
    return result;
  }
}
