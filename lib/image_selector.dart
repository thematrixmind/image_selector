import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_select/camera_image_pick.dart';
import 'package:path_provider/path_provider.dart';

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

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'appbar_color': appbarColor?.value,
      'text_style': textStyle != null
          ? {
              'font_size': textStyle?.fontSize,
              'color': textStyle?.color?.value,
              // Add more TextStyle properties here if necessary
            }
          : null,
      'icon_theme': iconTheme != null
          ? {
              'color': iconTheme?.color?.value,
              'size': iconTheme?.size,
              // Add more IconThemeData properties here if necessary
            }
          : null,
      'initial_camera_side': initialCameraSide?.name,
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
    cameraUiSettings?.initialCameraSide ??= CameraSide.back;

    try {
      if (source == ImageFrom.camera) {
        debugPrint("This is camera settings: ${cameraUiSettings?.toJson()}");

        file = await Navigator.push(
          context,
          CupertinoPageRoute(
            builder: (context) => CameraPlugin(cameraUiSettings: cameraUiSettings),
          ),
        );
      } else {
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
          debugPrint('Before Compress: $sizeInKbBeforeCompression KB');

          file = await compress(image: file!, compressParams: compressParams ?? defaultCompress);

          final sizeInKbAfterCompression = file!.lengthSync() / 1024;
          debugPrint('After Compress: $sizeInKbAfterCompression KB');
        }
      }

      return file;
    } catch (e) {
      debugPrint('Error picking image: ${e.toString()}');
      return null;
    }
  }

  static Future<File?> compress({
    required File image,
    CompressParams compressParams = defaultCompress,
  }) async {
    var dir = await getTemporaryDirectory();
    var targetPath = '${dir.path}/compressed_${DateTime.now().millisecondsSinceEpoch}.jpg';

    var compressedFile = await FlutterImageCompress.compressAndGetFile(
      image.absolute.path,
      targetPath,
      quality: compressParams.quality,
      minHeight: compressParams.targetHeight,
      minWidth: compressParams.targetWidth,
    );

    if (compressedFile == null) {
      debugPrint('Compression failed');
      return null;
    }

    return File(compressedFile.path);
  }

  static const CompressParams defaultCompress = CompressParams(70, 1080, 1920); // Defaults for HD
}

class CompressParams {
  const CompressParams(this.quality, this.targetWidth, this.targetHeight);

  final int quality;
  final int targetWidth;
  final int targetHeight;
}

enum CameraSide {
  front,
  back
}
