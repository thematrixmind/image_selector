## 0.0.6

* Multi-image gallery pick (`pickMultiImages`, optional `pickMultiImagesAsXFiles`).
* Android activity death: `retrieveLostData` to recover a lost pick after restart.
* Compression: `CompressParams`, `compressImage`, HEIC/WebP handling helpers; optional `compressOnlyForCamera`.
* Optional features behind `ImageSelectFeatureConfig`: crop (`image_cropper`), video pick + `video_compress`, `file_picker` / `WebFilePickerFeatureConfig` for web.
* Camera flow updates (lifecycle, lens side, themed `CameraUiSettings`).
* Example app: bottom sheet flows, documented APIs; README with platform notes (iOS privacy strings, Android UCrop, Podfile).

## 0.0.4

* Enhanced image compression functionality for faster uploads and reduced file sizes.
* Added support for mirroring the front camera preview.
* Improved error handling during image selection and capturing processes.
* Updated dependencies to ensure compatibility with the latest versions of Flutter.
* General bug fixes and performance optimizations.
* Updated documentation for clarity and better usage examples.

## 0.0.3

* Improved image selection from camera.
* Add compress image functionality.
* Bug fixes and performance optimizations.
* Updated documentation.

## 0.0.2

* Improved image selection functionality.
* Enhanced user experience for selecting images from both camera and gallery.
* Bug fixes and performance optimizations.
* Updated documentation.

## 0.0.1

* Initial Release of image_selector.
* Select images from the camera and gallery of the device.
