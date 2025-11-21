import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:ism_video_reel_player/domain/domain.dart';
import 'package:ism_video_reel_player/presentation/presentation.dart';
import 'package:ism_video_reel_player/res/res.dart';
import 'package:ism_video_reel_player/utils/utils.dart';

class ProductToLinkItem extends StatefulWidget {
  const ProductToLinkItem({
    Key? key,
    required this.productDataModel,
    required this.onRemove,
    required this.onLink,
    this.isLinked = false,
  }) : super(key: key);

  final ProductDataModel productDataModel;
  final bool Function() onRemove;
  final bool Function() onLink;
  final bool isLinked;

  @override
  State<ProductToLinkItem> createState() => _ProductToLinkItemState();
}

class _ProductToLinkItemState extends State<ProductToLinkItem> {
  ProductDataModel? productDataModel;

  @override
  void initState() {
    productDataModel = widget.productDataModel;
    super.initState();
  }

  @override
  void didUpdateWidget(ProductToLinkItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Update the internal state when widget properties change
    if (oldWidget.productDataModel != widget.productDataModel) {
      productDataModel = widget.productDataModel;
    }
    // Force rebuild when isLinked state changes
    if (oldWidget.isLinked != widget.isLinked) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAutoShipProduct = productDataModel?.sellerPlanDetails != null &&
        productDataModel?.sellerPlanDetails?.frequencies.isEmptyOrNull == false;
    final dynamic productImages = productDataModel?.images;
    var imageUrl = productImages == null
        ? ''
        : (productImages is List<ImageData> && (productImages).isEmptyOrNull == false)
            ? (productImages[0].small?.isEmpty == true
                ? productImages[0].medium ?? ''
                : productImages[0].small ?? '')
            : (productImages is ImageData)
                ? (productImages.small?.isEmpty == true
                    ? productImages.medium ?? ''
                    : productImages.small ?? '')
                : productImages.toString();
    if (imageUrl.isEmpty) {
      imageUrl = productDataModel?.productImage ?? '';
    }
    final finalPriceList = productDataModel?.finalPriceList;
    final membersSavePercentage = (finalPriceList != null &&
            finalPriceList.msrpPrice != null &&
            finalPriceList.basePrice != null)
        ? ((finalPriceList.msrpPrice! - finalPriceList.basePrice!) / finalPriceList.msrpPrice!) *
            100
        : 0;
    final brandName = productDataModel?.brandTitle?.isEmptyOrNull == false
        ? productDataModel?.brandTitle
        : productDataModel?.brand?.isEmptyOrNull == false
            ? productDataModel?.brand
            : productDataModel?.storeName?.isEmptyOrNull == false
                ? productDataModel?.storeName
                : productDataModel?.store?.isEmptyOrNull == false
                    ? productDataModel?.store
                    : '';
    return Container(
      padding: IsrDimens.edgeInsetsAll(8.responsiveDimension),
      decoration: BoxDecoration(
        border: Border.all(
          color: IsrColors.colorEFEFEF,
          width: IsrDimens.one,
        ),
        borderRadius: IsrDimens.borderRadiusAll(IsrDimens.twelve),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left side with image and AutoShip badge
          Stack(
            children: [
              AppImage.network(
                imageUrl,
                height: 166.responsiveDimension,
                width: 160.responsiveDimension,
                fit: BoxFit.cover,
              ),
              if (isAutoShipProduct)
                _buildTag(productDataModel?.sellerPlanDetails?.sellerPlanName ?? '', '00000'.color),
              if ((productDataModel?.rewardFinalPrice?.toDouble() ?? 0) > 0)
                _buildEarnTalentTag(productDataModel?.rewardFinalPrice?.toDouble() ?? 0),
            ],
          ),
          16.horizontalSpace,
          // Right side with product details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Brand Name
                if (brandName.isEmptyOrNull == false) ...[
                  Text(
                    brandName?.toUpperCase() ?? '',
                    style: IsrStyles.primaryText10.copyWith(
                      fontWeight: FontWeight.w500,
                      color: IsrColors.black,
                    ),
                  ),
                  4.verticalSpace,
                ],
                Text(
                  productDataModel?.productName ?? '',
                  style: IsrStyles.primaryText12.copyWith(
                    fontWeight: FontWeight.w500,
                    color: IsrColors.color333333,
                  ),
                  maxLines: 2,
                ),
                12.verticalSpace,
                CustomDivider(
                  height: 1.responsiveDimension,
                  color: '#868686'.toColor(),
                ),
                6.verticalSpace,
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (membersSavePercentage > 0) ...[
                      Text(
                        '${membersSavePercentage.round()}% OFF',
                        style: IsrStyles.primaryText12.copyWith(
                          color: '128855'.color,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ] else ...[
                      const Spacer(),
                    ],
                    Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          Utility.getFormattedPrice(
                              (productDataModel?.finalPriceList?.basePrice?.toDouble() ?? 0) -
                                  (productDataModel?.rewardFinalPrice?.toDouble() ?? 0),
                              productDataModel?.currencySymbol),
                          style: IsrStyles.primaryText16.copyWith(
                            color: Theme.of(context).primaryColor,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          IsrTranslationFile.afterTalentsBack,
                          style: IsrStyles.primaryText10.copyWith(
                            color: '333333'.color,
                            fontWeight: FontWeight.w500,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                8.verticalSpace,
                AppButton(
                  height: 40.responsiveDimension,
                  title: widget.isLinked
                      ? IsrTranslationFile.unLink
                      : (productDataModel?.allowOrderOutOfStock != true &&
                              productDataModel?.isAllVariantInStock == '0')
                          ? IsrTranslationFile.outOfStock
                          : IsrTranslationFile.link,
                  textStyle: IsrStyles.primaryText14.copyWith(
                      fontWeight: FontWeight.w600,
                      color: widget.isLinked ? IsrColors.appColor : IsrColors.white),
                  type: widget.isLinked ? ButtonType.secondary : ButtonType.primary,
                  isDisable:
                      widget.isLinked == false && productDataModel?.isAllVariantInStock == '0',
                  width: 101.responsiveDimension,
                  size: ButtonSize.small,
                  onPress: () {
                    if (widget.isLinked) {
                      widget.onRemove();
                    } else {
                      widget.onLink();
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTag(String tagName, Color backgroundColor) => Positioned(
        top: 5,
        left: 5,
        child: ClipRRect(
          borderRadius: BorderRadius.all(Radius.circular(6.responsiveDimension)),
          child: Container(
            padding: IsrDimens.edgeInsetsSymmetric(
              horizontal: IsrDimens.eight,
              vertical: IsrDimens.four,
            ),
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.all(Radius.circular(6.responsiveDimension)),
            ),
            child: Text(
              tagName,
              textAlign: TextAlign.center,
              style: IsrStyles.white10.copyWith(fontWeight: FontWeight.w500, color: '001E57'.color),
            ),
          ),
        ),
      );

  Widget _buildEarnTalentTag(double talentValue) => Positioned(
        bottom: 5,
        left: 5,
        child: Container(
          padding: IsrDimens.edgeInsetsSymmetric(
            horizontal: IsrDimens.four,
            vertical: IsrDimens.four,
          ),
          decoration: BoxDecoration(
            color: IsrColors.white,
            borderRadius: IsrDimens.borderRadiusAll(6.responsiveDimension),
            border: Border.all(
                color: IsrColors.black.changeOpacity(0.3), width: 0.5.responsiveDimension),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Text(
                '${IsrTranslationFile.earn} ',
                textAlign: TextAlign.center,
                style:
                    IsrStyles.white10.copyWith(fontWeight: FontWeight.w500, color: '333333'.color),
              ),
              3.horizontalSpace,
              AppImage.asset(
                AssetConstants.icTalentIcon,
                height: 11.responsiveDimension,
                width: 11.responsiveDimension,
              ),
              2.horizontalSpace,
              Text(
                talentValue.toStringAsFixed(2),
                textAlign: TextAlign.center,
                style:
                    IsrStyles.white10.copyWith(fontWeight: FontWeight.w500, color: '333333'.color),
              ),
              3.horizontalSpace,
              Text(
                IsrTranslationFile.talents,
                textAlign: TextAlign.center,
                style:
                    IsrStyles.white10.copyWith(fontWeight: FontWeight.w500, color: '333333'.color),
              ),
            ],
          ),
        ),
      );
}
