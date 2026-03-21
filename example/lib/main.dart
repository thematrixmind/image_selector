// Copyright (c) example app for package:image_select — see /README.md for full feature list.
//
// =============================================================================
// FEATURE MAP (this file)
// =============================================================================
//
// | Feature                    | Where in this file                                      |
// |----------------------------|---------------------------------------------------------|
// | Cold start / Android       | [main], [_recoverAndroidPickIfNeeded]                   |
// | Themed in-app camera       | [_cameraUi], [_pickSingle(ImageFrom.camera)]           |
// | Gallery single image       | [_pickSingle(ImageFrom.gallery)]                       |
// | JPEG compress + HEIC→JPEG  | [_selectorForSinglePick], [_pickMultiFromGallery]     |
// | Multi gallery pick         | [_pickMultiFromGallery]                                 |
// | Optional crop (image_crop)| [_enableCropDemo], [_selectorForSinglePick]             |
//
// Not wired to buttons here (copy from comments below): pickMultiImagesAsXFiles, pickVideo,
// WebFilePickerFeatureConfig, custom CompressParams, compressOnlyForCamera.
//
// =============================================================================

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_select/image_selector.dart';

/// Required if you call [ImageSelect.retrieveLostData] on Android (e.g. in [HomePage.initState]).
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ExampleApp());
}

/// Root widget — no package features beyond hosting [HomePage].
class ExampleApp extends StatelessWidget {
  const ExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'image_select example',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}

/// Example screen demonstrating [image_select] APIs.
///
/// **Implemented in UI**
/// - [ImageSelect.pickImage] — camera ([ImageFrom.camera]) and gallery ([ImageFrom.gallery])
/// - [ImageSelect.pickMultiImages] — multiple photos, with [compressImage] and [maxImages]
/// - [CameraUiSettings] — toolbar look + [CameraSide] for first lens
/// - [CompressParams] defaults via `compressImage: true` (HEIC/WebP → JPEG on iOS when compressing)
/// - [ImageSelectFeatureConfig] + [CropFeatureConfig] — optional; toggle [_enableCropDemo]
/// - [ImageSelect.retrieveLostData] — Android only; restore pick after activity death
///
/// **Comment-only examples** at bottom of this file: video, [XFile] multi, [file_picker] config.
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  /// [pickMultiImages] / sheet: max count forwarded to the platform picker (`limit`).
  static const int _kMaxMultiPick = 8;

  /// **Crop feature** — set `true` only after Android `UCropActivity` + [image_cropper] docs.
  ///
  /// Example:
  /// ```dart
  /// features: ImageSelectFeatureConfig(
  ///   crop: CropFeatureConfig(enabled: true, cropStyle: CropStyle.circle),
  /// ),
  /// ```
  static const bool _enableCropDemo = false;

  File? _previewFile;
  List<File> _multiSelection = [];

  /// **CameraUiSettings** — AppBar title/colors, [CameraSide.back] = first lens after open.
  ///
  /// Example variants:
  /// ```dart
  /// CameraUiSettings(
  ///   title: 'ID Photo',
  ///   initialCameraSide: CameraSide.front,
  ///   appbarColor: Colors.black,
  ///   textStyle: TextStyle(color: Colors.white),
  ///   iconTheme: IconThemeData(color: Colors.white),
  /// )
  /// ```
  final _cameraUi = CameraUiSettings(
    appbarColor: Colors.teal,
    iconTheme: IconThemeData(color: Colors.white),
    title: 'Shoot the Image',
    textStyle: TextStyle(color: Colors.white),
    initialCameraSide: CameraSide.back,
  );

  @override
  void initState() {
    super.initState();
    // -------------------------------------------------------------------------
    // Feature: Android — [ImageSelect.retrieveLostData]
    // -------------------------------------------------------------------------
    // If the system killed MainActivity while the gallery/camera was open, the
    // previous pick may be returned here after restart. iOS/web: empty response.
    //
    // Example (already in app lifecycle):
    //   final lost = await ImageSelect.retrieveLostData();
    //   if (!lost.isEmpty && lost.file != null) { ... use File(lost.file!.path) }
    // -------------------------------------------------------------------------
    _recoverAndroidPickIfNeeded();
  }

  Future<void> _recoverAndroidPickIfNeeded() async {
    try {
      final lost = await ImageSelect.retrieveLostData();
      if (lost.isEmpty) return;

      if (lost.files != null && lost.files!.isNotEmpty) {
        _applySelection(
          files: lost.files!.map((x) => File(x.path)).toList(),
          snackbar: 'Recovered multi selection after activity restart.',
        );
      } else if (lost.file != null) {
        _applySelection(
          files: [File(lost.file!.path)],
          snackbar: 'Recovered image after activity restart.',
        );
      }
    } catch (e, st) {
      debugPrint('retrieveLostData: $e\n$st');
    }
  }

  void _applySelection({required List<File> files, String? snackbar}) {
    if (!mounted) return;
    setState(() {
      _multiSelection = files;
      _previewFile = files.isNotEmpty ? files.first : null;
    });
    if (snackbar != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(snackbar)));
    }
  }

  void _showError(Object error) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error: $error')),
    );
  }

  // ---------------------------------------------------------------------------
  // Feature: [ImageSelect] for single pick — camera UI + compress + optional crop
  // ---------------------------------------------------------------------------
  // - [compressImage: true] — runs [ImageSelect.compress] with default [CompressParams]
  //   (JPEG output → good for HEIC from iOS gallery → `.jpg` for APIs that need JPEG).
  // - [compressOnlyForCamera: true] — if set, only camera shots are compressed, not gallery.
  // - [features.crop] — after pick, opens image_cropper when enabled.
  //
  // Example minimal single pick (no crop):
  //   await ImageSelect(compressImage: true).pickImage(
  //     context: context,
  //     source: ImageFrom.gallery,
  //   );
  // ---------------------------------------------------------------------------

  ImageSelect _selectorForSinglePick() {
    return ImageSelect(
      cameraUiSettings: _cameraUi,
      compressImage: true,
      features: _enableCropDemo
          ? ImageSelectFeatureConfig(
              crop: CropFeatureConfig(
                enabled: true,
                cropStyle: CropStyle.rectangle,
              ),
            )
          : null,
    );
  }

  // ---------------------------------------------------------------------------
  // Feature: [ImageSelect.pickImage] — one file from camera OR gallery
  // ---------------------------------------------------------------------------
  // - [ImageFrom.camera] — pushes package camera page ([CameraPlugin]).
  // - [ImageFrom.gallery] — system photo picker ([ImagePicker.pickImage]).
  // ---------------------------------------------------------------------------

  Future<void> _pickSingle(ImageFrom source) async {
    final selector = _selectorForSinglePick();
    try {
      final result = await selector.pickImage(context: context, source: source);
      if (!mounted || result == null) return;
      setState(() {
        _previewFile = result;
        _multiSelection = [];
      });
    } catch (e, st) {
      debugPrint('pickImage: $e\n$st');
      _showError(e);
    }
  }

  // ---------------------------------------------------------------------------
  // Feature: [ImageSelect.pickMultiImages] — several images + per-file compress
  // ---------------------------------------------------------------------------
  // Uses [ImagePicker.pickMultiImage] unless you pass
  // [ImageSelectFeatureConfig.webFilePicker] (then may use file_picker on some platforms).
  //
  // Example:
  //   await ImageSelect(compressImage: true, compressParams: CompressParams(80, 1920, 1080))
  //       .pickMultiImages(context: context, maxImages: 10);
  // ---------------------------------------------------------------------------

  Future<void> _pickMultiFromGallery() async {
    final selector = ImageSelect(compressImage: true);
    try {
      final list = await selector.pickMultiImages(
        context: context,
        maxImages: _kMaxMultiPick,
      );
      if (!mounted) return;
      setState(() {
        _multiSelection = list;
        _previewFile = list.isNotEmpty ? list.first : null;
      });
    } catch (e, st) {
      debugPrint('pickMultiImages: $e\n$st');
      _showError(e);
    }
  }

  // ---------------------------------------------------------------------------
  // UI: bottom sheet — wires the three flows above
  // ---------------------------------------------------------------------------

  Future<void> _openSourceSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        Future<void> closeAnd(Future<void> Function() fn) async {
          Navigator.of(sheetContext).pop();
          await Future<void>.delayed(Duration.zero);
          if (!mounted) return;
          await fn();
        }

        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_camera_outlined),
                title: const Text('Camera'),
                onTap: () => closeAnd(() => _pickSingle(ImageFrom.camera)),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: const Text('Gallery (one image)'),
                onTap: () => closeAnd(() => _pickSingle(ImageFrom.gallery)),
              ),
              ListTile(
                leading: const Icon(Icons.collections_outlined),
                title: Text('Gallery (up to $_kMaxMultiPick images)'),
                onTap: () => closeAnd(_pickMultiFromGallery),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('image_select'),
        backgroundColor: theme.colorScheme.inversePrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: AspectRatio(
                  aspectRatio: 3 / 4,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: _previewFile != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.file(
                              _previewFile!,
                              fit: BoxFit.contain,
                            ),
                          )
                        : Center(
                            child: Text(
                              'No image yet',
                              style: theme.textTheme.bodyLarge?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                  ),
                ),
              ),
            ),
            if (_multiSelection.length > 1)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  '${_multiSelection.length} images selected',
                  style: theme.textTheme.bodyMedium,
                ),
              ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _openSourceSheet,
              icon: const Icon(Icons.add_photo_alternate_outlined),
              label: const Text('Choose image source'),
            ),
            const SizedBox(height: 8),
            Text(
              _enableCropDemo
                  ? 'Crop demo is ON (requires image_cropper native setup).'
                  : 'Crop demo is OFF — enable `_enableCropDemo` in main.dart to try image_cropper.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// More examples (not hooked to this UI — paste into your code as needed)
// =============================================================================
//
// --- [ImageSelect.pickMultiImagesAsXFiles] — returns List<XFile> (web-friendly) ---
//
//   final xs = await ImageSelect(
//     features: ImageSelectFeatureConfig(
//       webFilePicker: WebFilePickerFeatureConfig(
//         enabled: true,
//         useFilePickerForMultiPick: true,
//         withData: true,
//       ),
//     ),
//   ).pickMultiImagesAsXFiles(maxImages: 10);
//
// --- Video pick + optional [video_compress] ---
//
//   final videoFile = await ImageSelect(
//     features: ImageSelectFeatureConfig(
//       video: VideoFeatureConfig(
//         enabled: true,
//         compressAfterPick: true,
//         quality: VideoQuality.Res1280x720Quality,
//       ),
//     ),
//   ).pickVideo(source: ImageFrom.gallery);
//
// --- Compress an existing file (no picker) ---
//
//   final out = await ImageSelect.compress(
//     image: File('/path/in.heic'),
//     compressParams: CompressParams(85, 1920, 1080, format: CompressFormat.jpeg),
//   );
//
// =============================================================================
