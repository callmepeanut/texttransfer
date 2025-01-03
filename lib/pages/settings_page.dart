import 'package:flutter/material.dart';
import 'package:texttransfer/services/settings_service.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final _noteNameController = TextEditingController();
  final _notePwdController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final noteName = await SettingsService.getNoteName();
    final notePwd = await SettingsService.getNotePwd();
    
    if (noteName != null) {
      _noteNameController.text = noteName;
    }
    if (notePwd != null) {
      _notePwdController.text = notePwd;
    }
  }

  Future<void> _saveSettings() async {
    final noteName = _noteNameController.text.trim();
    final notePwd = _notePwdController.text.trim();
    
    if (noteName.isEmpty || notePwd.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请填写完整信息')),
      );
      return;
    }

    await SettingsService.saveSettings(noteName, notePwd);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('保存成功')),
      );
      Navigator.pop(context);
    }
  }

  @override
  void dispose() {
    _noteNameController.dispose();
    _notePwdController.dispose();
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
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _saveSettings,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
              ),
              child: const Text('保存'),
            ),
          ],
        ),
      ),
    );
  }
} 