import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'payment_status.dart';
import 'upi_app.dart';

class UpiPaymentRequest {
  final String upiUri;
  final UpiApp? app;
  final double amount;
  final String merchantName;
  final String merchantUpiId;
  final String note;
  final String transactionRef;

  const UpiPaymentRequest({
    required this.upiUri,
    this.app,
    required this.amount,
    required this.merchantName,
    required this.merchantUpiId,
    required this.note,
    required this.transactionRef,
  });
}

class UpiPaymentResponse {
  final PaymentStatus status;
  final String? rawResponse;
  final String? approvalRefNo;
  final String? txnId;
  final String? txnRef;
  final String? responseCode;
  final String? errorMessage;
  final String? rawStatus;

  const UpiPaymentResponse({
    required this.status,
    this.rawResponse,
    this.approvalRefNo,
    this.txnId,
    this.txnRef,
    this.responseCode,
    this.errorMessage,
    this.rawStatus,
  });

  bool get isBankDecline =>
      status == PaymentStatus.failed &&
      (responseCode != null ||
          (errorMessage != null && errorMessage!.toLowerCase().contains('decline')) ||
          (rawResponse != null &&
              (rawResponse!.toUpperCase().contains('DECLINE') ||
                  rawResponse!.toUpperCase().contains('FAIL'))));

  List<String> get troubleshootingTips {
    if (status != PaymentStatus.failed) return const [];

    final code = responseCode?.toUpperCase().trim();
    if (code == 'ZM' || code == 'U09') {
      return const [
        'Incorrect UPI PIN entered. Please re-enter your correct PIN.',
        'If entered incorrectly 3 times, your bank freezes UPI for 24 hours.',
      ];
    }
    if (code == 'Z9' || code == '51') {
      return const [
        'Insufficient balance in the selected bank account.',
        'Choose a different bank account linked in your UPI app.',
      ];
    }
    if (code == 'Z6' || code == 'Z8' || code == 'U17' || code == 'U54') {
      return const [
        'Bank/UPI transaction limit exceeded (standard limit is ₹1,00,000 per day).',
        'If you recently changed SIM or smartphone, a ₹5,000 cooling limit applies for 24 hours.',
        'Try paying a smaller amount or use Net Banking / Cards.',
      ];
    }
    if (code == '01' || code == '02' || code == 'ZD' || code == 'ZH' || code == 'ZP') {
      return const [
        'The recipient UPI address (VPA) is invalid, inactive, or expired.',
        'Payment-link QRs (e.g. Swiggy, Zomato, Razorpay checkout) expire quickly — request a fresh QR.',
        'For shops, scan their static printed acrylic standee QR.',
      ];
    }
    if (code == 'BT' || code == 'U19' || code == 'U30' || code == 'XY' || code == 'X9' || code == '91' || code == '96') {
      return const [
        'Bank network or switch timeout. The bank server was unavailable.',
        'No money was deducted. You can try again in a few minutes or switch to another UPI app.',
      ];
    }

    // Default / ZA / U16 / RB / General Decline
    return const [
      'Self-Transfer check: Indian banks strictly decline payments sent to your own UPI ID or phone number.',
      'Merchant vs Personal: Many banks block third-party app P2P transfers. Verified merchant QRs work best.',
      'Bank Downtime: Your bank server may be experiencing temporary downtime or maintenance.',
      'Money Debited? If money was deducted, use "Mark as Paid Manually" below to track it in your ledger.',
    ];
  }

  String get humanReadableMessage {
    final appMsg = (errorMessage != null && errorMessage!.trim().isNotEmpty)
        ? errorMessage!.trim()
        : null;

    if (responseCode == null || responseCode!.trim().isEmpty) {
      switch (status) {
        case PaymentStatus.success:
          return 'Transaction completed successfully.';
        case PaymentStatus.failed:
          if (appMsg != null) {
            return 'Transaction declined by bank: $appMsg';
          }
          return 'Transaction was declined by your bank or the UPI network.\n\n'
              'Common causes:\n'
              '• Self-Transfer: Banks block UPI transfers to your own account / mobile number.\n'
              '• Inactive QR: If you scanned a dynamic payment link, it may have expired.\n'
              '• Bank UPI Limits: Daily transaction count or amount limit reached.\n'
              '• Bank Server: Temporary bank switch downtime or maintenance.';
        case PaymentStatus.cancelled:
          return appMsg ?? 'Payment was cancelled before authentication.';
        case PaymentStatus.pending:
          return appMsg ?? 'Payment has been submitted and is pending bank processing.';
        case PaymentStatus.unknown:
          return appMsg ?? 'Status uncertain. Please check your banking app or SMS before retrying.';
        default:
          return appMsg ?? 'Status: ${status.name}';
      }
    }

    // Full NPCI / UPI response code reference
    final code = responseCode!.toUpperCase().trim();
    String explanation;
    switch (code) {
      // ── Success ──────────────────────────────────────────────────────
      case '00':
      case '0':
        explanation = 'Payment Successful (NPCI Code 00 – Approved)';
        break;

      // ── VPA / Payee Issues ───────────────────────────────────────────
      case '01':
        explanation = 'Invalid or Inactive UPI ID (Code 01) — The UPI address you are paying to does not exist or has been deactivated. '
            'If you scanned a payment-link QR code, it may have expired. '
            'Please ask the merchant for a fresh QR code or use a static shop QR.';
        break;
      case '02':
        explanation = 'Invalid Payee VPA / Merchant not registered (Code 02) — The merchant UPI ID is not linked to any active bank account.';
        break;
      case '03':
        explanation = 'Transaction not permitted to payee (Code 03) — The payee bank or NPCI has blocked this type of transaction.';
        break;
      case '05':
        explanation = 'Declined by Bank (Code 05) — Do not honor. Your bank declined the transaction. Check account status with your bank.';
        break;
      case '12':
        explanation = 'Invalid Transaction (Code 12) — The bank rejected the transaction request format.';
        break;
      case 'ZD':
        explanation = 'Payee VPA invalid or account inactive (Code ZD) — The receiving account is not active. '
            'Use a static merchant QR or personal UPI ID instead.';
        break;
      case 'ZH':
        explanation = 'Invalid Virtual Address (Code ZH) — The payee UPI ID could not be found or verified by the switch.';
        break;
      case 'ZP':
        explanation = 'Payee account does not exist or closed (Code ZP) — The receiving bank account is closed or does not exist.';
        break;
      case 'ZK':
        explanation = 'Card/Account blocked (Code ZK) — Your bank account or debit card is frozen or blocked for UPI.';
        break;

      // ── Payer / Authentication Issues ────────────────────────────────
      case 'ZM':
        explanation = 'Incorrect UPI PIN or maximum PIN attempts exceeded (Code ZM) — '
            'Your UPI PIN was wrong. If you failed 3 times your UPI PIN may be locked for 24 hours.';
        break;
      case 'U09':
        explanation = 'Incorrect OTP or UPI PIN (Code U09) — The authorization credentials entered were invalid.';
        break;
      case 'Z9':
      case '51':
        explanation = 'Insufficient balance in your bank account (Code $code).';
        break;
      case 'Z6':
        explanation = 'Transaction limit exceeded for your account or VPA (Code Z6) — '
            'UPI per-transaction limit is ₹1,00,000. Daily limit may also be exceeded.';
        break;
      case 'Z8':
      case 'U54':
        explanation = 'Per-transaction limit exceeded (Code $code) — The amount exceeds the maximum allowed limit for a single UPI transaction.';
        break;
      case 'U17':
        explanation = 'Transaction limit exceeded as set by customer bank (Code U17).';
        break;
      case 'RB':
        explanation = 'Blocked by NPCI Risk Management system (Code RB) — '
            'Your bank or NPCI flagged this as a high-risk transaction. '
            'This sometimes happens with new payees or large amounts. Try again later.';
        break;

      // ── Bank / Network Issues ─────────────────────────────────────────
      case 'ZA':
        explanation = 'Transaction declined by your bank / PSP (Code ZA) — '
            'This could be due to account restrictions, bank downtime, or risk policy.';
        break;
      case 'BT':
        explanation = 'Bank transaction timeout — The bank did not respond in time. No money was deducted.';
        break;
      case 'U16':
        explanation = 'Risk declined by payer bank (Code U16) — The bank rejected the transaction due to its own risk policy.';
        break;
      case 'U19':
        explanation = 'Bank network busy or transaction failed (Code U19) — The bank server was unavailable.';
        break;
      case 'U30':
        explanation = 'Transaction timeout at beneficiary bank (Code U30) — '
            'The receiving bank did not respond in time. Check with your bank if money was deducted.';
        break;
      case 'U66':
        explanation = 'Payer PSP not available (Code U66) — Your UPI app\'s payment server is temporarily down.';
        break;
      case 'XH':
        explanation = 'Original transaction not found (Code XH) — The transaction reference could not be located by the switch.';
        break;
      case 'XY':
        explanation = 'Remitter (payer) bank unavailable (Code XY) — Your bank\'s UPI system is down.';
        break;
      case 'X9':
        explanation = 'Beneficiary (payee) bank unavailable (Code X9) — The merchant\'s bank UPI system is down.';
        break;
      case '91':
        explanation = 'Bank server timeout (Code 91) — The remitter or beneficiary bank server timed out.';
        break;
      case '96':
        explanation = 'System malfunction at bank (Code 96) — Switch or bank processing failure.';
        break;

      // ── Cooling Period & New Device ───────────────────────────────────
      case 'EM':
        explanation = 'Cooling period active (Code EM) — You recently changed your SIM/phone. '
            'Transactions may be capped at ₹5,00,00 for the first 24 hours.';
        break;
      case 'B1':
        explanation = 'Registered mobile number linked with multiple accounts (Code B1).';
        break;
      case 'K1':
        explanation = 'Customer suspended from UPI by bank (Code K1).';
        break;
      case 'VR':
        explanation = 'Invalid amount specified in transaction (Code VR).';
        break;
      case 'IR':
        explanation = 'Invalid transaction reference (Code IR) — The merchant order reference is not valid.';
        break;
      case 'XB':
        explanation = 'Invalid merchant / Payee not allowed to receive payment (Code XB).';
        break;

      default:
        explanation = 'Bank response code: $responseCode — Transaction was unsuccessful. '
            'Please check your bank\'s UPI app or SMS for details.';
        break;
    }

    if (appMsg != null && !explanation.toLowerCase().contains(appMsg.toLowerCase())) {
      return '$explanation\n\nApp Message: $appMsg';
    }
    return explanation;
  }

  factory UpiPaymentResponse.parse({
    required int resultCode,
    required String? rawResponse,
    required Map<String, dynamic>? extras,
  }) {
    // If user cancelled or pressed back
    if (resultCode == 0 && (rawResponse == null || rawResponse.isEmpty) && (extras == null || extras.isEmpty)) {
      return const UpiPaymentResponse(
        status: PaymentStatus.cancelled,
        rawResponse: 'USER_CANCELLED',
        errorMessage: 'Payment was cancelled by the user.',
      );
    }

    final params = <String, String>{};

    // 1. Parse URI string format (upi://pay?txnId=...&Status=SUCCESS)
    if (rawResponse != null && rawResponse.isNotEmpty) {
      if (rawResponse.contains('?')) {
        try {
          final uri = Uri.parse(rawResponse);
          uri.queryParameters.forEach((k, v) {
            params[k.toLowerCase().trim()] = v.trim();
          });
        } catch (_) {}
      }

      // 2. Parse query string format (txnId=...&responseCode=...&Status=SUCCESS)
      final cleanString = rawResponse.contains('?') ? rawResponse.split('?').last : rawResponse;
      if (cleanString.contains('=')) {
        final pairs = cleanString.split('&');
        for (var pair in pairs) {
          final kv = pair.split('=');
          if (kv.length >= 2) {
            final key = kv[0].trim().toLowerCase();
            String val = kv.sublist(1).join('=').trim();
            try {
              val = Uri.decodeComponent(val);
            } catch (_) {
              // Keep raw string if percent decoding fails
            }
            params[key] = val;
          }
        }
      }
    }

    // 3. Blend in extras bundle
    if (extras != null) {
      extras.forEach((key, value) {
        if (value != null) {
          params[key.toString().toLowerCase().trim()] = value.toString().trim();
        }
      });
    }

    final rawStatus = params['status']?.toUpperCase();
    final responseCode = params['responsecode'] ??
        params['response_code'] ??
        params['rescode'] ??
        params['res_code'] ??
        params['rc'] ??
        params['code'] ??
        params['statuscode'] ??
        params['status_code'] ??
        params['error_code'] ??
        params['errorcode'];

    final errorMessage = params['errormessage'] ??
        params['error_message'] ??
        params['message'] ??
        params['statusmessage'] ??
        params['status_message'] ??
        params['description'] ??
        params['desc'] ??
        params['reason'] ??
        params['error'] ??
        params['err_msg'] ??
        params['err'];

    final approvalRefNo = params['approvalrefno'] ?? params['approval_ref_no'] ?? params['refid'];
    final txnId = params['txnid'] ?? params['txn_id'];
    final txnRef = params['txnref'] ?? params['txn_ref'];

    PaymentStatus status;

    // Normalize codes for comparison
    final rcNorm = responseCode?.toUpperCase().trim();

    // Explicit SUCCESS indicators (check first)
    final isSuccessStatus = rawStatus == 'SUCCESS' ||
        rawStatus == 'SUCCESSFUL' ||
        rcNorm == '00' ||
        rcNorm == '0';

    // Pending/Submitted — NOT a failure
    final isPendingStatus = rawStatus == 'SUBMITTED' ||
        rawStatus == 'PENDING' ||
        rcNorm == 'SUBMITTED';

    // Cancelled — user backed out
    final isCancelledStatus = rawStatus == 'CANCELLED' || rawStatus == 'CANCELED';

    // Known failure codes
    const knownFailureCodes = {
      '01', '02', '03', '05', '12', '51', '91', '96',
      'ZA', 'ZD', 'ZM', 'Z6', 'Z8', 'Z9', 'ZH', 'ZP', 'ZK',
      'RB', 'BT', 'U09', 'U14', 'U16', 'U17', 'U19', 'U28', 'U30', 'U31', 'U54', 'U66',
      'XH', 'XY', 'X9', 'EM', 'B1', 'K1', 'VR', 'IR', 'XB',
    };

    final containsFailureWord = rawResponse != null &&
        (rawResponse.toUpperCase().contains('FAIL') ||
            rawResponse.toUpperCase().contains('DECLINE') ||
            rawResponse.toUpperCase().contains('REJECT'));

    final isFailedStatus = rawStatus == 'FAILURE' ||
        rawStatus == 'FAILED' ||
        rawStatus == 'FAIL' ||
        rawStatus == 'DECLINED' ||
        containsFailureWord ||
        (rcNorm != null && knownFailureCodes.contains(rcNorm));

    if (isSuccessStatus) {
      status = PaymentStatus.success;
    } else if (isPendingStatus) {
      status = PaymentStatus.pending;
    } else if (isFailedStatus) {
      status = PaymentStatus.failed;
    } else if (isCancelledStatus) {
      status = PaymentStatus.cancelled;
    } else if (resultCode == 0 && (rawResponse == null || rawResponse.isEmpty) && (extras == null || extras.isEmpty)) {
      status = PaymentStatus.cancelled;
    } else if (resultCode == -1 && (approvalRefNo != null || txnId != null)) {
      status = PaymentStatus.success;
    } else if (resultCode == -1 && rawResponse != null && rawResponse.toUpperCase().contains('SUCCESS')) {
      status = PaymentStatus.success;
    } else if (params.isNotEmpty) {
      status = PaymentStatus.unknown;
    } else {
      status = PaymentStatus.unknown;
    }

    return UpiPaymentResponse(
      status: status,
      rawResponse: rawResponse ?? extras?.toString(),
      approvalRefNo: approvalRefNo,
      txnId: txnId,
      txnRef: txnRef,
      responseCode: responseCode,
      errorMessage: errorMessage,
      rawStatus: rawStatus,
    );
  }
}


abstract class UpiPaymentService {
  Future<List<UpiApp>> getInstalledApps();

  Future<UpiPaymentResponse> initiatePayment({
    required UpiPaymentRequest request,
    required UpiApp app,
  });
}

class MethodChannelUpiService implements UpiPaymentService {
  static const _channel = MethodChannel('fam_ledge/upi');

  @override
  Future<List<UpiApp>> getInstalledApps() async {
    try {
      final List<dynamic>? appsList = await _channel.invokeMethod('getInstalledUpiApps');
      if (appsList == null) return _fallbackApps();

      final apps = appsList.map((e) {
        final map = Map<String, dynamic>.from(e as Map);
        return UpiApp.fromMap(map);
      }).toList();

      if (apps.isEmpty) {
        return _fallbackApps();
      }

      return apps;
    } on PlatformException catch (_) {
      return _fallbackApps();
    } catch (_) {
      return _fallbackApps();
    }
  }

  @override
  Future<UpiPaymentResponse> initiatePayment({
    required UpiPaymentRequest request,
    required UpiApp app,
  }) async {
    try {
      final Map<dynamic, dynamic>? result = await _channel.invokeMethod(
        'launchUpiPayment',
        {
          'upiUri': request.upiUri,
          'packageName': app.packageName,
        },
      );

      if (result == null) {
        return const UpiPaymentResponse(
          status: PaymentStatus.unknown,
          errorMessage: 'No response received from UPI application.',
        );
      }

      final resultCode = result['resultCode'] as int? ?? -1;
      final rawResponse = result['response'] as String?;
      final extrasRaw = result['extras'];
      Map<String, dynamic>? extrasMap;
      if (extrasRaw is Map) {
        extrasMap = Map<String, dynamic>.from(extrasRaw);
      }

      debugPrint('[FamLedger Channel Debug] Native returned -> resultCode: $resultCode, rawResponse: "$rawResponse", extras: $extrasMap');

      final parsedResponse = UpiPaymentResponse.parse(
        resultCode: resultCode,
        rawResponse: rawResponse,
        extras: extrasMap,
      );

      debugPrint('[FamLedger Channel Debug] Parsed response -> status: ${parsedResponse.status}, code: "${parsedResponse.responseCode}", message: "${parsedResponse.errorMessage}"');

      return parsedResponse;
    } on PlatformException catch (e) {
      return UpiPaymentResponse(
        status: PaymentStatus.failed,
        errorMessage: e.message ?? 'Platform failure while launching UPI app.',
      );
    } catch (e) {
      return UpiPaymentResponse(
        status: PaymentStatus.failed,
        errorMessage: e.toString(),
      );
    }
  }

  List<UpiApp> _fallbackApps() {
    return const [
      UpiApp(appName: 'Google Pay', packageName: 'com.google.android.apps.nfc.phonebank'),
      UpiApp(appName: 'PhonePe', packageName: 'com.phonepe.app'),
      UpiApp(appName: 'Paytm', packageName: 'net.one97.paytm'),
      UpiApp(appName: 'BHIM UPI', packageName: 'in.org.npci.upiapp'),
      UpiApp(appName: 'Cred', packageName: 'com.dreamplug.androidapp'),
    ];
  }
}
