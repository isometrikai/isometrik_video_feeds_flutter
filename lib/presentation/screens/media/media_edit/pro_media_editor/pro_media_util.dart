import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ism_video_reel_player/domain/models/create_edit_post_config.dart';
import 'package:ism_video_reel_player/presentation/screens/media/media_edit/media_edit_config.dart';
import 'package:ism_video_reel_player/presentation/screens/widgets/app_image.dart';
import 'package:ism_video_reel_player/res/res.dart';
import 'package:ism_video_reel_player/utils/utils.dart';
import 'package:pro_image_editor/pro_image_editor.dart';

PaintEditorConfigs paintEditorConfigs(MediaEditConfig mediaEditConfig) =>
    PaintEditorConfigs(
      safeArea: const EditorSafeArea(top: false),
      style: PaintEditorStyle(
          uiOverlayStyle: mediaEditorUiOverlay(mediaEditConfig),
          appBarColor: mediaEditConfig.blackColor,
          appBarBackground: mediaEditConfig.whiteColor.changeOpacity(0.3),
          bottomBarBackground: mediaEditConfig.whiteColor,
          bottomBarActiveItemColor: mediaEditConfig.primaryColor,
          bottomBarInactiveItemColor: Colors.black.changeOpacity(0.4),
          // bottomBarTextSize: IsrDimens.twelve,
          // bottomBarIconSize: IsrDimens.twentyFour,
          // bottomBarHeight: IsrDimens.seventy,
          background: mediaEditConfig.whiteColor,
          lineWidthBottomSheetBackground: mediaEditConfig.whiteColor,
          opacityBottomSheetBackground: mediaEditConfig.whiteColor),
    );

TextEditorConfigs textEditorConfigs(MediaEditConfig mediaEditConfig) =>
    TextEditorConfigs(
      // AppBar already accounts for status-bar inset; SafeArea top would double it.
      safeArea: const EditorSafeArea(top: false, bottom: false),
      style: TextEditorStyle(
        background: Colors.black.applyOpacity(.1),
        appBarColor: mediaEditConfig.blackColor,
        appBarBackground: mediaEditConfig.whiteColor,
        bottomBarBackground: mediaEditConfig.whiteColor,
        fontScaleBottomSheetBackground: mediaEditConfig.whiteColor,
      ),
    );

CropRotateEditorConfigs cropRotateEditorConfigs(
        MediaEditConfig mediaEditConfig) =>
    CropRotateEditorConfigs(
      safeArea: const EditorSafeArea(top: false),
      style: CropRotateEditorStyle(
        uiOverlayStyle: mediaEditorUiOverlay(mediaEditConfig),
        appBarColor: mediaEditConfig.blackColor,
        appBarBackground: mediaEditConfig.whiteColor,
        bottomBarBackground: mediaEditConfig.whiteColor,
        background: mediaEditConfig.backgroundColor,
      ),
    );

FilterEditorConfigs filterEditorConfigs(MediaEditConfig mediaEditConfig) =>
    FilterEditorConfigs(
      safeArea: const EditorSafeArea(top: false),
      style: FilterEditorStyle(
        uiOverlayStyle: mediaEditorUiOverlay(mediaEditConfig),
        background: mediaEditConfig.backgroundColor,
        appBarColor: mediaEditConfig.blackColor,
        appBarBackground: mediaEditConfig.whiteColor,
        previewTextColor: mediaEditConfig.primaryTextColor,
        previewSelectedTextColor: mediaEditConfig.primaryColor,
      ),
    );

BlurEditorConfigs blurEditorConfigs(MediaEditConfig mediaEditConfig) =>
    BlurEditorConfigs(
      safeArea: const EditorSafeArea(top: false),
      style: BlurEditorStyle(
        uiOverlayStyle: mediaEditorUiOverlay(mediaEditConfig),
        appBarForegroundColor: mediaEditConfig.blackColor,
        appBarBackgroundColor: mediaEditConfig.whiteColor,
        background: mediaEditConfig.whiteColor,
      ),
    );

TuneEditorConfigs tuneEditorConfigs(MediaEditConfig mediaEditConfig) =>
    TuneEditorConfigs(
      safeArea: const EditorSafeArea(top: false),
      style: TuneEditorStyle(
        uiOverlayStyle: mediaEditorUiOverlay(mediaEditConfig),
        appBarColor: mediaEditConfig.blackColor,
        appBarBackground: mediaEditConfig.whiteColor,
        bottomBarBackground: mediaEditConfig.whiteColor,
        bottomBarActiveItemColor: mediaEditConfig.primaryColor,
        bottomBarInactiveItemColor: mediaEditConfig.primaryTextColor,
        background: mediaEditConfig.backgroundColor,
      ),
    );

EmojiEditorConfigs emojiEditorConfigs(MediaEditConfig mediaEditConfig) =>
    const EmojiEditorConfigs();

StickerEditorConfigs stickerEditorConfigs(MediaEditConfig mediaEditConfig) =>
    StickerEditorConfigs(
      builder: (setLayer, scrollController) => _buildStickerPicker(
        setLayer,
        scrollController,
        mediaEditConfig.mediaEditorStickersConfig,
      ),
    );

/// White system bars with dark status/nav icons (light-content overlay).
SystemUiOverlayStyle mediaEditorUiOverlay(MediaEditConfig mediaEditConfig) =>
    IsrSystemUi.lightBarsOverlay(background: mediaEditConfig.whiteColor);

MainEditorConfigs mainEditorConfig(MediaEditConfig mediaEditConfig) =>
    MainEditorConfigs(
      enableZoom: false,
      enableDoubleTapZoom: false,
      mobilePanInteraction: MobilePanInteraction.dragSelect,
      style: MainEditorStyle(
        uiOverlayStyle: mediaEditorUiOverlay(mediaEditConfig),
        appBarColor: mediaEditConfig.blackColor,
        appBarBackground: mediaEditConfig.whiteColor.changeOpacity(0.3),
        bottomBarBackground: mediaEditConfig.whiteColor,
        bottomBarColor: mediaEditConfig.primaryTextColor,
        background: mediaEditConfig.whiteColor,
        outsideCaptureAreaLayerOpacity: 0,
      ),
      widgets: buildMainEditorWidgets(mediaEditConfig),
      tools: const [
        SubEditorMode.paint,
        SubEditorMode.text,
        SubEditorMode.cropRotate,
        SubEditorMode.tune,
        SubEditorMode.filter,
        SubEditorMode.blur,
        SubEditorMode.emoji,
        SubEditorMode.sticker,
      ],
    );

/// Whether [editingMode] should open a single sub-editor immediately.
bool isDirectSubEditorMode(String? editingMode) {
  switch (editingMode) {
    case 'text':
    case 'filter':
      return true;
    default:
      return false;
  }
}

/// Opens the sub-editor that matches [editingMode] on the main editor.
void openDirectSubEditor(ProImageEditorState editor, String? editingMode) {
  switch (editingMode) {
    case 'text':
      editor.openTextEditor();
    case 'filter':
      editor.openFilterEditor();
    default:
      break;
  }
}

/// Main-editor config with no bottom toolbar (used for direct sub-editor flows).
MainEditorConfigs directSubEditorMainConfig(MediaEditConfig mediaEditConfig) =>
    mainEditorConfig(mediaEditConfig).copyWith(
      tools: const [],
      widgets: buildMainEditorWidgets(
        mediaEditConfig,
        hideBottomBar: true,
      ),
    );

/// Builds main-editor widget overrides supported by `pro_image_editor` 12.x.
MainEditorWidgets buildMainEditorWidgets(
  MediaEditConfig mediaEditConfig, {
  bool hideBottomBar = false,
  bool hideUndoRedoActions = false,
  Widget Function(
    GlobalKey removeAreaKey,
    ProImageEditorState editor,
    Stream<void> rebuildStream,
    bool isLayerBeingTransformed,
  )? removeLayerArea,
}) =>
    MainEditorWidgets(
      removeLayerArea: removeLayerArea,
      // Use a recorded overlay instead of [wrapBody]. Wrapping the interactive
      // body with padding changes the rendered size without updating the
      // editor's internal [SizesManager.bodySize], which can trigger resize
      // handling and reset edits when layers are added.
      // bodyItemsRecorded: (editor, rebuildStream) => [
      //   buildMainEditorBodyFrameOverlay(
      //     mediaEditConfig: mediaEditConfig,
      //     editor: editor,
      //     rebuildStream: rebuildStream,
      //   ),
      // ],
      bottomBar: hideBottomBar
          ? (_, __, ___) => null
          : (editor, rebuildStream, key) => ReactiveWidget(
                stream: rebuildStream,
                builder: (_) => buildMainEditorBottomBar(
                  editor: editor,
                  mediaEditConfig: mediaEditConfig,
                  bottomBarKey: key,
                ),
              ),
      appBar: hideUndoRedoActions
          ? (editor, rebuildStream) => buildMainEditorAppBarWithoutUndoRedo(
                editor: editor,
                rebuildStream: rebuildStream,
                mediaEditConfig: mediaEditConfig,
              )
          : null,
    );

const EdgeInsets _mainEditorBodyFramePadding = EdgeInsets.all(12);

/// Decorative frame drawn inside the content recorder so it does not affect
/// layer coordinates or resize calculations.
ReactiveWidget buildMainEditorBodyFrameOverlay({
  required MediaEditConfig mediaEditConfig,
  required ProImageEditorState editor,
  required Stream<void> rebuildStream,
}) =>
    ReactiveWidget(
      stream: rebuildStream,
      builder: (_) {
        final bodySize = editor.sizesManager.bodySize;
        if (bodySize == Size.zero) {
          return const SizedBox.shrink();
        }

        return IgnorePointer(
          child: CustomPaint(
            size: bodySize,
            painter: _MainEditorBodyFramePainter(
              padding: _mainEditorBodyFramePadding,
              borderRadius: BorderRadius.circular(20.responsiveDimension),
              color: mediaEditConfig.whiteColor,
            ),
          ),
        );
      },
    );

class _MainEditorBodyFramePainter extends CustomPainter {
  const _MainEditorBodyFramePainter({
    required this.padding,
    required this.borderRadius,
    required this.color,
  });

  final EdgeInsets padding;
  final BorderRadius borderRadius;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final outer = Path()..addRect(Offset.zero & size);
    final innerRect = Rect.fromLTWH(
      padding.left,
      padding.top,
      size.width - padding.horizontal,
      size.height - padding.vertical,
    );
    if (innerRect.width <= 0 || innerRect.height <= 0) {
      return;
    }

    final inner = Path()
      ..addRRect(borderRadius.toRRect(innerRect));
    final frame = Path.combine(PathOperation.difference, outer, inner);
    canvas.drawPath(frame, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant _MainEditorBodyFramePainter oldDelegate) =>
      oldDelegate.padding != padding ||
      oldDelegate.borderRadius != borderRadius ||
      oldDelegate.color != color;
}

ReactiveAppbar buildMainEditorAppBarWithoutUndoRedo({
  required ProImageEditorState editor,
  required Stream<void> rebuildStream,
  required MediaEditConfig mediaEditConfig,
}) =>
    ReactiveAppbar(
      stream: rebuildStream,
      builder: (_) {
        final mainEditorStyle = editor.configs.mainEditor.style;
        return AppBar(
          foregroundColor: mainEditorStyle.appBarColor,
          backgroundColor: mainEditorStyle.appBarBackground,
          systemOverlayStyle: mediaEditorUiOverlay(mediaEditConfig),
          leading: editor.configs.mainEditor.enableCloseButton
              ? IconButton(
                  tooltip: editor.configs.i18n.cancel,
                  icon: Icon(editor.configs.mainEditor.icons.closeEditor),
                  onPressed: editor.closeEditor,
                )
              : null,
          actions: [
            IconButton(
              key: const ValueKey('MainEditorDoneButton'),
              tooltip: editor.configs.i18n.done,
              icon: Icon(editor.configs.mainEditor.icons.doneIcon),
              iconSize: 28,
              onPressed: editor.doneEditing,
            ),
          ],
        );
      },
    );

Widget buildMainEditorBottomBar({
  required ProImageEditorState editor,
  required MediaEditConfig mediaEditConfig,
  required Key bottomBarKey,
}) {
  final configs = editor.configs;
  final tools = configs.mainEditor.tools;
  if (tools.isEmpty) {
    return const SizedBox.shrink(key: ValueKey('main-editor-bottom-bar'));
  }

  final buttons = <Widget>[];
  for (final tool in tools) {
    final button = _buildMainEditorToolButton(editor: editor, tool: tool);
    if (button == null) continue;
    if (buttons.isNotEmpty) {
      buttons.add(SizedBox(width: 16.responsiveDimension));
    }
    buttons.add(button);
  }

  return SizedBox(
    key: bottomBarKey,
    child: BottomAppBar(
      height: 100.responsiveDimension,
      color: configs.mainEditor.style.bottomBarBackground,
      padding: EdgeInsets.zero,
      child: Center(
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 12.responsiveDimension),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: buttons,
            ),
          ),
        ),
      ),
    ),
  );
}

Widget? _buildMainEditorToolButton({
  required ProImageEditorState editor,
  required SubEditorMode tool,
}) {
  final configs = editor.configs;
  switch (tool) {
    case SubEditorMode.paint:
      return _buildMainEditorBottomBarButton(
        key: const ValueKey('open-paint-editor-btn'),
        title: configs.i18n.paintEditor.bottomNavigationBarText,
        iconData: configs.paintEditor.icons.bottomNavBar,
        onPressed: editor.openPaintEditor,
      );
    case SubEditorMode.text:
      return _buildMainEditorBottomBarButton(
        key: const ValueKey('open-text-editor-btn'),
        title: configs.i18n.textEditor.bottomNavigationBarText,
        iconData: configs.textEditor.icons.bottomNavBar,
        onPressed: editor.openTextEditor,
      );
    case SubEditorMode.cropRotate:
      return _buildMainEditorBottomBarButton(
        key: const ValueKey('open-crop-rotate-editor-btn'),
        title: configs.i18n.cropRotateEditor.bottomNavigationBarText,
        iconData: configs.cropRotateEditor.icons.bottomNavBar,
        onPressed: editor.openCropRotateEditor,
      );
    case SubEditorMode.tune:
      return _buildMainEditorBottomBarButton(
        key: const ValueKey('open-tune-editor-btn'),
        title: configs.i18n.tuneEditor.bottomNavigationBarText,
        iconData: configs.tuneEditor.icons.bottomNavBar,
        onPressed: editor.openTuneEditor,
      );
    case SubEditorMode.filter:
      return _buildMainEditorBottomBarButton(
        key: const ValueKey('open-filter-editor-btn'),
        title: configs.i18n.filterEditor.bottomNavigationBarText,
        iconData: configs.filterEditor.icons.bottomNavBar,
        onPressed: editor.openFilterEditor,
      );
    case SubEditorMode.blur:
      return _buildMainEditorBottomBarButton(
        key: const ValueKey('open-blur-editor-btn'),
        title: configs.i18n.blurEditor.bottomNavigationBarText,
        iconData: configs.blurEditor.icons.bottomNavBar,
        onPressed: editor.openBlurEditor,
      );
    case SubEditorMode.emoji:
      return _buildMainEditorBottomBarButton(
        key: const ValueKey('open-emoji-editor-btn'),
        title: configs.i18n.emojiEditor.bottomNavigationBarText,
        iconData: configs.emojiEditor.icons.bottomNavBar,
        onPressed: editor.openEmojiEditor,
      );
    case SubEditorMode.sticker:
      return _buildMainEditorBottomBarButton(
        key: const ValueKey('open-sticker-editor-btn'),
        title: configs.i18n.stickerEditor.bottomNavigationBarText,
        iconData: configs.stickerEditor.icons.bottomNavBar,
        onPressed: editor.openStickerEditor,
      );
    case SubEditorMode.audio:
      return _buildMainEditorBottomBarButton(
        key: const ValueKey('open-audio-editor-btn'),
        title: configs.i18n.audioEditor.bottomNavigationBarText,
        iconData: configs.audioEditor.icons.bottomNavBar,
        onPressed: editor.openAudioEditor,
      );
    case SubEditorMode.videoClips:
      return _buildMainEditorBottomBarButton(
        key: const ValueKey('open-clips-editor-btn'),
        title: configs.i18n.clipsEditor.bottomNavigationBarText,
        iconData: configs.clipsEditor.icons.bottomNavBar,
        onPressed: editor.openClipsEditor,
      );
  }
}

Widget _buildMainEditorBottomBarButton({
  required Key key,
  required String title,
  required IconData iconData,
  required VoidCallback onPressed,
}) =>
    TextButton(
      key: key,
      onPressed: onPressed,
      style: TextButton.styleFrom(
        padding: EdgeInsets.zero,
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: _buildMainEditorBottomBarIcon(title, iconData),
    );

Widget _buildMainEditorBottomBarIcon(String title, IconData iconData) =>
    Container(
      height: 58.responsiveDimension,
      width: 76.responsiveDimension,
      decoration: BoxDecoration(
        color: IsrColors.colorF4F4F4,
        borderRadius: BorderRadius.circular(8.responsiveDimension),
      ),
      padding: IsrDimens.edgeInsetsAll(5.responsiveDimension),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Icon(
            iconData,
            size: 24.responsiveDimension,
            color: IsrColors.primaryTextColor,
          ),
          Text(
            title,
            style:
                IsrStyles.primaryText14.copyWith(fontWeight: FontWeight.w500),
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ],
      ),
    );

/// Loading overlay shown while editor changes are applied/exported.
/// Must not dismiss on outside tap — export continues in the background.
Widget nonDismissibleEditorLoadingDialog(
  String message,
  ProImageEditorConfigs configs,
) =>
    Builder(
      builder: (context) {
        final theme = configs.theme ?? Theme.of(context);
        final textColor = configs.dialogConfigs.style.loadingDialog.textColor;
        final content = _editorLoadingDialogContent(
          message: message,
          textColor: textColor,
          configs: configs,
        );

        return Stack(
          children: [
            const ModalBarrier(
              color: Colors.black54,
              dismissible: false,
            ),
            Center(
              child: Theme(
                data: theme,
                child: configs.designMode == ImageEditorDesignMode.cupertino
                    ? CupertinoAlertDialog(content: content)
                    : AlertDialog(
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 16,
                          horizontal: 20,
                        ),
                        content: content,
                      ),
              ),
            ),
          ],
        );
      },
    );

Widget _editorLoadingDialogContent({
  required String message,
  required Color textColor,
  required ProImageEditorConfigs configs,
}) =>
    ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 500),
      child: Padding(
        padding: const EdgeInsets.only(top: 3),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(
              height: 40,
              width: 40,
              child: FittedBox(
                child: configs.designMode == ImageEditorDesignMode.cupertino
                    ? const CupertinoActivityIndicator(radius: 14)
                    : CircularProgressIndicator(color: textColor),
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Text(
                message,
                style: TextStyle(fontSize: 16, color: textColor),
              ),
            ),
          ],
        ),
      ),
    );

ProImageEditorConfigs proImageEditorConfigs(MediaEditConfig mediaEditConfig) {
  final overlay = mediaEditorUiOverlay(mediaEditConfig);
  return ProImageEditorConfigs(
      theme: ThemeData.light().copyWith(
        appBarTheme: AppBarTheme(
          backgroundColor: mediaEditConfig.whiteColor,
          foregroundColor: mediaEditConfig.blackColor,
          iconTheme: IconThemeData(color: mediaEditConfig.blackColor),
          systemOverlayStyle: overlay,
        ),
      ),
      dialogConfigs: DialogConfigs(
          style: DialogStyle(
              loadingDialog:
                  LoadingDialogStyle(textColor: IsrColors.primaryTextColor)),
          widgets: DialogWidgets(
            loadingDialog: nonDismissibleEditorLoadingDialog,
          )),
      layerInteraction: const LayerInteractionConfigs(
        hideToolbarOnInteraction: false,
      ),
      mainEditor: mainEditorConfig(mediaEditConfig),
      textEditor: textEditorConfigs(mediaEditConfig),
      emojiEditor: emojiEditorConfigs(mediaEditConfig),
      paintEditor: paintEditorConfigs(mediaEditConfig),
      stickerEditor: stickerEditorConfigs(mediaEditConfig),
      // Disable other editors
      cropRotateEditor: cropRotateEditorConfigs(mediaEditConfig),
      filterEditor: filterEditorConfigs(mediaEditConfig),
      blurEditor: blurEditorConfigs(mediaEditConfig),
      tuneEditor: tuneEditorConfigs(mediaEditConfig),
      designMode: Platform.isAndroid
          ? ImageEditorDesignMode.material
          : ImageEditorDesignMode.cupertino,
    );
}

/// Builds the sticker picker interface
Widget _buildStickerPicker(
  Function(WidgetLayer) setLayer,
  ScrollController scrollController,
  MediaEditorStickersConfig stickersConfig,
) {
  final stickerAssets = stickersConfig.stickerAssetPaths;
  return Container(
    height: 300,
    padding: const EdgeInsets.all(16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          stickersConfig.pickerTitle,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: stickerAssets.isEmpty
              ? const Center(child: Text('No stickers available'))
              : GridView.builder(
                  controller: scrollController,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: stickersConfig.gridCrossAxisCount,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  itemCount: stickerAssets.length,
                  itemBuilder: (context, index) => _buildStickerItem(
                    stickerAssets[index],
                    stickersConfig.layerSize,
                    setLayer,
                  ),
                ),
        ),
      ],
    ),
  );
}

Widget _buildStickerLayerWidget(String assetPath, double size) => SizedBox(
      width: size,
      height: size,
      child: _buildStickerAsset(assetPath, size * 0.85),
    );

Widget _buildStickerAsset(String assetPath, double size) {
  if (assetPath.toLowerCase().endsWith('.png')) {
    return AppImage.asset(
      assetPath,
      width: size,
      height: size,
      fit: BoxFit.contain,
    );
  }
  return AppImage.svg(
    assetPath,
    width: size,
    height: size,
    fit: BoxFit.contain,
  );
}

/// Builds individual sticker items
Widget _buildStickerItem(
  String assetPath,
  double layerSize,
  Function(WidgetLayer) setLayer,
) =>
    GestureDetector(
      onTap: () {
        setLayer(
          WidgetLayer(
            widget: _buildStickerLayerWidget(assetPath, layerSize),
            exportConfigs: const WidgetLayerExportConfigs(),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
        ),
        child: Center(
          child: _buildStickerAsset(assetPath, 36),
        ),
      ),
    );
