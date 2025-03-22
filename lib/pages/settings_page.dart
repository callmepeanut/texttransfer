import 'package:flutter/material.dart';
import 'package:texttransfer/services/settings_service.dart';
import 'package:texttransfer/pages/qr_scan_page.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final _noteNameController = TextEditingController();
  final _notePwdController = TextEditingController();
  final _shiftController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final noteName = await SettingsService.getNoteName();
    final notePwd = await SettingsService.getNotePwd();
    final shift = await SettingsService.getShift();
    
    if (noteName != null) {
      _noteNameController.text = noteName;
    }
    if (notePwd != null) {
      _notePwdController.text = notePwd;
    }
    _shiftController.text = shift.toString();
  }

  Future<void> _saveSettings() async {
    final noteName = _noteNameController.text.trim();
    final notePwd = _notePwdController.text.trim();
    final shiftText = _shiftController.text.trim();
    
    if (noteName.isEmpty || notePwd.isEmpty || shiftText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请填写完整信息')),
      );
      return;
    }

    final shift = int.tryParse(shiftText);
    if (shift == null || shift < 0 || shift > 65535) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('移位值必须在 0-65535 之间')),
      );
      return;
    }

    await SettingsService.saveSettings(noteName, notePwd, shift);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('保存成功')),
      );
      Navigator.pop(context, true);
    }
  }

  Future<void> _scanQRCode() async {
    // 打开扫码页面
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (context) => const QRScanPage()),
    );

    // 如果扫码成功，重新加载设置
    if (result == true) {
      await _loadSettings();
      Navigator.pop(context, true);
    }
  }

  @override
  void dispose() {
    _noteNameController.dispose();
    _notePwdController.dispose();
    _shiftController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('设置'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _noteNameController,
              decoration: const InputDecoration(
                labelText: 'Note Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _notePwdController,
              decoration: const InputDecoration(
                labelText: 'Note Password',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _shiftController,
              decoration: const InputDecoration(
                labelText: 'Base64 移位值 (0-65535)',
                border: OutlineInputBorder(),
                helperText: '用于加密数据，修改后新数据将使用新的移位值',
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _saveSettings,
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(50),
                    ),
                    child: const Text('保存'),
                  ),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: _scanQRCode,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(50, 50),
                    padding: const EdgeInsets.all(0),
                  ),
                  child: const Icon(Icons.qr_code_scanner),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
} 