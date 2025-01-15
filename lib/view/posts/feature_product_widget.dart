import 'package:flutter/cupertino.dart';
import 'package:ism_video_reel_player/export.dart';

class FeatureProductWidget extends StatelessWidget {
  const FeatureProductWidget({super.key, this.productData});

  final FeaturedProductDataItem? productData;

  @override
  Widget build(BuildContext context) => TapHandler(
        onTap: () {},
        child: Container(
          height: Dimens.ninety,
          width: Dimens.twoHundredTwenty,
          padding: Dimens.edgeInsetsSymmetric(
            vertical: Dimens.five,
            horizontal: Dimens.ten,
          ),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: Dimens.borderRadiusAll(Dimens.eight),
          ),
          child: Row(
            children: [
              AppImage.network(
                productData?.images?.first.small ?? '',
                height: Dimens.forty,
                width: Dimens.forty,
              ),
              Dimens.boxWidth(Dimens.ten),
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      productData?.productName ?? '',
                      style: Styles.secondaryText12,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Dimens.boxHeight(Dimens.five),
                    Text(
                      IsmVideoReelUtility.getFormattedPrice(
                          productData?.finalPriceList?.finalPrice?.toDouble() ?? 0, productData?.currencySymbol),
                      style: Styles.secondaryText12.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Dimens.boxHeight(Dimens.ten),
                    // AddToCartButton(
                    //   isDisable: false,
                    //   width: Dimens.eighty,
                    //   productCartStatus: ProductCartStatus(
                    //     productId: productData?.childProductId,
                    //     cartQuantity: 0,
                    //     availableQuantity: productData?.availableQuantity?.toInt(),
                    //     maxAllowedQuantity: 100,
                    //     offerDetails: {},
                    //   ),
                    //   height: Dimens.twentySix,
                    //   radius: Dimens.four,
                    // ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
}
