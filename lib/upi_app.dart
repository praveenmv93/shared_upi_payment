import 'dart:convert';
import 'dart:typed_data';

class UpiApp {
  final String appName;
  final String packageName;
  final String? iconBase64;

  const UpiApp({
    required this.appName,
    required this.packageName,
    this.iconBase64,
  });

  Uint8List? get iconBytes {
    if (iconBase64 == null || iconBase64!.isEmpty) return null;
    try {
      return base64Decode(iconBase64!);
    } catch (_) {
      return null;
    }
  }

  factory UpiApp.fromMap(Map<String, dynamic> map) {
    return UpiApp(
      appName: map['appName'] as String? ?? 'UPI App',
      packageName: map['packageName'] as String? ?? '',
      iconBase64: map['icon'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'appName': appName,
      'packageName': packageName,
      'icon': iconBase64,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UpiApp &&
          runtimeType == other.runtimeType &&
          packageName == other.packageName;

  @override
  int get hashCode => packageName.hashCode;
}
