import 'package:flutter/cupertino.dart';
import 'package:ism_video_reel_player/export.dart';

class FeatureProductWidget extends StatelessWidget {
  const FeatureProductWidget({super.key, this.productData});

  final FeaturedProductDataItem? productData;

  @override
  Widget build(BuildContext context) => TapHandler(
        onTap: () {},
        child: Container(
          height: IsrDimens.ninety,
          width: IsrDimens.twoHundredTwenty,
          padding: IsrDimens.edgeInsetsSymmetric(
            vertical: IsrDimens.five,
            horizontal: IsrDimens.ten,
          ),
          decoration: BoxDecoration(
            color: IsrColors.white,
            borderRadius: IsrDimens.borderRadiusAll(IsrDimens.eight),
          ),
          child: Row(
            children: [
              AppImage.network(
                productData?.images?.first.small ?? '',
                height: IsrDimens.forty,
                width: IsrDimens.forty,
              ),
              IsrDimens.boxWidth(IsrDimens.ten),
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      productData?.productName ?? '',
                      style: IsrStyles.secondaryText12,
                      overflow: TextOverflow.ellipsis,
                    ),
                    IsrDimens.boxHeight(IsrDimens.five),
                    Text(
                      IsrVideoReelUtility.getFormattedPrice(
                          productData?.finalPriceList?.finalPrice?.toDouble() ?? 0, productData?.currencySymbol),
                      style: IsrStyles.secondaryText12.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    IsrDimens.boxHeight(IsrDimens.ten),
                    // AddToCartButton(
                    //   isDisable: false,
                    //   width: IsrDimens.eighty,
                    //   productCartStatus: ProductCartStatus(
                    //     productId: productData?.childProductId,
                    //     cartQuantity: 0,
                    //     availableQuantity: productData?.availableQuantity?.toInt(),
                    //     maxAllowedQuantity: 100,
                    //     offerDetails: {},
                    //   ),
                    //   height: IsrDimens.twentySix,
                    //   radius: IsrDimens.four,
                    // ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
}
