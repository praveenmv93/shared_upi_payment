import 'package:flutter_test/flutter_test.dart';
import 'package:shared_upi_payment/shared_upi_payment.dart';
import 'package:shared_upi_payment/shared_upi_payment_platform_interface.dart';
import 'package:shared_upi_payment/shared_upi_payment_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockSharedUpiPaymentPlatform
    with MockPlatformInterfaceMixin
    implements SharedUpiPaymentPlatform {
  @override
  Future<String?> getPlatformVersion() => Future.value('42');
}

void main() {
  final SharedUpiPaymentPlatform initialPlatform = SharedUpiPaymentPlatform.instance;

  test('$MethodChannelSharedUpiPayment is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelSharedUpiPayment>());
  });

  test('getPlatformVersion', () async {
    SharedUpiPayment sharedUpiPaymentPlugin = SharedUpiPayment();
    MockSharedUpiPaymentPlatform fakePlatform = MockSharedUpiPaymentPlatform();
    SharedUpiPaymentPlatform.instance = fakePlatform;

    expect(await sharedUpiPaymentPlugin.getPlatformVersion(), '42');
  });
}
