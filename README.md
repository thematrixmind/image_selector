# The Image Select Maestro 🌈✨

[![pub package](https://img.shields.io/pub/v/image_select?label=image_select&color=blue)](https://pub.dev/packages/image_select)

Welcome to the enchanting realm of the Image Picker Maestro! 🎩✨ This Flutter wizardry has been meticulously crafted by weaving together the enchantments of three magical plugins: `image_picker`, `camera`, and `flutter_native_image`.

Bid farewell to mundane and crash-prone experiences, as our Image Selector plugin ensures a seamless journey across all devices, leaving you spellbound with its flawless performance!

## Installation Magic 🪄

Sprinkle the magic potion into your `pubspec.yaml` file, and witness the wonders of `image_select`. [Tap here to cast the spell](https://flutter.dev/docs/development/platform-integration/platform-channels)!

```yaml
dependencies:
  image_select: ^0.0.3 
```

## Compress Images 🌄

Behold the power of image compression! Now, you can select and compress images effortlessly using this single magical package. How enchanting!

### Android Incantation 🤖

No need for extra runes or secret scrolls. Android bows before the might of this enchantment with no additional configurations needed.

## Camera Features 📸

### Mirrored Front Camera

Experience a captivating camera interface! The front camera now features a mirrored effect for a more natural self-portrait experience.

## Example Spellcasting 🪄

```dart
import 'package:flutter/material.dart';
import 'package:image_select/image_select.dart';

File? file;

CameraUiSettings cameraUiSettings = CameraUiSettings(
  appbarColor: Colors.teal,
  iconTheme: const IconThemeData(color: Colors.white),
  title: 'Shoot the Image',
  textStyle: const TextStyle(
    color: Colors.white,
  ),
  initialCameraSide: CameraSide.back,
);

pickImage(ImageFrom source) async {
  debugPrint(cameraUiSettings.toJson().toString());
  ImageSelect imageSelector = ImageSelect(cameraUiSettings: cameraUiSettings, compressImage: true);
  await imageSelector.pickImage(context: context, source: source).then((pickedFile) {
    if (pickedFile != null) {
      setState(() {
        file = pickedFile;
      });
      Navigator.pop(context);
    }
  });
}
```

## Contribution 👐

We welcome contributions from fellow wizards! Feel free to submit issues and pull requests to enhance the enchantment of this package.

## License 📜

This package is licensed under the [MIT License](LICENSE).
