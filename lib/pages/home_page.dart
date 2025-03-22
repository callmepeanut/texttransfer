import 'package:flutter/material.dart';

class HomePage extends StatefulWidget {
  // ... (existing code)
}

class _HomePageState extends State<HomePage> {
  // ... (existing code)

  void _openSettings() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (context) => const SettingsPage()),
    );

    if (result == true) {
      // 如果设置有更改，重新加载数据
      await _loadData();
    }
  }

  // ... (rest of the existing code)
} 