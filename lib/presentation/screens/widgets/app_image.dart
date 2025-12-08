import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:ism_video_reel_player/presentation/presentation.dart';
import 'package:ism_video_reel_player/res/res.dart';
import 'package:ism_video_reel_player/utils/utils.dart';

class AppImage extends StatelessWidget {
  const AppImage.asset(
    this.path, {
    super.key,
    this.name = '',
    this.fit,
    this.isProfileImage = false,
    this.dimensions,
    this.height,
    this.width,
    this.radius,
    this.borderRadius,
    this.border,
    this.padding,
    this.placeHolderName,
    this.fadeAnimationEnable,
    this.filterQuality,
    this.textColor,
  })  : _imageType = ImageType.asset,
        showError = false,
        color = null;

  const AppImage.svg(
    this.path, {
    super.key,
    this.name = '',
    this.fit,
    this.isProfileImage = false,
    this.dimensions,
    this.height,
    this.width,
    this.radius,
    this.color,
    this.borderRadius,
    this.border,
    this.padding,
    this.placeHolderName,
    this.fadeAnimationEnable,
    this.filterQuality,
    this.textColor,
  })  : _imageType = ImageType.svg,
        showError = false;

  const AppImage.network(
    this.path, {
    super.key,
    this.name = '',
    this.fit,
    this.isProfileImage = false,
    this.dimensions,
    this.height,
    this.width,
    this.radius,
    this.borderRadius,
    this.border,
    this.showError = true,
    this.padding,
    this.placeHolderName,
    this.fadeAnimationEnable,
    this.filterQuality,
    this.textColor,
  })  : _imageType = ImageType.network,
        color = null;

  const AppImage.file(
    this.path, {
    super.key,
    this.name = '',
    this.fit,
    this.isProfileImage = false,
    this.dimensions,
    this.height,
    this.width,
    this.radius,
    this.borderRadius,
    this.border,
    this.padding,
    this.placeHolderName,
    this.fadeAnimationEnable,
    this.filterQuality,
    this.textColor,
  })  : _imageType = ImageType.file,
        showError = false,
        color = null;

  final String path;
  final String name;
  final bool isProfileImage;
  final double? dimensions;
  final double? height;
  final double? width;
  final double? radius;
  final Color? color;
  final BorderRadius? borderRadius;
  final ImageType _imageType;
  final Border? border;
  final bool showError;
  final EdgeInsets? padding;
  final String? placeHolderName;
  final BoxFit? fit;
  final bool? fadeAnimationEnable;
  final FilterQuality? filterQuality;
  final Color? textColor;

  @override
  Widget build(BuildContext context) => Container(
        height: height ?? dimensions,
        width: width ?? dimensions,
        padding: padding,
        decoration: BoxDecoration(
          borderRadius: isProfileImage
              ? null
              : borderRadius ?? BorderRadius.circular(radius ?? 0),
          shape: isProfileImage ? BoxShape.circle : BoxShape.rectangle,
          border: border,
        ),
        clipBehavior: Clip.antiAlias,
        child: switch (_imageType) {
          ImageType.asset =>
            _Asset(path, fit: fit, height: height, width: width),
          ImageType.svg =>
            _Svg(path, fit: fit, color: color, height: height, width: width),
          ImageType.file => _File(
              path,
              fit: fit,
              height: height,
              width: width,
            ),
          ImageType.network => _Network(
              path,
              height: height,
              width: width,
              fit: fit,
              isProfileImage: isProfileImage,
              name: name,
              showError: showError,
              placeHolderName: placeHolderName,
              borderRadius: borderRadius,
              fadeAnimationEnable: fadeAnimationEnable,
              filterQuality: filterQuality,
              textColor: textColor,
            ),
        },
      );
}

class _Asset extends StatelessWidget {
  const _Asset(
    this.path, {
    this.fit,
    this.height,
    this.width,
  });

  final String path;
  final BoxFit? fit;
  final double? height;
  final double? width;

  @override
  Widget build(BuildContext context) => Image.asset(
        path,
        fit: fit,
        height: height,
        width: width,
      );
}

class _File extends StatelessWidget {
  const _File(
    this.path, {
    this.fit,
    this.height,
    this.width,
  });

  final String path;
  final BoxFit? fit;
  final double? height;
  final double? width;

  @override
  Widget build(BuildContext context) => Image.file(
        File(path),
        fit: fit ?? BoxFit.cover,
        height: height,
        width: width,
      );
}

class _Network extends StatelessWidget {
  const _Network(
    this.imageUrl, {
    required this.name,
    required this.isProfileImage,
    required this.showError,
    this.fit,
    this.placeHolderName,
    this.height,
    this.width,
    this.borderRadius,
    this.fadeAnimationEnable = false,
    this.filterQuality,
    this.textColor,
  });

  final String imageUrl;
  final String name;
  final String? placeHolderName;
  final bool isProfileImage;
  final bool showError;
  final BoxFit? fit;
  final double? height;
  final double? width;
  final BorderRadius? borderRadius;
  final bool? fadeAnimationEnable;
  final FilterQuality? filterQuality;
  final Color? textColor;

  @override
  Widget build(BuildContext context) {
    final fullName = name.isStringEmptyOrNull == false ? name : '';
    final words = fullName.split(' ');
    final initials =
        words.map((word) => word.isNotEmpty ? word[0] : '').join('');
    final isOptimizationEnable =
        imageUrl.contains('https://cdn.trulyfreehome.dev');

    final optimizedImageUrl =
        AppConstants.isGumletEnable && isOptimizationEnable
            ? Utility.buildGumletImageUrl(
                imageUrl: imageUrl.trim().replaceAll(RegExp(r'[",]+$'), ''),
                width: width,
                height: height)
            : imageUrl.trim().replaceAll(RegExp(r'[",]+$'), '');
    // debugPrint('optimizedImageUrl: $optimizedImageUrl');
    return CachedNetworkImage(
      width: width,
      imageUrl: optimizedImageUrl,
      filterQuality: filterQuality ?? FilterQuality.high,
      fit: fit ?? BoxFit.cover,
      alignment: Alignment.center,
      cacheKey: optimizedImageUrl,
      fadeInDuration: fadeAnimationEnable ?? false
          ? const Duration(milliseconds: 300)
          : Duration.zero,
      fadeOutDuration: fadeAnimationEnable ?? false
          ? const Duration(milliseconds: 300)
          : Duration.zero,
      placeholderFadeInDuration: Duration.zero,
      imageBuilder: (_, image) => ClipRRect(
        borderRadius: borderRadius ?? BorderRadius.zero,
        child: Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            borderRadius: borderRadius,
            shape: isProfileImage ? BoxShape.circle : BoxShape.rectangle,
            image: DecorationImage(image: image, fit: fit ?? BoxFit.cover),
          ),
        ),
      ),
      placeholder: (context, url) => showError
          ? ImagePlaceHolder(
              width: width,
              height: height,
              borderRadius: borderRadius,
              placeHolderName: placeHolderName,
              boxShape: isProfileImage ? BoxShape.circle : BoxShape.rectangle,
              child: name.isStringEmptyOrNull == false && isProfileImage
                  ? Center(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(
                            initials,
                            style: IsrStyles.secondaryText14.copyWith(
                                fontWeight: FontWeight.w500, color: textColor),
                            textAlign: TextAlign.center,
                            maxLines: 1,
                          ),
                        ),
                      ),
                    )
                  : null,
            )
          : Container(
              width: width,
              height: height,
              decoration: BoxDecoration(
                color: Colors.black.changeOpacity(0.3),
                borderRadius: borderRadius,
                shape: isProfileImage ? BoxShape.circle : BoxShape.rectangle,
              ),
            ),
      errorWidget: (context, url, error) => showError
          ? ImagePlaceHolder(
              width: width,
              height: height,
              borderRadius: borderRadius,
              boxFit: fit ?? BoxFit.contain,
              padding: 4,
              placeHolderName: placeHolderName,
              boxShape: isProfileImage ? BoxShape.circle : BoxShape.rectangle,
              child: name.isStringEmptyOrNull == false && isProfileImage
                  ? Center(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(
                            initials,
                            style: IsrStyles.secondaryText14.copyWith(
                                fontWeight: FontWeight.w500, color: textColor),
                            textAlign: TextAlign.center,
                            maxLines: 1,
                          ),
                        ),
                      ),
                    )
                  : null,
            )
          : Container(
              width: width,
              height: height,
              decoration: BoxDecoration(
                color: Colors.black.changeOpacity(0.3),
                borderRadius: borderRadius,
                shape: isProfileImage ? BoxShape.circle : BoxShape.rectangle,
              ),
            ),
    );
  }
}

class _Svg extends StatelessWidget {
  const _Svg(
    this.path, {
    this.color,
    this.fit,
    this.height,
    this.width,
  });

  final String path;
  final Color? color;
  final BoxFit? fit;
  final double? height;
  final double? width;

  @override
  Widget build(BuildContext context) => SvgPicture.asset(
        path,
        height: height,
        width: width,
        fit: fit ?? BoxFit.cover,
        colorFilter: color != null
            ? ColorFilter.mode(
                color!,
                BlendMode.srcIn,
              )
            : null,
      );
}
