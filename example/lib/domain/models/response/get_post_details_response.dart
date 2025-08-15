import 'dart:convert';

PostDetailsResponse postDetailsResponseFromJson(String str) =>
    PostDetailsResponse.fromJson(json.decode(str) as Map<String, dynamic>);

String postDetailsResponseToJson(PostDetailsResponse data) => json.encode(data.toJson());

class PostDetailsResponse {
  PostDetailsResponse({
    this.message,
    this.count,
    this.data,
  });

  factory PostDetailsResponse.fromJson(Map<String, dynamic> json) => PostDetailsResponse(
        message: json['message'] as String? ?? '',
        count: json['count'] as num? ?? 0,
        data: json['data'] == null
            ? []
            : List<ProductDataModel>.from((json['data'] as List)
                .map((x) => ProductDataModel.fromJson(x as Map<String, dynamic>))),
      );
  String? message;
  num? count;
  List<ProductDataModel>? data;

  Map<String, dynamic> toJson() => {
        'message': message,
        'count': count,
        'data': data == null ? [] : List<dynamic>.from(data!.map((x) => x.toJson())),
      };
}

class ProductDataModel {
  ProductDataModel({
    this.id,
    this.documentId,
    this.searchAbleAttributes,
    this.offers,
    // this.offersList,
    this.colourName,
    this.popularScore,
    this.categoryList,
    this.status,
    this.currency,
    this.currencySymbol,
    this.brandTitle,
    this.brand,
    this.parentProductId,
    this.storeId,
    this.supplier,
    this.unitId,
    this.bestOffer,
    this.finalPriceList,
    this.colourData,
    this.isAllVariantInStock,
    this.totalReview,
    this.avgRating,
    this.addToCartOnId,
    this.score,
    this.isFavourite,
    this.childProductId,
    this.size,
    this.inStock,
    this.sku,
    this.slug,
    this.brandId,
    this.productName,
    this.availableQuantity,
    this.maxQuantity,
    this.maxQuantityList,
    this.maxQuantityPerUser,
    this.isVisibleInAllVariants,
    this.images,
    this.modelImage,
    this.resellerCommission,
    this.resellerCommissionType,
    this.resellerFixedCommission,
    this.resellerPercentageCommission,
    this.productCondition,
    this.userStoreProduct,
    this.productConditionText,
    this.isproductCondition,
    this.moderationStatus,
    this.currencyRate,
    this.variantCount,
    this.productDataItem,
    this.productImage,
    this.storeName,
    this.store,
    this.userCount,
    this.tag,
    this.totalNoOfRating,
    this.colorCount,
    this.totalStarRating,
    this.rewardFinalPrice,
    this.rewerdBasePrice,
    this.outOfStock,
    this.sellerPlanDetails,
    this.storeCategoryId,
    this.productType,
    this.productSeo,
    this.subScriptionStatus,
  });

  factory ProductDataModel.fromJson(Map<String, dynamic> json) => ProductDataModel(
        id: json['_id'] as String? ?? '',
        documentId: json['id'] as String? ?? '',
        offers: (() {
          final offersData = json['offers'] ?? json['bestOffer'];
          if (offersData == null) return null;

          if (offersData is List && offersData.isNotEmpty) {
            final firstOffer = offersData[0];
            if (firstOffer is Map && firstOffer.isNotEmpty) {
              return Offer.fromJson(firstOffer as Map<String, dynamic>);
            }
          } else if (offersData is Map<String, dynamic> && offersData.isNotEmpty) {
            return Offer.fromJson(offersData);
          }

          return null;
        })(),
        // offersList: json['offers'] == null
        //     ? [] // If it's null, return an empty list
        //     : (json['offers'] is List
        //         ? List<Offer>.from(
        //             (json['offers'] as List).map((dynamic x) =>
        //                 Offer.fromJson(x as Map<String, dynamic>)),
        //           )
        //         : (json['offers'] is Map
        //             ? (json['offers'] as Map)['offerId'] == null
        //                 ? []
        //                 : [
        //                     Offer.fromJson(
        //                         json['offers'] as Map<String, dynamic>),
        //                   ]
        //             : [])),
        colourName: json['colourName'] as String? ?? '',
        searchAbleAttributes: (json['searchAbleAttributes'] as List<dynamic>? ?? [])
            .map((e) => SearchAbleAttribute.fromJson(e as Map<String, dynamic>))
            .toList(),
        popularScore: json['popularScore'] as num? ?? 0,
        categoryList: json['categoryList'] == null
            ? []
            : List<PlpCategoryItem>.from((json['categoryList'] as List)
                .map((dynamic x) => PlpCategoryItem.fromJson(x as Map<String, dynamic>))),
        status: (json['status'] is num)
            ? json['status'] as num
            : (json['status'] == 'APPROVED' ? 1 as num : 0 as num),
        currency: json['currency'] as String? ?? '',
        currencySymbol: ProductDataModel.fixEncoding(json['currencySymbol'] as String? ?? ''),
        brandTitle: json['brandTitle'] == null
            ? json['brandName'] as String? ?? ''
            : json['brandTitle'] as String? ?? '',
        brand:
            json['brand'] == null ? json['brand'] as String? ?? '' : json['brand'] as String? ?? '',
        parentProductId: json['parentProductId'] as String? ?? '',
        storeId: json['storeId'] as String? ?? '',
        supplier: json['supplier'] == null
            ? null
            : Supplier.fromJson(json['supplier'] as Map<String, dynamic>),
        unitId: json['unitId'] as String? ?? '',
        bestOffer: json['bestOffer'] == null
            ? json['offers'] == null
                ? null
                : !(json['offers'] is List)
                    ? BestOffer.fromJson(json['offers'] as Map<String, dynamic>)
                    : null
            : BestOffer.fromJson(json['bestOffer'] as Map<String, dynamic>),
        finalPriceList: json['finalPriceList'] == null
            ? null
            : FinalPriceList.fromJson(json['finalPriceList'] as Map<String, dynamic>),
        colourData: json['colourData'] == null
            ? []
            : List<ColourData>.from((json['colourData'] as List)
                .map((dynamic x) => ColourData.fromJson(x as Map<String, dynamic>))),
        isAllVariantInStock: json['isAllVariantInStock'] as String? ?? '',
        totalReview: json['totalReview'] == null
            ? json['userCount'] as num? ?? 0
            : json['totalReview'] as num? ?? 0,
        avgRating: json['avgRating'] == null
            ? json['rating'] as num? ?? 0
            : json['avgRating'] as num? ?? 0,
        addToCartOnId: json['addToCartOnId'] as num? ?? 0,
        score: json['score'] as num? ?? 0,
        isFavourite: json['isFavourite'] as bool? ?? false,
        childProductId: json['childProductId'] == null
            ? json['childproductid'] as String? ?? ''
            : json['childProductId'] as String? ?? '',
        size: json['size'],
        inStock: json['inStock'] as bool?,
        sku: (json['sku'] ?? '').toString(),
        slug: json['slug'] as String? ?? '',
        brandId: json['brandId'] as String? ?? '',
        productName: json['productName'] as String? ?? '',
        availableQuantity: json['availableQuantity'] as num? ?? 0,
        maxQuantity: json['maxQuantity'] is num ? json['maxQuantity'] as num? ?? 0 : 0,
        maxQuantityList: json['maxQuantity'] is List
            ? List<int>.from((json['maxQuantity'] as List).map((x) => x))
            : [],
        maxQuantityPerUser: json['maxQuantityPerUser'] as num? ?? 0,
        isVisibleInAllVariants: json['isVisibleInAllVariants'] as bool? ?? false,
        images: json['images'] == null
            ? null
            : (json['images'] is String)
                ? json['images'] as String? ?? ''
                : (json['images'] is List)
                    ? (json['images'] as List).isEmpty
                        ? (json['modelImage'] == null
                            ? []
                            : List<ImageData>.from((json['modelImage'] as List)
                                .map((dynamic x) => ImageData.fromJson(x as Map<String, dynamic>))))
                        : List<ImageData>.from((json['images'] as List)
                            .map((dynamic x) => ImageData.fromJson(x as Map<String, dynamic>)))
                    : ImageData.fromJson(json['images'] as Map<String, dynamic>),
        modelImage: json['modelImage'] == null
            ? []
            : List<ImageData>.from((json['modelImage'] as List)
                .map((dynamic x) => ImageData.fromJson(x as Map<String, dynamic>))),
        resellerCommission: json['resellerCommission'] as num? ?? 0,
        resellerCommissionType: json['resellerCommissionType'] as num? ?? 0,
        resellerFixedCommission: json['resellerFixedCommission'] as num? ?? 0,
        resellerPercentageCommission: json['resellerPercentageCommission'] as num? ?? 0,
        productCondition: json['productCondition'] as num? ?? 0,
        userStoreProduct: json['userStoreProduct'] as bool? ?? false,
        productConditionText: json['productConditionText'] as String? ?? '',
        isproductCondition: json['isproductCondition'] as num? ?? 0,
        moderationStatus: json['moderationStatus'] as String? ?? '',
        productImage: json['productImage'] as String? ?? '',
        storeName: json['storeName'] as String? ?? '',
        store: json['store'] as String? ?? '',
        currencyRate: json['currency_rate'] as num? ?? 0,
        userCount: json['userCount'] as num? ?? 0,
        variantCount: json['variantCount'] is num
            ? json['variantCount'] as num? ?? 0
            : json['variantCount'] as bool? ?? false,
        tag: json['tag'] as int? ?? 0,
        colorCount: json['colorCount'] as int? ?? 0,
        totalNoOfRating: json['totalNoOfRating'] as int? ?? 0,
        totalStarRating: json['totalStarRating'] as num? ?? 0,
        rewardFinalPrice: json['rewardFinalPrice'] as num? ?? 0,
        rewerdBasePrice: json['rewerdBasePrice'] as num? ?? 0,
        outOfStock: json['outOfStock'] as bool? ?? false,
        storeCategoryId: json['storeCategoryId'] as String? ?? '',
        sellerPlanDetails: json['sellerPlanDetails'] == null
            ? null
            : SellerPlanDetails.fromJson(json['sellerPlanDetails'] as Map<String, dynamic>),
        productType: json['productType'] as num? ?? 1,
        productSeo: json['productSeo'] == null
            ? null
            : PdpProductSeo.fromJson(json['productSeo'] as Map<String, dynamic>),
        subScriptionStatus: json['subScriptionStatus'] as num? ?? null,
      );
  String? id;
  String? documentId;
  List<SearchAbleAttribute>? searchAbleAttributes;
  num? popularScore;
  List<PlpCategoryItem>? categoryList;
  String? colourName;
  Offer? offers;
  // List<Offer>? offersList;
  num? status;
  String? currency;
  String? currencySymbol;
  String? brandTitle;
  String? brand;
  String? parentProductId;
  String? storeId;
  Supplier? supplier;
  String? unitId;
  BestOffer? bestOffer;
  FinalPriceList? finalPriceList;
  List<ColourData>? colourData;
  String? isAllVariantInStock;
  num? totalReview;
  num? avgRating;
  num? score;
  bool? isFavourite;
  String? childProductId;
  num? addToCartOnId;
  dynamic size;
  bool? inStock;
  String? sku;
  String? slug;
  String? brandId;
  String? productName;
  num? availableQuantity;
  bool? isVisibleInAllVariants;
  dynamic images;
  List<ImageData>? modelImage;
  num? resellerCommission;
  num? resellerCommissionType;
  num? resellerFixedCommission;
  num? resellerPercentageCommission;
  num? productCondition;
  bool? userStoreProduct;
  String? productConditionText;
  num? isproductCondition;
  String? moderationStatus;
  num? currencyRate;
  dynamic variantCount;
  ProductDataItem? productDataItem;
  String? productImage;
  num? maxQuantity;
  List<int>? maxQuantityList;
  num? maxQuantityPerUser;
  num? userCount;
  String? storeName;
  String? store;
  int? colorCount;
  int? tag;
  int? totalNoOfRating;
  num? totalStarRating;
  num? rewardFinalPrice;
  num? rewerdBasePrice;
  bool? outOfStock;
  SellerPlanDetails? sellerPlanDetails;
  String? storeCategoryId;
  num? productType;
  PdpProductSeo? productSeo;
  num? subScriptionStatus;

  Map<String, dynamic> toJson() => {
        '_id': id,
        'colourName': colourName,
        'searchAbleAttributes': searchAbleAttributes == null
            ? []
            : List<dynamic>.from(searchAbleAttributes!.map((x) => x.toJson())),
        'id': documentId,
        'offers': offers?.toJson(),
        // 'offersList': offersList == null
        //     ? []
        //     : List<dynamic>.from(offersList!.map((x) => x.toJson())),
        'popularScore': popularScore,
        'categoryList':
            categoryList == null ? [] : List<dynamic>.from(categoryList!.map((x) => x.toJson())),
        'status': status,
        'currency': currency,
        'currencySymbol': currencySymbol,
        'brandTitle': brandTitle,
        'brand': brand,
        'parentProductId': parentProductId,
        'storeId': storeId,
        'supplier': supplier?.toJson(),
        'unitId': unitId,
        'bestOffer': bestOffer?.toJson(),
        'finalPriceList': finalPriceList?.toJson(),
        'colourData':
            colourData == null ? [] : List<dynamic>.from(colourData!.map((x) => x.toJson())),
        'isAllVariantInStock': isAllVariantInStock,
        'totalReview': totalReview,
        'avgRating': avgRating,
        'addToCartOnId': addToCartOnId,
        'score': score,
        'isFavourite': isFavourite,
        'childProductId': childProductId,
        'size': size,
        'inStock': inStock,
        'sku': sku,
        'slug': slug,
        'brandId': brandId,
        'productName': productName,
        'availableQuantity': availableQuantity,
        'maxQuantity': maxQuantity,
        'maxQuantityList': maxQuantityList is List
            ? maxQuantityList == null
                ? []
                : List<dynamic>.from(maxQuantityList!.map((x) => x))
            : [],
        'maxQuantityPerUser': maxQuantityPerUser,
        'isVisibleInAllVariants': isVisibleInAllVariants,
        'images': images is List
            ? List<dynamic>.from((images as List).map((x) => x.toJson()))
            : jsonEncode(images),
        'modelImage':
            modelImage == null ? [] : List<dynamic>.from(modelImage!.map((x) => x.toJson())),
        'resellerCommission': resellerCommission,
        'resellerCommissionType': resellerCommissionType,
        'resellerFixedCommission': resellerFixedCommission,
        'resellerPercentageCommission': resellerPercentageCommission,
        'productCondition': productCondition,
        'userStoreProduct': userStoreProduct,
        'productConditionText': productConditionText,
        'isproductCondition': isproductCondition,
        'moderationStatus': moderationStatus,
        'currency_rate': currencyRate,
        'variantCount': variantCount,
        'productImage': productImage,
        'storeName': storeName,
        'store': store,
        'userCount': userCount,
        'sellerPlanDetails': sellerPlanDetails?.toJson(),
        'productType': productType,
        'productSeo': productSeo?.toJson(),
      };

  ProductDataModel copyWith() => ProductDataModel(
        childProductId: childProductId,
      );

  static String fixEncoding(String input) {
    try {
      return utf8.decode(input.codeUnits); // Converts the string to bytes and decodes it.
    } catch (e) {
      return input;
    }
  }
}

class Offer {
  Offer({
    this.images,
    this.offerName,
    this.statusString,
    this.offerId,
    this.discountType,
    this.listComboProducts,
    this.offerFor,
    this.discountValue,
    this.globalClaimCount,
    this.webimages,
    this.status,
    this.name,
    this.termscond,
    this.startTime,
    this.endTime,
    this.gmtStartTime,
    this.gmtEndTime,
    this.childOffers,
  });

  factory Offer.fromJson(Map<String, dynamic> json) => Offer(
        images: json['images'] is Map<String, dynamic>
            ? Images.fromJson(json['images'] as Map<String, dynamic>)
            : (json['images'] is List &&
                    (json['images'] as List).isNotEmpty &&
                    (json['images'] as List)[0] is Map<String, dynamic>)
                ? Images.fromJson((json['images'] as List)[0] as Map<String, dynamic>)
                : null,
        offerName: json['offerName'] == null
            ? null
            : OfferName.fromJson(json['offerName'] as Map<String, dynamic>),
        statusString: json['statusString'] as String? ?? '',
        offerId: json['offerId'] as String? ?? '',
        discountType: json['discountType'] as num? ?? 0,
        listComboProducts: json['listComboProducts'] == null
            ? []
            : List<dynamic>.from((json['listComboProducts'] as List).map((x) => x)),
        offerFor: json['offerFor'] as num? ?? 0,
        discountValue: json['discountValue'] as num? ?? 0,
        globalClaimCount: json['globalClaimCount'] as num? ?? 0,
        webimages: json['webimages'] is Map<String, dynamic>
            ? Images.fromJson(json['webimages'] as Map<String, dynamic>)
            : (json['webimages'] is List &&
                    (json['webimages'] as List).isNotEmpty &&
                    (json['webimages'] as List)[0] is Map<String, dynamic>)
                ? Images.fromJson((json['webimages'] as List)[0] as Map<String, dynamic>)
                : null,
        status: json['status'] as num? ?? 0,
        termscond: json['termscond'] as String? ?? '',
        name: json['name'],
        startTime: json['startTime'] as num?,
        endTime: json['endTime'] as num?,
        gmtStartTime: json['gmtStartTime'] as num?,
        gmtEndTime: json['gmtEndTime'] as num?,
        childOffers: json['childOffers'] == null
            ? []
            : List<ChildOffer>.from((json['childOffers'] as List)
                .map((x) => ChildOffer.fromJson(x as Map<String, dynamic>))),
      );
  Images? images;
  OfferName? offerName;
  String? statusString;
  String? offerId;
  num? discountType;
  List<dynamic>? listComboProducts;
  num? offerFor;
  num? discountValue;
  num? globalClaimCount;
  Images? webimages;
  num? status;
  String? termscond;
  dynamic name;
  num? startTime;
  num? endTime;
  num? gmtStartTime;
  num? gmtEndTime;
  List<ChildOffer>? childOffers;

  Map<String, dynamic> toJson() => {
        'images': images?.toJson(),
        'offerName': offerName?.toJson(),
        'statusString': statusString,
        'offerId': offerId,
        'discountType': discountType,
        'listComboProducts':
            listComboProducts == null ? [] : List<dynamic>.from(listComboProducts!.map((x) => x)),
        'offerFor': offerFor,
        'discountValue': discountValue,
        'globalClaimCount': globalClaimCount,
        'webimages': webimages?.toJson(),
        'status': status,
        'termscond': termscond,
        'name': name,
      };
}

class Images {
  Images({
    this.image,
    this.thumbnail,
    this.mobile,
  });

  factory Images.fromJson(Map<String, dynamic> json) => Images(
        image: json['image'] as String? ?? '',
        thumbnail: json['thumbnail'] as String? ?? '',
        mobile: json['mobile'] as String? ?? '',
      );
  String? image;
  String? thumbnail;
  String? mobile;

  Map<String, dynamic> toJson() => {
        'image': image,
        'thumbnail': thumbnail,
        'mobile': mobile,
      };
}

class SearchAbleAttribute {
  SearchAbleAttribute({
    this.attrname,
    this.value,
  });

  factory SearchAbleAttribute.fromJson(Map<String, dynamic> json) => SearchAbleAttribute(
        attrname: json['attrname'] == null
            ? null
            : Attrname.fromJson(json['attrname'] as Map<String, dynamic>),
        value:
            json['value'] == null ? null : Attrname.fromJson(json['value'] as Map<String, dynamic>),
      );
  final Attrname? attrname;
  final Attrname? value;

  Map<String, dynamic> toJson() => {
        'attrname': attrname?.toJson(),
        'value': value?.toJson(),
      };
}

class Attrname {
  Attrname({
    this.en,
  });

  factory Attrname.fromJson(Map<String, dynamic> json) => Attrname(
        en: json['en'] as String? ?? '',
      );
  final String? en;

  Map<String, dynamic> toJson() => {
        'en': en,
      };
}

class PlpCategoryItem {
  PlpCategoryItem({
    this.categoryId,
    this.categoryName,
    this.parent,
    this.slug,
  });

  factory PlpCategoryItem.fromJson(Map<String, dynamic> json) => PlpCategoryItem(
        categoryId: json['categoryId'] as String? ?? '',
        categoryName: json['categoryName'] as String? ?? '',
        parent: json['parent'] as bool? ?? false,
        slug: json['slug'] as String? ?? '',
      );
  String? categoryId;
  String? categoryName;
  bool? parent;
  final String? slug;

  Map<String, dynamic> toJson() => {
        'categoryId': categoryId,
        'categoryName': categoryName,
        'parent': parent,
        'slug': slug,
      };
}

class Supplier {
  Supplier({
    this.productId,
    this.id,
    this.retailerQty,
    this.distributorPrice,
    this.distributorQty,
    this.retailerPrice,
    this.supplierName,
    this.cityName,
    this.logoImages,
    this.bannerImages,
    this.userId,
    this.userType,
    this.userTypeText,
    this.postCode,
    this.latitude,
    this.longitude,
    this.rating,
    this.totalRating,
    this.userCount,
    this.reviewParameter,
    this.sellerSince,
    this.storeAliasName,
    this.storeFrontTypeId,
    this.storeFrontType,
    this.storeTypeId,
    this.storeType,
    this.sellerTypeId,
    this.sellerType,
    this.areaName,
    this.street1,
    this.city,
    this.state,
    this.country,
    this.email,
    this.designation,
    this.profilePic,
    this.about,
  });

  factory Supplier.fromJson(Map<String, dynamic> json) => Supplier(
        productId: json['productId'] as String? ?? '',
        id: json['id'] as String? ?? '',
        retailerQty: json['retailerQty'] as num? ?? 0,
        distributorPrice: json['distributorPrice'] as num? ?? 0,
        distributorQty: json['distributorQty'] as num? ?? 0,
        retailerPrice: json['retailerPrice'] as num? ?? 0,
        supplierName: json['supplierName'] as String? ?? '',
        cityName: json['cityName'] as String? ?? '',
        logoImages: json['logoImages'] == null
            ? null
            : LogoImages.fromJson(json['logoImages'] as Map<String, dynamic>),
        bannerImages: json['bannerImages'] == null
            ? null
            : UndefinedValueClass.fromJson(json['bannerImages'] as Map<String, dynamic>),
        userId: json['userId'] as String? ?? '',
        userType: json['userType'] as num? ?? 0,
        userTypeText: json['userTypeText'] as String? ?? '',
        postCode: json['postCode'] as String? ?? '',
        latitude: json['latitude'] as String? ?? '',
        longitude: json['longitude'] as String? ?? '',
        rating: json['rating'] as num? ?? 0,
        totalRating: json['totalRating'] as num? ?? 0,
        userCount: json['userCount'] as num? ?? 0,
        reviewParameter: json['reviewParameter'] == null
            ? []
            : List<dynamic>.from((json['reviewParameter'] as List).map((x) => x)),
        sellerSince: json['sellerSince'] as String? ?? '',
        storeAliasName: json['storeAliasName'] as String? ?? '',
        storeFrontTypeId: json['storeFrontTypeId'],
        storeFrontType: json['storeFrontType'] as String? ?? '',
        storeTypeId: json['storeTypeId'] as num? ?? 0,
        storeType: json['storeType'],
        sellerTypeId: json['sellerTypeId'] as num? ?? 0,
        sellerType: json['sellerType'] as String? ?? '',
        areaName: json['areaName'] as String? ?? '',
        street1: json['street1'] as String? ?? '',
        city: json['city'] as String? ?? '',
        state: json['state'] as String? ?? '',
        country: json['country'] as String? ?? '',
        email: json['email'] as String? ?? '',
        designation: json['designation'] as String? ?? '',
        profilePic: json['profilePic'] as String? ?? '',
        about: json['about'] as String? ?? '',
      );
  String? productId;
  String? id;
  num? retailerQty;
  num? distributorPrice;
  num? distributorQty;
  num? retailerPrice;
  String? supplierName;
  String? cityName;
  LogoImages? logoImages;
  UndefinedValueClass? bannerImages;
  String? userId;
  num? userType;
  String? userTypeText;
  String? postCode;
  String? latitude;
  String? longitude;
  num? rating;
  num? totalRating;
  num? userCount;
  List<dynamic>? reviewParameter;
  String? sellerSince;
  String? storeAliasName;
  dynamic storeFrontTypeId;
  String? storeFrontType;
  num? storeTypeId;
  dynamic storeType;
  num? sellerTypeId;
  String? sellerType;
  String? areaName;
  String? street1;
  String? city;
  String? state;
  String? country;
  String? email;
  String? designation;
  String? profilePic;
  String? about;

  Map<String, dynamic> toJson() => {
        'productId': productId,
        'id': id,
        'retailerQty': retailerQty,
        'distributorPrice': distributorPrice,
        'distributorQty': distributorQty,
        'retailerPrice': retailerPrice,
        'supplierName': supplierName,
        'cityName': cityName,
        'logoImages': logoImages?.toJson(),
        'bannerImages': bannerImages?.toJson(),
        'userId': userId,
        'userType': userType,
        'userTypeText': userTypeText,
        'postCode': postCode,
        'latitude': latitude,
        'longitude': longitude,
        'rating': rating,
        'totalRating': totalRating,
        'userCount': userCount,
        'reviewParameter':
            reviewParameter == null ? [] : List<dynamic>.from(reviewParameter!.map((x) => x)),
        'sellerSince': sellerSince,
        'storeAliasName': storeAliasName,
        'storeFrontTypeId': storeFrontTypeId,
        'storeFrontType': storeFrontType,
        'storeTypeId': storeTypeId,
        'storeType': storeType,
        'sellerTypeId': sellerTypeId,
        'sellerType': sellerType,
        'areaName': areaName,
        'street1': street1,
        'city': city,
        'state': state,
        'country': country,
        'email': email,
        'designation': designation,
        'profilePic': profilePic,
        'about': about,
      };
}

class LogoImages {
  LogoImages({
    this.logoImageMobile,
    this.logoImageThumb,
    this.logoImageweb,
    this.logoMobileFilePath,
    this.profileimgeFilePath,
    this.twitterfilePath,
    this.opengraphfilePath,
    this.logoFilePath,
  });

  factory LogoImages.fromRawJson(String str) =>
      LogoImages.fromJson(json.decode(str) as Map<String, dynamic>);

  factory LogoImages.fromJson(Map<String, dynamic> json) => LogoImages(
        logoImageMobile: json['logoImageMobile'] as String? ?? '',
        logoImageThumb: json['logoImageThumb'] as String? ?? '',
        logoImageweb: json['logoImageweb'] as String? ?? '',
        logoFilePath: json['logoFilePath'] as String? ?? '',
        logoMobileFilePath: json['logoMobileFilePath'] as String? ?? '',
        profileimgeFilePath: json['profileimgeFilePath'] as String? ?? '',
        twitterfilePath: json['twitterfilePath'] as String? ?? '',
        opengraphfilePath: json['opengraphfilePath'] as String? ?? '',
      );
  String? logoImageMobile;
  String? logoImageThumb;
  String? logoImageweb;
  String? logoMobileFilePath;
  String? profileimgeFilePath;
  String? twitterfilePath;
  String? opengraphfilePath;
  String? logoFilePath;

  String toRawJson() => json.encode(toJson());

  Map<String, dynamic> toJson() => {
        'logoImageMobile': logoImageMobile,
        'logoImageThumb': logoImageThumb,
        'logoImageweb': logoImageweb,
        'logoMobileFilePath': logoMobileFilePath,
        'profileimgeFilePath': profileimgeFilePath,
        'twitterfilePath': twitterfilePath,
        'opengraphfilePath': opengraphfilePath,
        'logoFilePath': logoFilePath,
      };
}

class UndefinedValueClass {
  UndefinedValueClass();

  // ignore: avoid_unused_constructor_parameters
  factory UndefinedValueClass.fromJson(Map<String, dynamic> json) => UndefinedValueClass();

  Map<String, dynamic> toJson() => {};
}

class BestOffer {
  BestOffer({
    this.offerId,
    this.offerFor,
    this.offerName,
    this.images,
    this.webimages,
    this.discountType,
    this.discountValue,
    this.listComboProducts,
    this.status,
    this.statusString,
    this.globalClaimCount,
  });

  factory BestOffer.fromJson(Map<String, dynamic> json) => BestOffer(
        offerId: json['offerId'] as String? ?? '',
        offerFor: json['offerFor'] as num? ?? 0,
        offerName: json['offerName'] == null
            ? null
            : OfferName.fromJson(json['offerName'] as Map<String, dynamic>),
        images: json['images'] is Map<String, dynamic>
            ? Images.fromJson(json['images'] as Map<String, dynamic>)
            : (json['images'] is List &&
                    (json['images'] as List).isNotEmpty &&
                    (json['images'] as List)[0] is Map<String, dynamic>)
                ? Images.fromJson((json['images'] as List)[0] as Map<String, dynamic>)
                : null,
        webimages: json['webimages'] is Map<String, dynamic>
            ? Images.fromJson(json['webimages'] as Map<String, dynamic>)
            : (json['webimages'] is List &&
                    (json['webimages'] as List).isNotEmpty &&
                    (json['webimages'] as List)[0] is Map<String, dynamic>)
                ? Images.fromJson((json['webimages'] as List)[0] as Map<String, dynamic>)
                : null,
        discountType: json['discountType'] as num? ?? 0,
        discountValue: json['discountValue'] as num? ?? 0,
        listComboProducts: json['listComboProducts'] == null
            ? []
            : List<dynamic>.from((json['listComboProducts'] as List).map((x) => x)),
        status: json['status'] as num? ?? 0,
        statusString: json['statusString'] as String? ?? '',
        globalClaimCount: json['globalClaimCount'] as num? ?? 0,
      );
  String? offerId;
  num? offerFor;
  OfferName? offerName;
  Images? images;
  Images? webimages;
  num? discountType;
  num? discountValue;
  List<dynamic>? listComboProducts;
  num? status;
  String? statusString;
  num? globalClaimCount;

  Map<String, dynamic> toJson() => {
        'offerId': offerId,
        'offerFor': offerFor,
        'offerName': offerName?.toJson(),
        'images': images?.toJson(),
        'webimages': webimages?.toJson(),
        'discountType': discountType,
        'discountValue': discountValue,
        'listComboProducts':
            listComboProducts == null ? [] : List<dynamic>.from(listComboProducts!.map((x) => x)),
        'status': status,
        'statusString': statusString,
        'globalClaimCount': globalClaimCount,
      };
}

class OfferName {
  OfferName({
    this.en,
    this.pl,
    this.hi,
  });

  factory OfferName.fromJson(Map<String, dynamic> json) => OfferName(
        en: json['en'] as String? ?? '',
        pl: json['pl'] as String? ?? '',
        hi: json['hi'] as String? ?? '',
      );
  String? en;
  String? pl;
  String? hi;

  Map<String, dynamic> toJson() => {
        'en': en,
        'pl': pl,
        'hi': hi,
      };
}

class FinalPriceList {
  FinalPriceList({
    this.basePrice,
    this.finalPrice,
    this.discountPrice,
    this.sellerPrice,
    this.discountPercentage,
    this.discountType,
    this.taxRate,
    this.discount,
    this.discountValue,
    this.msrpPrice,
    this.otoPrice,
    this.rewardRange,
    this.sherpaCommissionRange,
    this.rewardFinalPrice,
    this.sherpaCommissionRangeObj,
    this.bestPrice,
  });

  factory FinalPriceList.fromJson(Map<String, dynamic> json) => FinalPriceList(
        basePrice: json['basePrice'] as num? ?? 0,
        finalPrice: json['finalPrice'] as num? ?? 0,
        bestPrice: json['bestPrice'] as num? ?? 0,
        discountPrice: json['discountPrice'] as num? ?? 0,
        sellerPrice: json['sellerPrice'] as num? ?? 0,
        discountPercentage: json['discountPercentage'] as num? ?? 0,
        discountType: json['discountType'] as num? ?? 0,
        taxRate: json['taxRate'] as num? ?? 0,
        discount: json['discount'] as num? ?? 0,
        discountValue: json['discountValue'] as num? ?? 0,
        msrpPrice: parsePrice(json['msrpPrice']),
        otoPrice: (parsePrice(json['otoPrice']) == 0)
            ? parsePrice(json['msrpPrice'])
            : parsePrice(json['otoPrice']),
        rewardFinalPrice: json['rewardFinalPrice'] as num? ?? 0,
        rewardRange: (json['rewardRange'] as List<dynamic>?)?.map((e) => e as num).toList(),
        sherpaCommissionRange:
            (json['sherpaCommissionRange'] as List<dynamic>?)?.map((e) => e as num).toList(),
        sherpaCommissionRangeObj: json['sherpaCommissionRangeObj'] == null
            ? null
            : SherpaCommissionRangeObj.fromJson(
                json['sherpaCommissionRangeObj'] as Map<String, dynamic>),
      );

  static double parsePrice(dynamic value) {
    if (value == null) return 0;

    if (value is String) {
      final trimmed = value.trim();
      if (trimmed.isEmpty) return 0;
      return double.tryParse(trimmed) ?? 0;
    }

    if (value is num) return value.toDouble();

    return 0;
  }

  FinalPriceList copyWith({
    num? basePrice,
    num? finalPrice,
    num? discountPrice,
    num? sellerPrice,
    num? discountPercentage,
    num? discountType,
    num? taxRate,
    num? discount,
    num? discountValue,
    num? msrpPrice,
    num? otoPrice,
    num? rewardFinalPrice,
    List<num>? rewardRange,
    List<num>? sherpaCommissionRange,
    num? bestPrice,
    SherpaCommissionRangeObj? sherpaCommissionRangeObj,
  }) =>
      FinalPriceList(
        basePrice: basePrice ?? this.basePrice,
        finalPrice: finalPrice ?? this.finalPrice,
        discountPrice: discountPrice ?? this.discountPrice,
        sellerPrice: sellerPrice ?? this.sellerPrice,
        discountPercentage: discountPercentage ?? this.discountPercentage,
        discountType: discountType ?? this.discountType,
        taxRate: taxRate ?? this.taxRate,
        discount: discount ?? this.discount,
        discountValue: discountValue ?? this.discountValue,
        msrpPrice: msrpPrice ?? this.msrpPrice,
        otoPrice: otoPrice ?? this.otoPrice,
        rewardFinalPrice: rewardFinalPrice ?? this.rewardFinalPrice,
        rewardRange: rewardRange ?? this.rewardRange,
        sherpaCommissionRange: sherpaCommissionRange ?? this.sherpaCommissionRange,
        bestPrice: bestPrice,
        sherpaCommissionRangeObj: sherpaCommissionRangeObj ?? this.sherpaCommissionRangeObj,
      );

  num? basePrice;
  num? finalPrice;
  num? discountPrice;
  num? sellerPrice;
  num? discountPercentage;
  num? discountType;
  num? taxRate;
  num? discount;
  num? discountValue;
  num? msrpPrice;
  num? otoPrice;
  num? rewardFinalPrice;
  List<num>? rewardRange;
  List<num>? sherpaCommissionRange;
  num? bestPrice;
  SherpaCommissionRangeObj? sherpaCommissionRangeObj;

  Map<String, dynamic> toJson() => {
        'basePrice': basePrice,
        'finalPrice': finalPrice,
        'bestPrice': bestPrice,
        'discountPrice': discountPrice,
        'sellerPrice': sellerPrice,
        'discountPercentage': discountPercentage,
        'discountType': discountType,
        'taxRate': taxRate,
        'discount': discount,
        'discountValue': discountValue,
        'otoPrice': otoPrice,
        'rewardRange': rewardRange,
        'sherpaCommissionRange': sherpaCommissionRange,
      };
}

class SherpaCommissionRangeObj {
  factory SherpaCommissionRangeObj.fromJson(Map<String, dynamic> json) => SherpaCommissionRangeObj(
        onMsrp: json['onMsrp'] as num? ?? 0,
        onTfm: json['onTfm'] as num? ?? 0,
        onOto: json['onOto'] as num? ?? 0,
        onAutoShipPrice: json['onAutoShipPrice'] as num? ?? 0,
        onPromo: json['onPromo'] as num? ?? 0,
        highestPrice: json['highestPrice'] as num? ?? 0,
      );
  SherpaCommissionRangeObj({
    this.onMsrp,
    this.onTfm,
    this.onOto,
    this.onAutoShipPrice,
    this.onPromo,
    this.highestPrice,
  });
  final num? onMsrp;
  final num? onTfm;
  final num? onOto;
  final num? onAutoShipPrice;
  final num? onPromo;
  final num? highestPrice;
}

class ColourData {
  ColourData({
    this.name,
    this.childProductId,
    this.parentProductId,
    this.rgb,
  });

  factory ColourData.fromJson(Map<String, dynamic> json) => ColourData(
        name: json['name'] as String? ?? '',
        childProductId: json['childProductId'] as String? ?? '',
        parentProductId: json['parentProductId'] as String? ?? '',
        rgb: json['rgb'] as String? ?? '',
      );
  String? name;
  String? childProductId;
  String? parentProductId;
  String? rgb;

  Map<String, dynamic> toJson() => {
        'name': name,
        'childProductId': childProductId,
        'parentProductId': parentProductId,
        'rgb': rgb,
      };
}

class ImageData {
  ImageData({
    this.altText,
    this.extraLarge,
    this.large,
    this.medium,
    this.small,
    this.filePath,
    this.seqId,
  });

  factory ImageData.fromJson(Map<String, dynamic> json) => ImageData(
        altText: json['altText'] as String? ?? '',
        extraLarge: json['extraLarge'] as String? ?? '',
        large: json['small'] as String? ?? '',
        medium: json['small'] as String? ?? '',
        small: json['small'] as String? ?? '',
        filePath: json['filePath'] as String? ?? '',
        seqId: json['seqId'] as num? ?? 0,
      );
  String? altText;
  String? extraLarge;
  String? large;
  String? medium;
  String? small;
  String? filePath;
  num? seqId;

  Map<String, dynamic> toJson() => {
        'altText': altText,
        'extraLarge': extraLarge,
        'large': large,
        'medium': medium,
        'small': small,
        'filePath': filePath,
        'seqId': seqId,
      };
}

class SellerPlanDetails {
  SellerPlanDetails({
    this.sellerPlanName,
    this.planSelectorTitle,
    this.planDescription,
    this.sellerPlanId,
    this.frequencies,
    this.minimumSubscriptionPrice,
  });

  factory SellerPlanDetails.fromJson(Map<String, dynamic> json) => SellerPlanDetails(
        sellerPlanName: json['sellerPlanName'] as String? ?? '',
        planSelectorTitle: json['planSelectorTitle'] as String? ?? '',
        planDescription: json['planDescription'] as String? ?? '',
        sellerPlanId: json['sellerPlanId'] as String? ?? '',
        frequencies: (json['frequencies'] as List<dynamic>?)
                ?.map((e) => SellerPlanDetailsFrequency.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
        minimumSubscriptionPrice: json['minimumSubscriptionPrice'] as num? ?? 0.0,
      );

  SellerPlanDetails copyWith({
    String? sellerPlanName,
    String? planSelectorTitle,
    String? planDescription,
    String? sellerPlanId,
    List<SellerPlanDetailsFrequency>? frequencies,
    num? minimumSubscriptionPrice,
  }) =>
      SellerPlanDetails(
        sellerPlanName: sellerPlanName ?? this.sellerPlanName,
        planSelectorTitle: planSelectorTitle ?? this.planSelectorTitle,
        planDescription: planDescription ?? this.planDescription,
        sellerPlanId: sellerPlanId ?? this.sellerPlanId,
        frequencies: frequencies ?? this.frequencies,
        minimumSubscriptionPrice: minimumSubscriptionPrice ?? this.minimumSubscriptionPrice,
      );

  String? sellerPlanName;
  String? planSelectorTitle;
  String? planDescription;
  String? sellerPlanId;
  List<SellerPlanDetailsFrequency>? frequencies;
  num? minimumSubscriptionPrice;

  Map<String, dynamic> toJson() => {
        'sellerPlanName': sellerPlanName,
        'planSelectorTitle': planSelectorTitle,
        'planDescription': planDescription,
        'sellerPlanId': sellerPlanId,
        'frequencies': frequencies?.map((e) => e.toJson()).toList(),
        'minimumSubscriptionPrice': minimumSubscriptionPrice,
      };
}

class SellerPlanDetailsFrequency {
  SellerPlanDetailsFrequency({
    this.frequencyId,
    this.frequencyDuration,
    this.frequencyValue,
    this.planDropdownLabel,
    this.discountType,
    this.discountValue,
    this.discountPercentageOnTFMPrice,
    this.discountPercentageOnMSRP,
    this.subscriptionPrice,
  });

  factory SellerPlanDetailsFrequency.fromJson(Map<String, dynamic> json) =>
      SellerPlanDetailsFrequency(
        frequencyId: json['frequencyId'] as String? ?? '',
        frequencyDuration: json['frequencyDuration'] as String? ?? '',
        frequencyValue: json['frequencyValue'] as num? ?? 0,
        planDropdownLabel: json['planDropdownLabel'] as String? ?? '',
        discountType: json['discountType'] as String? ?? '',
        discountValue: json['discountValue'] as num? ?? 0.0,
        discountPercentageOnTFMPrice: json['discountPercentageOnTFMPrice'] as num? ?? 0.0,
        discountPercentageOnMSRP: json['discountPercentageOnMSRP'] as num? ?? 0.0,
        subscriptionPrice: json['subscriptionPrice'] as num? ?? 0.0,
      );
  String? frequencyId;
  String? frequencyDuration;
  num? frequencyValue;
  String? planDropdownLabel;
  String? discountType;
  num? discountValue;
  num? discountPercentageOnTFMPrice;
  num? discountPercentageOnMSRP;
  num? subscriptionPrice;

  Map<String, dynamic> toJson() => {
        'frequencyId': frequencyId,
        'frequencyDuration': frequencyDuration,
        'frequencyValue': frequencyValue,
        'planDropdownLabel': planDropdownLabel,
        'discountType': discountType,
        'discountValue': discountValue,
        'discountPercentageOnTFMPrice': discountPercentageOnTFMPrice,
        'discountPercentageOnMSRP': discountPercentageOnMSRP,
        'subscriptionPrice': subscriptionPrice,
      };
}

class PdpProductSeo {
  PdpProductSeo({
    required this.title,
    required this.description,
    required this.metatags,
    required this.slug,
  });

  factory PdpProductSeo.fromJson(Map<String, dynamic> json) => PdpProductSeo(
        title: _extractLangValue(json['title']),
        description: _extractLangValue(json['description']),
        metatags: _extractLangValue(json['metatags']),
        slug: _extractLangValue(json['slug']),
      );
  final String title;
  final String description;
  final String metatags;
  final String slug;

  static String _extractLangValue(dynamic value, [String locale = 'en']) {
    if (value is String) {
      return value;
    } else if (value is Map<String, dynamic>) {
      if (value.containsKey(locale) && value[locale] is String) {
        return value[locale] as String? ?? '';
      }
      // fallback to any non-null string value
      for (final v in value.values) {
        if (v is String && v.trim().isNotEmpty) {
          return v;
        }
      }
    }
    return '';
  }

  Map<String, dynamic> toJson() => {
        'title': title,
        'description': description,
        'metatags': metatags,
        'slug': slug,
      };
}

class ChildOffer {
  factory ChildOffer.fromJson(Map<String, dynamic> json) => ChildOffer(
        childOfferId: json['childOfferId'] as String? ?? '',
        label: json['label'] as String? ?? '',
        quantity: json['quantity'] as int? ?? 0,
        offerPrice: json['offerPrice'] as num? ?? 0,
        basePrice: json['basePrice'] as num? ?? 0,
        b2cMsrpSellingPrice: json['b2cMsrpSellingPrice'] as num? ?? 0,
        b2cproductSellingPrice: json['b2cproductSellingPrice'] as num? ?? 0,
        offerDiscount: json['offerDiscount'] as num? ?? 0,
        shippingFee: json['shippingFee'] as num? ?? 0,
        highlight: json['highlight'] as bool? ?? false,
        image:
            json['image'] == null ? null : Images.fromJson(json['image'] as Map<String, dynamic>),
        createdAt: json['createdAt'] as num? ?? 0,
        tagline: json['tagline'] as String? ?? '',
        seqId: json['seqId'] as int? ?? 0,
        updatedAt: json['updatedAt'] as num? ?? 0,
      );
  ChildOffer({
    this.childOfferId,
    this.label,
    this.quantity,
    this.offerPrice,
    this.basePrice,
    this.b2cMsrpSellingPrice,
    this.b2cproductSellingPrice,
    this.offerDiscount,
    this.shippingFee,
    this.highlight,
    this.image,
    this.createdAt,
    this.tagline,
    this.seqId,
    this.updatedAt,
  });

  String? childOfferId;
  String? label;
  int? quantity;
  num? offerPrice;
  num? basePrice;
  num? b2cMsrpSellingPrice;
  num? b2cproductSellingPrice;
  num? offerDiscount;
  num? shippingFee;
  bool? highlight;
  Images? image;
  num? createdAt;
  String? tagline;
  int? seqId;
  num? updatedAt;

  Map<String, dynamic> toJson() => {
        'childOfferId': childOfferId,
        'label': label,
        'quantity': quantity,
        'offerPrice': offerPrice,
        'basePrice': basePrice,
        'b2cMsrpSellingPrice': b2cMsrpSellingPrice,
        'b2cproductSellingPrice': b2cproductSellingPrice,
        'offerDiscount': offerDiscount,
        'shippingFee': shippingFee,
        'highlight': highlight,
        'image': image?.toJson(),
        'createdAt': createdAt,
        'tagline': tagline,
        'seqId': seqId,
        'updatedAt': updatedAt,
      };
}

class ProductDataItem {
  ProductDataItem({
    this.storeDetails,
    this.brandId,
    this.sku,
    this.parsedDescription,
    this.moderationStatus,
    this.productCondition,
    this.isomatricChatUserId,
    this.productPickUpAddress,
    this.userStoreProduct,
    this.productConditionText,
    this.isproductCondition,
    this.parentProductId,
    this.childProductId,
    this.comboProducts,
    this.productType,
    this.offerProductDetails,
    this.storeCategoryId,
    this.cashOnDelivery,
    this.shareLink,
    this.replacementPolicy,
    this.maxQuantity,
    this.maxQuantityPerUser,
    this.resellerCommission,
    this.resellerCommissionType,
    this.resellerPercentageCommission,
    this.resellerFixedCommission,
    this.termCondition,
    this.sizeChartDescription,
    this.exchangePolicy,
    this.returnPolicy,
    this.productName,
    this.unitName,
    this.brandName,
    this.categoryPath,
    this.shoppingListId,
    this.catName,
    this.subCatName,
    this.subSubCatName,
    this.isStoreClose,
    this.currency,
    this.currencySymbol,
    this.allOffers,
    this.attributes,
    this.htmlAttributes,
    this.highlight,
    this.images,
    this.mobileImage,
    this.modelImage,
    this.overviewData,
    this.offers,
    this.offer,
    this.linkedVariant,
    this.isFavourite,
    this.variants,
    this.sellerCount,
    this.moqData,
    this.allowOrderOutOfStock,
    this.finalPriceList,
    this.availableQuantity,
    this.supplier,
    this.productSeo,
    this.sizeChart,
    this.isSizeChart,
    this.detailDesc,
    this.outOfStock,
    this.prescriptionRequired,
    this.needsIdProof,
    this.saleOnline,
    this.nextSlotTime,
    this.isB2CMultiPrice,
    this.b2CPriceRange,
    this.subScriptionStatus,
    this.sellerPlanDetails,
    this.liveStreamfinalPriceList,
    this.status,
    this.categoryList,
    this.rating,
    this.totalRating,
    this.slug,
    this.variantCount,
    this.productHigestPromoDetails,
    this.appShareLink,
    this.rewardFinalPrice,
    this.partnerRevsharePercentage,
    this.addToCartOnId,
    this.centralProductId,
    this.followStatus,
    this.storeCustomerId,
    this.unitId,
    this.storeName,
  });

  factory ProductDataItem.fromJson(Map<String, dynamic> json) => ProductDataItem(
        storeDetails: json['storeDetail'] == null
            ? null
            : StoreDetails.fromJson(json['storeDetail'] as Map<String, dynamic>),
        brandId: json['brand'] as String? ?? json['brandId'] as String? ?? '',
        sku: json['sku'] as String? ?? '',
        parsedDescription: json['parsedDescription'] as String? ?? '',
        moderationStatus: json['moderationStatus'] as String? ?? '',
        productCondition: json['productCondition'] as num? ?? 0,
        isomatricChatUserId: json['isomatricChatUserId'] as String? ?? '',
        productPickUpAddress: json['productPickUpAddress'] == null
            ? null
            : ProductPickUpAddress.fromJson(json['productPickUpAddress'] as Map<String, dynamic>),
        userStoreProduct: json['userStoreProduct'] as bool? ?? false,
        productConditionText: json['productConditionText'] as String? ?? '',
        isproductCondition: json['isproductCondition'] as num? ?? 0,
        parentProductId: json['parentProductId'] as String? ?? '',
        childProductId: json['id'] as String? ?? json['childProductId'] as String? ?? '',
        comboProducts: json['comboProducts'] == null
            ? []
            : List<dynamic>.from((json['comboProducts'] as List).map((dynamic x) => x)),
        productType: json['productType'] as num? ?? 0,
        offerProductDetails: json['offerProductDetails'] == null
            ? []
            : List<dynamic>.from((json['offerProductDetails'] as List).map((x) => x)),
        storeCategoryId: json['storeCategoryId'] as String? ?? '',
        cashOnDelivery: json['cashOnDelivery'] as bool? ?? false,
        shareLink: json['shareLink'] as String? ?? '',
        replacementPolicy: json['replacementPolicy'] == null
            ? null
            : ReplacementPolicy.fromJson(json['replacementPolicy'] as Map<String, dynamic>),
        maxQuantity: json['maxQuantity'] is List
            ? List<int>.from(json['maxQuantity'] as List)
            : json['maxQuantityList'] is List
                ? List<int>.from(json['maxQuantityList'] as List)
                : [],
        maxQuantityPerUser: json['maxQuantityPerUser'] as num? ?? 10,
        resellerCommission: json['resellerCommission'] as num? ?? 0,
        resellerCommissionType: json['resellerCommissionType'] as num? ?? 0,
        resellerPercentageCommission: json['resellerPercentageCommission'] as num? ?? 0,
        resellerFixedCommission: json['resellerFixedCommission'] as num? ?? 0,
        termCondition: json['term&condition'] == null
            ? null
            : UndefinedValueClass.fromJson(json['term&condition'] as Map<String, dynamic>),
        sizeChartDescription: json['sizeChartDescription'] as String? ?? '',
        exchangePolicy: json['exchangePolicy'] == null
            ? null
            : ExchangePolicy.fromJson(json['exchangePolicy'] as Map<String, dynamic>),
        returnPolicy: json['returnPolicy'] == null
            ? null
            : ReturnPolicy.fromJson(json['returnPolicy'] as Map<String, dynamic>),
        productName: json['productName'] as String? ?? '',
        unitName: json['unitName'] as String? ?? '',
        brandName: json['brand'] as String? ?? json['brandName'] as String? ?? '',
        categoryPath: json['categoryPath'] == null
            ? []
            : List<CategoryPath>.from((json['categoryPath'] as List)
                .map((x) => CategoryPath.fromJson(x as Map<String, dynamic>))),
        shoppingListId: json['shoppingListId'] as String? ?? '',
        catName: json['catName'] as String? ?? '',
        subCatName: json['subCatName'] as String? ?? '',
        subSubCatName: json['subSubCatName'] as String? ?? '',
        isStoreClose: json['isStoreClose'] as bool? ?? false,
        currency: json['currency'] as String? ?? '',
        currencySymbol: json['currencySymbol'] as String? ?? '',
        allOffers: json['allOffers'] == null
            ? []
            : List<dynamic>.from((json['allOffers'] as List).map((x) => x)),
        attributes: json['attributes'] == null
            ? []
            : List<AttributesData>.from((json['attributes'] as List)
                .map((dynamic x) => AttributesData.fromJson(x as Map<String, dynamic>))),
        htmlAttributes: json['htmlAttributes'] == null
            ? []
            : List<dynamic>.from((json['htmlAttributes'] as List).map((x) => x)),
        highlight: json['highlight'] == null
            ? (json['highlights'] == null
                ? []
                : (json['highlights'] as List)
                    .expand((item) => item is List ? item : [item])
                    .whereType<Map<String, dynamic>>() // only keep Maps
                    .map((map) => map['en'] as String? ?? '')
                    .toList())
            : List<String>.from(
                (json['highlight'] as List).map((item) => item as String),
              ),
        images: json['images'] == null
            ? []
            : json['images'] == 'null'
                ? [
                    ImageData(large: json['productImage'] as String? ?? ''),
                  ]
                : List<ImageData>.from((json['images'] as List)
                    .map((dynamic x) => ImageData.fromJson(x as Map<String, dynamic>))),
        mobileImage: json['mobileImage'] == null
            ? []
            : List<ImageData>.from((json['mobileImage'] as List)
                .map((x) => ImageData.fromJson(x as Map<String, dynamic>))),
        modelImage: json['modelImage'] == null
            ? []
            : List<dynamic>.from((json['modelImage'] as List).map((x) => x)),
        overviewData: json['overviewData'] == null
            ? []
            : List<dynamic>.from((json['overviewData'] as List).map((x) => x)),
        offers: (json['offers'] != null && (json['offers'] as Map).isNotEmpty
            ? Offer.fromJson(json['offers'] as Map<String, dynamic>)
            : null),
        offer: (json['offer'] != null && (json['offer'] as Map).isNotEmpty
            ? Offer.fromJson(json['offer'] as Map<String, dynamic>)
            : null),
        linkedVariant: json['linkedVariant'] == null
            ? []
            : List<LinkedVariant>.from((json['linkedVariant'] as List)
                .map((dynamic x) => LinkedVariant.fromJson(x as Map<String, dynamic>))),
        isFavourite: json['isFavourite'] as bool? ?? false,
        variants: json['variants'] == null
            ? []
            : List<Variant>.from((json['variants'] as List)
                .map((dynamic x) => Variant.fromJson(x as Map<String, dynamic>))),
        sellerCount: json['sellerCount'] as num? ?? 0,
        moqData: json['MOQData'] == null
            ? null
            : MoqData.fromJson(json['MOQData'] as Map<String, dynamic>),
        allowOrderOutOfStock: json['allowOrderOutOfStock'] as bool? ?? false,
        finalPriceList: json['finalPriceList'] == null
            ? null
            : FinalPriceList.fromJson(json['finalPriceList'] as Map<String, dynamic>),
        availableQuantity: json['availableQuantity'] as num? ?? 0,
        supplier: json['supplier'] == null
            ? null
            : Supplier.fromJson(json['supplier'] as Map<String, dynamic>),
        productSeo: json['productSeo'] == null
            ? null
            : ProductSeo.fromJson(json['productSeo'] as Map<String, dynamic>),
        sizeChart: json['sizeChart'] == null
            ? []
            : List<SizeChartData>.from((json['sizeChart'] as List)
                .map((dynamic x) => SizeChartData.fromJson(x as Map<String, dynamic>))),
        isSizeChart: json['isSizeChart'] as bool? ?? false,
        detailDesc: json['detailedDesc'] is List
            ? (json['detailedDesc'] as List).isNotEmpty
                ? json['detailedDesc'][0] as String?
                : ''
            : json['detailedDesc'] as String? ?? json['detailDesc'] as String? ?? '',
        outOfStock: json['outOfStock'] as bool? ?? false,
        prescriptionRequired: json['prescriptionRequired'] as bool? ?? false,
        needsIdProof: json['needsIdProof'] as bool? ?? false,
        saleOnline: json['saleOnline'] as bool? ?? false,
        nextSlotTime: json['nextSlotTime'] as String? ?? '',
        isB2CMultiPrice: json['isB2cMultiPrice'] as bool? ?? false,
        b2CPriceRange: json['b2cPriceRange'] == null
            ? []
            : List<B2CPriceRange>.from((json['b2cPriceRange'] as List)
                .map((dynamic x) => B2CPriceRange.fromJson(x as Map<String, dynamic>))),
        subScriptionStatus: json['subScriptionStatus'] as num? ?? 0,
        sellerPlanDetails: json['sellerPlanDetails'] == null
            ? null
            : SellerPlanDetails.fromJson(json['sellerPlanDetails'] as Map<String, dynamic>),
        liveStreamfinalPriceList: json['liveStreamfinalPriceList'] == null
            ? null
            : FinalPriceList.fromJson(json['liveStreamfinalPriceList'] as Map<String, dynamic>),
        status: json['status'] as num? ?? 0,
        categoryList: json['categoryList'] == null
            ? []
            : List<CategoryItem>.from((json['categoryList'] as List)
                .map((dynamic x) => CategoryItem.fromJson(x as Map<String, dynamic>))),
        rating: json['rating'] as num? ?? 0,
        totalRating: json['totalRating'] as num? ?? 0,
        slug: json['slug'] as String? ?? '',
        variantCount: json['variantCount'] is num ? json['variantCount'] as num : 0,
        productHigestPromoDetails: json['productHigestPromoDetails'] == null
            ? null
            : ProductHigestPromoDetails.fromJson(
                json['productHigestPromoDetails'] as Map<String, dynamic>),
        appShareLink: json['appShareLink'] as String? ?? '',
        rewardFinalPrice: json['rewardFinalPrice'] as num? ?? 0,
        partnerRevsharePercentage: json['partnerRevsharePercentage'] as num? ?? 0,
        addToCartOnId: json['addToCartOnId'] as num? ?? 0,
        centralProductId: json['centralProductId'] as String? ?? '',
        followStatus: json['followStatus'] as num? ?? 0,
        storeCustomerId: json['storeCustomerId'] as String? ?? '',
        unitId: json['unitId'] as String? ?? '',
        storeName: json['storeName'] as String? ?? '',
      );
  StoreDetails? storeDetails;
  String? brandId;
  String? sku;
  String? parsedDescription;
  String? moderationStatus;
  num? productCondition;
  String? isomatricChatUserId;
  ProductPickUpAddress? productPickUpAddress;
  bool? userStoreProduct;
  String? productConditionText;
  num? isproductCondition;
  String? parentProductId;
  String? childProductId;
  List<dynamic>? comboProducts;
  num? productType;
  List<dynamic>? offerProductDetails;
  String? storeCategoryId;
  bool? cashOnDelivery;
  String? shareLink;
  ReplacementPolicy? replacementPolicy;
  List<int>? maxQuantity;
  num? maxQuantityPerUser;
  num? resellerCommission;
  num? resellerCommissionType;
  num? resellerPercentageCommission;
  num? resellerFixedCommission;
  UndefinedValueClass? termCondition;
  String? sizeChartDescription;
  ExchangePolicy? exchangePolicy;
  ReturnPolicy? returnPolicy;
  String? productName;
  String? unitName;
  String? brandName;
  List<CategoryPath>? categoryPath;
  String? shoppingListId;
  String? catName;
  String? subCatName;
  String? subSubCatName;
  bool? isStoreClose;
  String? currency;
  String? currencySymbol;
  List<dynamic>? allOffers;
  List<AttributesData>? attributes;
  List<dynamic>? htmlAttributes;
  List<String>? highlight;
  List<ImageData>? images;
  List<ImageData>? mobileImage;
  List<dynamic>? modelImage;
  List<dynamic>? overviewData;
  Offer? offers;
  Offer? offer;
  List<LinkedVariant>? linkedVariant;
  bool? isFavourite;
  List<Variant>? variants;
  num? sellerCount;
  MoqData? moqData;
  bool? allowOrderOutOfStock;
  FinalPriceList? finalPriceList;
  num? availableQuantity;
  Supplier? supplier;
  ProductSeo? productSeo;
  List<SizeChartData>? sizeChart;
  bool? isSizeChart;
  String? detailDesc;
  bool? outOfStock;
  bool? prescriptionRequired;
  bool? needsIdProof;
  bool? saleOnline;
  String? nextSlotTime;
  bool? isB2CMultiPrice;
  List<B2CPriceRange>? b2CPriceRange;
  num? subScriptionStatus;
  SellerPlanDetails? sellerPlanDetails;
  FinalPriceList? liveStreamfinalPriceList;
  num? status;
  List<CategoryItem>? categoryList;
  num? rating;
  num? totalRating;
  String? slug;
  num? variantCount;
  ProductHigestPromoDetails? productHigestPromoDetails;
  String? appShareLink;
  num? rewardFinalPrice;
  num? partnerRevsharePercentage;
  num? addToCartOnId;
  String? centralProductId;
  num? followStatus;
  String? storeCustomerId;
  String? unitId;
  String? storeName;

  Map<String, dynamic> toJson() => {
        'storeDetail': storeDetails?.toJson(),
        'brandId': brandId,
        'sku': sku,
        'parsedDescription': parsedDescription,
        'moderationStatus': moderationStatus,
        'productCondition': productCondition,
        'isomatricChatUserId': isomatricChatUserId,
        'productPickUpAddress': productPickUpAddress?.toJson(),
        'userStoreProduct': userStoreProduct,
        'productConditionText': productConditionText,
        'isproductCondition': isproductCondition,
        'parentProductId': parentProductId,
        'childProductId': childProductId,
        'comboProducts':
            comboProducts == null ? [] : List<dynamic>.from(comboProducts!.map((x) => x)),
        'productType': productType,
        'offerProductDetails': offerProductDetails == null
            ? []
            : List<dynamic>.from(offerProductDetails!.map((x) => x)),
        'storeCategoryId': storeCategoryId,
        'cashOnDelivery': cashOnDelivery,
        'shareLink': shareLink,
        'replacementPolicy': replacementPolicy?.toJson(),
        'maxQuantity': maxQuantity == null ? [] : List<dynamic>.from(maxQuantity!.map((x) => x)),
        'maxQuantityPerUser': maxQuantityPerUser,
        'resellerCommission': resellerCommission,
        'resellerCommissionType': resellerCommissionType,
        'resellerPercentageCommission': resellerPercentageCommission,
        'resellerFixedCommission': resellerFixedCommission,
        'term&condition': termCondition?.toJson(),
        'sizeChartDescription': sizeChartDescription,
        'exchangePolicy': exchangePolicy?.toJson(),
        'returnPolicy': returnPolicy?.toJson(),
        'productName': productName,
        'unitName': unitName,
        'brandName': brandName,
        'categoryPath':
            categoryPath == null ? [] : List<dynamic>.from(categoryPath!.map((x) => x.toJson())),
        'shoppingListId': shoppingListId,
        'catName': catName,
        'subCatName': subCatName,
        'subSubCatName': subSubCatName,
        'isStoreClose': isStoreClose,
        'currency': currency,
        'currencySymbol': currencySymbol,
        'allOffers': allOffers == null ? [] : List<dynamic>.from(allOffers!.map((x) => x)),
        'attributes':
            attributes == null ? [] : List<dynamic>.from(attributes!.map((x) => x.toJson())),
        'htmlAttributes':
            htmlAttributes == null ? [] : List<dynamic>.from(htmlAttributes!.map((x) => x)),
        'highlight': highlight == null ? [] : List<dynamic>.from(highlight!.map((x) => x)),
        'images': images == null ? [] : List<dynamic>.from(images!.map((x) => x.toJson())),
        'mobileImage':
            mobileImage == null ? [] : List<dynamic>.from(mobileImage!.map((x) => x.toJson())),
        'modelImage': modelImage == null ? [] : List<dynamic>.from(modelImage!.map((x) => x)),
        'overviewData': overviewData == null ? [] : List<dynamic>.from(overviewData!.map((x) => x)),
        'offers': offers?.toJson(),
        'offer': offer?.toJson(),
        'linkedVariant':
            linkedVariant == null ? [] : List<dynamic>.from(linkedVariant!.map((x) => x.toJson())),
        'isFavourite': isFavourite,
        'variants': variants == null ? [] : List<dynamic>.from(variants!.map((x) => x.toJson())),
        'sellerCount': sellerCount,
        'MOQData': moqData?.toJson(),
        'allowOrderOutOfStock': allowOrderOutOfStock,
        'finalPriceList': finalPriceList?.toJson(),
        'availableQuantity': availableQuantity,
        'supplier': supplier?.toJson(),
        'productSeo': productSeo?.toJson(),
        'sizeChart': sizeChart == null ? [] : List<dynamic>.from(sizeChart!.map((x) => x.toJson())),
        'isSizeChart': isSizeChart,
        'detailDesc': detailDesc,
        'outOfStock': outOfStock,
        'prescriptionRequired': prescriptionRequired,
        'needsIdProof': needsIdProof,
        'saleOnline': saleOnline,
        'nextSlotTime': nextSlotTime,
        'isB2cMultiPrice': isB2CMultiPrice,
        'b2cPriceRange':
            b2CPriceRange == null ? [] : List<dynamic>.from(b2CPriceRange!.map((x) => x.toJson())),
        'subScriptionStatus': subScriptionStatus,
        'sellerPlanDetails': sellerPlanDetails?.toJson(),
        'liveStreamfinalPriceList': liveStreamfinalPriceList?.toJson(),
        'status': status,
        'categoryList':
            categoryList == null ? [] : List<dynamic>.from(categoryList!.map((x) => x.toJson())),
        'rating': rating,
        'totalRating': totalRating,
        'slug': slug,
        'variantCount': variantCount,
        'productHigestPromoDetails': productHigestPromoDetails?.toJson(),
        'appShareLink': appShareLink,
        'addToCartOnId': addToCartOnId,
        'centralProductId': centralProductId,
      };
}

class StoreDetails {
  StoreDetails({
    this.companyName,
    this.manufacturer,
    this.importer,
    this.packer,
    this.countryName,
  });

  factory StoreDetails.fromJson(Map<String, dynamic> json) => StoreDetails(
        companyName: json['companyName'] as String? ?? '',
        manufacturer: json['manufacturer'] == null
            ? null
            : Importer.fromJson(json['manufacturer'] as Map<String, dynamic>),
        importer: json['importer'] == null
            ? null
            : Importer.fromJson(json['importer'] as Map<String, dynamic>),
        packer: json['packer'] == null
            ? null
            : Importer.fromJson(json['packer'] as Map<String, dynamic>),
        countryName: json['countryName'] as String? ?? '',
      );
  String? companyName;
  Importer? manufacturer;
  Importer? importer;
  Importer? packer;
  String? countryName;

  Map<String, dynamic> toJson() => {
        'companyName': companyName,
        'manufacturer': manufacturer?.toJson(),
        'importer': importer?.toJson(),
        'packer': packer?.toJson(),
        'countryName': countryName,
      };
}

class Importer {
  factory Importer.fromJson(Map<String, dynamic> json) => Importer(
        addressLine1: json['addressLine1'] as String? ?? '',
        addressLine2: json['addressLine2'] as String? ?? '',
        addressArea: json['addressArea'] as String? ?? '',
        city: json['city'] as String? ?? '',
        postCode: json['postCode'] as String? ?? '',
        state: json['state'] as String? ?? '',
        lat: json['lat'] as String? ?? '',
        long: json['long'] as String? ?? '',
        address: json['address'] as String? ?? '',
        country: json['country'] as String? ?? '',
        googlePlaceName: json['googlePlaceName'] as String? ?? '',
        areaOrDistrict: json['areaOrDistrict'] as String? ?? '',
        locality: json['locality'] as String? ?? '',
        emiratesCountryId: json['emiratesCountryId'] as String? ?? '',
        emiratesCityId: json['emiratesCityId'] as String? ?? '',
        emiratesZoneId: json['emiratesZoneId'] as String? ?? '',
        emiratesRegionId: json['emiratesRegionId'] as String? ?? '',
      );

  Importer({
    this.addressLine1,
    this.addressLine2,
    this.addressArea,
    this.city,
    this.postCode,
    this.state,
    this.lat,
    this.long,
    this.address,
    this.country,
    this.googlePlaceName,
    this.areaOrDistrict,
    this.locality,
    this.emiratesCountryId,
    this.emiratesCityId,
    this.emiratesZoneId,
    this.emiratesRegionId,
  });

  String? addressLine1;
  String? addressLine2;
  String? addressArea;
  String? city;
  String? postCode;
  String? state;
  String? lat;
  String? long;
  String? address;
  String? country;
  String? googlePlaceName;
  String? areaOrDistrict;
  String? locality;
  String? emiratesCountryId;
  String? emiratesCityId;
  String? emiratesZoneId;
  String? emiratesRegionId;

  Map<String, dynamic> toJson() => {
        'addressLine1': addressLine1,
        'addressLine2': addressLine2,
        'addressArea': addressArea,
        'city': city,
        'postCode': postCode,
        'state': state,
        'lat': lat,
        'long': long,
        'address': address,
        'country': country,
        'googlePlaceName': googlePlaceName,
        'areaOrDistrict': areaOrDistrict,
        'locality': locality,
        'emiratesCountryId': emiratesCountryId,
        'emiratesCityId': emiratesCityId,
        'emiratesZoneId': emiratesZoneId,
        'emiratesRegionId': emiratesRegionId,
      };
}

class AttributeRating {
  AttributeRating({
    this.attributeId,
    this.attributeName,
    this.rating,
    this.totalStarRating,
  });

  factory AttributeRating.fromJson(Map<String, dynamic> json) => AttributeRating(
        attributeId: json['attributeId'] as String? ?? '',
        attributeName: json['attributeName'] as String? ?? '',
        rating: json['rating'] as num? ?? 0,
        totalStarRating: json['TotalStarRating'] as num? ?? 0,
      );
  String? attributeId;
  String? attributeName;
  num? rating;
  num? totalStarRating;

  Map<String, dynamic> toJson() => {
        'attributeId': attributeId,
        'attributeName': attributeName,
        'rating': rating,
        'TotalStarRating': totalStarRating,
      };
}

class VariantPriceDetails {
  factory VariantPriceDetails.fromJson(Map<String, dynamic> json) => VariantPriceDetails(
        message: json['message'] as String? ?? '',
        data: json['data'] == null
            ? null
            : VariantPriceDetailsData.fromJson(json['data'] as Map<String, dynamic>),
      );

  VariantPriceDetails({
    this.message,
    this.data,
  });

  String? message;
  VariantPriceDetailsData? data;
}

class VariantPriceDetailsData {
  VariantPriceDetailsData({
    this.variantId,
    this.subScriptionStatus,
    this.sellerPlanDetails,
    this.finalPriceDetails,
    this.priceDetails,
  });

  factory VariantPriceDetailsData.fromJson(Map<String, dynamic> json) => VariantPriceDetailsData(
        variantId: json['variantId'] as String? ?? '',
        subScriptionStatus: json['subScriptionStatus'] as num? ?? 0,
        sellerPlanDetails: json['sellerPlanDetails'] != null
            ? SellerPlanDetails.fromJson(json['sellerPlanDetails'] as Map<String, dynamic>)
            : null,
        finalPriceDetails: json['finalPriceDetails'] != null
            ? FinalPriceList.fromJson(json['finalPriceDetails'] as Map<String, dynamic>)
            : null,
        priceDetails: json['priceDetails'] != null
            ? PriceDetails.fromJson(json['priceDetails'] as Map<String, dynamic>)
            : null,
      );
  String? variantId;
  num? subScriptionStatus;
  SellerPlanDetails? sellerPlanDetails;
  FinalPriceList? finalPriceDetails;
  PriceDetails? priceDetails;
}

class PriceDetails {
  PriceDetails({
    this.id,
    this.sellerId,
    this.priceData,
    this.creationSource,
    this.priceCondition,
    this.linkProduct,
    this.creationDate,
    this.updateDate,
    this.status,
    this.isActive,
    this.changedBy,
  });

  factory PriceDetails.fromJson(Map<String, dynamic> json) => PriceDetails(
        id: json['_id'] as String? ?? '',
        sellerId: json['sellerId'] as String? ?? '',
        priceData: json['priceData'] != null
            ? PriceData.fromJson(json['priceData'] as Map<String, dynamic>)
            : null,
        creationSource: json['creationSource'] as String? ?? '',
        priceCondition: json['priceCondition'] != null
            ? PriceCondition.fromJson(json['priceCondition'] as Map<String, dynamic>)
            : null,
        linkProduct:
            (json['linkProduct'] as List<dynamic>?)?.map((e) => e as String).toList() ?? [],
        creationDate: json['creationDate'] as String? ?? '',
        updateDate: json['updateDate'] as String? ?? '',
        status: json['status'] as int? ?? 0,
        isActive: json['isActive'] as bool? ?? false,
        changedBy: json['changedBy'] as String? ?? '',
      );

  final String? id;
  final String? sellerId;
  final PriceData? priceData;
  final String? creationSource;
  final PriceCondition? priceCondition;
  final List<String>? linkProduct;
  final String? creationDate;
  final String? updateDate;
  final int? status;
  final bool? isActive;
  final String? changedBy;

  Map<String, dynamic> toJson() => {
        '_id': id,
        'sellerId': sellerId,
        'priceData': priceData?.toJson(),
        'creationSource': creationSource,
        'priceCondition': priceCondition?.toJson(),
        'linkProduct': linkProduct,
        'creationDate': creationDate,
        'updateDate': updateDate,
        'status': status,
        'isActive': isActive,
        'changedBy': changedBy,
      };
}

class PriceData {
  PriceData({
    this.msrp,
    this.tfmPrice,
    this.autoShipPrice,
    this.oneTimeOffer,
    this.promo,
  });

  factory PriceData.fromJson(Map<String, dynamic> json) => PriceData(
        msrp:
            json['msrp'] != null ? PriceItem.fromJson(json['msrp'] as Map<String, dynamic>) : null,
        tfmPrice: json['tfm_price'] != null
            ? PriceItem.fromJson(json['tfm_price'] as Map<String, dynamic>)
            : null,
        autoShipPrice: json['auto_ship_price'] != null
            ? PriceItem.fromJson(json['auto_ship_price'] as Map<String, dynamic>)
            : null,
        oneTimeOffer: json['one_time_offer'] != null
            ? PriceItem.fromJson(json['one_time_offer'] as Map<String, dynamic>)
            : null,
        promo: json['promo'] != null
            ? PriceItem.fromJson(json['promo'] as Map<String, dynamic>)
            : null,
      );

  final PriceItem? msrp;
  final PriceItem? tfmPrice;
  final PriceItem? autoShipPrice;
  final PriceItem? oneTimeOffer;
  final PriceItem? promo;

  Map<String, dynamic> toJson() => {
        'msrp': msrp?.toJson(),
        'tfm_price': tfmPrice?.toJson(),
        'auto_ship_price': autoShipPrice?.toJson(),
        'one_time_offer': oneTimeOffer?.toJson(),
        'promo': promo?.toJson(),
      };
}

class PriceItem {
  PriceItem({
    this.price,
    this.sherpaCommission,
    this.additionalTalent,
    this.isEnabled,
  });

  factory PriceItem.fromJson(Map<String, dynamic> json) => PriceItem(
        price: json['price'] as num? ?? 0,
        sherpaCommission: json['sherpa_commission'] as num? ?? 0,
        additionalTalent: json['additional_talent'] as num? ?? 0,
        isEnabled: json['isEnabled'] as bool? ?? false,
      );

  final num? price;
  final num? sherpaCommission;
  final num? additionalTalent;
  final bool? isEnabled;

  Map<String, dynamic> toJson() => {
        'price': price,
        'sherpa_commission': sherpaCommission,
        'additional_talent': additionalTalent,
        'isEnabled': isEnabled,
      };
}

class PriceCondition {
  PriceCondition({
    this.beginDateTimeStamp,
    this.endDateTimeStamp,
  });

  factory PriceCondition.fromJson(Map<String, dynamic> json) => PriceCondition(
        beginDateTimeStamp: json['beginDateTimeStamp'] as int? ?? 0,
        endDateTimeStamp: json['endDateTimeStamp'] as int? ?? 0,
      );

  final int? beginDateTimeStamp;
  final int? endDateTimeStamp;

  Map<String, dynamic> toJson() => {
        'beginDateTimeStamp': beginDateTimeStamp,
        'endDateTimeStamp': endDateTimeStamp,
      };
}

//// Product variant response
class ProductVariantReponse {
  factory ProductVariantReponse.fromJson(Map<String, dynamic> json) => ProductVariantReponse(
        message: json['message'] as String? ?? '',
        data: json['variant'] == null
            ? null
            : ProductVariantDetailData.fromJson(json['variant'] as Map<String, dynamic>),
      );

  ProductVariantReponse({
    this.message,
    this.data,
  });

  String? message;
  ProductVariantDetailData? data;
}

class ProductVariantDetailData {
  factory ProductVariantDetailData.fromJson(Map<String, dynamic> json) => ProductVariantDetailData(
        variantId: json['variantId'] as String? ?? '',
        slug: json['slug'] as String? ?? '',
        productName: json['productName'] as String? ?? '',
        parentProductId: json['parentProductId'] as String? ?? '',
        colorName: json['colorName'] as String? ?? '',
        color: json['color'] as String? ?? '',
        size: json['size'] as String? ?? '',
        sku: json['sku'] as String? ?? '',
        finalPriceList: json['finalPriceList'] == null
            ? null
            : VariantFinalPriceList.fromJson(json['finalPriceList'] as Map<String, dynamic>),
        inStock: json['inStock'] as bool? ?? false,
        availableQuantity: json['availableQuantity'] as int? ?? 0,
        images: (json['images'] as List<dynamic>?)
                ?.map((e) => VariantImage.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
        modelImage: json['modelImage'] as List<dynamic>? ?? [],
        bestOffer: json['bestOffer'] as Map<String, dynamic>? ?? {},
        storeId: json['storeId'] as String? ?? '',
        storeName: json['storeName'] as String? ?? '',
        status: json['status'] as int? ?? 0,
        linkedtounits: (json['linkedtounits'] as List<dynamic>?)
                ?.map((e) => VariantLinkedUnit.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
        minimumOrderQty: json['minimumOrderQty'] as int? ?? 0,
      );
  ProductVariantDetailData({
    this.variantId,
    this.slug,
    this.productName,
    this.parentProductId,
    this.colorName,
    this.color,
    this.size,
    this.sku,
    this.finalPriceList,
    this.inStock,
    this.availableQuantity,
    this.images,
    this.modelImage,
    this.bestOffer,
    this.storeId,
    this.storeName,
    this.status,
    this.linkedtounits,
    this.minimumOrderQty,
  });

  String? variantId;
  String? slug;
  String? productName;
  String? parentProductId;
  String? colorName;
  String? color;
  String? size;
  String? sku;
  VariantFinalPriceList? finalPriceList;
  bool? inStock;
  int? availableQuantity;
  List<VariantImage>? images;
  List<dynamic>? modelImage;
  Map<String, dynamic>? bestOffer;
  String? storeId;
  String? storeName;
  int? status;
  List<VariantLinkedUnit>? linkedtounits;
  int? minimumOrderQty;
}

class VariantFinalPriceList {
  factory VariantFinalPriceList.fromJson(Map<String, dynamic> json) => VariantFinalPriceList(
        basePrice: (json['basePrice'] as num?)?.toDouble() ?? 0.0,
        finalPrice: (json['finalPrice'] as num?)?.toDouble() ?? 0.0,
        discountPrice: (json['discountPrice'] as num?)?.toDouble() ?? 0.0,
        discountPercentage: (json['discountPercentage'] as num?)?.toDouble() ?? 0.0,
        discountType: json['discountType'] as int? ?? 0,
        taxRate: json['taxRate'] as int? ?? 0,
        msrpPrice: (json['msrpPrice'] as num?)?.toDouble() ?? 0.0,
      );
  VariantFinalPriceList({
    this.basePrice,
    this.finalPrice,
    this.discountPrice,
    this.discountPercentage,
    this.discountType,
    this.taxRate,
    this.msrpPrice,
  });

  double? basePrice;
  double? finalPrice;
  double? discountPrice;
  double? discountPercentage;
  int? discountType;
  int? taxRate;
  double? msrpPrice;
}

class VariantImage {
  factory VariantImage.fromJson(Map<String, dynamic> json) => VariantImage(
        small: json['small'] as String? ?? '',
        altText: json['altText'] as String? ?? '',
        filePath: json['filePath'] as String? ?? '',
      );
  VariantImage({
    this.small,
    this.altText,
    this.filePath,
  });

  String? small;
  String? altText;
  String? filePath;
}

class VariantLinkedUnit {
  factory VariantLinkedUnit.fromJson(Map<String, dynamic> json) => VariantLinkedUnit(
        attrname: json['attrname'] == null
            ? null
            : VariantAttribute.fromJson(json['attrname'] as Map<String, dynamic>),
        value: json['value'] == null
            ? null
            : VariantAttribute.fromJson(json['value'] as Map<String, dynamic>),
      );
  VariantLinkedUnit({
    this.attrname,
    this.value,
  });

  VariantAttribute? attrname;
  VariantAttribute? value;
}

class VariantAttribute {
  factory VariantAttribute.fromJson(Map<String, dynamic> json) => VariantAttribute(
        en: json['en'] as String? ?? '',
      );
  VariantAttribute({
    this.en,
  });

  String? en;
}

///Bitmap filter variants response
class BitMapFilterVariantsResponse {
  BitMapFilterVariantsResponse({
    this.productId,
    this.bitmap,
    this.selectedFilters,
  });

  factory BitMapFilterVariantsResponse.fromJson(Map<String, dynamic> json) =>
      BitMapFilterVariantsResponse(
        productId: json['productId'] as String?,
        bitmap: json['bitmap'] != null
            ? DynamicBitmap.fromJson(json['bitmap'] as Map<String, dynamic>)
            : null,
        selectedFilters: json['selectedFilters'] != null
            ? SelectedFilters.fromJson(json['selectedFilters'] as Map<String, dynamic>)
            : null,
      );

  String? productId;
  DynamicBitmap? bitmap;
  SelectedFilters? selectedFilters;

  Map<String, dynamic> toJson() => {
        'productId': productId,
        'bitmap': bitmap?.toJson(),
        'selectedFilters': selectedFilters?.toJson(),
      };
}

class DynamicBitmap {
  DynamicBitmap({
    this.options,
    this.optionValidity,
    this.variantMap,
  });

  factory DynamicBitmap.fromJson(Map<String, dynamic> json) => DynamicBitmap(
        options: (json['options'] as Map<String, dynamic>?)?.map(
          (key, value) => MapEntry(
            key,
            List<String>.from(value as Iterable<dynamic>),
          ),
        ),
        optionValidity: (json['optionValidity'] as Map<String, dynamic>?)?.map(
          (mainKey, innerMap) => MapEntry(
            mainKey,
            (innerMap as Map<String, dynamic>).map(
              (indexKey, indexValue) => MapEntry(
                indexKey,
                (indexValue as Map<String, dynamic>).map(
                  (fieldKey, valueList) =>
                      MapEntry(fieldKey, List<dynamic>.from(valueList as Iterable<dynamic>)),
                ),
              ),
            ),
          ),
        ),
        variantMap: (json['variantMap'] as Map<String, dynamic>?)?.map(
          (key, value) => MapEntry(key, ProductVariant.fromJson(value as Map<String, dynamic>)),
        ),
      );

  Map<String, List<String>>? options;

  Map<String, Map<String, Map<String, List<dynamic>>>>? optionValidity;

  Map<String, ProductVariant>? variantMap;

  Map<String, dynamic> toJson() => {
        'options': options,
        'optionValidity': optionValidity,
        'variantMap': variantMap?.map((k, v) => MapEntry(k, v.toJson())),
      };
}

class ProductVariant {
  ProductVariant({
    this.variantId,
    this.sku,
    this.price,
    this.inStock,
    this.stockQty,
  });

  factory ProductVariant.fromJson(Map<String, dynamic> json) => ProductVariant(
        variantId: json['variantId'] as String?,
        sku: json['sku'] as String?,
        price: (json['price'] as num?)?.toDouble(),
        inStock: json['inStock'] as bool?,
        stockQty: json['stockQty'] as int?,
      );

  String? variantId;
  String? sku;
  double? price;
  bool? inStock;
  int? stockQty;

  Map<String, dynamic> toJson() => {
        'variantId': variantId,
        'sku': sku,
        'price': price,
        'inStock': inStock,
        'stockQty': stockQty,
      };
}

class SelectedFilters {
  SelectedFilters({
    this.colorIndex,
    this.sizeIndex,
  });

  factory SelectedFilters.fromJson(Map<String, dynamic> json) => SelectedFilters(
        colorIndex: json['colorIndex'] as int?,
        sizeIndex: json['sizeIndex'] as int?,
      );

  int? colorIndex;
  int? sizeIndex;

  Map<String, dynamic> toJson() => {
        'colorIndex': colorIndex,
        'sizeIndex': sizeIndex,
      };
}

class ProductPickUpAddress {
  ProductPickUpAddress({
    this.addressLine2,
    this.state,
    this.mobileNumberCode,
    this.locality,
    this.city,
    this.mobileNumber,
    this.areaOrDistrict,
    this.postCode,
    this.country,
    this.googlePlaceName,
    this.addressLine1,
    this.address,
    this.long,
    this.lat,
    this.addressArea,
  });

  factory ProductPickUpAddress.fromJson(Map<String, dynamic> json) => ProductPickUpAddress(
        addressLine2: json['addressLine2'] as String? ?? '',
        state: json['state'] as String? ?? '',
        mobileNumberCode: json['mobileNumberCode'] as String? ?? '',
        locality: json['locality'] as String? ?? '',
        city: json['city'] as String? ?? '',
        mobileNumber: json['mobileNumber'] as String? ?? '',
        areaOrDistrict: json['areaOrDistrict'] as String? ?? '',
        postCode: json['postCode'] as String? ?? '',
        country: json['country'] as String? ?? '',
        googlePlaceName: json['googlePlaceName'] as String? ?? '',
        addressLine1: json['addressLine1'] as String? ?? '',
        address: json['address'] as String? ?? '',
        long:
            json['long'] is String ? json['long'] as String? ?? '0' : json['long'] as double? ?? 0,
        lat: json['lat'] is String ? json['lat'] as String? ?? '0' : json['lat'] as double? ?? 0,
        addressArea: json['addressArea'] as String? ?? '',
      );
  String? addressLine2;
  String? state;
  String? mobileNumberCode;
  String? locality;
  String? city;
  String? mobileNumber;
  String? areaOrDistrict;
  String? postCode;
  String? country;
  String? googlePlaceName;
  String? addressLine1;
  String? address;
  dynamic long;
  dynamic lat;
  String? addressArea;

  Map<String, dynamic> toJson() => {
        'addressLine2': addressLine2,
        'state': state,
        'mobileNumberCode': mobileNumberCode,
        'locality': locality,
        'city': city,
        'mobileNumber': mobileNumber,
        'areaOrDistrict': areaOrDistrict,
        'postCode': postCode,
        'country': country,
        'googlePlaceName': googlePlaceName,
        'addressLine1': addressLine1,
        'address': address,
        'long': long,
        'addressArea': addressArea,
        'lat': lat,
      };
}

class ReplacementPolicy {
  ReplacementPolicy({
    this.isReplacement,
    this.noofdays,
  });

  factory ReplacementPolicy.fromJson(Map<String, dynamic> json) => ReplacementPolicy(
        isReplacement: json['isReplacement'] as bool? ?? false,
        noofdays: json['noofdays'] as num? ?? 0,
      );
  bool? isReplacement;
  num? noofdays;

  Map<String, dynamic> toJson() => {
        'isReplacement': isReplacement,
        'noofdays': noofdays,
      };
}

class ReturnPolicy {
  ReturnPolicy({
    this.isReturn,
    this.noofdays,
  });

  factory ReturnPolicy.fromJson(Map<String, dynamic> json) => ReturnPolicy(
        isReturn: json['isReturn'] as bool? ?? false,
        noofdays: json['noofdays'] as num? ?? 0,
      );
  bool? isReturn;
  num? noofdays;

  Map<String, dynamic> toJson() => {
        'isReturn': isReturn,
        'noofdays': noofdays,
      };
}

class Variant {
  Variant({
    this.name,
    this.keyName,
    this.rgb,
    this.unitData,
    this.childProductId,
    this.sizeData,
    this.image,
    this.unitId,
    this.extraLarge,
    this.isPrimary,
  });

  factory Variant.fromJson(Map<String, dynamic> json) => Variant(
        name: json['name'] as String? ?? '',
        keyName: json['keyName'] as String? ?? '',
        rgb: json['rgb'] as String? ?? '',
        unitData: json['unitData'] as String? ?? '',
        childProductId: json['childProductId'] as String? ?? '',
        sizeData: json['sizeData'] == null
            ? []
            : List<VariantItem>.from((json['sizeData'] as List)
                .map((x) => VariantItem.fromJson(x as Map<String, dynamic>))),
        image: json['image'] as String? ?? '',
        unitId: json['unitId'] as String? ?? '',
        extraLarge: json['extraLarge'] as String? ?? '',
        isPrimary: json['isPrimary'] as bool? ?? false,
      );
  String? name;
  String? keyName;
  String? rgb;
  String? unitData;
  String? childProductId;
  List<VariantItem>? sizeData;
  String? image;
  String? unitId;
  String? extraLarge;
  bool? isPrimary;

  Map<String, dynamic> toJson() => {
        'name': name,
        'keyName': keyName,
        'rgb': rgb,
        'unitData': unitData,
        'childProductId': childProductId,
        'sizeData': sizeData == null ? [] : List<dynamic>.from(sizeData!.map((x) => x.toJson())),
        'image': image,
        'unitId': unitId,
        'extraLarge': extraLarge,
        'isPrimary': isPrimary,
      };
}

class VariantItem {
  VariantItem({
    this.childProductId,
    this.size,
    this.keyName,
    this.unitData,
    this.rgb,
    this.isPrimary,
    this.finalPriceList,
    this.unitId,
    this.name,
    this.visible,
    this.seqId,
    this.image,
    this.extraLarge,
    this.outOfStock,
    this.availableStock,
    this.slug,
    this.sku,
  });

  factory VariantItem.fromJson(Map<String, dynamic> json) => VariantItem(
        childProductId: json['childProductId'] as String? ?? '',
        size: json['size'] as String? ?? '',
        keyName: json['keyName'] as String? ?? '',
        unitData: json['unitData'] as String? ?? '',
        rgb: json['rgb'] as String? ?? '',
        isPrimary: json['isPrimary'] as bool? ?? false,
        finalPriceList: json['finalPriceList'] == null
            ? null
            : FinalPriceList.fromJson(json['finalPriceList'] as Map<String, dynamic>),
        unitId: json['unitId'] as String? ?? '',
        name: json['name'] as String? ?? '',
        visible: json['visible'] as bool? ?? false,
        seqId: json['seqId'] as num? ?? 0,
        image: json['image'] as String? ?? '',
        extraLarge: json['extraLarge'] as String? ?? '',
        outOfStock: json['outOfStock'] as bool? ?? false,
        availableStock: json['availableStock'] as num? ?? 0,
        slug: json['slug'] == null ? null : Slug.fromJson(json['slug'] as Map<String, dynamic>),
        sku: json['sku'] as String? ?? '',
      );
  String? childProductId;
  String? size;
  String? keyName;
  String? unitData;
  String? rgb;
  bool? isPrimary;
  FinalPriceList? finalPriceList;
  String? unitId;
  String? name;
  bool? visible;
  num? seqId;
  String? image;
  String? extraLarge;
  bool? outOfStock;
  num? availableStock;
  Slug? slug;
  String? sku;

  Map<String, dynamic> toJson() => {
        'childProductId': childProductId,
        'size': size,
        'keyName': keyName,
        'unitData': unitData,
        'rgb': rgb,
        'isPrimary': isPrimary,
        'finalPriceList': finalPriceList?.toJson(),
        'unitId': unitId,
        'name': name,
        'visible': visible,
        'seqId': seqId,
        'image': image,
        'extraLarge': extraLarge,
        'outOfStock': outOfStock,
        'availableStock': availableStock,
        'slug': slug?.toJson(),
        'sku': sku,
      };
}

class Slug {
  Slug({
    this.title,
    this.slug,
    this.metatags,
    this.description,
  });

  factory Slug.fromJson(Map<String, dynamic> json) => Slug(
        title: json['title'] == null
            ? null
            : (json['title'] is List)
                ? List<SlugClass>.from((json['title'] as List)
                    .map((dynamic x) => SlugClass.fromJson(x as Map<String, dynamic>)))
                : SlugClass.fromJson(json['title'] as Map<String, dynamic>),
        slug: json['slug'] == null
            ? null
            : (json['slug'] is String)
                ? json['slug'] as String? ?? ''
                : (json['slug'] is List)
                    ? List<SlugClass>.from((json['slug'] as List)
                        .map((dynamic x) => SlugClass.fromJson(x as Map<String, dynamic>)))
                    : SlugClass.fromJson(json['slug'] as Map<String, dynamic>),
        metatags: json['metatags'] == null
            ? null
            : (json['metatags'] is List)
                ? List<SlugClass>.from((json['metatags'] as List)
                    .map((dynamic x) => SlugClass.fromJson(x as Map<String, dynamic>)))
                : SlugClass.fromJson(json['metatags'] as Map<String, dynamic>),
        description: json['description'] == null
            ? null
            : (json['description'] is List)
                ? List<SlugClass>.from((json['description'] as List)
                    .map((dynamic x) => SlugClass.fromJson(x as Map<String, dynamic>)))
                : SlugClass.fromJson(json['description'] as Map<String, dynamic>),
      );
  dynamic title;
  dynamic slug;
  dynamic metatags;
  dynamic description;

  Map<String, dynamic> toJson() => {
        'title': title is String
            ? title
            : title is List
                ? List<dynamic>.from((title as List).map((x) => x))
                : title?.toJson(),
        'slug': slug is String
            ? slug
            : slug is List
                ? List<dynamic>.from((slug as List).map((x) => x))
                : slug?.toJson(),
        'metatags': metatags is String
            ? metatags
            : metatags is List
                ? List<dynamic>.from((metatags as List).map((x) => x))
                : metatags?.toJson(),
        'description': description is String
            ? description
            : description is List
                ? List<dynamic>.from((description as List).map((x) => x))
                : description?.toJson(),
      };
}

class ProductReviewsResponse {
  factory ProductReviewsResponse.fromJson(Map<String, dynamic> json) => ProductReviewsResponse(
        data: json['data'] == null
            ? null
            : ProductReviewsResponseDataReview.fromJson(json['data'] as Map<String, dynamic>),
      );

  ProductReviewsResponse({
    this.data,
  });

  ProductReviewsResponseDataReview? data;

  Map<String, dynamic> toJson() => {
        'data': data?.toJson(),
      };
}

class ProductReviewsResponseDataReview {
  factory ProductReviewsResponseDataReview.fromJson(Map<String, dynamic> json) =>
      ProductReviewsResponseDataReview(
        review: json['review'] == null
            ? null
            : ProductReviewData.fromJson(json['review'] as Map<String, dynamic>),
      );

  ProductReviewsResponseDataReview({
    this.review,
  });

  ProductReviewData? review;

  Map<String, dynamic> toJson() => {
        'data': review?.toJson(),
      };
}

class ProductReviewData {
  ProductReviewData({
    this.userReviews,
    this.fiveStarRating,
    this.fourStartRating,
    this.threeStarRating,
    this.twoStarRating,
    this.oneStarRating,
    this.penCount,
    this.totalNoOfReviews,
    this.totalNoOfRatings,
    this.totalStarRating,
    this.attributeRating,
    this.images,
  });

  factory ProductReviewData.fromJson(Map<String, dynamic> json) => ProductReviewData(
        userReviews: json['userReviews'] == null
            ? []
            : List<UserReview>.from((json['userReviews'] as List)
                .map((dynamic x) => UserReview.fromJson(x as Map<String, dynamic>))),
        fiveStarRating: json['FiveStarRating'] as num? ?? 0,
        fourStartRating: json['FourStartRating'] as num? ?? 0,
        threeStarRating: json['ThreeStarRating'] as num? ?? 0,
        twoStarRating: json['TwoStarRating'] as num? ?? 0,
        oneStarRating: json['OneStarRating'] as num? ?? 0,
        penCount: json['penCount'] as num? ?? 0,
        totalNoOfReviews: json['TotalNoOfReviews'] as num? ?? 0,
        totalNoOfRatings: json['TotalNoOfRatings'] as num? ?? 0,
        totalStarRating: json['TotalStarRating'] as num? ?? 0,
        attributeRating: json['attributeRating'] == null
            ? []
            : List<AttributeRating>.from((json['attributeRating'] as List)
                .map((dynamic x) => AttributeRating.fromJson(x as Map<String, dynamic>))),
        images:
            json['images'] == null ? [] : List<String>.from((json['images'] as List).map((x) => x)),
      );
  List<UserReview>? userReviews;
  num? fiveStarRating;
  num? fourStartRating;
  num? threeStarRating;
  num? twoStarRating;
  num? oneStarRating;
  num? penCount;
  num? totalNoOfReviews;
  num? totalNoOfRatings;
  num? totalStarRating;
  List<AttributeRating>? attributeRating;
  List<String>? images;

  Map<String, dynamic> toJson() => {
        'userReviews':
            userReviews == null ? [] : List<dynamic>.from(userReviews!.map((x) => x.toJson())),
        'FiveStarRating': fiveStarRating,
        'FourStartRating': fourStartRating,
        'ThreeStarRating': threeStarRating,
        'TwoStarRating': twoStarRating,
        'OneStarRating': oneStarRating,
        'penCount': penCount,
        'TotalNoOfReviews': totalNoOfReviews,
        'TotalNoOfRatings': totalNoOfRatings,
        'TotalStarRating': totalStarRating,
        'attributeRating': attributeRating == null
            ? []
            : List<dynamic>.from(attributeRating!.map((x) => x.toJson())),
        'images': images == null ? [] : List<dynamic>.from(images!.map((x) => x)),
      };
}

class UserReview {
  UserReview({
    this.reviewId,
    this.userId,
    this.name,
    this.userLikes,
    this.userdisLikes,
    this.userReported,
    this.timestamp,
    this.createdTimestamp,
    this.likes,
    this.images,
    this.replies,
    this.disLikes,
    this.rating,
    this.reviewTitle,
    this.reviewDesc,
    this.sellerName,
  });

  factory UserReview.fromJson(Map<String, dynamic> json) => UserReview(
        reviewId: json['reviewId'] as String? ?? '',
        userId: json['userId'] as String? ?? '',
        name: (json['name'] ?? json['userName']) as String? ?? '',
        userLikes: (json['userLikes'] ?? json['isUserLike']) as bool? ?? false,
        userdisLikes: json['userdisLikes'] as bool? ?? false,
        userReported: json['usersReported'] as bool? ?? false,
        timestamp: json['timestamp'] as String? ?? '',
        createdTimestamp: json['createdTimestamp'] as num? ?? 0,
        likes: (json['likes'] ?? json['likesCount']) as num? ?? 0,
        images:
            json['images'] == null ? [] : List<String>.from((json['images'] as List).map((x) => x)),
        replies: json['replies'] == null
            ? []
            : List<dynamic>.from((json['replies'] as List).map((x) => x)),
        disLikes: json['disLikes'] as num? ?? 0,
        rating: num.tryParse(json['rating']?.toString() ?? '') ?? 0,
        reviewTitle: json['reviewTitle'] as String? ?? '',
        reviewDesc: (json['reviewDesc'] ?? json['reviewDescription']) as String? ?? '',
        sellerName: json['sellerName'] as String? ?? '',
      );
  String? reviewId;
  String? userId;
  String? name;
  bool? userLikes;
  bool? userdisLikes;
  bool? userReported;
  String? timestamp;
  num? createdTimestamp;
  num? likes;
  List<String>? images;
  List<dynamic>? replies;
  num? disLikes;
  num? rating;
  String? reviewTitle;
  String? reviewDesc;
  String? sellerName;

  Map<String, dynamic> toJson() => {
        'reviewId': reviewId,
        'userId': userId,
        'name': name,
        'userLikes': userLikes,
        'userdisLikes': userdisLikes,
        'usersReported': userReported,
        'timestamp': timestamp,
        'createdTimestamp': createdTimestamp,
        'likes': likes,
        'images': images == null ? [] : List<dynamic>.from(images!.map((x) => x)),
        'replies': replies == null ? [] : List<dynamic>.from(replies!.map((x) => x)),
        'disLikes': disLikes,
        'rating': rating,
        'reviewTitle': reviewTitle,
        'reviewDesc': reviewDesc,
      };
}

class DescriptionElement {
  DescriptionElement({
    this.langCode,
    this.contain,
  });

  factory DescriptionElement.fromJson(Map<String, dynamic> json) => DescriptionElement(
        langCode: json['langCode'] as String? ?? '',
        contain: json['contain'] as String? ?? '',
      );
  String? langCode;
  String? contain;

  Map<String, dynamic> toJson() => {
        'langCode': langCode,
        'contain': contain,
      };
}

class B2CPriceRange {
  B2CPriceRange({
    this.minimumQty,
    this.maximumQty,
    this.price,
    this.finalPrice,
    this.discountType,
    this.discountValue,
  });

  factory B2CPriceRange.fromJson(Map<String, dynamic> json) => B2CPriceRange(
        minimumQty: json['minimumQty'] as num? ?? 0,
        maximumQty: json['maximumQty'] as num? ?? 0,
        price: json['price'] as num? ?? 0,
        finalPrice: json['finalPrice'] as num? ?? 0,
        discountType: json['discountType'] as num? ?? 0,
        discountValue: json['discountValue'] as num? ?? 0,
      );
  num? minimumQty;
  num? maximumQty;
  num? price;
  num? finalPrice;
  num? discountType;
  num? discountValue;

  Map<String, dynamic> toJson() => {
        'minimumQty': minimumQty,
        'maximumQty': maximumQty,
        'price': price,
        'finalPrice': finalPrice,
        'discountType': discountType,
        'discountValue': discountValue,
      };
}

class CategoryPath {
  CategoryPath({
    this.level,
    this.path,
    this.name,
    this.isSelected,
  });

  factory CategoryPath.fromJson(Map<String, dynamic> json) => CategoryPath(
        level: json['level'] as num? ?? 0,
        path: json['path'] as String? ?? '',
        name: json['name'] as String? ?? '',
        isSelected: json['isSelected'] as bool? ?? false,
      );
  num? level;
  String? path;
  String? name;
  bool? isSelected;

  Map<String, dynamic> toJson() => {
        'level': level,
        'path': path,
        'name': name,
        'isSelected': isSelected,
      };
}

class ExchangePolicy {
  ExchangePolicy({
    this.isExchange,
    this.noofdays,
  });

  factory ExchangePolicy.fromJson(Map<String, dynamic> json) => ExchangePolicy(
        isExchange: json['isExchange'] as bool? ?? false,
        noofdays: json['noofdays'] as num? ?? 0,
      );
  bool? isExchange;
  num? noofdays;

  Map<String, dynamic> toJson() => {
        'isExchange': isExchange,
        'noofdays': noofdays,
      };
}

class AttributesData {
  AttributesData({
    this.innerAttributes,
    this.seqId,
    this.name,
  });

  factory AttributesData.fromJson(Map<String, dynamic> json) => AttributesData(
        innerAttributes: json['innerAttributes'] == null
            ? []
            : List<InnerAttribute>.from((json['innerAttributes'] as List)
                .map((x) => InnerAttribute.fromJson(x as Map<String, dynamic>))),
        seqId: json['seqId'] as int? ?? 0,
        name: json['name'] as String? ?? '',
      );
  List<InnerAttribute>? innerAttributes;
  int? seqId;
  String? name;

  Map<String, dynamic> toJson() => {
        'innerAttributes': innerAttributes == null
            ? []
            : List<dynamic>.from(innerAttributes!.map((x) => x.toJson())),
        'seqId': seqId,
        'name': name,
      };
}

class InnerAttribute {
  InnerAttribute({
    this.name,
    this.value,
    this.attributeImage,
    this.attriubteType,
    this.customizable,
    this.isHtml,
  });

  factory InnerAttribute.fromJson(Map<String, dynamic> json) => InnerAttribute(
        name: json['name'] as String? ?? '',
        value: json['value'] as String? ?? '',
        attributeImage: json['attributeImage'] as String? ?? '',
        attriubteType: json['attriubteType'] as num? ?? 0,
        customizable: json['customizable'] as num? ?? 0,
        isHtml: json['isHtml'] as bool? ?? false,
      );
  String? name;
  String? value;
  String? attributeImage;
  num? attriubteType;
  num? customizable;
  bool? isHtml;

  Map<String, dynamic> toJson() => {
        'name': name,
        'value': value,
        'attributeImage': attributeImage,
        'attriubteType': attriubteType,
        'customizable': customizable,
        'isHtml': isHtml,
      };
}

class LinkedVariant {
  LinkedVariant({
    this.name,
    this.keyName,
  });

  factory LinkedVariant.fromJson(Map<String, dynamic> json) => LinkedVariant(
        name: json['name'] as String? ?? '',
        keyName: json['keyName'] as String? ?? '',
      );
  String? name;
  String? keyName;

  Map<String, dynamic> toJson() => {
        'name': name,
        'keyName': keyName,
      };
}

class MoqData {
  MoqData({
    this.minimumOrderQty,
    this.unitPackageType,
    this.unitMoqType,
    this.moq,
  });

  factory MoqData.fromJson(Map<String, dynamic> json) => MoqData(
        minimumOrderQty: json['minimumOrderQty'] as num? ?? 0,
        unitPackageType: json['unitPackageType'] as String? ?? '',
        unitMoqType: json['unitMoqType'] as String? ?? '',
        moq: json['MOQ'] as dynamic,
      );
  num? minimumOrderQty;
  String? unitPackageType;
  String? unitMoqType;
  dynamic moq;

  Map<String, dynamic> toJson() => {
        'minimumOrderQty': minimumOrderQty,
        'unitPackageType': unitPackageType,
        'unitMoqType': unitMoqType,
        'MOQ': moq,
      };
}

class ProductSeo {
  ProductSeo({
    this.title,
    this.description,
    this.metatags,
    this.slug,
  });

  factory ProductSeo.fromJson(Map<String, dynamic> json) => ProductSeo(
        title: json['title'] as String? ?? '',
        description: json['description'] as String? ?? '',
        metatags: json['metatags'] as String? ?? '',
        slug: json['slug'] as String? ?? '',
      );
  String? title;
  String? description;
  String? metatags;
  String? slug;

  Map<String, dynamic> toJson() => {
        'title': title,
        'description': description,
        'metatags': metatags,
        'slug': slug,
      };
}

class SizeChartData {
  factory SizeChartData.fromRawJson(String str) =>
      SizeChartData.fromJson(json.decode(str) as Map<String, dynamic>);

  SizeChartData({
    this.name,
    this.size,
  });

  factory SizeChartData.fromJson(Map<String, dynamic> json) => SizeChartData(
        name: json['name'] as String? ?? '',
        size: json['size'] == null ? [] : List<String>.from((json['size'] as List).map((x) => x)),
      );
  String? name;
  List<String>? size;

  String toRawJson() => json.encode(toJson());

  Map<String, dynamic> toJson() => {
        'name': name,
        'size': size == null ? [] : List<dynamic>.from(size!.map((x) => x)),
      };
}

class CategoryItem {
  CategoryItem({
    this.categoryId,
    this.categoryName,
    this.parentCategory,
    this.slug,
  });

  factory CategoryItem.fromJson(Map<String, dynamic> json) => CategoryItem(
        categoryId: json['categoryId'] as String? ?? '',
        categoryName: json['categoryName'] is Map<String, dynamic>
            ? OfferName.fromJson(json['categoryName'] as Map<String, dynamic>)
            : json['categoryName'] is String
                ? json['categoryName'] as String? ?? ''
                : null,
        parentCategory: json['parent'] as bool? ?? json['parentCategory'] as bool? ?? false,
        slug: json['slug'] is Map<String, dynamic>
            ? OfferName.fromJson(json['slug'] as Map<String, dynamic>)
            : json['slug'] is String
                ? json['slug'] as String? ?? ''
                : null,
      );
  String? categoryId;
  dynamic categoryName;
  bool? parentCategory;
  dynamic slug;

  Map<String, dynamic> toJson() => {
        'categoryId': categoryId,
        'categoryName': categoryName?.toJson(),
        'parentCategory': parentCategory,
        'slug': slug?.toJson(),
      };
}

class ProductHigestPromoDetails {
  ProductHigestPromoDetails({
    this.promoId,
    this.title,
    this.description,
    this.howItWorks,
    this.promoCode,
    this.promoDiscountType,
    this.promoDiscountValue,
    this.maxPromoDiscount,
  });

  factory ProductHigestPromoDetails.fromJson(Map<String, dynamic> json) =>
      ProductHigestPromoDetails(
        promoId: json['promo_id'] as String? ?? '',
        title: json['title'] as String? ?? '',
        description: json['description'] == null
            ? []
            : List<DescriptionElement>.from((json['description'] as List)
                .map((x) => DescriptionElement.fromJson(x as Map<String, dynamic>))),
        howItWorks: json['howItWorks'] == null
            ? []
            : List<DescriptionElement>.from((json['howItWorks'] as List)
                .map((x) => DescriptionElement.fromJson(x as Map<String, dynamic>))),
        promoCode: json['promoCode'] as String? ?? '',
        promoDiscountType: json['promo_discount_type'] as String? ?? '',
        promoDiscountValue: json['promo_discount_value'] as num? ?? 0,
        maxPromoDiscount: json['maxPromoDiscount'] as num? ?? 0,
      );
  String? promoId;
  String? title;
  List<DescriptionElement>? description;
  List<DescriptionElement>? howItWorks;
  String? promoCode;
  String? promoDiscountType;
  num? promoDiscountValue;
  num? maxPromoDiscount;

  Map<String, dynamic> toJson() => {
        'promo_id': promoId,
        'title': title,
        'description':
            description == null ? [] : List<dynamic>.from(description!.map((x) => x.toJson())),
        'howItWorks':
            howItWorks == null ? [] : List<dynamic>.from(howItWorks!.map((x) => x.toJson())),
        'promoCode': promoCode,
        'promo_discount_type': promoDiscountType,
        'promo_discount_value': promoDiscountValue,
        'maxPromoDiscount': maxPromoDiscount,
      };
}

class SlugClass {
  SlugClass({
    this.en,
    this.pl,
    this.hi,
  });

  factory SlugClass.fromJson(Map<String, dynamic> json) => SlugClass(
        en: json['en'] as String? ?? '',
        pl: json['pl'] as String? ?? '',
        hi: json['hi'] as String? ?? '',
      );
  String? en;
  String? pl;
  String? hi;

  Map<String, dynamic> toJson() => {
        'en': en,
        'pl': pl,
        'hi': hi,
      };
}
