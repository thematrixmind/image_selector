# The Image Picker Maestro 🌈✨

[![pub package](https://img.shields.io/pub/v/image_select?label=image_select&color=blue)](https://pub.dev/packages/image_select)

Welcome to the magical realm of the Image Picker Maestro! 🎩✨ This Flutter wizardry is crafted with the combined enchantments of two spellbinding plugins: `image_picker` and `camera`.

Ditch the dull and crash-prone experiences, for our Image Selector plugin guarantees a smooth journey across all devices without a single hiccup!

## Installation Magic 🪄

Simply sprinkle the magic potion into your `pubspec.yaml` file, and behold the wonders of `image_select`. [Tap here to cast the spell](https://flutter.dev/docs/development/platform-integration/platform-channels)!

### Android Incantation 🤖

No need for extra runes or secret scrolls. Android bows before the power of this enchantment with no extra configurations needed.

## Example Spellcasting 🪄

```dart
import 'package:flutter/material.dart';
import 'package:image_select/image_select.dart';

File? file;

CameraUiSettings cameraUiSettings = CameraUiSettings(
  appbarColor: Colors.teal,
  iconTheme: const IconThemeData(color: Colors.white),
  title: 'Shoot the Image 📷',
  textStyle: const TextStyle(
    color: Colors.white,
  ),
);

pickImage(ImageFrom source) async {
  ImageSelect imageSelector = ImageSelect(cameraUiSettings: cameraUiSettings);
  await imageSelector.pickImage(context: context, source: source).then((pickedFile) {
    if (pickedFile != null) {
      setState(() {
        file = pickedFile;
      });
      Navigator.pop(context);
    }
  });
}
