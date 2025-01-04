import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:texttransfer/models/text_item.dart';
import 'package:texttransfer/services/settings_service.dart';

class NetcutService {
  static String? _noteId;
  static String? _noteToken;
  static int? _expireTime;

  static Future<List<TextItem>> getNoteInfo() async {
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
          
          final noteContent = json.decode(noteContentStr);
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
          'note_content': json.encode(noteContent),
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