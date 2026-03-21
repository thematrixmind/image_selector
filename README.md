# image_select

[![pub package](https://img.shields.io/pub/v/image_select?label=image_select&color=blue)](https://pub.dev/packages/image_select)

Flutter helpers for **choosing images** (gallery or in-app camera), **optional processing** (resize, JPEG output, EXIF orientation), and **optional add-ons** (crop, multi-select modes, video, Android result recovery).

**Stack:** [`image_picker`](https://pub.dev/packages/image_picker) · [`camera`](https://pub.dev/packages/camera) · [`flutter_image_compress`](https://pub.dev/packages/flutter_image_compress) · [`path_provider`](https://pub.dev/packages/path_provider) · optional [`image_cropper`](https://pub.dev/packages/image_cropper) · [`video_compress`](https://pub.dev/packages/video_compress) · [`file_picker`](https://pub.dev/packages/file_picker)

---

## Feature highlights

### Image picking & camera

| Highlight | What you get |
|-----------|----------------|
| **Single image** | Gallery (`ImageSource.gallery`) or full-screen **in-app camera** with AppBar theming. |
| **Camera UI** | `CameraUiSettings`: title, colors, text/icon theme, **front/back** lens, **mirrored** front preview. |
| **Flow order** | Pick → optional **crop** → optional **compress** (when enabled). |

### Image processing & formats

| Highlight | What you get |
|-----------|----------------|
| **HEIC → JPEG (and similar)** | With **`compressImage: true`** and default **`CompressParams`**, output uses **`CompressFormat.jpeg`**. [`flutter_image_compress`](https://pub.dev/packages/flutter_image_compress) decodes the picked file (including **HEIC** on iOS when supported) and writes a **`.jpg`** — good for backends that only accept JPEG. |
| **EXIF orientation** | **`autoCorrectionAngle`** (default `true`) bakes correct upright pixels into the output (typical Android gallery issue). |
| **Resize & quality** | **`quality`**, **`targetWidth`**, **`targetHeight`** map to the compressor’s min dimensions / quality. |
| **Metadata** | **`keepExif`** (default `false`) — strip or keep embedded EXIF in the output. |
| **Other formats** | Set **`CompressParams.format`** to PNG, WebP, or HEIC if you need a non-JPEG pipeline. |
| **Standalone compress** | **`ImageSelect.compress(File, …)`** for files you already have (no picker). |

> **Note:** If **`compressImage: false`**, the file keeps the **original type** from the picker (e.g. **HEIC** on iOS). Enable compression when you want **normalized JPEG** uploads.

### Multi-select

| Highlight | What you get |
|-----------|----------------|
| **`pickMultiImages`** | Returns **`List<File>`**. Uses **`ImagePicker.pickMultiImage`** by default; can use **`file_picker`** when configured (see below). |
| **`pickMultiImagesAsXFiles`** | Returns **`List<XFile>`** — paths or **bytes** (web-friendly, in-memory). |
| **`file_picker` path** | With **`ImageSelectFeatureConfig.webFilePicker`** (`WebFilePickerFeatureConfig`), multi-select can go through **`FilePicker.platform.pickFiles`** where supported (web/desktop emphasis; see source docs). |
| **Per-file compress** | With **`compressImage: true`**, each selected image can be run through the same **`CompressParams`**. |

### Optional native add-ons (`ImageSelectFeatureConfig`)

Pass **`features:`** only for what you need; **`null`** keeps the smallest behavior (no crop / no video helpers / default multi picker).

| Add-on | Config | Purpose |
|--------|--------|---------|
| **Crop** | `CropFeatureConfig` | **[image_cropper](https://pub.dev/packages/image_cropper)** after a successful **single** `pickImage`. Requires [Android UCrop](#android-ucrop-for-crop) + upstream iOS/Web setup. |
| **Video** | `VideoFeatureConfig` | **`pickVideo`**, **`pickVideoFromGallery`**, **`pickVideoFromCamera`** + optional **`video_compress`**. Not aimed at **web**. |
| **Multi via file picker** | `WebFilePickerFeatureConfig` | Toggle **`file_picker`** for multi flows (see `pickMultiImages` / `pickMultiImagesAsXFiles` in code). |

### Android: recover lost pick

| Highlight | What you get |
|-----------|----------------|
| **`ImageSelect.retrieveLostData()`** | Wraps **`ImagePicker.retrieveLostData`** on **Android** when the activity was destroyed (e.g. low memory). Returns **`LostDataResponse`**; no-op / empty on other platforms. Call after **`WidgetsFlutterBinding.ensureInitialized()`** (e.g. `initState`). |

---

## Installation

```yaml
dependencies:
  image_select: ^0.0.6
```

```bash
flutter pub get
```

### Platform requirements

| Platform | Notes |
|----------|--------|
| **iOS** | Photo library / camera **usage descriptions** in `Info.plist` (see `image_picker` & `camera`). |
| **Android** | Use a current Flutter template (**Java 17**, recent AGP/Gradle). |
| **Web** | Camera and file APIs are limited; **`File`**-centric APIs target **mobile/desktop** first. |

### Android: UCrop (for crop)

If you enable **`CropFeatureConfig`**, add **UCropActivity** inside `<application>` in `android/app/src/main/AndroidManifest.xml`:

```xml
<activity
    android:name="com.yalantis.ucrop.UCropActivity"
    android:screenOrientation="portrait"
    android:theme="@style/Theme.AppCompat.Light.NoActionBar"/>
```

Full details: [image_cropper — Installing](https://pub.dev/packages/image_cropper).

---

## Core API (quick reference)

### `ImageSelect`

```dart
ImageSelect({
  CameraUiSettings? cameraUiSettings,
  bool compressImage = false,
  CompressParams? compressParams,
  bool compressOnlyForCamera = false,
  ImageSelectFeatureConfig? features,
});
```

| Method | Role |
|--------|------|
| **`pickImage`** | One image from **camera** or **gallery**. |
| **`pickMultiImages`** | Multiple images; optional **`file_picker`** via **`features.webFilePicker`**. |
| **`pickMultiImagesAsXFiles`** | Same idea, **`List<XFile>`**. |
| **`pickVideo`**, **`pickVideoFromGallery`**, **`pickVideoFromCamera`** | Need **`features.video`**; uses **`video_compress`** when configured. |

### `CameraUiSettings`

App bar **title**, **colors**, **textStyle**, **iconTheme**, **`initialCameraSide`** (`CameraSide.front` / `CameraSide.back`).

### `CompressParams`

| Field | Typical use |
|-------|-------------|
| **`quality`**, **`targetWidth`**, **`targetHeight`** | Resize / quality. |
| **`format`** | Default **`CompressFormat.jpeg`** → **HEIC/WebP/PNG in → JPEG out** when compressing. |
| **`autoCorrectionAngle`** | Default **`true`** — fix orientation from EXIF. |
| **`keepExif`** | Default **`false`** — privacy-friendly uploads. |

### Static helpers

- **`ImageSelect.compress`** — compress any **`File`**.
- **`ImageSelect.retrieveLostData`** — Android recovery only.

---

## Exports

Re-exports include **`XFile`**, **`LostDataResponse`**, **`RetrieveType`** (from `image_picker`), crop types (**`CropStyle`**, **`CropAspectRatioPreset`**, …), **`VideoQuality`**, and **`feature_config.dart`**.

---

## Example

Run the [`example/`](example/) app: single/multi pick, optional crop flag, errors, Android recovery.

```dart
import 'package:image_select/image_selector.dart';

final selector = ImageSelect(
  cameraUiSettings: CameraUiSettings(
    title: 'Take a photo',
    initialCameraSide: CameraSide.back,
  ),
  compressImage: true, // HEIC etc. → JPEG with default CompressParams
);

final file = await selector.pickImage(
  context: context,
  source: ImageFrom.gallery,
);
```

---

## Contributing

Issues and pull requests are welcome.

## License

[MIT License](LICENSE).
