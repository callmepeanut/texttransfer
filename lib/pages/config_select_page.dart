import 'package:flutter/material.dart';
import 'package:texttransfer/services/settings_service.dart';

class ConfigSelectPage extends StatefulWidget {
  const ConfigSelectPage({super.key});

  @override
  State<ConfigSelectPage> createState() => _ConfigSelectPageState();
}

class _ConfigSelectPageState extends State<ConfigSelectPage> {
  List<Config> _configs = [];
  String? _activeConfigId;

  @override
  void initState() {
    super.initState();
    _loadConfigs();
  }

  Future<void> _loadConfigs() async {
    final configs = await SettingsService.getAllConfigs();
    final activeId = await SettingsService.getActiveConfigId();
    
    setState(() {
      _configs = configs;
      _activeConfigId = activeId;
    });
  }

  Future<void> _selectConfig(Config config) async {
    await SettingsService.setActiveConfigId(config.id);
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('选择配置'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: _configs.isEmpty
          ? const Center(child: Text('没有可用的配置'))
          : ListView.separated(
              itemCount: _configs.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final config = _configs[index];
                final isActive = config.id == _activeConfigId;
                
                return ListTile(
                  title: Text(
                    config.name,
                    style: TextStyle(
                      fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  subtitle: Text('Note: ${config.noteName}'),
                  trailing: isActive
                      ? const Icon(Icons.check_circle, color: Colors.green)
                      : null,
                  onTap: () => _selectConfig(config),
                  selected: isActive,
                  tileColor: isActive ? Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3) : null,
                );
              },
            ),
    );
  }
} 