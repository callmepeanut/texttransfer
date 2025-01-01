import 'package:http/http.dart' as http;
import 'dart:convert';

class NetcutService {
  static Future<Map<String, dynamic>> getNoteInfo() async {
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
        return json.decode(response.body);
      } else {
        throw Exception('请求失败: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('网络请求错误: $e');
    }
  }
} 