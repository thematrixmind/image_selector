import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb;
import 'package:flutter/services.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_select/camera_image_pick.dart';
import 'package:image_select/feature_config.dart';
import 'package:path_provider/path_provider.dart';
import 'package:video_compress/video_compress.dart';

export 'package:image_picker/image_picker.dart' show LostDataResponse, RetrieveType, XFile;
export 'package:image_cropper/image_cropper.dart'
    show CropAspectRatioPreset, CropAspectRatioPresetData, CropStyle, ImageCompressFormat;
export 'package:video_compress/video_compress.dart' show VideoQuality;
export 'feature_config.dart';

enum ImageFrom {
  camera,
  gallery,
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
      'appbar_color': appbarColor?.toARGB32(),
      'text_style': textStyle != null
          ? {
              'font_size': textStyle?.fontSize,
              'color': textStyle?.color?.toARGB32(),
            }
          : null,
      'icon_theme': iconTheme != null
          ? {
              'color': iconTheme?.color?.toARGB32(),
              'size': iconTheme?.size,
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
    this.features,
  });

  CameraUiSettings? cameraUiSettings;
  final bool compressImage;
  final bool compressOnlyForCamera;
  final CompressParams? compressParams;

  /// Optional: crop (image_cropper), video (video_compress), file_picker multi (web/desktop).
  /// Leave null to keep behavior identical to older versions (image picker + camera only).
  final ImageSelectFeatureConfig? features;

  /// Last single image from [pickImage], if any.
  File? file;

  /// Last batch from [pickMultiImages], if any.
  List<File>? files;

  /// Last video from [pickVideo] / [pickVideoFromGallery], if any.
  File? videoFile;

  final ImagePicker _picker = ImagePicker();

  Future<File?> pickImage({required BuildContext context, required ImageFrom source}) async {
    cameraUiSettings?.initialCameraSide ??= CameraSide.back;

    try {
      if (source == ImageFrom.camera) {
        debugPrint('Camera settings: ${cameraUiSettings?.toJson()}');

        file = await Navigator.push<File?>(
          context,
          CupertinoPageRoute<File?>(
            builder: (context) => CameraPlugin(cameraUiSettings: cameraUiSettings),
          ),
        );
      } else {
        final pickedFile = await _picker.pickImage(source: ImageSource.gallery);

        if (pickedFile != null) {
          debugPrint('Image picked successfully: ${pickedFile.path}');
          file = File(pickedFile.path);
        } else {
          debugPrint('User canceled image picking');
        }
      }

      if (file != null && features?.crop != null && features!.crop!.enabled) {
        file = await _cropIfNeeded(file!);
      }

      if (compressImage && file != null) {
        if (!compressOnlyForCamera || (compressOnlyForCamera && source == ImageFrom.camera)) {
          final sizeInKbBeforeCompression = file!.lengthSync() / 1024;
          debugPrint('Before compress: $sizeInKbBeforeCompression KB');

          file = await compress(image: file!, compressParams: compressParams ?? defaultCompress);

          if (file != null) {
            final sizeInKbAfterCompression = file!.lengthSync() / 1024;
            debugPrint('After compress: $sizeInKbAfterCompression KB');
          }
        }
      }

      return file;
    } catch (e, st) {
      debugPrint('Error picking image: $e\n$st');
      return null;
    }
  }

  Future<File?> _cropIfNeeded(File input) async {
    final cfg = features?.crop;
    if (cfg == null || !cfg.enabled) return input;

    try {
      final cropped = await ImageCropper().cropImage(
        sourcePath: input.path,
        maxWidth: cfg.maxWidth,
        maxHeight: cfg.maxHeight,
        compressQuality: cfg.compressQuality,
        compressFormat: ImageCompressFormat.jpg,
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: cfg.androidToolbarTitle,
            initAspectRatio: cfg.aspectRatioPresets.isNotEmpty ? cfg.aspectRatioPresets.first : CropAspectRatioPreset.original,
            lockAspectRatio: cfg.lockAspectRatio,
            aspectRatioPresets: cfg.aspectRatioPresets,
            cropStyle: cfg.cropStyle,
          ),
          IOSUiSettings(
            title: cfg.iosTitle,
            aspectRatioPresets: cfg.aspectRatioPresets,
            cropStyle: cfg.cropStyle,
          ),
        ],
      );
      if (cropped == null) return input;
      return File(cropped.path);
    } catch (e, st) {
      debugPrint('Crop failed or canceled: $e\n$st');
      return input;
    }
  }

  /// Picks multiple images from the gallery (iOS 14+; may be limited on older OS).
  ///
  /// When [features.webFilePicker] is set with [WebFilePickerFeatureConfig.useFilePickerForMultiPick],
  /// uses `file_picker` on **non-web** platforms. On **web**, prefer [pickMultiImagesAsXFiles].
  Future<List<File>> pickMultiImages({
    required BuildContext context,
    int? maxImages,
    bool requestFullMetadata = true,
  }) async {
    try {
      final useFp = features?.webFilePicker != null &&
          features!.webFilePicker!.enabled &&
          features!.webFilePicker!.useFilePickerForMultiPick &&
          !kIsWeb;

      if (useFp) {
        final result = await FilePicker.platform.pickFiles(
          type: FileType.image,
          allowMultiple: true,
          withData: false,
        );
        if (result == null || result.files.isEmpty) {
          files = [];
          return [];
        }
        final list = <File>[];
        for (final p in result.files) {
          final path = p.path;
          if (path != null) list.add(File(path));
        }
        if (maxImages != null && list.length > maxImages) {
          files = list.take(maxImages).toList();
        } else {
          files = list;
        }
      } else {
        final picked = await _picker.pickMultiImage(
          limit: maxImages,
          requestFullMetadata: requestFullMetadata,
        );

        if (picked.isEmpty) {
          files = [];
          return [];
        }

        files = picked.map((x) => File(x.path)).toList();
      }

      var result = files!;

      if (compressImage) {
        final compressed = <File>[];
        final params = compressParams ?? defaultCompress;
        for (final f in result) {
          final out = await compress(image: f, compressParams: params);
          compressed.add(out ?? f);
        }
        result = compressed;
      }

      files = result;
      return result;
    } catch (e, st) {
      debugPrint('Error picking multiple images: $e\n$st');
      files = [];
      return [];
    }
  }

  /// Cross-platform multi pick using [XFile] (works on **web** when using [file_picker]).
  ///
  /// If [features.webFilePicker] enables [WebFilePickerFeatureConfig.useFilePickerForMultiPick],
  /// uses `file_picker` (web/desktop friendly). Otherwise uses [ImagePicker.pickMultiImage].
  Future<List<XFile>> pickMultiImagesAsXFiles({
    int? maxImages,
    bool requestFullMetadata = true,
  }) async {
    final useFp = features?.webFilePicker != null &&
        features!.webFilePicker!.enabled &&
        features!.webFilePicker!.useFilePickerForMultiPick;

    if (useFp) {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: true,
        withData: features!.webFilePicker!.withData || kIsWeb,
      );
      if (result == null || result.files.isEmpty) return [];

      final out = <XFile>[];
      for (final p in result.files) {
        if (p.bytes != null) {
          out.add(XFile.fromData(p.bytes!, name: p.name, mimeType: 'image/*'));
        } else if (p.path != null) {
          out.add(XFile(p.path!));
        }
      }
      if (maxImages != null && out.length > maxImages) {
        return out.take(maxImages).toList();
      }
      return out;
    }

    final picked = await _picker.pickMultiImage(
      limit: maxImages,
      requestFullMetadata: requestFullMetadata,
    );
    return picked;
  }

  /// Records a video from camera or gallery. Requires [ImageSelectFeatureConfig.video] with [VideoFeatureConfig.enabled].
  ///
  /// Not supported on **web** (depends on `dart:io` + native compressors).
  Future<File?> pickVideo({
    required ImageFrom source,
  }) async {
    final v = features?.video;
    if (v == null || !v.enabled) {
      debugPrint('Video picking disabled: set ImageSelectFeatureConfig.video');
      return null;
    }
    if (kIsWeb) {
      debugPrint('pickVideo is not supported on web in this package.');
      return null;
    }

    try {
      final x = await _picker.pickVideo(
        source: source == ImageFrom.camera ? ImageSource.camera : ImageSource.gallery,
        maxDuration: v.maxDuration,
      );
      if (x == null) {
        videoFile = null;
        return null;
      }
      var f = File(x.path);

      if (v.compressAfterPick) {
        final info = await VideoCompress.compressVideo(
          f.path,
          quality: v.quality,
          deleteOrigin: v.deleteOriginAfterCompress,
        );
        if (info?.path != null) {
          f = File(info!.path!);
        }
      }

      videoFile = f;
      return f;
    } catch (e, st) {
      debugPrint('Error picking/compressing video: $e\n$st');
      return null;
    }
  }

  /// Same as [pickVideo] with [ImageFrom.gallery].
  Future<File?> pickVideoFromGallery() => pickVideo(source: ImageFrom.gallery);

  /// Same as [pickVideo] with [ImageFrom.camera].
  Future<File?> pickVideoFromCamera() => pickVideo(source: ImageFrom.camera);

  /// Android: recovers a pick result after the activity was destroyed (e.g. low memory).
  ///
  /// Call from `initState` or early in `main` after `WidgetsFlutterBinding.ensureInitialized()`.
  /// On non-Android platforms this returns an empty [LostDataResponse] without calling the plugin.
  static Future<LostDataResponse> retrieveLostData() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      return LostDataResponse.empty();
    }
    try {
      return await ImagePicker().retrieveLostData();
    } on PlatformException catch (e) {
      debugPrint('retrieveLostData: $e');
      return LostDataResponse.empty();
    } on UnimplementedError {
      return LostDataResponse.empty();
    }
  }

  /// Converts HEIC/WebP/PNG to JPEG when [CompressParams.format] is [CompressFormat.jpeg]
  /// and applies optional resize. Uses EXIF-based orientation when [autoCorrectionAngle] is true.
  static Future<File?> compress({
    required File image,
    CompressParams compressParams = defaultCompress,
  }) async {
    final dir = await getTemporaryDirectory();
    final ext = switch (compressParams.format) {
      CompressFormat.jpeg => 'jpg',
      CompressFormat.png => 'png',
      CompressFormat.heic => 'heic',
      CompressFormat.webp => 'webp',
    };
    final targetPath = '${dir.path}/compressed_${DateTime.now().millisecondsSinceEpoch}.$ext';

    final compressedFile = await FlutterImageCompress.compressAndGetFile(
      image.absolute.path,
      targetPath,
      quality: compressParams.quality,
      minHeight: compressParams.targetHeight,
      minWidth: compressParams.targetWidth,
      autoCorrectionAngle: compressParams.autoCorrectionAngle,
      format: compressParams.format,
      keepExif: compressParams.keepExif,
    );

    if (compressedFile == null) {
      debugPrint('Compression failed');
      return null;
    }

    return File(compressedFile.path);
  }

  static const CompressParams defaultCompress = CompressParams(
    70,
    1080,
    1920,
    autoCorrectionAngle: true,
    keepExif: false,
    format: CompressFormat.jpeg,
  );
}

class CompressParams {
  const CompressParams(
    this.quality,
    this.targetWidth,
    this.targetHeight, {
    this.autoCorrectionAngle = true,
    this.keepExif = false,
    this.format = CompressFormat.jpeg,
  });

  final int quality;
  final int targetWidth;
  final int targetHeight;

  /// When true, uses EXIF orientation so pixels are upright (common Android gallery issue).
  final bool autoCorrectionAngle;

  /// Keep embedded metadata in output (often undesirable for privacy).
  final bool keepExif;

  /// Use [CompressFormat.jpeg] to normalize HEIC/WebP from the gallery for backends that expect JPG.
  final CompressFormat format;
}

enum CameraSide {
  front,
  back,
}
