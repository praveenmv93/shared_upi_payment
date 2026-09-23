import 'package:flutter_test/flutter_test.dart';
import 'package:shared_upi_payment/shared_upi_payment.dart';

void main() {
  group('UpiQrParser Unit Tests', () {
    test('Parse valid standard UPI QR code with all parameters', () {
      const qrStr = 'upi://pay?pa=freshmart@upi&pn=Fresh%20Mart&am=850.00&cu=INR&tn=Weekly%20Groceries&tr=REF123456&mc=5411';
      final result = UpiQrParser.parse(qrStr);

      expect(result.isValid, isTrue);
      expect(result.upiId, 'freshmart@upi');
      expect(result.merchantName, 'Fresh Mart');
      expect(result.amount, 850.00);
      expect(result.currency, 'INR');
      expect(result.transactionNote, 'Weekly Groceries');
      expect(result.transactionRef, 'REF123456');
      expect(result.categoryCode, '5411');
      expect(result.hasAmount, isTrue);
    });

    test('Parse UPI QR with missing amount', () {
      const qrStr = 'upi://pay?pa=merchant@okaxis&pn=Local%20Store';
      final result = UpiQrParser.parse(qrStr);

      expect(result.isValid, isTrue);
      expect(result.upiId, 'merchant@okaxis');
      expect(result.merchantName, 'Local Store');
      expect(result.amount, isNull);
      expect(result.hasAmount, isFalse);
    });

    test('Parse UPI QR with missing merchant name', () {
      const qrStr = 'upi://pay?pa=vendor@ybl&am=150';
      final result = UpiQrParser.parse(qrStr);

      expect(result.isValid, isTrue);
      expect(result.upiId, 'vendor@ybl');
      expect(result.merchantName, isNull);
      expect(result.amount, 150.0);
    });

    test('Parse UPI QR with special characters and complex URL encoding', () {
      const qrStr = 'upi://pay?pa=cafe%26dine@icici&pn=Caf%C3%A9%20%26%20Bistro&tn=Coffee%20%2B%20Snacks';
      final result = UpiQrParser.parse(qrStr);

      expect(result.isValid, isTrue);
      expect(result.merchantName, 'Café & Bistro');
      expect(result.transactionNote, 'Coffee + Snacks');
    });

    test('Reject non-UPI scheme URI', () {
      const qrStr = 'https://example.com/pay?pa=merchant@upi';
      final result = UpiQrParser.parse(qrStr);

      expect(result.isValid, isFalse);
      expect(result.errorMessage, contains('Not a UPI QR code'));
    });

    test('Reject malformed UPI URI without VPA (pa)', () {
      const qrStr = 'upi://pay?pn=MerchantOnly&am=100';
      final result = UpiQrParser.parse(qrStr);

      expect(result.isValid, isFalse);
      expect(result.errorMessage, contains('Missing UPI Payee VPA'));
    });

    test('Reject invalid VPA format without @ symbol', () {
      const qrStr = 'upi://pay?pa=invalidvpaid&pn=Test';
      final result = UpiQrParser.parse(qrStr);

      expect(result.isValid, isFalse);
      expect(result.errorMessage, contains('Invalid UPI ID format'));
    });

    test('Parse QR code with UPPERCASE query parameter keys correctly', () {
      const qrStr = 'upi://pay?PA=wedinvite750328.rzp@rxairtel&PN=Wedinvite&AM=1.00&CU=INR&TN=Order%20123&ORGID=400001&MODE=02';
      final result = UpiQrParser.parse(qrStr);

      expect(result.isValid, isTrue);
      expect(result.upiId, 'wedinvite750328.rzp@rxairtel');
      expect(result.merchantName, 'Wedinvite');
      expect(result.amount, 1.00);
      expect(result.currency, 'INR');
      expect(result.isDynamicGatewayVpa, isTrue);
      expect(result.rawQueryParams['orgid'], '400001');
      expect(result.rawQueryParams['mode'], '02');
    });

    test('Detect dynamic payment gateway VPAs correctly', () {
      const rzpQr = 'upi://pay?pa=checkout.rzp@rxairtel&pn=GatewayMerchant';
      const cfQr = 'upi://pay?pa=order.cf@icici&pn=CashfreeMerchant';

      expect(UpiQrParser.parse(rzpQr).isDynamicGatewayVpa, isTrue);
      expect(UpiQrParser.parse(cfQr).isDynamicGatewayVpa, isTrue);
    });
  });
}
