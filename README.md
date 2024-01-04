# Image Selector plugin for Flutter
<?code-excerpt path-base="example/lib"?>

[![pub package](https://img.shields.io/badge/image_selector-plugin_dev)](https://pub.dev/packages/image_selector)

A Flutter plugin for Android for picking images from the image library,
and taking new pictures with the camera.

|             | Android 
|-------------|--------|

## Installation

First, add `image_selector` as a
[dependency in your pubspec.yaml file](https://flutter.dev/docs/development/platform-integration/platform-channels).

### Android

No configuration required.

### Example

<?code-excerpt "readme_excerpts.dart (Pick)"?>
```dart
File? file;
final ImagePicker picker = ImagePicker();
// Pick an image.
  pickImage(ImageFrom source) async {
    ImageSelector imageSelector = ImageSelector();
    await imageSelector.pickImage(context: context, source: source).then((pickedFile) {
      if (pickedFile != null) {
        setState(() {
          file = pickedFile;
        });
     
      }
    });
  }
```
