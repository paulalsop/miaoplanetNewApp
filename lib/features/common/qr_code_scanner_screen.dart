import 'dart:async';
import 'dart:developer';

import 'package:dartx/dartx.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
// import 'package:flutter_easy_permission/easy_permissions.dart';
import 'package:hiddify/core/localization/translations.dart';
import 'package:hiddify/utils/utils.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';

// const permissions = [Permissions.CAMERA];
// const permissionGroup = [PermissionGroup.Camera];

class QRCodeScannerScreen extends StatefulHookConsumerWidget {
  const QRCodeScannerScreen({super.key});

  Future<String?> open(BuildContext context) async {
    return Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (context) => const QRCodeScannerScreen(),
      ),
    );
  }

  @override
  ConsumerState<QRCodeScannerScreen> createState() => _QRCodeScannerScreenState();
}

class _QRCodeScannerScreenState extends ConsumerState<QRCodeScannerScreen> with WidgetsBindingObserver, PresLogger {
  final MobileScannerController controller = MobileScannerController(
    detectionTimeoutMs: 500,
    autoStart: false,
  );
  bool started = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeScanner();
  }

  Future<bool> _requestCameraPermission() async {
    final status = await Permission.camera.status;
    
    if (status.isGranted) return true;
    
    if (status.isDenied) {
      final result = await Permission.camera.request();
      return result.isGranted;
    }
    
    return false;
  }

  Future<void> _initializeScanner() async {
    final hasPermission = await _requestCameraPermission();
    if (hasPermission) {
      _startScanner();
    } else {
      _showPermissionDialog();
    }
  }

  @override
  void dispose() {
    controller.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    /// Checking app cycle so that when user returns from settings, need to recheck for permissions
    if (state == AppLifecycleState.resumed) {
      _checkPermissionAndStartScanner();
    }
  }

  Future<void> _checkPermissionAndStartScanner() async {
    final hasPermission = await Permission.camera.status.isGranted;
    if (hasPermission) {
      _startScanner();
    } else {
      setState(() {}); // Trigger rebuild to show permission denied UI
    }
  }

  Future<void> _startScanner() async {
    loggy.info("Starting scanner");
    await controller.stop();
    await controller.start().whenComplete(() {
      setState(() {
        started = true;
      });
    }).catchError((error) {
      loggy.warning("Error starting scanner: $error");
    });
  }

  Future<void> startQrScannerIfPermissionIsGranted() async {
    final hasPermission = await Permission.camera.status.isGranted;
    if (hasPermission) {
      _startScanner();
    }
  }

  void _showPermissionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("相机权限"),
        content: const Text("需要相机权限来扫描二维码"),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text("取消"),
          ),
          TextButton(
            onPressed: () {
              openAppSettings();
              Navigator.of(context).pop();
            },
            child: const Text("设置"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final Translations t = ref.watch(translationsProvider);

    return FutureBuilder(
      future: Permission.camera.status.isGranted,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.data == true) {
          return _buildScannerUI(context, t);
        } else {
          return _buildPermissionDeniedUI(context, t);
        }
      },
    );
  }

  Widget _buildScannerUI(BuildContext context, Translations t) {
    final size = MediaQuery.sizeOf(context);
    final overlaySize = (size.shortestSide - 12).coerceAtMost(248);
    // _startScanner();
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        iconTheme: Theme.of(context).iconTheme.copyWith(
              color: Colors.white,
              size: 32,
            ),
        actions: [
          IconButton(
            icon: const Icon(FluentIcons.flash_24_regular),
            tooltip: t.profile.add.qrScanner.torchSemanticLabel,
            onPressed: () => controller.toggleTorch(),
          ),
          // IconButton(
          //   icon: ValueListenableBuilder(
          //     valueListenable: controller.torchState,
          //     builder: (context, state, child) {
          //       switch (state) {
          //         case TorchState.off:
          //           return const Icon(
          //             FluentIcons.flash_off_24_regular,
          //             color: Colors.grey,
          //           );
          //         case TorchState.on:
          //           return const Icon(
          //             FluentIcons.flash_24_regular,
          //             color: Colors.yellow,
          //           );
          //       }
          //     },
          //   ),
          //   tooltip: t.profile.add.qrScanner.torchSemanticLabel,
          //   onPressed: () => controller.toggleTorch(),
          // ),
          IconButton(
            icon: const Icon(FluentIcons.camera_switch_24_regular),
            tooltip: t.profile.add.qrScanner.facingSemanticLabel,
            onPressed: () => controller.switchCamera(),
          ),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: controller,
            onDetect: (capture) {
              final rawData = capture.barcodes.first.rawValue;
              loggy.debug('captured raw: [$rawData]');
              if (rawData != null) {
                final uri = Uri.tryParse(rawData);
                if (context.mounted && uri != null) {
                  loggy.debug('captured url: [$uri]');
                  Navigator.of(context, rootNavigator: true).pop(uri.toString());
                }
              } else {
                loggy.warning("unable to capture");
              }
            },
            errorBuilder: (_, error, __) {
              final message = switch (error.errorCode) {
                MobileScannerErrorCode.permissionDenied => t.profile.add.qrScanner.permissionDeniedError,
                _ => t.profile.add.qrScanner.unexpectedError,
              };

              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(bottom: 8),
                      child: Icon(
                        FluentIcons.error_circle_24_regular,
                        color: Colors.white,
                      ),
                    ),
                    Text(message),
                    Text(error.errorDetails?.message ?? ''),
                  ],
                ),
              );
            },
          ),
          if (started)
            CustomPaint(
              painter: ScannerOverlay(
                Rect.fromCenter(
                  center: size.center(Offset.zero),
                  width: overlaySize,
                  height: overlaySize,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPermissionDeniedUI(BuildContext context, Translations t) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        iconTheme: Theme.of(context).iconTheme.copyWith(
              color: Colors.white,
              size: 32,
            ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(t.profile.add.qrScanner.permissionDeniedError),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => openAppSettings(),
              child: const Text("设置"),
            ),
          ],
        ),
      ),
    );
  }
}

class ScannerOverlay extends CustomPainter {
  ScannerOverlay(this.scanWindow);

  final Rect scanWindow;
  final double borderRadius = 12.0;

  @override
  void paint(Canvas canvas, Size size) {
    final backgroundPath = Path()..addRect(Rect.largest);
    final cutoutPath = Path()
      ..addRRect(
        RRect.fromRectAndCorners(
          scanWindow,
          topLeft: Radius.circular(borderRadius),
          topRight: Radius.circular(borderRadius),
          bottomLeft: Radius.circular(borderRadius),
          bottomRight: Radius.circular(borderRadius),
        ),
      );

    final backgroundPaint = Paint()
      ..color = Colors.black.withOpacity(0.5)
      ..style = PaintingStyle.fill
      ..blendMode = BlendMode.dstOut;

    final backgroundWithCutout = Path.combine(
      PathOperation.difference,
      backgroundPath,
      cutoutPath,
    );

    final borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;

    final borderRect = RRect.fromRectAndCorners(
      scanWindow,
      topLeft: Radius.circular(borderRadius),
      topRight: Radius.circular(borderRadius),
      bottomLeft: Radius.circular(borderRadius),
      bottomRight: Radius.circular(borderRadius),
    );

    canvas.drawPath(backgroundWithCutout, backgroundPaint);
    canvas.drawRRect(borderRect, borderPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}
