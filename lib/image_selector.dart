library image_selector;

import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_selector/camera_image_pick.dart';

enum ImageFrom {
  camera,
  gallery
}

class ImageSelector {
  Future<File?> pickImage({required BuildContext context, required ImageFrom source}) async {
    try {
      if (source == ImageFrom.camera) {
        // Navigate to the custom camera plugin for capturing images
        File file = await Navigator.push(context, CupertinoPageRoute(builder: (context) => const CameraPlugin()));
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
          return null; // User canceled image picking
        }
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
      return null;
    }
  }
}
