import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ism_video_reel_player/presentation/screens/media/media_edit/media_edit_config.dart';
import 'package:ism_video_reel_player/res/res.dart';
import 'package:ism_video_reel_player/utils/utils.dart';
import 'package:pro_image_editor/pro_image_editor.dart';

PaintEditorConfigs paintEditorConfigs(MediaEditConfig mediaEditConfig) =>
    PaintEditorConfigs(
      style: PaintEditorStyle(
          uiOverlayStyle: uiOverLay,
          appBarColor: mediaEditConfig.blackColor,
          appBarBackground: mediaEditConfig.whiteColor,
          bottomBarBackground: mediaEditConfig.whiteColor,
          bottomBarActiveItemColor: mediaEditConfig.primaryColor,
          bottomBarInactiveItemColor: mediaEditConfig.primaryTextColor,
          background: mediaEditConfig.whiteColor,
          lineWidthBottomSheetBackground: mediaEditConfig.whiteColor,
          opacityBottomSheetBackground: mediaEditConfig.whiteColor),
    );

TextEditorConfigs textEditorConfigs(MediaEditConfig mediaEditConfig) =>
    TextEditorConfigs(
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
        style: CropRotateEditorStyle(
      uiOverlayStyle: uiOverLay,
      appBarColor: mediaEditConfig.blackColor,
      appBarBackground: mediaEditConfig.whiteColor,
      bottomBarBackground: mediaEditConfig.whiteColor,
      background: mediaEditConfig.backgroundColor,
    ));

FilterEditorConfigs filterEditorConfigs(MediaEditConfig mediaEditConfig) =>
    FilterEditorConfigs(
        style: FilterEditorStyle(
      uiOverlayStyle: uiOverLay,
      background: mediaEditConfig.backgroundColor,
      appBarColor: mediaEditConfig.blackColor,
      appBarBackground: mediaEditConfig.whiteColor,
      previewTextColor: mediaEditConfig.primaryTextColor,
      previewSelectedTextColor: mediaEditConfig.primaryColor,
    ));

BlurEditorConfigs blurEditorConfigs(MediaEditConfig mediaEditConfig) =>
    BlurEditorConfigs(
        style: BlurEditorStyle(
      uiOverlayStyle: uiOverLay,
      appBarForegroundColor: mediaEditConfig.blackColor,
      appBarBackgroundColor: mediaEditConfig.whiteColor,
      background: mediaEditConfig.whiteColor,
    ));

TuneEditorConfigs tuneEditorConfigs(MediaEditConfig mediaEditConfig) =>
    TuneEditorConfigs(
        style: TuneEditorStyle(
      uiOverlayStyle: uiOverLay,
      appBarColor: mediaEditConfig.blackColor,
      appBarBackground: mediaEditConfig.whiteColor,
      bottomBarBackground: mediaEditConfig.whiteColor,
      bottomBarActiveItemColor: mediaEditConfig.primaryColor,
      bottomBarInactiveItemColor: mediaEditConfig.primaryTextColor,
      background: mediaEditConfig.backgroundColor,
    ));

EmojiEditorConfigs emojiEditorConfigs(MediaEditConfig mediaEditConfig) =>
    const EmojiEditorConfigs();

StickerEditorConfigs stickerEditorConfigs(MediaEditConfig mediaEditConfig) =>
    const StickerEditorConfigs(
      builder: _buildStickerPicker,
    );

final uiOverLay = const SystemUiOverlayStyle(
  statusBarColor: IsrColors.appBarColor,
  statusBarIconBrightness: Brightness.dark,
  statusBarBrightness: Brightness.light,
  systemNavigationBarColor: IsrColors.navigationBar,
  systemNavigationBarIconBrightness: Brightness.dark,
);

MainEditorConfigs mainEditorConfig(MediaEditConfig mediaEditConfig) =>
    MainEditorConfigs(
        enableZoom: false,
        enableDoubleTapZoom: false,
        mobilePanInteraction: MobilePanInteraction.dragSelect,
        style: MainEditorStyle(
          uiOverlayStyle: uiOverLay,
          appBarColor: mediaEditConfig.blackColor,
          appBarBackground: mediaEditConfig.whiteColor,
          bottomBarBackground: mediaEditConfig.whiteColor,
          bottomBarColor: mediaEditConfig.primaryTextColor,
          background: mediaEditConfig.whiteColor,
          bodyPadding: const EdgeInsets.all(12),
          bodyBackground: mediaEditConfig.blackColor,
          bodyBorderColor: mediaEditConfig.blackColor,
          bodyCornerRadius: 20.responsiveDimension,
          bodyBorderWidth: 0,
          outsideCaptureAreaLayerOpacity: 0,
        ),
        tools: [
          SubEditorMode.paint,
          SubEditorMode.text,
          SubEditorMode.cropRotate,
          SubEditorMode.tune,
          SubEditorMode.filter,
          SubEditorMode.blur,
          SubEditorMode.emoji,
          SubEditorMode.sticker,
        ],
        bottomBarHeight: 100.responsiveDimension,
        bottomBarIconSpacing: 16.responsiveDimension,
        bottomBarIcon: (title, iconData) => Container(
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
                    style: IsrStyles.primaryText14
                        .copyWith(fontWeight: FontWeight.w500),
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  )
                ],
              ),
            ));

ProImageEditorConfigs proImageEditorConfigs(MediaEditConfig mediaEditConfig) =>
    ProImageEditorConfigs(
      theme: ThemeData.light(),
      dialogConfigs: const DialogConfigs(
          style: DialogStyle(
              loadingDialog:
                  LoadingDialogStyle(textColor: IsrColors.primaryTextColor))),
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

/// Builds the sticker picker interface
Widget _buildStickerPicker(
  Function(WidgetLayer) setLayer,
  ScrollController scrollController,
) =>
    Container(
      height: 300,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Stickers',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: GridView.builder(
              controller: scrollController,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: _getStickerCount(),
              itemBuilder: (context, index) =>
                  _buildStickerItem(index, setLayer),
            ),
          ),
        ],
      ),
    );

/// Returns the number of available stickers
int _getStickerCount() => 20;

/// Builds individual sticker items
Widget _buildStickerItem(int index, Function(WidgetLayer) setLayer) =>
    GestureDetector(
      onTap: () {
        // Create a simple text-based sticker for demonstration
        // In a real implementation, you would use actual sticker images
        final stickerWidget = Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            color: Colors.blue.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.blue, width: 2),
          ),
          child: const Center(
            child: Text(
              '😊', // Simple emoji as placeholder
              style: TextStyle(fontSize: 40),
            ),
          ),
        );

        // Create a WidgetLayer with the sticker
        final widgetLayer = WidgetLayer(
          widget: stickerWidget,
          exportConfigs: const WidgetLayerExportConfigs(),
        );

        // Set the layer and close the picker
        setLayer(widgetLayer);
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
        ),
        child: const Center(
          child: Text(
            '😊', // Placeholder emoji
            style: TextStyle(fontSize: 30),
          ),
        ),
      ),
    );
