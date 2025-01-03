import 'package:shared_preferences/shared_preferences.dart';

class SettingsService {
  static const String _noteNameKey = 'note_name';
  static const String _notePwdKey = 'note_pwd';

  static Future<void> init() async {
    await getNoteName();
  }

  static Future<void> saveSettings(String noteName, String notePwd) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_noteNameKey, noteName);
    await prefs.setString(_notePwdKey, notePwd);
  }

  static Future<String?> getNoteName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_noteNameKey);
  }

  static Future<String?> getNotePwd() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_notePwdKey);
  }
} 