import 'package:shared_preferences/shared_preferences.dart';

class SettingsService {
  static const String _noteNameKey = 'note_name';
  static const String _notePwdKey = 'note_pwd';
  static const String _shiftKey = 'shift_value';
  static const int defaultShift = 1000;

  static Future<void> init() async {
    await getNoteName();
    // 确保 shift 值存在
    final prefs = await SharedPreferences.getInstance();
    if (!prefs.containsKey(_shiftKey)) {
      await prefs.setInt(_shiftKey, defaultShift);
    }
  }

  static Future<void> saveSettings(String noteName, String notePwd, int shift) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_noteNameKey, noteName);
    await prefs.setString(_notePwdKey, notePwd);
    await prefs.setInt(_shiftKey, shift);
  }

  static Future<String?> getNoteName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_noteNameKey);
  }

  static Future<String?> getNotePwd() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_notePwdKey);
  }

  static Future<int> getShift() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_shiftKey) ?? defaultShift;
  }
} 