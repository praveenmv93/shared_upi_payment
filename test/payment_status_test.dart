import 'package:flutter_test/flutter_test.dart';
import 'package:shared_upi_payment/shared_upi_payment.dart';
import 'package:shared_upi_payment/shared_upi_payment.dart';

void main() {
  group('PaymentStatus & UpiPaymentResponse Unit Tests', () {
    test('Parse successful UPI response string', () {
      const rawResponse = 'txnId=TXN91823&responseCode=00&ApprovalRefNo=42681920&Status=SUCCESS&txnRef=TR100';
      final response = UpiPaymentResponse.parse(
        resultCode: -1,
        rawResponse: rawResponse,
        extras: null,
      );

      expect(response.status, PaymentStatus.success);
      expect(response.txnId, 'TXN91823');
      expect(response.approvalRefNo, '42681920');
      expect(response.responseCode, '00');
    });

    test('Parse failed UPI response string', () {
      const rawResponse = 'txnId=TXN91824&responseCode=ZA&Status=FAILURE&txnRef=TR101';
      final response = UpiPaymentResponse.parse(
        resultCode: -1,
        rawResponse: rawResponse,
        extras: null,
      );

      expect(response.status, PaymentStatus.failed);
      expect(response.responseCode, 'ZA');
    });

    test('Parse user cancelled payment when result code is 0 and empty response', () {
      final response = UpiPaymentResponse.parse(
        resultCode: 0,
        rawResponse: null,
        extras: null,
      );

      expect(response.status, PaymentStatus.cancelled);
      expect(response.errorMessage, contains('cancelled by the user'));
    });

    test('Parse pending / submitted status', () {
      const rawResponse = 'txnId=TXN91825&Status=SUBMITTED&txnRef=TR102';
      final response = UpiPaymentResponse.parse(
        resultCode: -1,
        rawResponse: rawResponse,
        extras: null,
      );

      expect(response.status, PaymentStatus.pending);
    });

    test('Parse unknown status when response is unparseable', () {
      const rawResponse = 'some_unrecognized_response_data';
      final response = UpiPaymentResponse.parse(
        resultCode: -1,
        rawResponse: rawResponse,
        extras: null,
      );

      expect(response.status, PaymentStatus.unknown);
    });
  });
}
