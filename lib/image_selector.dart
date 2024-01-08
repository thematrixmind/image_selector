library image_selector;

import 'dart:io';
import 'package:flutter/cupertino.dart';
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
  });
  String? title;
  Color? appbarColor;
  TextStyle? textStyle;

  IconThemeData? iconTheme;

  toJson() {
    return {
      'title': title,
      'appbar_color': appbarColor,
      'text_style': textStyle,
      'icon_theme': iconTheme,
    };
  }
}

class ImageSelect {
  ImageSelect({this.cameraUiSettings});
  CameraUiSettings? cameraUiSettings;
  Future<File?> pickImage({required BuildContext context, required ImageFrom source}) async {
    try {
      if (source == ImageFrom.camera) {
        debugPrint("This is camera settings : ${cameraUiSettings?.toJson()}");

        File file = await Navigator.push(
          context,
          CupertinoPageRoute(
            builder: (context) => CameraPlugin(
              cameraUiSettings: cameraUiSettings,
            ),
          ),
        );
        return file;
      } else {
        // Use the image_picker package to pick an image from the gallery
        final imagePicker = ImagePicker();
        final pickedFile = await imagePicker.pickImage(source: ImageSource.gallery);

        if (pickedFile != null) {
          debugPrint('Image picked successfully: ${pickedFile.path}');
          return File(pickedFile.path);
        } else {
          debugPrint('User canceled image picking');
          return null;
        }
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
      return null;
    }
  }
}
