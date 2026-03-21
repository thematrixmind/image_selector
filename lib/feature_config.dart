import 'package:image_cropper/image_cropper.dart';
import 'package:video_compress/video_compress.dart';

/// Optional add-ons for [ImageSelect]. Pass only what you need; `null` means
/// that feature is off (no crop step, no video helpers, default gallery multi-pick).
///
/// Native setup is still required for each plugin you enable (e.g. `image_cropper`
/// Android manifest / iOS plist entries — see each package’s readme).
class ImageSelectFeatureConfig {
  const ImageSelectFeatureConfig({
    this.crop,
    this.video,
    this.webFilePicker,
  });

  /// Non-null + [CropFeatureConfig.enabled] → run [ImageCropper] after a single [pickImage].
  final CropFeatureConfig? crop;

  /// Non-null + [VideoFeatureConfig.enabled] → [pickVideo] / [pickVideoFromGallery] work.
  final VideoFeatureConfig? video;

  /// Non-null + [WebFilePickerFeatureConfig.enabled] → multi-pick can use [file_picker]
  /// (better on web/desktop; see [WebFilePickerFeatureConfig]).
  final WebFilePickerFeatureConfig? webFilePicker;
}

/// Settings for optional **image_cropper** integration (avatar / Instagram-style crop).
class CropFeatureConfig {
  const CropFeatureConfig({
    this.enabled = true,
    this.compressQuality = 90,
    this.aspectRatioPresets = const <CropAspectRatioPresetData>[
      CropAspectRatioPreset.square,
      CropAspectRatioPreset.original,
    ],
    this.lockAspectRatio = false,
    this.cropStyle = CropStyle.rectangle,
    this.androidToolbarTitle = 'Crop',
    this.iosTitle = 'Crop',
    this.maxWidth,
    this.maxHeight,
  });

  final bool enabled;

  /// 0–100 passed to [ImageCropper.cropImage].
  final int compressQuality;

  final List<CropAspectRatioPresetData> aspectRatioPresets;
  final bool lockAspectRatio;
  final CropStyle cropStyle;
  final String androidToolbarTitle;
  final String iosTitle;
  final int? maxWidth;
  final int? maxHeight;
}

/// Settings for optional **video_compress** after [ImagePicker.pickVideo].
class VideoFeatureConfig {
  const VideoFeatureConfig({
    this.enabled = true,
    this.compressAfterPick = true,
    this.quality = VideoQuality.Res1280x720Quality,
    this.deleteOriginAfterCompress = false,
    this.maxDuration,
  });

  final bool enabled;

  /// When false, returns the original picked file without calling [VideoCompress.compressVideo].
  final bool compressAfterPick;

  /// Preset passed to [VideoCompress.compressVideo].
  final VideoQuality quality;

  /// Passed to [VideoCompress.compressVideo] when [compressAfterPick] is true.
  final bool deleteOriginAfterCompress;

  /// Forwarded to [ImagePicker.pickVideo].
  final Duration? maxDuration;
}

/// Use [file_picker] for multi-image selection (strong on **web** and desktop).
///
/// When [useFilePickerForMultiPick] is true, [ImageSelect.pickMultiImagesAsXFiles] can
/// use [file_picker] instead of [ImagePicker.pickMultiImage] (see method docs).
class WebFilePickerFeatureConfig {
  const WebFilePickerFeatureConfig({
    this.enabled = true,
    this.useFilePickerForMultiPick = true,
    this.withData = true,
  });

  final bool enabled;

  /// If true, multi selection may go through `FilePicker.platform.pickFiles` when supported.
  final bool useFilePickerForMultiPick;

  /// Web: load bytes in memory (needed when path is unavailable).
  final bool withData;
}
