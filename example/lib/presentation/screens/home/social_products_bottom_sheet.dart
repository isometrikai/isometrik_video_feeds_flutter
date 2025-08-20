import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:ism_video_reel_player_example/di/di.dart';
import 'package:ism_video_reel_player_example/domain/domain.dart';
import 'package:ism_video_reel_player_example/presentation/presentation.dart';
import 'package:ism_video_reel_player_example/res/res.dart';
import 'package:ism_video_reel_player_example/utils/utils.dart';

class SocialProductsBottomSheet extends StatefulWidget {
  const SocialProductsBottomSheet({
    Key? key,
    this.products,
    this.productIds,
  }) : super(key: key);

  final List<SocialProductData>? products;
  final List<String>? productIds;

  @override
  State<SocialProductsBottomSheet> createState() => _SocialProductsBottomSheetState();
}

class _SocialProductsBottomSheetState extends State<SocialProductsBottomSheet> {
  final List<ProductDataModel> _productsList = [];
  final ScrollController _scrollController = ScrollController();
  var _hasMoreData = true;
  var _isLoadingMore = false;
  final _homeBloc = InjectionUtils.getBloc<HomeBloc>();
  var _totalProductsCount = 0;

  @override
  void initState() {
    _onStartInit();
    super.initState();
  }

  void _onStartInit() {
    _homeBloc.add(GetPostDetailsEvent(productIds: widget.productIds));
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
        child: BlocBuilder<HomeBloc, HomeState>(
          buildWhen: (previousState, currentState) =>
              currentState is PostDetailsLoading || currentState is PostDetailsLoaded,
          builder: (context, state) {
            if (state is PostDetailsLoaded) {
              _productsList.clear();
              _productsList.addAll(state.productList as Iterable<ProductDataModel>);
              _totalProductsCount = state.totalProductCount;
              _hasMoreData = _productsList.length < _totalProductsCount;
              _isLoadingMore = false;
            }
            return Container(
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
                    child: state is PostDetailsLoading
                        ? Utility.loaderWidget()
                        : _productsList.isEmptyOrNull == true
                            ? _buildPlaceHolderView()
                            : ListView.separated(
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
            );
          },
        ),
      );

  Widget _buildProductItem(
    BuildContext context,
    ProductDataModel? productDataModel, {
    bool isSelected = false,
  }) {
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
                : '';
    if (imageUrl.isEmpty) {
      imageUrl = productDataModel?.productImage ?? '';
    }
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
                    imageUrl,
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
                    brandName ?? '',
                    style: Styles.primaryText10.copyWith(
                      fontWeight: FontWeight.w500,
                      color: '838383'.toHexColor,
                    ),
                  ),
                  Text(
                    productDataModel?.productName ?? '',
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
                            Utility.getFormattedPrice(
                                (productDataModel?.finalPriceList?.basePrice?.toDouble() ?? 0) -
                                    (productDataModel?.rewardFinalPrice?.toDouble() ?? 0),
                                productDataModel?.currencySymbol),
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
                                productDataModel?.finalPriceList?.msrpPrice?.toDouble() ?? 0,
                                productDataModel?.currencySymbol),
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

  Widget _buildPlaceHolderView() => Center(
        child: Text(
          'No product found',
          style: Styles.primaryText14,
        ),
      );
}
