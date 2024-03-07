library image_selector;

import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter_native_image/flutter_native_image.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_select/camera_image_pick.dart';

enum ImageFrom {
  camera,
  gallery
}

class CameraUiSettings {
  CameraUiSettings({
    this.appbarColor,
    this.textStyle,
    this.title,
    this.iconTheme,
    this.initialCameraSide,
  });
  String? title;
  Color? appbarColor;
  TextStyle? textStyle;
  CameraSide? initialCameraSide;
  IconThemeData? iconTheme;

  toJson() {
    return {
      'title': title,
      'appbar_color': appbarColor,
      'text_style': textStyle,
      'icon_theme': iconTheme,
      'initial_camera_side': initialCameraSide!.name
    };
  }
}

class ImageSelect {
  ImageSelect({
    this.cameraUiSettings,
    this.compressImage = false,
    this.compressParams,
    this.compressOnlyForCamera = false,
  });
  CameraUiSettings? cameraUiSettings;

  final bool compressImage;
  final bool compressOnlyForCamera;
  final CompressParams? compressParams;

  File? file;
  Future<File?> pickImage({required BuildContext context, required ImageFrom source}) async {
    cameraUiSettings?.initialCameraSide = CameraSide.back;
    try {
      if (source == ImageFrom.camera) {
        debugPrint("This is camera settings : ${cameraUiSettings?.toJson()}");

        file = await Navigator.push(
          context,
          CupertinoPageRoute(
            builder: (context) => CameraPlugin(
              cameraUiSettings: cameraUiSettings,
            ),
          ),
        );
      } else {
        // Use the image_picker package to pick an image from the gallery
        final imagePicker = ImagePicker();
        final pickedFile = await imagePicker.pickImage(source: ImageSource.gallery);

        if (pickedFile != null) {
          debugPrint('Image picked successfully: ${pickedFile.path}');
          file = File(pickedFile.path);
        } else {
          debugPrint('User canceled image picking');
        }
      }

      if (compressImage && file != null) {
        if (!compressOnlyForCamera || (compressOnlyForCamera && source == ImageFrom.camera)) {
          final sizeInKbBeforeCompression = file!.lengthSync() / 1024;
          debugPrint('Before Compress $sizeInKbBeforeCompression kb');
          file = await compress(image: file!);
          final sizeInKbAfterCompression = file!.lengthSync() / 1024;
          debugPrint('After Compress $sizeInKbAfterCompression kb');
        }
      }

      return file;
    } catch (e) {
      debugPrint('Error picking image: $e');
      return file;
    }
  }

  static Future<File> compress({required File image, CompressParams compressParams = defaultCompress}) async {
    var file = await FlutterNativeImage.compressImage(
      image.absolute.path,
      quality: compressParams.quality,
      percentage: compressParams.percentage,
      targetHeight: compressParams.targetHeight,
      targetWidth: compressParams.targetWidth,
    );
    return file;
  }

  // default configuration for compressing images
  static const CompressParams defaultCompress = CompressParams(70, 70, 0, 0);
}

class CompressParams {
  const CompressParams(
    this.percentage,
    this.quality,
    this.targetHeight,
    this.targetWidth,
  );
  final int percentage;
  final int quality;
  final int targetWidth;
  final int targetHeight;
}

enum CameraSide {
  front,
  back
}
