import 'package:flutter/services.dart';

class NativeBridgeService {
  NativeBridgeService._();

  static final NativeBridgeService instance = NativeBridgeService._();

  static const MethodChannel _channel = MethodChannel('app_agent/native_bridge');

  Future<String> getPlatformContext() async {
    try {
      final result = await _channel.invokeMethod<String>('getPlatformContext');
      if (result == null || result.isEmpty) {
        return 'Mobile Native';
      }
      return result;
    } catch (_) {
      return 'Flutter Mock Runtime';
    }
  }
}
