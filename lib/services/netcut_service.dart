import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:texttransfer/models/text_item.dart';

class NetcutService {
  static Future<List<TextItem>> getNoteInfo() async {
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
          'note_name': 'ddd',
          'note_pwd': 'kanyun'
        }
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        if (responseData['status'] == 1 && responseData['data'] != null) {
          final noteContent = json.decode(responseData['data']['note_content']);
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
} 