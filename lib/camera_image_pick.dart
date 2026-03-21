import 'dart:developer';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:image_select/image_selector.dart';

class CameraPlugin extends StatefulWidget {
  const CameraPlugin({super.key, this.cameraUiSettings});

  final CameraUiSettings? cameraUiSettings;

  @override
  State<CameraPlugin> createState() => _CameraPluginState();
}

class _CameraPluginState extends State<CameraPlugin> with WidgetsBindingObserver {
  static const ResolutionPreset _kResolution = ResolutionPreset.max;

  List<CameraDescription> _cameras = [];
  CameraController? controller;

  /// Last lens the user had active — restored after app pause/resume (e.g. phone call).
  CameraDescription? _lastCameraDescription;

  bool _bootstrapDone = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _bootstrap();
  }

  CameraDescription _cameraForInitialSide() {
    final wantFront = widget.cameraUiSettings?.initialCameraSide == CameraSide.front;
    return _cameras.firstWhere(
      (c) => c.lensDirection == (wantFront ? CameraLensDirection.front : CameraLensDirection.back),
      orElse: () => _cameras.first,
    );
  }

  Future<void> _bootstrap() async {
    try {
      _cameras = await availableCameras();
      log(_cameras.toString());
    } catch (e, st) {
      debugPrint('availableCameras failed: $e\n$st');
      if (mounted) setState(() => _bootstrapDone = true);
      return;
    }
    if (!mounted) return;
    if (_cameras.isEmpty) {
      setState(() => _bootstrapDone = true);
      return;
    }
    await _startCameraController(_cameraForInitialSide());
    if (mounted) setState(() => _bootstrapDone = true);
  }

  Future<void> _startCameraController(CameraDescription description) async {
    await controller?.dispose();
    controller = null;

    final next = CameraController(description, _kResolution);
    controller = next;
    _lastCameraDescription = description;

    try {
      await next.initialize();
    } catch (e, st) {
      debugPrint('Error initializing camera: $e\n$st');
    }

    if (mounted) setState(() {});
  }

  Future<void> _toggleCamera() async {
    if (_cameras.isEmpty || controller == null) return;

    final current = controller!.description;
    final wantLens = current.lensDirection == CameraLensDirection.front
        ? CameraLensDirection.back
        : CameraLensDirection.front;

    final next = _cameras.firstWhere(
      (c) => c.lensDirection == wantLens,
      orElse: () => _cameras.first,
    );

    await _startCameraController(next);
  }

  Future<void> _onResume() async {
    final saved = _lastCameraDescription;
    if (saved == null) return;

    try {
      _cameras = await availableCameras();
    } catch (e) {
      debugPrint('availableCameras on resume failed: $e');
      return;
    }
    if (_cameras.isEmpty || !mounted) return;

    CameraDescription? match;
    for (final c in _cameras) {
      if (c.name == saved.name && c.lensDirection == saved.lensDirection) {
        match = c;
        break;
      }
    }

    await _startCameraController(match ?? _cameras.first);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      controller?.dispose();
      controller = null;
      return;
    }
    if (state == AppLifecycleState.resumed) {
      _onResume();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    controller?.dispose();
    super.dispose();
  }

  Future<void> captureImage(BuildContext context) async {
    if (controller == null || !controller!.value.isInitialized) return;
    CustomLoader.show(context, text: 'Capturing image');
    final pictureFile = await controller!.takePicture();
    if (!context.mounted) return;
    CustomLoader.hide(context);
    final file = File(pictureFile.path);
    Navigator.pop(context, file);
  }

  @override
  Widget build(BuildContext context) {
    Widget body;
    if (!_bootstrapDone && _cameras.isEmpty) {
      body = const ProgressBar(color: Colors.white);
    } else if (_bootstrapDone && _cameras.isEmpty) {
      body = const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'No camera is available on this device.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white70),
          ),
        ),
      );
    } else if (controller == null || !controller!.value.isInitialized) {
      body = const ProgressBar(color: Colors.white);
    } else {
      body = Column(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: <Widget>[
          SizedBox(
            width: double.infinity,
            height: MediaQuery.of(context).size.height * 0.6,
            child: Transform(
              alignment: Alignment.center,
              transform: controller!.description.lensDirection == CameraLensDirection.front
                  ? Matrix4.rotationY(3.14159)
                  : Matrix4.identity(),
              child: CameraPreview(controller!),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(),
              InkWell(
                onTap: () => captureImage(context),
                child: const Icon(
                  Icons.circle,
                  color: Colors.white,
                  size: 85,
                ),
              ),
              IconButton(
                onPressed: _toggleCamera,
                icon: const Icon(
                  Icons.switch_camera,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ],
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        elevation: 0,
        iconTheme: widget.cameraUiSettings?.iconTheme,
        backgroundColor: widget.cameraUiSettings?.appbarColor ?? Theme.of(context).appBarTheme.backgroundColor,
        title: Text(widget.cameraUiSettings?.title ?? 'Capture Image'),
        titleTextStyle: widget.cameraUiSettings?.textStyle ?? Theme.of(context).appBarTheme.titleTextStyle,
      ),
      body: body,
    );
  }
}

class ProgressBar extends StatelessWidget {
  const ProgressBar({super.key, this.color});
  final Color? color;
  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: 100.0,
        height: 100.0,
        child: Center(
          child: SizedBox(
            width: 50.0,
            height: 50.0,
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(color ?? Theme.of(context).primaryColor),
              strokeWidth: 3.0,
            ),
          ),
        ),
      ),
    );
  }
}

class LoadingDialog extends StatelessWidget {
  final String? text;

  const LoadingDialog({super.key, this.text});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 20),
            if (text != null) Text(text!),
          ],
        ),
      ),
    );
  }
}

class CustomLoader {
  static void show(BuildContext context, {String? text}) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => LoadingDialog(text: text),
    );
  }

  static void hide(BuildContext context) {
    Navigator.of(context).pop();
  }
}
