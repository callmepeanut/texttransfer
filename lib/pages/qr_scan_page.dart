import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:texttransfer/services/settings_service.dart';

class QRScanPage extends StatefulWidget {
  final bool createNewConfig;
  
  const QRScanPage({
    super.key, 
    this.createNewConfig = false,
  });

  @override
  State<QRScanPage> createState() => _QRScanPageState();
}

class _QRScanPageState extends State<QRScanPage> {
  final MobileScannerController controller = MobileScannerController();
  bool _isProcessing = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('扫描二维码'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: ValueListenableBuilder(
              valueListenable: controller.torchState,
              builder: (context, state, child) {
                switch (state) {
                  case TorchState.off:
                    return const Icon(Icons.flash_off);
                  case TorchState.on:
                    return const Icon(Icons.flash_on);
                }
              },
            ),
            onPressed: () => controller.toggleTorch(),
          ),
          IconButton(
            icon: ValueListenableBuilder(
              valueListenable: controller.cameraFacingState,
              builder: (context, state, child) {
                switch (state) {
                  case CameraFacing.front:
                    return const Icon(Icons.camera_front);
                  case CameraFacing.back:
                    return const Icon(Icons.camera_rear);
                }
              },
            ),
            onPressed: () => controller.switchCamera(),
          ),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: controller,
            onDetect: _onDetect,
          ),
          CustomPaint(
            painter: ScannerOverlay(),
            child: Container(),
          ),
        ],
      ),
    );
  }

  void _onDetect(BarcodeCapture capture) async {
    if (_isProcessing) return;
    _isProcessing = true;

    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isEmpty) {
      _isProcessing = false;
      return;
    }

    try {
      final data = jsonDecode(barcodes.first.rawValue ?? '');
      if (data is! Map<String, dynamic>) throw Exception('无效的配置格式');

      final noteName = data['note_name'] as String?;
      final notePwd = data['note_pwd'] as String?;
      final shiftValue = data['shift_value'] as int?;

      if (noteName == null || notePwd == null || shiftValue == null) {
        throw Exception('配置信息不完整');
      }

      if (shiftValue < 0 || shiftValue > 65535) {
        throw Exception('移位值必须在 0-65535 之间');
      }

      if (widget.createNewConfig) {
        // 创建新配置
        final newConfig = Config(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          name: '扫码配置 ${DateTime.now().millisecondsSinceEpoch.toString().substring(8, 13)}',
          noteName: noteName,
          notePwd: notePwd,
          shift: shiftValue,
        );
        
        await SettingsService.saveConfig(newConfig);
        await SettingsService.setActiveConfigId(newConfig.id);
      } else {
        // 更新当前配置
        await SettingsService.saveSettings(noteName, notePwd, shiftValue);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('配置导入成功')),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('配置导入失败: ${e.toString()}')),
        );
        _isProcessing = false;
      }
    }
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }
}

// 自定义扫描框绘制
class ScannerOverlay extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.5)
      ..style = PaintingStyle.fill;

    const scanAreaSize = 250.0;
    final scanAreaRect = Rect.fromCenter(
      center: Offset(size.width / 2, size.height / 2),
      width: scanAreaSize,
      height: scanAreaSize,
    );

    // 绘制半透明背景
    canvas.drawPath(
      Path.combine(
        PathOperation.difference,
        Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height)),
        Path()..addRect(scanAreaRect),
      ),
      paint,
    );

    // 绘制扫描框边框
    final borderPaint = Paint()
      ..color = Colors.purple
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;

    canvas.drawRect(scanAreaRect, borderPaint);

    // 绘制扫描框四角
    const cornerLength = 30.0;
    final cornerPaint = Paint()
      ..color = Colors.purple
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5.0;

    // 左上角
    canvas.drawLine(
      scanAreaRect.topLeft,
      scanAreaRect.topLeft.translate(cornerLength, 0),
      cornerPaint,
    );
    canvas.drawLine(
      scanAreaRect.topLeft,
      scanAreaRect.topLeft.translate(0, cornerLength),
      cornerPaint,
    );

    // 右上角
    canvas.drawLine(
      scanAreaRect.topRight,
      scanAreaRect.topRight.translate(-cornerLength, 0),
      cornerPaint,
    );
    canvas.drawLine(
      scanAreaRect.topRight,
      scanAreaRect.topRight.translate(0, cornerLength),
      cornerPaint,
    );

    // 左下角
    canvas.drawLine(
      scanAreaRect.bottomLeft,
      scanAreaRect.bottomLeft.translate(cornerLength, 0),
      cornerPaint,
    );
    canvas.drawLine(
      scanAreaRect.bottomLeft,
      scanAreaRect.bottomLeft.translate(0, -cornerLength),
      cornerPaint,
    );

    // 右下角
    canvas.drawLine(
      scanAreaRect.bottomRight,
      scanAreaRect.bottomRight.translate(-cornerLength, 0),
      cornerPaint,
    );
    canvas.drawLine(
      scanAreaRect.bottomRight,
      scanAreaRect.bottomRight.translate(0, -cornerLength),
      cornerPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
} 