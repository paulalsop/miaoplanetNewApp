import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

class DeviceIdService {
  static Future<String> getDeviceId() async {
    // 获取持久化存储中的设备ID
    final prefs = await SharedPreferences.getInstance();
    String? deviceId = prefs.getString('device_id');
    
    // 如果不存在，则生成新的随机UUID作为设备ID
    if (deviceId == null) {
      deviceId = const Uuid().v4(); // 生成标准UUID，长度为36字符（含连字符）
      
      // UUID格式：8-4-4-4-12，例如：123e4567-e89b-12d3-a456-426614174000
      // 数据库长度限制为64字符，UUID长度为36字符，完全满足要求
      
      await prefs.setString('device_id', deviceId);
    }
    
    return deviceId;
  }
} 