import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:ism_video_reel_player/presentation/presentation.dart';
import 'package:ism_video_reel_player/res/res.dart';
import 'package:ism_video_reel_player/utils/isr_utils.dart';

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

  @override
  Widget build(BuildContext context) => Container(
        height: height ?? dimensions,
        width: width ?? dimensions,
        padding: padding,
        decoration: BoxDecoration(
          borderRadius: isProfileImage ? null : borderRadius ?? BorderRadius.circular(radius ?? 0),
          shape: isProfileImage ? BoxShape.circle : BoxShape.rectangle,
          border: border,
        ),
        clipBehavior: Clip.antiAlias,
        child: switch (_imageType) {
          ImageType.asset => _Asset(path, fit: fit, height: height, width: width),
          ImageType.svg => _Svg(path, fit: fit, color: color, height: height, width: width),
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

  @override
  Widget build(BuildContext context) {
    final fullName = name.isStringEmptyOrNull == false ? name : '';
    final words = fullName.split(' ');
    final initials = words.map((word) => word.isNotEmpty ? word[0] : '').join('');
    final optimizedImageUrl = AppConstants.isGumletEnable
        ? IsrVideoReelUtility.buildGumletImageUrl(imageUrl: imageUrl, width: width, height: height)
        : imageUrl;
    return CachedNetworkImage(
      width: width,
      imageUrl: optimizedImageUrl,
      fit: fit ?? BoxFit.cover,
      alignment: Alignment.center,
      cacheKey: optimizedImageUrl,
      fadeInDuration:
          fadeAnimationEnable ?? false ? const Duration(milliseconds: 300) : Duration.zero,
      fadeOutDuration:
          fadeAnimationEnable ?? false ? const Duration(milliseconds: 300) : Duration.zero,
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
      placeholder: (context, url) => ImagePlaceHolder(
        borderRadius: borderRadius,
        placeHolderName: placeHolderName,
        width: width,
        height: height,
        boxFit: fit ?? BoxFit.contain,
        boxShape: isProfileImage ? BoxShape.circle : BoxShape.rectangle,
        child: name.isStringEmptyOrNull == false && isProfileImage
            ? Text(
                initials,
                style: IsrStyles.secondaryText14
                    .copyWith(fontWeight: FontWeight.w500, color: IsrColors.white),
                textAlign: TextAlign.center,
              )
            : null,
      ),
      errorWidget: (context, url, error) => ImagePlaceHolder(
        width: width,
        height: height,
        borderRadius: borderRadius,
        boxFit: fit ?? BoxFit.contain,
        padding: 4,
        placeHolderName: placeHolderName,
        boxShape: isProfileImage ? BoxShape.circle : BoxShape.rectangle,
        child: name.isStringEmptyOrNull == false && isProfileImage
            ? Text(
                initials,
                style: IsrStyles.secondaryText14
                    .copyWith(fontWeight: FontWeight.w500, color: IsrColors.white),
                textAlign: TextAlign.center,
              )
            : null,
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
