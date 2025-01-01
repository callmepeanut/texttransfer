import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:texttransfer/services/netcut_service.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:texttransfer/models/text_item.dart';
// import 'package:texttransfer/services/storage_service.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Netcut Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Netcut Demo'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  List<TextItem>? _texts;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _makeNetcutRequest();
  }

  Future<void> _makeNetcutRequest() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final result = await NetcutService.getNoteInfo();
      setState(() {
        _texts = result;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      Fluttertoast.showToast(
        msg: e.toString(),
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.CENTER,
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
    }
  }

  Future<void> _addClipboardText() async {
    try {
      final clipboardData = await Clipboard.getData(Clipboard.kTextPlain);
      if (clipboardData?.text == null || clipboardData!.text!.isEmpty) {
        throw Exception('剪贴板为空');
      }

      // 检查是否与第一项内容相同
      if (_texts != null && _texts!.isNotEmpty && _texts![0].content == clipboardData.text) {
        Fluttertoast.showToast(
          msg: '该内容已添加过',
          backgroundColor: Colors.orange,
        );
        return;
      }

      setState(() {
        _isLoading = true;
      });

      final newItem = TextItem(
        content: clipboardData.text!,
        device: 'Flutter App',
        createTime: DateTime.now().millisecondsSinceEpoch,
      );

      final updatedTexts = [newItem, ...?_texts];
      
      // 保存到服务器
      await NetcutService.saveNote(updatedTexts);
      
      setState(() {
        _texts = updatedTexts;
        _isLoading = false;
      });

      Fluttertoast.showToast(
        msg: '添加成功',
        backgroundColor: Colors.green,
      );
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      Fluttertoast.showToast(
        msg: e.toString(),
        backgroundColor: Colors.red,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
        actions: [
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              ),
            ),
        ],
      ),
      body: _texts == null
          ? const Center(child: Text('暂无数据'))
          : ListView.builder(
              itemCount: _texts!.length,
              itemBuilder: (context, index) {
                final item = _texts![index];
                return Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.content,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '设备: ${item.device}',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                          ),
                          Text(
                            '时间: ${DateTime.fromMillisecondsSinceEpoch(item.createTime).toString()}',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _isLoading ? null : _addClipboardText,
        child: const Icon(Icons.content_paste),
      ),
    );
  }
}
