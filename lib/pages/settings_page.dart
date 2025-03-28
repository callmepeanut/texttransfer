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
  final _configNameController = TextEditingController();
  
  List<Config> _configs = [];
  String? _activeConfigId;
  bool _isEditingName = false;

  @override
  void initState() {
    super.initState();
    _loadConfigs();
  }

  Future<void> _loadConfigs() async {
    _configs = await SettingsService.getAllConfigs();
    _activeConfigId = await SettingsService.getActiveConfigId();
    
    await _loadActiveConfig();
    
    setState(() {});
  }

  Future<void> _loadActiveConfig() async {
    final activeConfig = await SettingsService.getActiveConfig();
    
    if (activeConfig != null) {
      _noteNameController.text = activeConfig.noteName;
      _notePwdController.text = activeConfig.notePwd;
      _shiftController.text = activeConfig.shift.toString();
      _configNameController.text = activeConfig.name;
    } else {
      // 清空表单
      _noteNameController.clear();
      _notePwdController.clear();
      _shiftController.text = SettingsService.defaultShift.toString();
      _configNameController.text = "新配置";
    }
  }

  Future<void> _saveSettings() async {
    final noteName = _noteNameController.text.trim();
    final notePwd = _notePwdController.text.trim();
    final shiftText = _shiftController.text.trim();
    final configName = _configNameController.text.trim();
    
    if (noteName.isEmpty || notePwd.isEmpty || shiftText.isEmpty || configName.isEmpty) {
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

    // 保存当前活跃配置
    if (_activeConfigId != null) {
      final activeConfig = _configs.firstWhere(
        (config) => config.id == _activeConfigId,
        orElse: () => Config(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          name: configName,
          noteName: noteName,
          notePwd: notePwd,
          shift: shift,
        ),
      );
      
      final updatedConfig = Config(
        id: activeConfig.id,
        name: configName,
        noteName: noteName,
        notePwd: notePwd,
        shift: shift,
      );
      
      await SettingsService.saveConfig(updatedConfig);
      await SettingsService.setActiveConfigId(updatedConfig.id);
    } else {
      // 创建新配置
      final newConfig = Config(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: configName,
        noteName: noteName,
        notePwd: notePwd,
        shift: shift,
      );
      
      await SettingsService.saveConfig(newConfig);
      await SettingsService.setActiveConfigId(newConfig.id);
    }
    
    // 重新加载配置列表
    await _loadConfigs();
    _isEditingName = false;
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('保存成功')),
      );
      Navigator.pop(context, true);
    }
  }

  Future<void> _createNewConfig() async {
    setState(() {
      _activeConfigId = null;
      _noteNameController.clear();
      _notePwdController.clear();
      _shiftController.text = SettingsService.defaultShift.toString();
      _configNameController.text = '新配置 ${_configs.length + 1}';
      _isEditingName = true;
    });
  }

  Future<void> _switchConfig(String id) async {
    if (_activeConfigId == id) return;
    
    await SettingsService.setActiveConfigId(id);
    _activeConfigId = id;
    await _loadActiveConfig();
    setState(() {});
  }

  Future<void> _deleteConfig(String id) async {
    try {
      // 获取要删除的配置名称
      final configToDelete = _configs.firstWhere((c) => c.id == id);
      
      // 确认删除
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('确认删除', style: TextStyle(fontSize: 18)),
          content: RichText(
            text: TextSpan(
              style: const TextStyle(
                color: Colors.black87,
                fontSize: 14,
                height: 1.5,
              ),
              children: [
                const TextSpan(text: '确定要删除配置 '),
                TextSpan(
                  text: '"${configToDelete.name}"',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
                const TextSpan(text: ' 吗？\n\n此操作无法撤销。'),
              ],
            ),
          ),
          contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
          actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
              ),
              child: const Text('删除'),
            ),
          ],
        ),
      );
      
      if (confirmed != true) return;
      
      final bool isDeletingActiveConfig = id == _activeConfigId;
      
      // 执行删除操作
      await SettingsService.deleteConfig(id);
      
      // 重新加载配置列表
      await _loadConfigs();
      
      // 如果删除的是当前活跃配置，重新加载活跃配置内容
      if (isDeletingActiveConfig) {
        await _loadActiveConfig();
      }
      
      // 显示删除成功提示
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isDeletingActiveConfig 
                ? '配置"${configToDelete.name}"已删除，已自动切换到其他配置' 
                : '配置"${configToDelete.name}"已删除'),
          ),
        );
      }
    } catch (e) {
      // 找不到配置或其他错误
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('删除配置时出错')),
        );
      }
    }
  }

  Future<void> _scanQRCode() async {
    // 标记当前是否处于创建新配置模式
    final isCreatingNew = _activeConfigId == null;
    
    // 打开扫码页面
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (context) => QRScanPage(
        createNewConfig: isCreatingNew,
      )),
    );

    // 如果扫码成功，重新加载配置
    if (result == true) {
      await _loadConfigs();
      
      // 返回并通知主页刷新
      if (mounted) {
        Navigator.pop(context, true);
      }
    }
  }

  void _toggleNameEditing() {
    setState(() {
      _isEditingName = !_isEditingName;
    });
    
    // 如果是从编辑状态切换回显示状态，保存配置名称
    if (!_isEditingName && _activeConfigId != null) {
      _saveConfigName();
    }
  }

  Future<void> _saveConfigName() async {
    final configName = _configNameController.text.trim();
    if (configName.isEmpty) return;
    
    try {
      // 查找当前活跃配置
      final activeConfig = _configs.firstWhere(
        (config) => config.id == _activeConfigId,
      );
      
      // 如果名称没有变化，不需要保存
      if (activeConfig.name == configName) return;
      
      // 更新配置名称
      final updatedConfig = Config(
        id: activeConfig.id,
        name: configName,
        noteName: activeConfig.noteName,
        notePwd: activeConfig.notePwd,
        shift: activeConfig.shift,
      );
      
      // 保存更新后的配置
      await SettingsService.saveConfig(updatedConfig);
      
      // 刷新配置列表
      await _loadConfigs();
      
      // 显示保存成功提示
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('配置名称已更新')),
        );
      }
    } catch (e) {
      // 找不到活跃配置，不进行操作
    }
  }

  void _showCreateOptions() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.qr_code_scanner),
                title: const Text('扫码创建配置'),
                onTap: () {
                  Navigator.pop(context);
                  _scanQRCode();
                },
              ),
              ListTile(
                leading: const Icon(Icons.edit),
                title: const Text('手动填写配置'),
                onTap: () {
                  Navigator.pop(context);
                  _createNewConfig();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _noteNameController.dispose();
    _notePwdController.dispose();
    _shiftController.dispose();
    _configNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('设置'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.add),
            tooltip: '创建新配置',
            offset: const Offset(0, 45),
            itemBuilder: (context) => [
              const PopupMenuItem<String>(
                value: 'scan',
                child: Row(
                  children: [
                    Icon(Icons.qr_code_scanner, size: 20),
                    SizedBox(width: 10),
                    Text('扫码创建配置'),
                  ],
                ),
              ),
              const PopupMenuItem<String>(
                value: 'manual',
                child: Row(
                  children: [
                    Icon(Icons.edit, size: 20),
                    SizedBox(width: 10),
                    Text('手动填写配置'),
                  ],
                ),
              ),
            ],
            onSelected: (value) {
              if (value == 'scan') {
                // 打开扫码页面，并明确指定为创建新配置模式
                Navigator.push<bool>(
                  context,
                  MaterialPageRoute(builder: (context) => const QRScanPage(
                    createNewConfig: true,
                  )),
                ).then((result) async {
                  if (result == true) {
                    await _loadConfigs();
                  }
                });
              } else if (value == 'manual') {
                _createNewConfig();
              }
            },
          ),
        ],
      ),
      body: _shouldShowEmptyState()
          ? _buildEmptyState()
          : _buildSettingsForm(),
    );
  }

  bool _shouldShowEmptyState() {
    // 如果正在创建新配置，不显示空状态
    if (_configNameController.text.isNotEmpty) {
      return false;
    }
    // 如果没有配置且没有活跃配置ID，显示空状态
    if (_configs.isEmpty && _activeConfigId == null) {
      return true;
    }
    return false;
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.settings, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          const Text('没有配置', style: TextStyle(fontSize: 18)),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              // 显示创建选项菜单
              final RenderBox button = context.findRenderObject() as RenderBox;
              final RenderBox overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
              final RelativeRect position = RelativeRect.fromRect(
                Rect.fromPoints(
                  button.localToGlobal(Offset.zero, ancestor: overlay),
                  button.localToGlobal(button.size.bottomRight(Offset.zero), ancestor: overlay),
                ),
                Offset.zero & overlay.size,
              );
              
              showMenu<String>(
                context: context,
                position: position,
                items: [
                  const PopupMenuItem<String>(
                    value: 'scan',
                    child: Row(
                      children: [
                        Icon(Icons.qr_code_scanner, size: 20),
                        SizedBox(width: 10),
                        Text('扫码创建配置'),
                      ],
                    ),
                  ),
                  const PopupMenuItem<String>(
                    value: 'manual',
                    child: Row(
                      children: [
                        Icon(Icons.edit, size: 20),
                        SizedBox(width: 10),
                        Text('手动填写配置'),
                      ],
                    ),
                  ),
                ],
              ).then((value) {
                if (value == 'scan') {
                  // 打开扫码页面，并明确指定为创建新配置模式
                  Navigator.push<bool>(
                    context,
                    MaterialPageRoute(builder: (context) => const QRScanPage(
                      createNewConfig: true,
                    )),
                  ).then((result) async {
                    if (result == true) {
                      await _loadConfigs();
                    }
                  });
                } else if (value == 'manual') {
                  _createNewConfig();
                }
              });
            },
            child: const Text('创建新配置'),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_configs.isNotEmpty) _buildConfigSelector(),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildConfigNameField(),
              ),
              if (_activeConfigId != null && _configs.length > 1)
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  onPressed: () => _deleteConfig(_activeConfigId!),
                  tooltip: '删除当前配置',
                ),
            ],
          ),
          const SizedBox(height: 16),
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
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _saveSettings,
              child: const Text('保存'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfigSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 50,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _configs.length,
            separatorBuilder: (context, index) => const VerticalDivider(
              width: 1,
              color: Colors.grey,
            ),
            itemBuilder: (context, index) {
              final config = _configs[index];
              final isActive = config.id == _activeConfigId;
              
              return Tooltip(
                message: '点击切换到此配置${_configs.length > 1 ? "，长按删除" : ""}',
                child: GestureDetector(
                  onTap: () => _switchConfig(config.id),
                  onLongPress: () {
                    if (_configs.length > 1) {
                      _deleteConfig(config.id);
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    alignment: Alignment.center,
                    color: isActive ? Theme.of(context).colorScheme.primaryContainer : null,
                    child: Text(
                      config.name,
                      style: TextStyle(
                        fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                        color: isActive 
                          ? Theme.of(context).colorScheme.onPrimaryContainer 
                          : Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        if (_configs.length > 1)
          Padding(
            padding: const EdgeInsets.only(top: 4.0, left: 8.0),
            child: Text(
              '提示：长按配置标签可以删除配置',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildConfigNameField() {
    return Row(
      children: [
        Expanded(
          child: _isEditingName
            ? TextField(
                controller: _configNameController,
                decoration: const InputDecoration(
                  labelText: '配置名称',
                  border: OutlineInputBorder(),
                ),
                autofocus: true,
                onEditingComplete: _toggleNameEditing,
              )
            : Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Text(
                  _configNameController.text,
                  style: const TextStyle(fontSize: 16),
                ),
              ),
        ),
        IconButton(
          icon: Icon(_isEditingName ? Icons.check : Icons.edit),
          onPressed: _toggleNameEditing,
        ),
      ],
    );
  }
} 