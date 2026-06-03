import 'dart:io';

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
      style: PaintEditorStyle(
          uiOverlayStyle: mediaEditorUiOverlay(mediaEditConfig),
          appBarColor: mediaEditConfig.blackColor,
          appBarBackground: mediaEditConfig.whiteColor,
          bottomBarBackground: mediaEditConfig.whiteColor,
          bottomBarActiveItemColor: mediaEditConfig.primaryColor,
          bottomBarInactiveItemColor: Colors.black.changeOpacity(0.4),
          bottomBarTextSize: IsrDimens.twelve,
          bottomBarIconSize: IsrDimens.twentyFour,
          bottomBarHeight: IsrDimens.seventy,
          background: mediaEditConfig.whiteColor,
          lineWidthBottomSheetBackground: mediaEditConfig.whiteColor,
          opacityBottomSheetBackground: mediaEditConfig.whiteColor),
    );

TextEditorConfigs textEditorConfigs(MediaEditConfig mediaEditConfig) =>
    TextEditorConfigs(
      safeArea: const EditorSafeArea(bottom: false),
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
      uiOverlayStyle: mediaEditorUiOverlay(mediaEditConfig),
      appBarColor: mediaEditConfig.blackColor,
      appBarBackground: mediaEditConfig.whiteColor,
      bottomBarBackground: mediaEditConfig.whiteColor,
      background: mediaEditConfig.backgroundColor,
    ));

FilterEditorConfigs filterEditorConfigs(MediaEditConfig mediaEditConfig) =>
    FilterEditorConfigs(
        style: FilterEditorStyle(
      uiOverlayStyle: mediaEditorUiOverlay(mediaEditConfig),
      background: mediaEditConfig.backgroundColor,
      appBarColor: mediaEditConfig.blackColor,
      appBarBackground: mediaEditConfig.whiteColor,
      previewTextColor: mediaEditConfig.primaryTextColor,
      previewSelectedTextColor: mediaEditConfig.primaryColor,
    ));

BlurEditorConfigs blurEditorConfigs(MediaEditConfig mediaEditConfig) =>
    BlurEditorConfigs(
        style: BlurEditorStyle(
      uiOverlayStyle: mediaEditorUiOverlay(mediaEditConfig),
      appBarForegroundColor: mediaEditConfig.blackColor,
      appBarBackgroundColor: mediaEditConfig.whiteColor,
      background: mediaEditConfig.whiteColor,
    ));

TuneEditorConfigs tuneEditorConfigs(MediaEditConfig mediaEditConfig) =>
    TuneEditorConfigs(
        style: TuneEditorStyle(
      uiOverlayStyle: mediaEditorUiOverlay(mediaEditConfig),
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
