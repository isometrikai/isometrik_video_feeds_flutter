import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ism_video_reel_player_example/domain/domain.dart';
import 'package:ism_video_reel_player_example/presentation/presentation.dart';
import 'package:ism_video_reel_player_example/res/res.dart';
import 'package:ism_video_reel_player_example/utils/utils.dart';

class SocialProductsBottomSheet extends StatefulWidget {
  const SocialProductsBottomSheet({
    Key? key,
    required this.products,
  }) : super(key: key);

  final List<SocialProductData> products;

  @override
  State<SocialProductsBottomSheet> createState() => _SocialProductsBottomSheetState();
}

class _SocialProductsBottomSheetState extends State<SocialProductsBottomSheet> {
  final List<SocialProductData> _productsList = [];
  final ScrollController _scrollController = ScrollController();
  var _hasMoreData = true;
  var _isLoadingMore = false;

  @override
  void initState() {
    _onStartInit();
    super.initState();
  }

  void _onStartInit() {
    _productsList.addAll(widget.products);
    _scrollController.addListener(_scrollListener);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollListener() {
    if (!_isLoadingMore &&
        _hasMoreData &&
        _scrollController.position.pixels >= _scrollController.position.maxScrollExtent * 0.65) {
      _hasMoreData = false;
      _isLoadingMore = true;
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, _) async {
          if (!didPop) {
            context.pop(_productsList);
          }
        },
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.8,
          ),
          decoration: BoxDecoration(
            color: 'FFFFFF'.toHexColor,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(Dimens.twenty),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Padding(
                padding: Dimens.edgeInsetsSymmetric(
                  horizontal: Dimens.sixteen,
                  vertical: Dimens.twenty,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'All Products',
                      style: Styles.primaryText18.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    TapHandler(
                      onTap: () {
                        context.pop(_productsList);
                      },
                      child: Icon(
                        Icons.close,
                        color: '000000'.toHexColor,
                        size: Dimens.twenty,
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              // Products List
              Expanded(
                child: ListView.separated(
                  controller: _scrollController,
                  padding: Dimens.edgeInsetsAll(Dimens.sixteen),
                  itemCount: _productsList.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 16),
                  itemBuilder: (context, index) => _buildProductItem(
                    context,
                    _productsList[index],
                    isSelected: index == 1, // Example selection, adjust as needed
                  ),
                ),
              ),
              const SizedBox(height: 20)
            ],
          ),
        ),
      );

  Widget _buildProductItem(
    BuildContext context,
    SocialProductData? productDataModel, {
    bool isSelected = false,
  }) =>
      Container(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 161, // 161
              width: 144, // 144
              decoration: BoxDecoration(
                border: Border.all(
                  color: 'EFEFEF'.toHexColor,
                  width: Dimens.one,
                ),
                borderRadius: Dimens.borderRadiusAll(Dimens.twelve),
              ),
              child: ClipRRect(
                borderRadius: Dimens.borderRadiusAll(Dimens.twelve),
                child: Stack(
                  children: [
                    AppImage.network(
                      productDataModel?.imageUrl ?? '',
                      height: 161, // 161
                      width: 144, // 144
                      fit: BoxFit.cover,
                    ),
                  ],
                ),
              ),
            ),
            // Product Details
            Expanded(
              child: Padding(
                padding: Dimens.edgeInsetsAll(Dimens.twelve),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Brand Name
                    Text(
                      productDataModel?.brandName?.toUpperCase() ?? '',
                      style: Styles.primaryText10.copyWith(
                        fontWeight: FontWeight.w500,
                        color: '838383'.toHexColor,
                      ),
                    ),
                    Text(
                      productDataModel?.name ?? '',
                      style: Styles.primaryText12.copyWith(
                        fontWeight: FontWeight.w500,
                        color: '333333'.toHexColor,
                      ),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 8),
                    // Prices
                    Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      spacing: 5,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              Utility.getFormattedPrice(productDataModel?.price?.toDouble() ?? 0,
                                  productDataModel?.currency?.symbol),
                              style: Styles.primaryText12.copyWith(
                                color: '868686'.toHexColor,
                                decoration: TextDecoration.lineThrough,
                              ),
                            ),
                          ],
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              Utility.getFormattedPrice(
                                  productDataModel?.discountPrice?.toDouble() ?? 0,
                                  productDataModel?.currency?.symbol),
                              style: Styles.primaryText14.copyWith(
                                color: '333333'.toHexColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
}
