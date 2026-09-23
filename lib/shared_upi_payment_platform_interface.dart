import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'shared_upi_payment_method_channel.dart';

abstract class SharedUpiPaymentPlatform extends PlatformInterface {
  /// Constructs a SharedUpiPaymentPlatform.
  SharedUpiPaymentPlatform() : super(token: _token);

  static final Object _token = Object();

  static SharedUpiPaymentPlatform _instance = MethodChannelSharedUpiPayment();

  /// The default instance of [SharedUpiPaymentPlatform] to use.
  ///
  /// Defaults to [MethodChannelSharedUpiPayment].
  static SharedUpiPaymentPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [SharedUpiPaymentPlatform] when
  /// they register themselves.
  static set instance(SharedUpiPaymentPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }
}
