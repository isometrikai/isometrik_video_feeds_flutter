# Media Edit Package

An independent Flutter package for editing images and videos with customizable UI and functionality.

## Features

- Image editing (text, filters, adjustments)
- Video editing (trimming, filters)
- Video cover selection
- Customizable UI colors, styles, and text
- Configurable dialog functions

## Usage

### 1. Import the package

```dart
import 'package:your_project/packages/media_edit/media_edit.dart';
```

### 2. Create a configuration

```dart
final mediaEditConfig = MediaEditConfig(
  // Colors
  primaryColor: Colors.blue,
  primaryTextColor: Colors.black,
  backgroundColor: Colors.white,
  appBarColor: Colors.white,
  greyColor: Colors.grey,
  blackColor: Colors.black,
  whiteColor: Colors.white,
  
  // Text
  removeMediaTitle: 'Remove Media',
  removeMediaMessage: 'Are you sure you want to remove this media?',
  removeButtonText: 'Remove',
  cancelButtonText: 'Cancel',
  editCoverTitle: 'Edit Cover',
  addFromGalleryText: 'Add from Gallery',
  
  // Dialog function (required)
  showDialogFunction: (context) async {
    // Implement your custom dialog here
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: onPressNegativeButton,
            child: Text(negativeButtonText),
          ),
          TextButton(
            onPressed: onPressPositiveButton,
            child: Text(positiveButtonText),
          ),
        ],
      ),
    );
  },
);
```

### 3. Use the MediaEditView

```dart
MediaEditView(
  mediaDataList: [
    MediaEditItem(
      originalPath: '/path/to/image.jpg',
      mediaType: EditMediaType.image,
      width: 1920,
      height: 1080,
    ),
  ],
  mediaEditConfig: mediaEditConfig,
  onComplete: (editedMedia) async {
    // Handle completed editing
    return true;
  },
  onSelectSound: (sound) async {
    // Handle sound selection
    return sound;
  },
  addMoreMedia: (editedMedia) async {
    // Handle adding more media
    return true;
  },
)
```

## Configuration Options

### Colors
- `primaryColor`: Main theme color
- `primaryTextColor`: Default text color
- `backgroundColor`: Background color
- `appBarColor`: App bar background color
- `greyColor`: Grey color for secondary elements
- `blackColor`: Black color
- `whiteColor`: White color

### Text
- `removeMediaTitle`: Title for remove media dialog
- `removeMediaMessage`: Message for remove media dialog
- `removeButtonText`: Text for remove button
- `cancelButtonText`: Text for cancel button
- `editCoverTitle`: Title for edit cover screen
- `addFromGalleryText`: Text for add from gallery button

### Icons
All icons are customizable and can be replaced with your own widgets.

### Dialog Function
The `showDialogFunction` is required and must be implemented to show custom dialogs. This allows you to use your app's existing dialog system.

## Dependencies

This package requires the following dependencies in your `pubspec.yaml`:

```yaml
dependencies:
  flutter:
    sdk: flutter
  go_router: ^12.0.0
  pro_video_editor: ^latest
  ffmpeg_kit_flutter_new_min_gpl: ^latest
  image_picker: ^latest
  path_provider: ^latest
  video_player: ^latest
  photo_view: ^latest
  photo_manager: ^latest
```

## Migration from Project-Specific Version

If you're migrating from a project-specific version:

1. Replace all `AppColors` references with `mediaEditConfig` properties
2. Replace `Utility.showCommonAppDialog` with your custom dialog function
3. Replace `Styles` references with `mediaEditConfig` text styles
4. Pass the `mediaEditConfig` parameter to all media edit widgets

## Example

See the `media_selection` package for a similar implementation pattern.
