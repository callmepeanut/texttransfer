import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:texttransfer/models/text_item.dart';
import 'package:texttransfer/pages/settings_page.dart';
import 'package:texttransfer/services/netcut_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // await SettingsService.init();  // 初始化 MMKV
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '文本传输助手',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: '文本传输助手'),
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

      setState(() {
        _isLoading = true;
      });

      // 先获取最新数据
      final latestTexts = await NetcutService.getNoteInfo();
      
      // 检查是否与最新数据的第一项内容相同
      if (latestTexts.isNotEmpty && latestTexts[0].content == clipboardData.text) {
        setState(() {
          _texts = latestTexts;  // 更新本地列表为最新数据
          _isLoading = false;
        });
        
        Fluttertoast.showToast(
          msg: '该内容已添加过',
          backgroundColor: Colors.orange,
        );
        return;
      }

      final newItem = TextItem(
        content: clipboardData.text!,
        device: 'Flutter App',
        createTime: DateTime.now().millisecondsSinceEpoch,
      );

      final updatedTexts = [newItem, ...latestTexts];  // 使用最新获取的数据
      
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
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsPage()),
              );
            },
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
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  item.content,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.copy),
                                onPressed: () {
                                  Clipboard.setData(ClipboardData(text: item.content));
                                  Fluttertoast.showToast(
                                    msg: '已复制到剪贴板',
                                    backgroundColor: Colors.green,
                                  );
                                },
                              ),
                            ],
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
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            onPressed: _isLoading ? null : _makeNetcutRequest,
            heroTag: 'refresh',
            child: const Icon(Icons.refresh),
          ),
          const SizedBox(height: 16),
          FloatingActionButton(
            onPressed: _isLoading ? null : _addClipboardText,
            heroTag: 'paste',
            child: const Icon(Icons.content_paste),
          ),
        ],
      ),
    );
  }
}
