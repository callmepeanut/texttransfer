import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:texttransfer/models/text_item.dart';
import 'package:texttransfer/services/settings_service.dart';

class NetcutService {
  static String? _noteId;
  static String? _noteToken;
  static int? _expireTime;
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
    final noteName = await SettingsService.getNoteName();
    final notePwd = await SettingsService.getNotePwd();
    
    if (noteName == null || notePwd == null) {
      throw Exception('请先在设置中配置账号信息');
    }

    final url = Uri.parse('https://api.txttool.cn/netcut/note/info/');
    
    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded; charset=UTF-8',
          'Accept': 'application/json',
          'Origin': 'https://netcut.cn',
          'Referer': 'https://netcut.cn/'
        },
        body: {
          'note_name': noteName,
          'note_pwd': notePwd
        }
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        if (responseData['status'] == 1 && responseData['data'] != null) {
          _noteId = responseData['data']['note_id'];
          _noteToken = responseData['data']['note_token'];
          _expireTime = responseData['data']['expire_time'];
          
          final noteContentStr = responseData['data']['note_content'];
          if (noteContentStr == '') {
            return [];
          }
          
          // 解密数据
          final decryptedContent = _decryptText(noteContentStr);
          final noteContent = json.decode(decryptedContent);
          final List<dynamic> texts = noteContent['texts'];
          return texts.map((item) => TextItem.fromJson(item)).toList();
        }
        throw Exception('数据格式错误');
      } else {
        throw Exception('请求失败: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('网络请求错误: $e');
    }
  }

  static Future<void> saveNote(List<TextItem> texts) async {
    await updateShift(); // 获取最新的 shift 值
    if (_noteId == null || _noteToken == null) {
      throw Exception('需要先调用getNoteInfo初始化noteId和token');
    }

    final noteName = await SettingsService.getNoteName();
    final notePwd = await SettingsService.getNotePwd();
    
    if (noteName == null || notePwd == null) {
      throw Exception('请先在设置中配置账号信息');
    }

    final url = Uri.parse('https://api.txttool.cn/netcut/note/save/');
    
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
          'Content-Type': 'application/x-www-form-urlencoded; charset=UTF-8',
          'Accept': 'application/json',
          'Origin': 'https://netcut.cn',
          'Referer': 'https://netcut.cn/'
        },
        body: {
          'note_name': noteName,
          'note_id': _noteId,
          'note_content': encryptedContent,
          'note_token': _noteToken,
          'expire_time': (_expireTime ?? 259200).toString(),
          'note_pwd': notePwd
        }
      );

      if (response.statusCode != 200) {
        throw Exception('保存失败: ${response.statusCode}');
      }

      final responseData = json.decode(response.body);
      if (responseData['status'] != 1) {
        throw Exception('保存失败: ${responseData['error']}');
      }
    } catch (e) {
      throw Exception('保存失败: $e');
    }
  }
} 