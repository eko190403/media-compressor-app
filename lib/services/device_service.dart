import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math';

class DeviceService {
  static final DeviceService _instance = DeviceService._internal();
  factory DeviceService() => _instance;
  DeviceService._internal();

  String? _deviceId;

  Future<String> getDeviceId() async {
    if (_deviceId != null) return _deviceId!;

    final deviceInfo = DeviceInfoPlugin();

    if (Platform.isAndroid) {
      final androidInfo = await deviceInfo.androidInfo;
      _deviceId = androidInfo.id;
    } else if (Platform.isIOS) {
      final iosInfo = await deviceInfo.iosInfo;
      _deviceId = iosInfo.identifierForVendor ?? await _getFallbackId();
    } else {
      _deviceId = await _getFallbackId();
    }
    
    return _deviceId!;
  }

  Future<String> _getFallbackId() async {
    final prefs = await SharedPreferences.getInstance();
    String? storedId = prefs.getString('fallback_device_id');
    if (storedId == null) {
      storedId = 'device_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(10000)}';
      await prefs.setString('fallback_device_id', storedId);
    }
    return storedId;
  }
}
