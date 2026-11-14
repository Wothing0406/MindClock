import 'package:shared_preferences/shared_preferences.dart';

/// Giao diện lưu khóa-giá trị cục bộ để tách biệt tầng lưu trữ khi test hoặc đổi engine.
abstract interface class LocalKeyValueStore {
  Future<String?> readString(String key);

  Future<void> writeString(String key, String value);

  Future<void> remove(String key);
}

class SharedPreferencesKeyValueStore implements LocalKeyValueStore {
  SharedPreferencesKeyValueStore({SharedPreferences? instance})
      : _instance = instance;

  SharedPreferences? _instance;

  Future<SharedPreferences> _prefs() async {
    return _instance ??= await SharedPreferences.getInstance();
  }

  @override
  Future<String?> readString(String key) async {
    final SharedPreferences prefs = await _prefs();
    return prefs.getString(key);
  }

  @override
  Future<void> writeString(String key, String value) async {
    final SharedPreferences prefs = await _prefs();
    await prefs.setString(key, value);
  }

  @override
  Future<void> remove(String key) async {
    final SharedPreferences prefs = await _prefs();
    await prefs.remove(key);
  }
}

/// Bộ nhớ giả lập trong RAM dùng cho kiểm thử mô phỏng đóng/mở lại app.
class InMemoryKeyValueStore implements LocalKeyValueStore {
  InMemoryKeyValueStore([Map<String, String>? initial])
      : _data = Map<String, String>.from(initial ?? <String, String>{});

  final Map<String, String> _data;

  @override
  Future<String?> readString(String key) async => _data[key];

  @override
  Future<void> writeString(String key, String value) async {
    _data[key] = value;
  }

  @override
  Future<void> remove(String key) async {
    _data.remove(key);
  }
}
