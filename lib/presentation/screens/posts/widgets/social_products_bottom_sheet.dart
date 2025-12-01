// import 'package:flutter/material.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:go_router/go_router.dart';
// import 'package:ism_video_reel_player/di/di.dart';
// import 'package:ism_video_reel_player/domain/domain.dart';
// import 'package:ism_video_reel_player/presentation/presentation.dart';
// import 'package:ism_video_reel_player/res/res.dart';
// import 'package:ism_video_reel_player/utils/utils.dart';
//
// class SocialProductsBottomSheet extends StatefulWidget {
//   const SocialProductsBottomSheet({
//     Key? key,
//     required this.products,
//     required this.postId,
//     this.postUserId,
//     this.addToCartCallBack,
//     required this.myUserId,
//     required this.deviceId,
//     this.productIds,
//   }) : super(key: key);
//
//   final List<ProductDataModel> products;
//   final String postId;
//   final List<String>? productIds;
//   final String? postUserId;
//   final String myUserId;
//   final String deviceId;
//   final Function(ProductCartStatus?, List<ProductDataModel>?)? addToCartCallBack;
//
//   @override
//   State<SocialProductsBottomSheet> createState() => _SocialProductsBottomSheetState();
// }
//
// class _SocialProductsBottomSheetState extends State<SocialProductsBottomSheet> {
//   final _socialPostBloc = InjectionUtils.getBloc<SocialPostBloc>();
//   final List<ProductDataModel> _productsList = [];
//   final ScrollController _scrollController = ScrollController();
//   var _hasMoreData = true;
//   var _isLoadingMore = false;
//   var _totalProductsCount = 0;
//
//   @override
//   void initState() {
//     _onStartInit();
//     super.initState();
//   }
//
//   void _onStartInit() {
//     if (widget.products.isListEmptyOrNull == true) {
//       _socialPostBloc
//           .add(GetSocialProductsEvent(postId: widget.postId, productIds: widget.productIds));
//     } else {
//       _productsList.addAll(widget.products);
//     }
//     _scrollController.addListener(_scrollListener);
//   }
//
//   @override
//   void dispose() {
//     _scrollController.removeListener(_scrollListener);
//     _scrollController.dispose();
//     super.dispose();
//   }
//
//   void _scrollListener() {
//     if (!_isLoadingMore &&
//         _hasMoreData &&
//         _scrollController.position.pixels >= _scrollController.position.maxScrollExtent * 0.65) {
//       _hasMoreData = false;
//       _isLoadingMore = true;
//       _socialPostBloc.add(GetSocialProductsEvent(postId: widget.postId, isFromPagination: true));
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) => PopScope(
//         canPop: false,
//         onPopInvokedWithResult: (didPop, _) async {
//           if (!didPop) {
//             context.pop(_productsList);
//           }
//         },
//         child: BlocBuilder<SocialPostBloc, SocialPostState>(
//           buildWhen: (previousState, currentState) =>
//               currentState is SocialProductsLoading || currentState is SocialProductsLoaded,
//           builder: (context, state) {
//             if (state is SocialProductsLoaded) {
//               _productsList.clear();
//               _productsList.addAll(state.productList as Iterable<ProductDataModel>);
//               _totalProductsCount = state.totalProductCount;
//               _hasMoreData = _productsList.length < _totalProductsCount;
//               _isLoadingMore = false;
//             }
//             return Container(
//               constraints: BoxConstraints(
//                 maxHeight: MediaQuery.of(context).size.height * 0.8,
//               ),
//               decoration: BoxDecoration(
//                 color: IsrColors.white,
//                 borderRadius: BorderRadius.vertical(
//                   top: Radius.circular(IsrDimens.twenty),
//                 ),
//               ),
//               child: Column(
//                 mainAxisSize: MainAxisSize.min,
//                 children: [
//                   // Header
//                   Padding(
//                     padding: IsrDimens.edgeInsetsSymmetric(
//                       horizontal: IsrDimens.sixteen,
//                       vertical: IsrDimens.twenty,
//                     ),
//                     child: Row(
//                       mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                       children: [
//                         Text(
//                           IsrTranslationFile.shopFromThisPost,
//                           style: IsrStyles.primaryText18.copyWith(
//                             fontWeight: FontWeight.w600,
//                           ),
//                         ),
//                         TapHandler(
//                           onTap: () {
//                             context.pop(_productsList);
//                           },
//                           child: const AppImage.svg(AssetConstants.icClose),
//                         ),
//                       ],
//                     ),
//                   ),
//                   const Divider(height: 1),
//                   // Products List
//                   Expanded(
//                     child: state is SocialProductsLoading
//                         ? Utility.loaderWidget()
//                         : _productsList.isListEmptyOrNull == true
//                             ? _buildPlaceHolderView()
//                             : ListView.separated(
//                                 controller: _scrollController,
//                                 padding: IsrDimens.edgeInsetsAll(IsrDimens.sixteen),
//                                 itemCount: _productsList.length,
//                                 separatorBuilder: (_, __) => 16.responsiveVerticalSpace,
//                                 itemBuilder: (context, index) => _buildProductItem(
//                                   context,
//                                   _productsList[index],
//                                   isSelected: index == 1, // Example selection, adjust as needed
//                                 ),
//                               ),
//                   ),
//                   if (_productsList.length > 1) ...[
//                     Padding(
//                       padding: const EdgeInsets.all(15),
//                       child: BulkAddToCartButton(
//                           productsList: _productsList,
//                           addToCartCallBack: () {
//                             if (widget.addToCartCallBack != null) {
//                               widget.addToCartCallBack!(null, _productsList);
//                             }
//                           }),
//                     ),
//                   ],
//                 ],
//               ),
//             );
//           },
//         ),
//       );
//
//   Widget _buildProductItem(
//     BuildContext context,
//     ProductDataModel? productDataModel, {
//     bool isSelected = false,
//   }) {
//     final isAutoShipProduct = productDataModel?.sellerPlanDetails != null &&
//         productDataModel?.sellerPlanDetails?.frequencies.isEmptyOrNull == false;
//     final offerMap = productDataModel?.bestOffer != null
//         ? productDataModel?.bestOffer?.toJson()
//         : productDataModel?.offers?.toJson();
//     final isOfferExpired = offerMap != null && offerMap.containsKey('status') == true
//         ? offerMap['status'] == 0
//         : false;
//     final isOfferAvailable =
//         Utility.isOfferAvailable(productDataModel?.finalPriceList) && !isOfferExpired;
//     final dynamic productImages = productDataModel?.images;
//     var imageUrl = productImages == null
//         ? ''
//         : (productImages is List<ImageData> && (productImages).isEmptyOrNull == false)
//             ? (productImages[0].small?.isEmpty == true
//                 ? productImages[0].medium ?? ''
//                 : productImages[0].small ?? '')
//             : (productImages is ImageData)
//                 ? (productImages.small?.isEmpty == true
//                     ? productImages.medium ?? ''
//                     : productImages.small ?? '')
//                 : '';
//     if (imageUrl.isEmpty) {
//       imageUrl = productDataModel?.productImage ?? '';
//     }
//     final finalPriceList = productDataModel?.finalPriceList;
//
//     final membersSavePercentage = (finalPriceList != null &&
//             finalPriceList.msrpPrice != null &&
//             finalPriceList.finalPrice != null)
//         ? ((finalPriceList.msrpPrice ?? 0) -
//                 (finalPriceList.finalPrice ?? 0) +
//                 (productDataModel?.rewardFinalPrice ?? 0)) /
//             (finalPriceList.msrpPrice?.toDouble() ?? 1) *
//             100
//         : 0;
//     final brandName = productDataModel?.brandTitle?.isEmptyOrNull == false
//         ? productDataModel?.brandTitle
//         : productDataModel?.brand?.isEmptyOrNull == false
//             ? productDataModel?.brand
//             : productDataModel?.storeName?.isEmptyOrNull == false
//                 ? productDataModel?.storeName
//                 : productDataModel?.store?.isEmptyOrNull == false
//                     ? productDataModel?.store
//                     : '';
//     final isHasVariants = productDataModel?.variantCount is num
//         ? ((productDataModel?.variantCount as num?) ?? 0) > 1
//         : (productDataModel?.variantCount as bool? ?? false) == true;
//     return Container(
//       height: 195.scaledValue,
//       padding: IsrDimens.edgeInsetsAll(8.scaledValue),
//       decoration: BoxDecoration(
//         border: Border.all(
//           color: IsrColors.colorEFEFEF,
//           width: IsrDimens.one,
//         ),
//         borderRadius: IsrDimens.borderRadiusAll(IsrDimens.twelve),
//       ),
//       child: TapHandler(
//         onTap: () {
//           _goToProductDetailScreen(productDataModel);
//         },
//         child: Row(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             ClipRRect(
//               borderRadius: IsrDimens.borderRadiusAll(IsrDimens.twelve),
//               child: ClipRRect(
//                 borderRadius: IsrDimens.borderRadiusAll(IsrDimens.twelve),
//                 child: Stack(
//                   children: [
//                     AppImage.network(
//                       imageUrl,
//                       height: 175.scaledValue,
//                       width: 160.scaledValue,
//                       fit: BoxFit.cover,
//                     ),
//                     if (isAutoShipProduct)
//                       _buildTag(
//                           productDataModel?.sellerPlanDetails?.sellerPlanName ?? '', '00000'.color),
//                     if ((productDataModel?.rewardFinalPrice?.toDouble() ?? 0) > 0)
//                       _buildEarnTalentTag(productDataModel?.rewardFinalPrice?.toDouble() ?? 0),
//                   ],
//                 ),
//               ),
//             ),
//             8.horizontalSpace,
//             // Product Details
//             Expanded(
//               child: SizedBox(
//                 height: 175.scaledValue,
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   mainAxisAlignment: MainAxisAlignment.spaceBetween, // KEY CHANGE: Added this
//                   children: [
//                     // TOP CONTENT - Wrap in Expanded to take available space
//                     Expanded(
//                       child: Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           Row(
//                             crossAxisAlignment: CrossAxisAlignment.start,
//                             children: [
//                               Expanded(
//                                 child: Column(
//                                   crossAxisAlignment: CrossAxisAlignment.start,
//                                   children: [
//                                     17.responsiveVerticalSpace,
//                                     // Brand Name
//                                     if (brandName.isEmptyOrNull == false) ...[
//                                       Text(
//                                         brandName?.toUpperCase() ?? '',
//                                         style: IsrStyles.primaryText10.copyWith(
//                                           fontWeight: FontWeight.w500,
//                                           color: IsrColors.color838383,
//                                         ),
//                                         overflow: TextOverflow.ellipsis,
//                                         maxLines: 1,
//                                       ),
//                                     ],
//                                     Text(
//                                       productDataModel?.productName ?? '',
//                                       style: IsrStyles.primaryText12.copyWith(
//                                         fontWeight: FontWeight.w500,
//                                         color: IsrColors.color333333,
//                                       ),
//                                       overflow: TextOverflow.ellipsis,
//                                       maxLines: 2,
//                                     ),
//                                   ],
//                                 ),
//                               ),
//                               Container(
//                                 alignment: Alignment.topRight,
//                                 child: FavouriteIconView(
//                                   productId: productDataModel?.childProductId ?? '',
//                                   height: 24.scaledValue,
//                                   width: 24.scaledValue,
//                                   selectedIcon: AssetConstants.icSocialProductLikeSelected,
//                                   unselectedIcon: AssetConstants.icSocialProductLike,
//                                   isFavorite: productDataModel?.isFavourite ?? false,
//                                 ),
//                               ),
//                             ],
//                           ),
//                           12.responsiveVerticalSpace,
//                           CustomDivider(
//                             color: '868686'.toColor(),
//                             height: 1,
//                           ),
//                           5.responsiveVerticalSpace,
//                           Row(
//                             crossAxisAlignment: CrossAxisAlignment.start,
//                             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                             children: [
//                               if (membersSavePercentage >= 10) ...[
//                                 Text(
//                                   '${membersSavePercentage.round()}% OFF',
//                                   style: IsrStyles.primaryText12.copyWith(
//                                     color: '128855'.color,
//                                     fontWeight: FontWeight.w700,
//                                   ),
//                                 ),
//                               ] else ...[
//                                 const Spacer(),
//                               ],
//                               Column(
//                                 mainAxisAlignment: MainAxisAlignment.start,
//                                 crossAxisAlignment: CrossAxisAlignment.end,
//                                 children: [
//                                   Text(
//                                     Utility.getFormattedPrice(
//                                         (productDataModel?.finalPriceList?.finalPrice?.toDouble() ??
//                                                 0) -
//                                             (productDataModel?.rewardFinalPrice?.toDouble() ?? 0),
//                                         productDataModel?.currencySymbol),
//                                     style: IsrStyles.primaryText16.copyWith(
//                                       color: Theme.of(context).primaryColor,
//                                       fontWeight: FontWeight.w700,
//                                     ),
//                                   ),
//                                   Text(
//                                     IsrTranslationFile.afterTalentsBack,
//                                     style: IsrStyles.primaryText10.copyWith(
//                                       color: '333333'.color,
//                                       fontWeight: FontWeight.w500,
//                                       fontStyle: FontStyle.italic,
//                                     ),
//                                   ),
//                                 ],
//                               ),
//                             ],
//                           ),
//                         ],
//                       ),
//                     ),
//
//                     // BOTTOM CONTENT - Add to Cart Button (always at bottom)
//                     FutureBuilder(
//                       builder: (context, snapShot) {
//                         final productCartStatus = snapShot.data;
//                         final isOutOfStock = (productDataModel?.outOfStock ?? false) &&
//                             !(productDataModel?.allowOrderOutOfStock ?? false);
//                         return AddToCartButton(
//                           isDisable: isOutOfStock,
//                           isNeedToShowQuantityButton: false,
//                           productCartStatus: productCartStatus ??
//                               ProductCartStatus(
//                                   productId: productDataModel?.childProductId,
//                                   cartQuantity: 0,
//                                   availableQuantity: productDataModel?.availableQuantity?.toInt(),
//                                   maxAllowedQuantity: productDataModel?.maxQuantityPerUser?.toInt(),
//                                   offerDetails: isOfferAvailable ? offerMap : null,
//                                   storeId: productDataModel?.storeId,
//                                   allowOrderOutOfStock: productDataModel?.allowOrderOutOfStock,
//                                   attributionLinkData: AttributionLinkData(
//                                     fingerprintId: widget.deviceId,
//                                     createdByUserId: widget.postUserId,
//                                     socialPostId: widget.postId,
//                                     isSocial: true,
//                                     userId: widget.myUserId,
//                                   )),
//                           height: 40.scaledValue,
//                           radius: 6.scaledValue,
//                           onTapAddButton: null,
//                           title:
//                               isOutOfStock ? IsrTranslationFile.outOfStock : IsrTranslationFile.addToCart,
//                           titleTextStyle: IsrStyles.white14.copyWith(fontWeight: FontWeight.w600),
//                           isNeedToShowGoToCartButton: false,
//                           onTapGoToCart: () {},
//                           addToCartCallBack: (productCartStatus) {
//                             if (widget.addToCartCallBack != null) {
//                               widget.addToCartCallBack!(productCartStatus, _productsList);
//                             }
//                           },
//                         );
//                       },
//                       future: _socialPostBloc
//                           .getProductCartStatus(productDataModel?.childProductId ?? ''),
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   Widget _buildTag(String tagName, Color backgroundColor) => Positioned(
//         top: 5,
//         left: 5,
//         child: ClipRRect(
//           borderRadius: BorderRadius.all(Radius.circular(6.scaledValue)),
//           child: Container(
//             padding: IsrDimens.edgeInsetsSymmetric(
//               horizontal: IsrDimens.eight,
//               vertical: IsrDimens.four,
//             ),
//             decoration: BoxDecoration(
//               color: backgroundColor,
//               borderRadius: BorderRadius.all(Radius.circular(6.scaledValue)),
//             ),
//             child: Text(
//               tagName,
//               textAlign: TextAlign.center,
//               style: IsrStyles.white10.copyWith(fontWeight: FontWeight.w500, color: '001E57'.color),
//             ),
//           ),
//         ),
//       );
//
//   Widget _buildEarnTalentTag(double talentValue) => Positioned(
//         bottom: 5,
//         left: 5,
//         right: 5,
//         child: Container(
//           padding: EdgeInsets.symmetric(
//             horizontal: 10.scaledValue,
//             vertical: 6.scaledValue,
//           ),
//           decoration: BoxDecoration(
//             color: IsrColors.white,
//             borderRadius: BorderRadius.circular(6.scaledValue),
//             boxShadow: [
//               BoxShadow(
//                 color: Colors.black.applyOpacity(0.12),
//                 blurRadius: 6,
//                 offset: const Offset(0, 2),
//               ),
//             ],
//           ),
//           child: Row(
//             mainAxisSize: MainAxisSize.min,
//             crossAxisAlignment: CrossAxisAlignment.center,
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               Text(
//                 '${IsrTranslationFile.earn} ',
//                 style: IsrStyles.white10.copyWith(
//                   fontSize: 12.scaledValue,
//                   fontWeight: FontWeight.w500,
//                   color: '333333'.color,
//                 ),
//               ),
//               AppImage.asset(
//                 AssetConstants.icTalentIcon,
//                 height: 14.scaledValue,
//                 width: 14.scaledValue,
//               ),
//               4.horizontalSpace,
//               Text(
//                 talentValue.toStringAsFixed(2), // consistent decimal format
//                 style: IsrStyles.white10.copyWith(
//                   fontSize: 13.scaledValue,
//                   fontWeight: FontWeight.w600,
//                   color: '333333'.color,
//                 ),
//               ),
//               4.horizontalSpace,
//               Expanded(
//                 child: Text(
//                   IsrTranslationFile.talents,
//                   style: IsrStyles.white10.copyWith(
//                     fontSize: 13.scaledValue,
//                     fontWeight: FontWeight.w600,
//                     color: '333333'.color,
//                   ),
//                   maxLines: 1,
//                   overflow: TextOverflow.ellipsis,
//                 ),
//               ),
//             ],
//           ),
//         ),
//       );
//
//   Widget _buildPlaceHolderView() => const Center(
//         child: AppPlaceHolderWidget(
//           assetName: AssetConstants.icNoProductsAvailable,
//           firstLineText: IsrTranslationFile.noProductFound,
//         ),
//       );
//
//   void _goToProductDetailScreen(ProductDataModel? productDataModel) {
//     context.pop(_productsList);
//     final pdpTitle = productDataModel?.brandTitle ?? productDataModel?.productName;
//     InjectionUtils.getRouteManagement().goToPdpScreen(
//       productId: productDataModel?.childProductId ?? '',
//       productName: pdpTitle ?? '',
//       productActualName: productDataModel?.productName ?? '',
//       category: '',
//       parentProductId: productDataModel?.parentProductId ?? '',
//       productSlug: productDataModel?.productSeo?.slug ?? '',
//     );
//   }
// }
