import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

class UserService {
  static const _keyUserId = 'user_id';
  static String? _cachedUserId;

  static Future<String> getUserId() async {
    if (_cachedUserId != null) return _cachedUserId!;
    final prefs = await SharedPreferences.getInstance();
    String? id = prefs.getString(_keyUserId);
    if (id == null) {
      id = const Uuid().v4();
      await prefs.setString(_keyUserId, id);
    }
    _cachedUserId = id;
    return id;
  }
}
