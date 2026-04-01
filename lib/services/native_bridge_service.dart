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

  Future<String> generateSystemAiResponse({required String prompt}) async {
    try {
      final result = await _channel.invokeMethod<String>(
        'generateSystemAIResponse',
        {'prompt': prompt},
      );
      if (result == null || result.isEmpty) {
        throw Exception('System AI 返回为空');
      }
      return result;
    } on PlatformException catch (error) {
      throw Exception(error.message ?? 'System AI 调用失败');
    } catch (error) {
      throw Exception('System AI 调用失败: $error');
    }
  }
}
