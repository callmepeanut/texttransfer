import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class Config {
  String id;
  String name;
  String noteName;
  String notePwd;
  int shift;

  Config({
    required this.id,
    required this.name,
    required this.noteName,
    required this.notePwd,
    required this.shift,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'noteName': noteName,
      'notePwd': notePwd,
      'shift': shift,
    };
  }

  factory Config.fromJson(Map<String, dynamic> json) {
    return Config(
      id: json['id'],
      name: json['name'],
      noteName: json['noteName'],
      notePwd: json['notePwd'],
      shift: json['shift'],
    );
  }
}

class SettingsService {
  static const String _activeConfigIdKey = 'active_config_id';
  static const String _configsKey = 'configs';
  static const int defaultShift = 1000;

  // 兼容旧版本的键
  static const String _noteNameKey = 'note_name';
  static const String _notePwdKey = 'note_pwd';
  static const String _shiftKey = 'shift_value';

  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    
    // 如果没有配置，检查是否有旧版本的配置数据
    if (!prefs.containsKey(_configsKey) || (prefs.getStringList(_configsKey)?.isEmpty ?? true)) {
      // 从旧版本迁移数据
      final oldNoteName = prefs.getString(_noteNameKey);
      final oldNotePwd = prefs.getString(_notePwdKey);
      final oldShift = prefs.getInt(_shiftKey) ?? defaultShift;
      
      if (oldNoteName != null && oldNotePwd != null) {
        // 创建默认配置并设为活跃
        final defaultConfig = Config(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          name: "默认配置",
          noteName: oldNoteName,
          notePwd: oldNotePwd,
          shift: oldShift,
        );
        
        await saveConfig(defaultConfig);
        await setActiveConfigId(defaultConfig.id);
      } else {
        // 如果没有旧数据，创建空的默认配置
        final defaultConfig = Config(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          name: "默认配置",
          noteName: "",
          notePwd: "",
          shift: defaultShift,
        );
        
        await saveConfig(defaultConfig);
        await setActiveConfigId(defaultConfig.id);
      }
    }
    
    // 确保至少有一个活跃的配置ID
    final activeId = await getActiveConfigId();
    if (activeId == null) {
      final configs = await getAllConfigs();
      if (configs.isNotEmpty) {
        await setActiveConfigId(configs.first.id);
      }
    }
  }

  static Future<String?> getActiveConfigId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_activeConfigIdKey);
  }

  static Future<void> setActiveConfigId(String id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_activeConfigIdKey, id);
  }

  static Future<List<Config>> getAllConfigs() async {
    final prefs = await SharedPreferences.getInstance();
    final configStrings = prefs.getStringList(_configsKey) ?? [];
    
    return configStrings.map((str) {
      final Map<String, dynamic> json = jsonDecode(str);
      return Config.fromJson(json);
    }).toList();
  }

  static Future<Config?> getActiveConfig() async {
    final activeId = await getActiveConfigId();
    if (activeId == null) return null;
    
    final configs = await getAllConfigs();
    try {
      return configs.firstWhere(
        (config) => config.id == activeId,
      );
    } catch (e) {
      return configs.isNotEmpty ? configs.first : null;
    }
  }

  static Future<void> saveConfig(Config config) async {
    final prefs = await SharedPreferences.getInstance();
    final configs = await getAllConfigs();
    
    // 检查配置是否已存在
    final index = configs.indexWhere((c) => c.id == config.id);
    
    if (index >= 0) {
      // 更新现有配置
      configs[index] = config;
    } else {
      // 添加新配置
      configs.add(config);
    }
    
    // 保存配置列表
    final configStrings = configs.map((c) => jsonEncode(c.toJson())).toList();
    await prefs.setStringList(_configsKey, configStrings);
  }

  static Future<void> deleteConfig(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final configs = await getAllConfigs();
    
    // 删除指定配置
    configs.removeWhere((c) => c.id == id);
    
    // 保存更新后的配置列表
    final configStrings = configs.map((c) => jsonEncode(c.toJson())).toList();
    await prefs.setStringList(_configsKey, configStrings);
    
    // 如果删除的是当前活跃配置，则选择另一个配置作为活跃配置
    final activeId = await getActiveConfigId();
    if (activeId == id && configs.isNotEmpty) {
      await setActiveConfigId(configs.first.id);
    }
  }

  // 兼容旧版本的方法
  static Future<String?> getNoteName() async {
    final activeConfig = await getActiveConfig();
    return activeConfig?.noteName;
  }

  static Future<String?> getNotePwd() async {
    final activeConfig = await getActiveConfig();
    return activeConfig?.notePwd;
  }

  static Future<int> getShift() async {
    final activeConfig = await getActiveConfig();
    return activeConfig?.shift ?? defaultShift;
  }

  static Future<void> saveSettings(String noteName, String notePwd, int shift) async {
    final activeId = await getActiveConfigId();
    final configs = await getAllConfigs();
    
    if (activeId != null) {
      final index = configs.indexWhere((c) => c.id == activeId);
      if (index >= 0) {
        // 更新活跃配置
        final updatedConfig = Config(
          id: activeId,
          name: configs[index].name,
          noteName: noteName,
          notePwd: notePwd,
          shift: shift,
        );
        await saveConfig(updatedConfig);
        return;
      }
    }
    
    // 如果没有活跃配置，创建一个新配置
    final newConfig = Config(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: "新配置",
      noteName: noteName,
      notePwd: notePwd,
      shift: shift,
    );
    
    await saveConfig(newConfig);
    await setActiveConfigId(newConfig.id);
  }
} 