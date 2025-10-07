import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class Config {
  String id;
  String name;
  String apiKey;
  int shift;

  Config({
    required this.id,
    required this.name,
    required this.apiKey,
    required this.shift,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'apiKey': apiKey,
      'shift': shift,
    };
  }

  factory Config.fromJson(Map<String, dynamic> json) {
    return Config(
      id: json['id'],
      name: json['name'],
      // Support both old and new formats for migration
      apiKey: json['apiKey'] ?? json['noteName'] ?? '',
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
  static const String _apiKeyKey = 'api_key';

  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    
    // 检查是否有旧版本的配置数据需要迁移
    if (!prefs.containsKey(_configsKey) || (prefs.getStringList(_configsKey)?.isEmpty ?? true)) {
      // 从旧版本迁移数据
      final oldNoteName = prefs.getString(_noteNameKey);
      final oldNotePwd = prefs.getString(_notePwdKey);
      final oldShift = prefs.getInt(_shiftKey) ?? defaultShift;

      // 检查是否有新的 API Key 配置
      final oldApiKey = prefs.getString(_apiKeyKey);

      if (oldApiKey != null) {
        // 使用新的 API Key 配置
        final migratedConfig = Config(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          name: "已迁移的配置",
          apiKey: oldApiKey,
          shift: oldShift,
        );

        await saveConfig(migratedConfig);
        await setActiveConfigId(migratedConfig.id);
      } else if (oldNoteName != null && oldNotePwd != null) {
        // 从旧版本迁移：使用 noteName 作为 API Key
        final migratedConfig = Config(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          name: "已迁移的配置",
          apiKey: oldNoteName,  // 使用旧的 noteName 作为 API Key
          shift: oldShift,
        );

        await saveConfig(migratedConfig);
        await setActiveConfigId(migratedConfig.id);
      }
      // 注意：如果没有旧数据，不再自动创建默认配置
    }
    
    // 如果有配置但没有活跃的配置ID，设置第一个为活跃配置
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

  // 新的 API 方法
  static Future<String?> getApiKey() async {
    final activeConfig = await getActiveConfig();
    return activeConfig?.apiKey;
  }

  // 兼容旧版本的方法 (已弃用)
  @Deprecated('Use getApiKey() instead')
  static Future<String?> getNoteName() async {
    final activeConfig = await getActiveConfig();
    return activeConfig?.apiKey;  // 返回 apiKey
  }

  @Deprecated('This method is no longer used')
  static Future<String?> getNotePwd() async {
    return null;  // 不再使用密码
  }

  static Future<int> getShift() async {
    final activeConfig = await getActiveConfig();
    return activeConfig?.shift ?? defaultShift;
  }

  static Future<void> saveSettings(String apiKey, int shift) async {
    final activeId = await getActiveConfigId();
    final configs = await getAllConfigs();

    if (activeId != null) {
      final index = configs.indexWhere((c) => c.id == activeId);
      if (index >= 0) {
        // 更新活跃配置
        final updatedConfig = Config(
          id: activeId,
          name: configs[index].name,
          apiKey: apiKey,
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
      apiKey: apiKey,
      shift: shift,
    );

    await saveConfig(newConfig);
    await setActiveConfigId(newConfig.id);
  }

  // 兼容旧版本的方法
  @Deprecated('Use saveSettings(String apiKey, int shift) instead')
  static Future<void> saveSettingsOld(String noteName, String notePwd, int shift) async {
    // 将旧的 noteName 作为 API Key
    await saveSettings(noteName, shift);
  }
} 