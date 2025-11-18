// import 'package:flutter/material.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:flutter_screenutil/flutter_screenutil.dart';
// import 'package:ism_video_reel_player/di/di.dart';
// import 'package:ism_video_reel_player/domain/domain.dart';
// import 'package:ism_video_reel_player/presentation/presentation.dart';
// import 'package:ism_video_reel_player/res/res.dart';
// import 'package:ism_video_reel_player/utils/utils.dart';
//
// class LinkProductsView extends StatefulWidget {
//   const LinkProductsView({super.key, this.linkedProducts});
//
//   final List<ProductDataModel>? linkedProducts;
//
//   @override
//   State<LinkProductsView> createState() => _LinkProductsViewState();
// }
//
// class _LinkProductsViewState extends State<LinkProductsView> {
//   final TextEditingController _searchController = TextEditingController();
//   var _products = <ProductDataModel>[]; // Replace with your product model
//   final _createPostBloc = BlocProvider.of<CreatePostBloc>(context);
//   final _linkedProductList = <ProductDataModel>[];
//   var _totalProductsCount = 0;
//
//   final ScrollController _scrollController = ScrollController();
//   var _hasMoreData = true;
//   var _isLoadingMore = false;
//
//   // Expansion state for linked products
//   bool _isLinkedProductsExpanded = false;
//
//   @override
//   void initState() {
//     super.initState();
//     _loadProducts();
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
//       _createPostBloc.add(GetProductsEvent(isFromPagination: true));
//     }
//   }
//
//   void _loadProducts() {
//     _linkedProductList.clear();
//     if (widget.linkedProducts != null) {
//       _linkedProductList.addAll(widget.linkedProducts!);
//     }
//     _searchController.clear();
//     _createPostBloc.add(GetProductsEvent());
//   }
//
//   void _removeProduct(ProductDataModel product) {
//     setState(() {
//       if (_linkedProductList.contains(product)) {
//         _linkedProductList.remove(product);
//       }
//       if (_linkedProductList.isEmpty) {
//         _isLinkedProductsExpanded = false;
//       }
//     });
//   }
//
//   void _linkProduct(ProductDataModel product) {
//     final isAlreadyLinked = _isProductLinked(product);
//     if (!isAlreadyLinked) {
//       setState(() {
//         _linkedProductList.add(product);
//       });
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) => Scaffold(
//         appBar: IsmCustomAppBarWidget(
//           titleText: IsrTranslationFile.linkProductsToPost,
//           centerTitle: true,
//           onTap: () {
//             Navigator.pop(context, widget.linkedProducts);
//           },
//           showActions: _linkedProductList.isEmptyOrNull == false,
//           actions: [
//             TapHandler(
//               onTap: () {
//                 Navigator.pop(context, _linkedProductList);
//               },
//               child: const Icon(Icons.check, color: Colors.black, size: 24),
//             ),
//             16.horizontalSpace,
//           ],
//         ),
//         body: BlocConsumer<CreatePostBloc, CreatePostState>(
//           listener: (context, state) {
//             if (state is GetProductsState) {
//               _products = state.productList ?? [];
//               _checkForExistingProducts();
//               _totalProductsCount = state.totalProductsCount ?? 0;
//               _hasMoreData = _products.length < _totalProductsCount;
//               _isLoadingMore = false;
//             }
//           },
//           listenWhen: (previousState, currentState) =>
//               previousState != currentState && currentState is GetProductsState,
//           buildWhen: (previousState, currentState) => true, // Allow all rebuilds including setState
//           builder: (context, state) => SafeArea(
//             child: Padding(
//               padding: IsrDimens.edgeInsetsAll(10.responsiveDimension),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   ProductSearchBar(
//                     textEditingController: _searchController,
//                     onChangeValue: (value) {
//                       _createPostBloc.searchProduct(value);
//                     },
//                     height: IsrDimens.forty,
//                     hintText: IsrTranslationFile.search,
//                     fillColor: IsrColors.colorF5F5F5,
//                     hintTextStyle: IsrStyles.primaryText14.copyWith(color: IsrColors.color767676),
//                     fieldBorder: OutlineInputBorder(
//                       borderRadius: IsrDimens.borderRadiusAll(Dimens.eight),
//                       borderSide: const BorderSide(
//                         color: IsrColors.colorF5F5F5,
//                       ),
//                     ),
//                     isReadOnly: false,
//                     onTap: () {
//                       if (_isLinkedProductsExpanded) {
//                         setState(() {
//                           _isLinkedProductsExpanded = false;
//                         });
//                       }
//                     },
//                   ),
//
//                   // Selected linked products display
//                   if (_linkedProductList.isNotEmpty) ...[
//                     _buildSelectedProducts(),
//                     12.verticalSpace,
//                   ],
//
//                   if (state is GetProductsState) ...[
//                     10.verticalSpace,
//                     Text(
//                       '$_totalProductsCount ${IsrTranslationFile.totalProducts}',
//                       style: IsrStyles.primaryText14.copyWith(
//                         color: '333333'.color,
//                       ),
//                     ),
//                     10.verticalSpace,
//                   ],
//
//                   Expanded(
//                     child: state is GetProductsLoadingState && state.isLoading == true
//                         ? Center(child: Utility.loaderWidget())
//                         : _buildProductList(_getFilteredProducts()),
//                   ),
//                   12.verticalSpace,
//                 ],
//               ),
//             ),
//           ),
//         ),
//       );
//
//   /// Build product list widget
//   Widget _buildProductList(List<ProductDataModel> list) => list.isEmptyOrNull
//       ? const Center(
//           child: EmptyPlaceHolderWidget(
//             appImagePath: AssetConstants.icNoProductsAvailable,
//             contentText: IsmIsmInjectionUtils.noProductsFoundDesc,
//             titleText: IsmIsmInjectionUtils.noProductFound,
//           ),
//         )
//       : ListView.builder(
//           controller: _scrollController,
//           itemCount: list.length,
//           itemBuilder: (context, index) {
//             final product = list[index];
//             return Column(
//               children: [
//                 _buildProductCard(product),
//                 if (index != list.length - 1) 10.verticalSpace
//               ],
//             );
//           },
//         );
//
//   /// Build selected products display with expansion
//   Widget _buildSelectedProducts() => AnimatedContainer(
//         duration: const Duration(milliseconds: 300),
//         margin: const EdgeInsets.symmetric(vertical: 12),
//         padding: const EdgeInsets.all(16),
//         decoration: BoxDecoration(
//           gradient: LinearGradient(
//             colors: [
//               const Color(0xFF1976D2).applyOpacity(0.05),
//               const Color(0xFF1976D2).applyOpacity(0.1),
//             ],
//             begin: Alignment.topLeft,
//             end: Alignment.bottomRight,
//           ),
//           borderRadius: BorderRadius.circular(16),
//           border: Border.all(
//             color: const Color(0xFF1976D2).applyOpacity(0.2),
//             width: 1,
//           ),
//         ),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             // Header with expand/collapse functionality
//             GestureDetector(
//               onTap: () {
//                 setState(() {
//                   _isLinkedProductsExpanded = !_isLinkedProductsExpanded;
//                 });
//               },
//               child: Row(
//                 children: [
//                   Container(
//                     padding: const EdgeInsets.all(8),
//                     decoration: BoxDecoration(
//                       color: const Color(0xFF1976D2),
//                       borderRadius: BorderRadius.circular(8),
//                     ),
//                     child: const Icon(
//                       Icons.link,
//                       color: Colors.white,
//                       size: 16,
//                     ),
//                   ),
//                   12.horizontalSpace,
//                   Expanded(
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         Text(
//                           'Linked Products',
//                           style: IsrStyles.primaryText16.copyWith(
//                             fontWeight: FontWeight.w600,
//                             color: '333333'.color,
//                           ),
//                         ),
//                         Text(
//                           '${_linkedProductList.length} ${_linkedProductList.length == 1 ? 'product' : 'products'} selected',
//                           style: IsrStyles.primaryText12.copyWith(
//                             color: '666666'.color,
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                   8.horizontalSpace,
//                   AnimatedRotation(
//                     turns: _isLinkedProductsExpanded ? 0.5 : 0,
//                     duration: const Duration(milliseconds: 300),
//                     child: Icon(
//                       Icons.keyboard_arrow_down,
//                       color: '1976D2'.toColor(),
//                       size: 24.responsiveDimension,
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//
//             // Expandable products list - horizontal scrollable
//             AnimatedContainer(
//               duration: const Duration(milliseconds: 300),
//               height: _isLinkedProductsExpanded ? null : 0,
//               child: _isLinkedProductsExpanded
//                   ? Column(
//                       children: [
//                         16.verticalSpace,
//                         SizedBox(
//                           height: 300,
//                           child: ListView.separated(
//                             scrollDirection: Axis.horizontal,
//                             itemCount: _linkedProductList.length,
//                             separatorBuilder: (context, index) => 12.horizontalSpace,
//                             itemBuilder: (context, index) {
//                               final product = _linkedProductList[index];
//                               return _buildHorizontalProductCard(product, index);
//                             },
//                           ),
//                         ),
//                       ],
//                     )
//                   : const SizedBox.shrink(),
//             ),
//           ],
//         ),
//       );
//
//   /// Build horizontal product card for linked products display
//   Widget _buildHorizontalProductCard(ProductDataModel product, int index) {
//     final dynamic productImages = product.images;
//
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
//                 : productImages.toString();
//     if (imageUrl.isEmpty) {
//       imageUrl = product.productImage ?? '';
//     }
//
//     return Container(
//       width: 180,
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(12),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.applyOpacity(0.05),
//             blurRadius: 8,
//             offset: const Offset(0, 2),
//           ),
//         ],
//         border: Border.all(
//           color: const Color(0xFF1976D2).applyOpacity(0.3),
//           width: 1,
//         ),
//       ),
//       child: Stack(
//         children: [
//           Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               // Product image
//               Expanded(
//                 flex: 3,
//                 child: Container(
//                   width: double.infinity,
//                   decoration: const BoxDecoration(
//                     borderRadius: BorderRadius.only(
//                       topLeft: Radius.circular(12),
//                       topRight: Radius.circular(12),
//                     ),
//                   ),
//                   child: ClipRRect(
//                     borderRadius: const BorderRadius.only(
//                       topLeft: Radius.circular(12),
//                       topRight: Radius.circular(12),
//                     ),
//                     child: AppImage.network(
//                       imageUrl,
//                       fit: BoxFit.cover,
//                     ),
//                   ),
//                 ),
//               ),
//               // Product details
//               Expanded(
//                 flex: 2,
//                 child: Padding(
//                   padding: const EdgeInsets.all(8),
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       // Product name
//                       Expanded(
//                         child: Text(
//                           product.productName ?? 'Unknown Product',
//                           style: const TextStyle(
//                             fontSize: 12,
//                             fontWeight: FontWeight.w600,
//                             color: Color(0xFF333333),
//                           ),
//                           maxLines: 4,
//                           overflow: TextOverflow.ellipsis,
//                         ),
//                       ),
//                       // Additional spacing
//                       const SizedBox(height: 2),
//                     ],
//                   ),
//                 ),
//               ),
//             ],
//           ),
//           // Remove button
//           Positioned(
//             top: 6,
//             right: 6,
//             child: GestureDetector(
//               onTap: () => _removeProduct(product),
//               child: Container(
//                 padding: const EdgeInsets.all(4),
//                 decoration: BoxDecoration(
//                   color: Colors.red.applyOpacity(0.9),
//                   shape: BoxShape.circle,
//                   boxShadow: [
//                     BoxShadow(
//                       color: Colors.black.applyOpacity(0.2),
//                       blurRadius: 4,
//                       offset: const Offset(0, 2),
//                     ),
//                   ],
//                 ),
//                 child: const Icon(
//                   Icons.close,
//                   size: 14,
//                   color: Colors.white,
//                 ),
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   void _checkForExistingProducts() {
//     for (var product in _products) {
//       final productId = product.childProductId ?? '';
//       if (widget.linkedProducts?.any((element) => element.childProductId == productId) == true) {
//         _linkProduct(product);
//       }
//     }
//   }
//
//   bool _isProductLinked(ProductDataModel product) {
//     final isAlreadyLinked = _linkedProductList.any(
//       (linkedProduct) => linkedProduct.childProductId == product.childProductId,
//     );
//
//     return isAlreadyLinked;
//   }
//
//   /// Get filtered products (exclude already linked products from search results)
//   /// This method is called every time the UI rebuilds, ensuring real-time filtering
//   /// FLOW: Link product → Remove from search | Unlink product → Add back to search
//   List<ProductDataModel> _getFilteredProducts() {
//     final filtered = _products.where((product) => !_isProductLinked(product)).toList();
//     debugPrint(
//         'Filtered products: ${filtered.length}, filtered[0] :${filtered.firstOrNull?.productName}');
//     return filtered;
//   }
//
//   Widget _buildProductCard(ProductDataModel product) => ProductToLinkItem(
//         key: ValueKey('${product.childProductId}_${_isProductLinked(product)}'),
//         productDataModel: product,
//         isLinked: _isProductLinked(product),
//         onRemove: () {
//           _removeProduct(product);
//           return true;
//         },
//         onLink: () {
//           _linkProduct(product);
//           return true;
//         },
//       );
// }
