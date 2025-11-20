# Media Selection Package

A comprehensive Flutter package for selecting and managing media files (images and videos) from device gallery and camera with advanced features like multi-selection, preview, and customization.

## Features

- 📸 **Camera Integration**: Capture photos and videos directly from the camera
- 🖼️ **Gallery Access**: Browse and select media from device photo library
- 🎯 **Multi-Selection**: Support for both single and multi-selection modes
- 👀 **Live Preview**: Full-screen preview of selected media with navigation
- 🎨 **Customizable UI**: Fully customizable colors, fonts, icons, and text
- 📱 **Responsive Design**: Optimized for different screen sizes using flutter_screenutil
- ⚡ **Performance**: Lazy loading and pagination for large media libraries
- 🔒 **Permission Handling**: Automatic permission requests with user-friendly UI
- 📊 **Media Limits**: Configurable limits for different media types
- 🎬 **Video Support**: Video thumbnails, duration display, and playback controls

## Required Dependencies

Add these packages to your `pubspec.yaml`:

```yaml
dependencies:
  flutter_screenutil: ^5.9.0
  get_thumbnail_video: ^2.1.0
  photo_manager: ^3.0.0
  image_picker: ^1.0.4
  video_compress: ^3.1.2
```

## Installation

1. Add the media_selection package to your project
2. Import the package in your Dart file:

```dart
import 'package:your_project/packages/media_selection/media_selection.dart';
```

## Basic Usage

### Simple Media Selection

```dart
// Navigate to media selection
final selectedMedia = await Navigator.push<List<MediaAssetData>>(
  context,
  MaterialPageRoute(
    builder: (context) => MediaSelectionView(
      mediaSelectionConfig: MediaSelectionConfig(),
      onComplete: (selectedMedia) async {
        // Handle selected media
        print('Selected ${selectedMedia.length} media items');
        return true; // Return true to pop the screen
      },
    ),
  ),
);

if (selectedMedia != null) {
  // Process selected media
  for (final media in selectedMedia) {
    print('Media: ${media.localPath}');
    print('Type: ${media.mediaType}');
  }
}
```

### Custom Configuration

```dart
final config = MediaSelectionConfig(
  // Colors
  primaryColor: Colors.purple,
  primaryTextColor: Colors.white,
  backgroundColor: Colors.black,
  appBarColor: Colors.grey[900],
  
  // Text
  selectMediaTitle: 'Choose Photos & Videos',
  doneButtonText: 'Continue',
  
  // Limits
  mediaLimit: 5,
  imageMediaLimit: 3,
  videoMediaLimit: 2,
  
  // Options
  isMultiSelect: true,
  mediaListType: MediaListType.imageVideo,
  videoMaxDuration: Duration(minutes: 2),
  thumbnailQuality: 75,
  pageSize: 30,
  
  // Custom Icons
  cameraIcon: Icon(Icons.add_a_photo, color: Colors.purple),
  closeIcon: Icon(Icons.arrow_back, color: Colors.white),
);

final selectedMedia = await Navigator.push<List<MediaAssetData>>(
  context,
  MaterialPageRoute(
    builder: (context) => MediaSelectionView(
      mediaSelectionConfig: config,
      onComplete: (selectedMedia) async {
        // Custom completion logic
        return true;
      },
    ),
  ),
);
```

## Configuration Options

### MediaSelectionConfig Properties

| Property | Type | Default | Description |
|----------|------|---------|-------------|
| `primaryColor` | `Color` | `Colors.blue` | Primary theme color |
| `primaryTextColor` | `Color` | `Colors.black` | Text color |
| `backgroundColor` | `Color` | `Colors.white` | Background color |
| `appBarColor` | `Color` | `Colors.white` | App bar background |
| `primaryFontFamily` | `String` | `'Inter'` | Font family |
| `selectMediaTitle` | `String` | `'Select Media'` | App bar title |
| `doneButtonText` | `String` | `'Done'` | Done button text |
| `isMultiSelect` | `bool` | `true` | Enable multi-selection |
| `mediaLimit` | `int` | `10` | Total media limit |
| `imageMediaLimit` | `int` | `10` | Image limit |
| `videoMediaLimit` | `int` | `10` | Video limit |
| `videoMaxDuration` | `Duration` | `30 seconds` | Max video duration |
| `thumbnailQuality` | `int` | `50` | Thumbnail quality (1-100) |
| `pageSize` | `int` | `50` | Items per page |
| `mediaListType` | `MediaListType` | `imageVideo` | Media type filter |

### MediaListType Options

- `MediaListType.image` - Images only
- `MediaListType.video` - Videos only  
- `MediaListType.imageVideo` - Both images and videos
- `MediaListType.audio` - Audio files only

## Data Models

### MediaAssetData

Represents a selected media item with the following properties:

```dart
class MediaAssetData {
  String? assetId;           // Unique identifier
  String? localPath;         // File path
  String? isTemp;           // Temporary file indicator
  File? file;               // File object
  SelectedMediaType? mediaType; // image or video
  int? height;              // Media height
  int? width;               // Media width
  String? extension;        // File extension
  int? duration;            // Duration in seconds (for videos)
  Orientation? orientation; // portrait or landscape
  String? thumbnailPath;    // Thumbnail path (for videos)
}
```

### SelectedMediaType

```dart
enum SelectedMediaType {
  image,
  video;
}
```

## Advanced Features

### Custom Icons

```dart
final config = MediaSelectionConfig(
  primaryColor: Colors.orange,
  closeIcon: Icon(Icons.close, color: Colors.red),
  cameraIcon: Icon(Icons.camera_alt, color: Colors.orange, size: 50),
  videoIcon: Icon(Icons.videocam, color: Colors.orange, size: 50),
  playIcon: Icon(Icons.play_circle_filled, color: Colors.white, size: 60),
  pauseIcon: Icon(Icons.pause_circle_filled, color: Colors.white, size: 60),
  singleSelectModeIcon: Icon(Icons.radio_button_checked, color: Colors.orange),
  multiSelectModeIcon: Icon(Icons.checklist, color: Colors.orange),
);
```

### Pre-selected Media

```dart
// Pass previously selected media
final selectedMedia = await Navigator.push<List<MediaAssetData>>(
  context,
  MaterialPageRoute(
    builder: (context) => MediaSelectionView(
      mediaSelectionConfig: config,
      selectedMedia: previouslySelectedMedia, // Pre-selected items
      onComplete: (selectedMedia) async {
        return true;
      },
    ),
  ),
);
```

### Custom Completion Handler

```dart
final selectedMedia = await Navigator.push<List<MediaAssetData>>(
  context,
  MaterialPageRoute(
    builder: (context) => MediaSelectionView(
      mediaSelectionConfig: config,
      onComplete: (selectedMedia) async {
        // Custom validation
        if (selectedMedia.length < 2) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Please select at least 2 items')),
          );
          return false; // Don't pop the screen
        }
        
        // Process media
        await processSelectedMedia(selectedMedia);
        return true; // Pop the screen
      },
    ),
  ),
);
```

## UI Components

The package includes several customizable widgets:

- `MediaSelectionView` - Main selection interface
- `CameraButtonWidget` - Camera capture button
- `MediaGridItemWidget` - Individual media item in grid
- `MediaPreviewWidget` - Full-screen media preview

## Permissions

The package automatically handles the following permissions:

- **iOS**: `NSPhotoLibraryUsageDescription` and `NSCameraUsageDescription`
- **Android**: `READ_EXTERNAL_STORAGE`, `WRITE_EXTERNAL_STORAGE`, and `CAMERA`

Add these to your platform-specific configuration files.

## Error Handling

The package includes built-in error handling for:

- Permission denials
- File access errors
- Video thumbnail generation failures
- Camera capture errors

## Performance Considerations

- Uses pagination to load media in batches
- Generates video thumbnails on-demand
- Implements debouncing for rapid selections
- Lazy loading for large media libraries

## Example Apps

See the example directory for complete usage examples including:

- Basic media selection
- Custom themed selection
- Pre-selected media handling
- Custom completion logic

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is licensed under the MIT License.