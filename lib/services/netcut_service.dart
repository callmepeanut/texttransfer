import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:texttransfer/models/text_item.dart';
import 'package:texttransfer/services/settings_service.dart';

class NetcutService {
  static int _shift = 1000; // 改为非 const，从设置中获取

  // 添加更新 shift 的方法
  static Future<void> updateShift() async {
    _shift = await SettingsService.getShift();
  }

  // 添加加密方法
  static String _encryptText(String text) {
    // 字符移位加密
    String shifted = String.fromCharCodes(
      text.runes.map((int char) => (char + _shift) % 65536),
    );

    // Base64 编码
    return base64Encode(utf8.encode(shifted));
  }

  // 添加解密方法
  static String _decryptText(String encrypted) {
    try {
      // Base64 解码
      String decoded = utf8.decode(base64Decode(encrypted));

      // 字符移位解密
      return String.fromCharCodes(
        decoded.runes.map((int char) => (char - _shift + 65536) % 65536),
      );
    } catch (e) {
      // 如果解密失败，返回原文（兼容未加密的旧数据）
      return encrypted;
    }
  }

  static Future<List<TextItem>> getNoteInfo() async {
    await updateShift(); // 获取最新的 shift 值
    final apiKey = await SettingsService.getApiKey();

    if (apiKey == null || apiKey.isEmpty) {
      throw Exception('请先在设置中配置 API Key');
    }

    final url = Uri.parse('https://textdb.online/$apiKey');

    final response = await http.get(
      url,
      headers: {
        'Accept': 'text/plain',
      }
    );

    if (response.statusCode == 404) {
      return []; // 没有数据
    }

    if (response.statusCode != 200) {
      throw Exception('请求失败: ${response.statusCode}');
    }

    final noteContentStr = response.body;
    if (noteContentStr.isEmpty) {
      return [];
    }

    try {
      // 解密数据
      final decryptedContent = _decryptText(noteContentStr);
      final noteContent = json.decode(decryptedContent);
      final List<dynamic> texts = noteContent['texts'] ?? [];
      return texts.map((item) => TextItem.fromJson(item)).toList();
    } catch (e) {
      if (e.toString().contains('FormatException')) {
        // 如果解密失败，可能是未加密的旧数据，尝试直接解析
        try {
          final noteContent = json.decode(noteContentStr);
          final List<dynamic> texts = noteContent['texts'] ?? [];
          return texts.map((item) => TextItem.fromJson(item)).toList();
        } catch (e2) {
          throw Exception('数据格式错误: $e2');
        }
      }
      throw Exception('网络请求错误: $e');
    }
  }

  static Future<void> saveNote(List<TextItem> texts) async {
    await updateShift(); // 获取最新的 shift 值
    final apiKey = await SettingsService.getApiKey();

    if (apiKey == null || apiKey.isEmpty) {
      throw Exception('请先在设置中配置 API Key');
    }

    final url = Uri.parse('https://api.textdb.online/update/?key=$apiKey');

    try {
      final noteContent = {
        'texts': texts.map((item) => {
          'content': item.content,
          'device': item.device,
          'createTime': item.createTime,
        }).toList(),
      };

      // 加密数据
      final encryptedContent = _encryptText(json.encode(noteContent));

      final response = await http.post(
        url,
        headers: {
          'Accept': 'application/json',
        },
        body: {
          'value': encryptedContent,
        }
      );

      if (response.statusCode != 200) {
        throw Exception('保存失败: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('保存失败: $e');
    }
  }
} 