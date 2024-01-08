import 'dart:developer';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:image_select/image_selector.dart';

class CameraPlugin extends StatefulWidget {
  const CameraPlugin({Key? key, this.cameraUiSettings}) : super(key: key);

  final CameraUiSettings? cameraUiSettings;
  @override
  _CameraPluginState createState() => _CameraPluginState();
}

late List<CameraDescription> cameras;

class _CameraPluginState extends State<CameraPlugin> with WidgetsBindingObserver {
  CameraController? controller;
  Future<void>? _initializeControllerFuture;
  String? imagePath;

  @override
  void initState() {
    WidgetsBinding.instance.addObserver(this);
    super.initState();
    initializeCamera();
  }

  void initializeCamera() async {
    cameras = await availableCameras();
    log(cameras.toString());

    CameraDescription frontCamera = cameras.firstWhere(
      (camera) => camera.lensDirection == CameraLensDirection.front,
      orElse: () => cameras[0],
    );

    if (controller != null) {
      await controller!.dispose();
    }

    controller = CameraController(frontCamera, ResolutionPreset.max);

    try {
      await controller!.initialize();
    } catch (e) {
      debugPrint('Error initializing camera: $e');
    }

    if (mounted) {
      setState(() {
        _initializeControllerFuture = controller!.initialize();
      });
    }
  }

  @override
  void dispose() {
    // Dispose of the controller when the widget is disposed.
    WidgetsBinding.instance.removeObserver(this);
    controller!.dispose();
    super.dispose();
  }

  bool hasBackCamera() {
    return controller != null && controller!.description.lensDirection == CameraLensDirection.back;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      controller!.dispose();
    } else if (state == AppLifecycleState.resumed) {
      setState(() {
        controller = CameraController(cameras[0], ResolutionPreset.max);
        _initializeControllerFuture = controller!.initialize();
      });
    }
  }

  Future<void> captureImage(BuildContext context) async {
    if (controller == null) return;
    CustomLoader.show(context, text: 'Capturing image');
    final pictureFile = await controller!.takePicture();
    CustomLoader.hide(context);
    final file = File(pictureFile.path);

    Navigator.pop(context, file);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        elevation: 0,
        iconTheme: widget.cameraUiSettings?.iconTheme,
        backgroundColor: widget.cameraUiSettings?.appbarColor ?? Theme.of(context).appBarTheme.backgroundColor,
        title: Text(widget.cameraUiSettings?.title ?? 'Capture Image'),
        titleTextStyle: widget.cameraUiSettings?.textStyle ?? Theme.of(context).appBarTheme.titleTextStyle,
      ),
      body: FutureBuilder(
        future: _initializeControllerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            return Column(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: <Widget>[
                SizedBox(
                  width: double.infinity,
                  height: MediaQuery.of(context).size.height * 0.6,
                  child: CameraPreview(controller!),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(),
                    InkWell(
                      onTap: () {
                        captureImage(context);
                      },
                      child: const Icon(
                        Icons.circle,
                        color: Colors.white,
                        size: 85,
                      ),
                    ),
                    IconButton(
                      onPressed: () async {
                        if (controller != null) {
                          // Dispose the existing controller
                          await controller!.dispose();

                          // Switch to the front camera if available, otherwise use the back camera
                          CameraDescription newCamera = cameras.firstWhere(
                            (camera) => camera.lensDirection == (controller!.description.lensDirection == CameraLensDirection.front ? CameraLensDirection.back : CameraLensDirection.front),
                            orElse: () => cameras.first,
                          );

                          // Create a new controller with the selected camera
                          controller = CameraController(
                            newCamera,
                            ResolutionPreset.medium,
                          );

                          // Reinitialize the controller
                          await controller!.initialize();

                          // Update the widget state
                          setState(() {
                            _initializeControllerFuture = controller!.initialize();
                          });
                        }
                      },
                      icon: const Icon(
                        Icons.switch_camera,
                        color: Colors.white,
                      ),
                    )
                  ],
                )
              ],
            );
          } else {
            return const ProgressBar(
              color: Colors.white,
            );
          }
        },
      ),
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
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => LoadingDialog(text: text),
    );
  }

  static void hide(BuildContext context) {
    Navigator.of(context).pop();
  }
}
