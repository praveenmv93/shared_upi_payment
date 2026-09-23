import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'shared_upi_payment_platform_interface.dart';

/// An implementation of [SharedUpiPaymentPlatform] that uses method channels.
class MethodChannelSharedUpiPayment extends SharedUpiPaymentPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('shared_upi_payment');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>(
      'getPlatformVersion',
    );
    return version;
  }
}
