// To parse this JSON data, do
//
//     final postResponse = postResponseFromJson(jsonString);

import 'dart:convert';

PostResponseModel postResponseModelFromJson(String str) =>
    PostResponseModel.fromJson(json.decode(str) as Map<String, dynamic>);

String postResponseModelToJson(PostResponseModel data) => json.encode(data.toJson());

class PostResponseModel {
  PostResponseModel({
    this.message,
    this.totalPosts,
    this.data,
  });

  factory PostResponseModel.fromJson(Map<String, dynamic> json) => PostResponseModel(
        message: json['message'] as String? ?? '',
        totalPosts: json['totalPosts'] as num? ?? 0,
        data: json['data'] == null
            ? []
            : List<PostDataModel>.from(
                (json['data'] as List).map((x) => PostDataModel.fromJson(x as Map<String, dynamic>))),
      );
  String? message;
  num? totalPosts;
  List<PostDataModel>? data;

  Map<String, dynamic> toJson() => {
        'message': message,
        'totalPosts': totalPosts,
        'data': data == null ? [] : List<dynamic>.from(data!.map((x) => x.toJson())),
      };
}

class PostDataModel {
  PostDataModel({
    this.id,
    this.allowComment,
    this.allowDownload,
    this.allowDuet,
    this.categoryId,
    this.categoryName,
    this.categoryUrl,
    this.cloudinaryPublicId,
    this.commentCount,
    this.firstName,
    this.fullName,
    this.hashTags,
    this.imageUrl1,
    this.imageUrl1Height,
    this.imageUrl1Width,
    this.isPrivate,
    this.isStar,
    this.lastName,
    this.likesCount,
    this.location,
    this.mediaType1,
    this.mentionedUsers,
    this.musicData,
    this.musicId,
    this.place,
    this.placeId,
    this.postStatus,
    this.postViewsCount,
    this.productData,
    this.productIds,
    this.shareCount,
    this.thumbnailUrl1,
    this.timeStamp,
    this.title,
    this.userId,
    this.userName,
    this.userStoreId,
    this.userType,
    this.userTypeText,
    this.postId,
    this.liked,
    this.productCount,
    this.followStatus,
    this.profilePic,
    this.slugUrl,
    this.isBusinessUser,
    this.isSavedPost,
    this.distinctViews,
  });

  factory PostDataModel.fromJson(Map<String, dynamic> json) => PostDataModel(
        id: json['_id'] as String? ?? '',
        allowComment: json['allowComment'] as bool? ?? false,
        allowDownload: json['allowDownload'] as bool? ?? false,
        allowDuet: json['allowDuet'] as bool? ?? false,
        categoryId: json['categoryId'] as String? ?? '',
        categoryName: json['categoryName'] as String? ?? '',
        categoryUrl: json['categoryUrl'] as String? ?? '',
        cloudinaryPublicId: json['cloudinary_public_id'] as String? ?? '',
        commentCount: json['commentCount'] as num? ?? 0,
        firstName: json['firstName'] as String? ?? '',
        fullName: json['fullName'] as String? ?? '',
        hashTags: json['hashTags'] == null ? [] : List<String>.from((json['hashTags'] as List).map((x) => x)),
        imageUrl1: json['imageUrl1'] as String? ?? '',
        imageUrl1Height: json['imageUrl1Height'] as String? ?? '',
        imageUrl1Width: json['imageUrl1Width'] as String? ?? '',
        isPrivate: json['isPrivate'] as num? ?? 0,
        isStar: json['isStar'] as bool? ?? false,
        lastName: json['lastName'] as String? ?? '',
        likesCount: json['likesCount'] as num? ?? 0,
        location: json['location'] == null ? null : Location.fromJson(json['location'] as Map<String, dynamic>),
        mediaType1: json['mediaType1'] as num? ?? 0,
        mentionedUsers: json['mentionedUsers'] == null
            ? []
            : List<MentionedUser>.from(
                (json['mentionedUsers'] as List).map((x) => MentionedUser.fromJson(x as Map<String, dynamic>))),
        musicData: json['musicData'] == null ? null : MusicData.fromJson(json['musicData'] as Map<String, dynamic>),
        musicId: json['musicId'] as String? ?? '',
        place: json['place'] as String? ?? '',
        placeId: json['placeId'] as String? ?? '',
        postStatus: json['postStatus'] as num? ?? 0,
        postViewsCount: json['postViewsCount'] as num? ?? 0,
        productData: json['productData'] == null
            ? []
            : List<FeaturedProductDataItem>.from(
                (json['productData'] as List).map((x) => FeaturedProductDataItem.fromJson(x as Map<String, dynamic>))),
        productIds: json['productIds'] == null ? [] : List<dynamic>.from((json['productIds'] as List).map((x) => x)),
        shareCount: json['shareCount'] as num? ?? 0,
        thumbnailUrl1: json['thumbnailUrl1'] as String? ?? '',
        timeStamp: json['timeStamp'] as num? ?? 0,
        title: json['title'] as String? ?? '',
        userId: json['userId'] as String? ?? '',
        userName: json['userName'] as String? ?? '',
        userStoreId: json['userStoreId'] as String? ?? '',
        userType: json['userType'] as num? ?? 0,
        userTypeText: json['userTypeText'] as String? ?? '',
        postId: json['postId'] as String? ?? '',
        liked: json['liked'] as bool? ?? false,
        productCount: json['productCount'] as num? ?? 0,
        followStatus: json['followStatus'] as num? ?? 0,
        profilePic: json['profilePic'] as String? ?? '',
        slugUrl: json['slugUrl'] as String? ?? '',
        isBusinessUser: json['isBusinessUser'] as bool? ?? false,
        isSavedPost: json['isSavedPost'] as bool? ?? false,
        distinctViews: json['distinctViews'] as num? ?? 0,
      );
  String? id;
  bool? allowComment;
  bool? allowDownload;
  bool? allowDuet;
  String? categoryId;
  String? categoryName;
  String? categoryUrl;
  String? cloudinaryPublicId;
  num? commentCount;
  String? firstName;
  String? fullName;
  List<String>? hashTags;
  String? imageUrl1;
  String? imageUrl1Height;
  String? imageUrl1Width;
  num? isPrivate;
  bool? isStar;
  String? lastName;
  num? likesCount;
  Location? location;
  num? mediaType1;
  List<MentionedUser>? mentionedUsers;
  MusicData? musicData;
  String? musicId;
  String? place;
  String? placeId;
  num? postStatus;
  num? postViewsCount;
  List<FeaturedProductDataItem>? productData;
  List<dynamic>? productIds;
  num? shareCount;
  String? thumbnailUrl1;
  num? timeStamp;
  String? title;
  String? userId;
  String? userName;
  String? userStoreId;
  num? userType;
  String? userTypeText;
  String? postId;
  bool? liked;
  num? productCount;
  num? followStatus;
  String? profilePic;
  String? slugUrl;
  bool? isBusinessUser;
  bool? isSavedPost;
  num? distinctViews;

  Map<String, dynamic> toJson() => {
        '_id': id,
        'allowComment': allowComment,
        'allowDownload': allowDownload,
        'allowDuet': allowDuet,
        'categoryId': categoryId,
        'categoryName': categoryName,
        'categoryUrl': categoryUrl,
        'cloudinary_public_id': cloudinaryPublicId,
        'commentCount': commentCount,
        'firstName': firstName,
        'fullName': fullName,
        'hashTags': hashTags == null ? [] : List<dynamic>.from(hashTags!.map((x) => x)),
        'imageUrl1': imageUrl1,
        'imageUrl1Height': imageUrl1Height,
        'imageUrl1Width': imageUrl1Width,
        'isPrivate': isPrivate,
        'isStar': isStar,
        'lastName': lastName,
        'likesCount': likesCount,
        'location': location?.toJson(),
        'mediaType1': mediaType1,
        'mentionedUsers': mentionedUsers == null ? [] : List<dynamic>.from(mentionedUsers!.map((x) => x.toJson())),
        'musicData': musicData?.toJson(),
        'musicId': musicId,
        'place': place,
        'placeId': placeId,
        'postStatus': postStatus,
        'postViewsCount': postViewsCount,
        'productData': productData == null ? [] : List<dynamic>.from(productData!.map((x) => x.toJson())),
        'productIds': productIds == null ? [] : List<dynamic>.from(productIds!.map((x) => x)),
        'shareCount': shareCount,
        'thumbnailUrl1': thumbnailUrl1,
        'timeStamp': timeStamp,
        'title': title,
        'userId': userId,
        'userName': userName,
        'userStoreId': userStoreId,
        'userType': userType,
        'userTypeText': userTypeText,
        'postId': postId,
        'liked': liked,
        'productCount': productCount,
        'followStatus': followStatus,
        'profilePic': profilePic,
        'slugUrl': slugUrl,
        'isBusinessUser': isBusinessUser,
        'isSavedPost': isSavedPost,
        'distinctViews': distinctViews,
      };

  PostDataModel copyWith({
    String? id,
    bool? allowComment,
    bool? allowDownload,
    bool? allowDuet,
    String? categoryId,
    String? categoryName,
    String? categoryUrl,
    String? cloudinaryPublicId,
    num? commentCount,
    String? firstName,
    String? fullName,
    List<String>? hashTags,
    String? imageUrl1,
    String? imageUrl1Height,
    String? imageUrl1Width,
    num? isPrivate,
    bool? isStar,
    String? lastName,
    num? likesCount,
    Location? location,
    num? mediaType1,
    List<MentionedUser>? mentionedUsers,
    MusicData? musicData,
    String? musicId,
    String? place,
    String? placeId,
    num? postStatus,
    num? postViewsCount,
    List<FeaturedProductDataItem>? productData,
    List<dynamic>? productIds,
    num? shareCount,
    String? thumbnailUrl1,
    num? timeStamp,
    String? title,
    String? userId,
    String? userName,
    String? userStoreId,
    num? userType,
    String? userTypeText,
    String? postId,
    bool? liked,
    num? productCount,
    num? followStatus,
    String? profilePic,
    String? slugUrl,
    bool? isBusinessUser,
    bool? isSavedPost,
    num? distinctViews,
  }) =>
      PostDataModel(
        id: id ?? this.id,
        allowComment: allowComment ?? this.allowComment,
        allowDownload: allowDownload ?? this.allowDownload,
        allowDuet: allowDuet ?? this.allowDuet,
        categoryId: categoryId ?? this.categoryId,
        categoryName: categoryName ?? this.categoryName,
        categoryUrl: categoryUrl ?? this.categoryUrl,
        cloudinaryPublicId: cloudinaryPublicId ?? this.cloudinaryPublicId,
        commentCount: commentCount ?? this.commentCount,
        firstName: firstName ?? this.firstName,
        fullName: fullName ?? this.fullName,
        hashTags: hashTags ?? this.hashTags,
        imageUrl1: imageUrl1 ?? this.imageUrl1,
        imageUrl1Height: imageUrl1Height ?? this.imageUrl1Height,
        imageUrl1Width: imageUrl1Width ?? this.imageUrl1Width,
        isPrivate: isPrivate ?? this.isPrivate,
        isStar: isStar ?? this.isStar,
        lastName: lastName ?? this.lastName,
        likesCount: likesCount ?? this.likesCount,
        location: location ?? this.location,
        mediaType1: mediaType1 ?? this.mediaType1,
        mentionedUsers: mentionedUsers ?? this.mentionedUsers,
        musicData: musicData ?? this.musicData,
        musicId: musicId ?? this.musicId,
        place: place ?? this.place,
        placeId: placeId ?? this.placeId,
        postStatus: postStatus ?? this.postStatus,
        postViewsCount: postViewsCount ?? this.postViewsCount,
        productData: productData ?? this.productData,
        productIds: productIds ?? this.productIds,
        shareCount: shareCount ?? this.shareCount,
        thumbnailUrl1: thumbnailUrl1 ?? this.thumbnailUrl1,
        timeStamp: timeStamp ?? this.timeStamp,
        title: title ?? this.title,
        userId: userId ?? this.userId,
        userName: userName ?? this.userName,
        userStoreId: userStoreId ?? this.userStoreId,
        userType: userType ?? this.userType,
        userTypeText: userTypeText ?? this.userTypeText,
        postId: postId ?? this.postId,
        liked: liked ?? this.liked,
        productCount: productCount ?? this.productCount,
        followStatus: followStatus ?? this.followStatus,
        profilePic: profilePic ?? this.profilePic,
        slugUrl: slugUrl ?? this.slugUrl,
        isBusinessUser: isBusinessUser ?? this.isBusinessUser,
        isSavedPost: isSavedPost ?? this.isSavedPost,
        distinctViews: distinctViews ?? this.distinctViews,
      );
}

// class Location {
//   Location({
//     this.latitude,
//     this.longitude,
//   });
//
//   factory Location.fromJson(Map<String, dynamic> json) => Location(
//         latitude: json['latitude'] as num? ?? 0,
//         longitude: json['longitude'] as num? ?? 0,
//       );
//   num? latitude;
//   num? longitude;
//
//   Map<String, dynamic> toJson() => {
//         'latitude': latitude,
//         'longitude': longitude,
//       };
// }

class MentionedUser {
  MentionedUser({
    this.userId,
    this.userName,
  });

  factory MentionedUser.fromJson(Map<String, dynamic> json) => MentionedUser(
        userId: json['userId'] as String? ?? '',
        userName: json['userName'] as String? ?? '',
      );
  String? userId;
  String? userName;

  Map<String, dynamic> toJson() => {
        'userId': userId,
        'userName': userName,
      };
}

class MusicData {
  MusicData();

  factory MusicData.fromJson(Map<String, dynamic> json) => MusicData();

  Map<String, dynamic> toJson() => {};
}

class FeaturedProductDataItem {
  FeaturedProductDataItem({
    this.availableQuantity,
    this.avgRatings,
    this.bestOffer,
    this.brand,
    this.brandTitle,
    this.childProductId,
    this.currency,
    this.currencySymbol,
    this.imageUrl,
    this.finalPriceList,
    this.images,
    this.inStock,
    this.isAllVariantInStock,
    this.isproductCondition,
    this.parentProductId,
    this.productCondition,
    this.productConditionText,
    this.productName,
    this.resellerCommission,
    this.resellerCommissionType,
    this.resellerFixedCommission,
    this.resellerPercentageCommission,
    this.slug,
    this.status,
    this.statusText,
    this.storeId,
    this.totalReview,
    this.userStoreProduct,
    this.variantCount,
    this.brandId,
    this.moderationStatus,
    this.outOfStock,
    this.variants,
    this.avgRating,
  });

  factory FeaturedProductDataItem.fromJson(Map<String, dynamic> json) => FeaturedProductDataItem(
        availableQuantity: json['availableQuantity'] as num? ?? 0,
        avgRatings: json['avgRatings'] as num? ?? 0,
        bestOffer: json['bestOffer'] == null ? null : BestOffer.fromJson(json['bestOffer'] as Map<String, dynamic>),
        brand: json['brand'] as String? ?? '',
        brandTitle: json['brandTitle'] as String? ?? '',
        childProductId: json['childProductId'] as String? ?? '',
        currency: json['currency'] as String? ?? '',
        currencySymbol: json['currencySymbol'] as String? ?? '',
        imageUrl: json['imageUrl'] as String? ?? '',
        finalPriceList: json['finalPriceList'] == null
            ? null
            : FinalPriceList.fromJson(json['finalPriceList'] as Map<String, dynamic>),
        images: json['images'] == null
            ? []
            : List<ImageData>.from((json['images'] as List).map((x) => ImageData.fromJson(x as Map<String, dynamic>))),
        inStock: json['inStock'] as bool? ?? false,
        isAllVariantInStock: json['isAllVariantInStock'] as String? ?? '',
        isproductCondition: json['isproductCondition'] as num? ?? 0,
        parentProductId: json['parentProductId'] as String? ?? '',
        productCondition: json['productCondition'] as num? ?? 0,
        productConditionText: json['productConditionText'] as String? ?? '',
        productName: json['productName'] as String? ?? '',
        resellerCommission: json['resellerCommission'] as num? ?? 0,
        resellerCommissionType: json['resellerCommissionType'] as num? ?? 0,
        resellerFixedCommission: json['resellerFixedCommission'] as num? ?? 0,
        resellerPercentageCommission: json['resellerPercentageCommission'] as num? ?? 0,
        slug: json['slug'] as String? ?? '',
        status: json['status'] as num? ?? 0,
        statusText: json['statusText'] as String? ?? '',
        storeId: json['storeId'] as String? ?? '',
        totalReview: json['totalReview'] as num? ?? 0,
        userStoreProduct: json['userStoreProduct'] as bool? ?? false,
        variantCount: json['variantCount'] as num? ?? 0,
        brandId: json['brandId'] as String? ?? '',
        moderationStatus: json['moderationStatus'] as String? ?? '',
        outOfStock: json['outOfStock'] as bool? ?? false,
        variants: json['variants'] == null ? [] : List<dynamic>.from((json['variants'] as List).map((x) => x)),
        avgRating: json['avgRating'] as num? ?? 0,
      );
  num? availableQuantity;
  num? avgRatings;
  BestOffer? bestOffer;
  String? brand;
  String? brandTitle;
  String? childProductId;
  String? currency;
  String? currencySymbol;
  String? imageUrl;
  FinalPriceList? finalPriceList;
  List<ImageData>? images;
  bool? inStock;
  String? isAllVariantInStock;
  num? isproductCondition;
  String? parentProductId;
  num? productCondition;
  String? productConditionText;
  String? productName;
  num? resellerCommission;
  num? resellerCommissionType;
  num? resellerFixedCommission;
  num? resellerPercentageCommission;
  String? slug;
  num? status;
  String? statusText;
  String? storeId;
  num? totalReview;
  bool? userStoreProduct;
  num? variantCount;
  String? brandId;
  String? moderationStatus;
  bool? outOfStock;
  List<dynamic>? variants;
  num? avgRating;

  Map<String, dynamic> toJson() => {
        'availableQuantity': availableQuantity,
        'avgRatings': avgRatings,
        'bestOffer': bestOffer?.toJson(),
        'brand': brand,
        'brandTitle': brandTitle,
        'childProductId': childProductId,
        'currency': currency,
        'currencySymbol': currencySymbol,
        'imageUrl': imageUrl,
        'finalPriceList': finalPriceList?.toJson(),
        'images': images == null ? [] : List<dynamic>.from(images!.map((x) => x.toJson())),
        'inStock': inStock,
        'isAllVariantInStock': isAllVariantInStock,
        'isproductCondition': isproductCondition,
        'parentProductId': parentProductId,
        'productCondition': productCondition,
        'productConditionText': productConditionText,
        'productName': productName,
        'resellerCommission': resellerCommission,
        'resellerCommissionType': resellerCommissionType,
        'resellerFixedCommission': resellerFixedCommission,
        'resellerPercentageCommission': resellerPercentageCommission,
        'slug': slug,
        'status': status,
        'statusText': statusText,
        'storeId': storeId,
        'totalReview': totalReview,
        'userStoreProduct': userStoreProduct,
        'variantCount': variantCount,
        'brandId': brandId,
        'moderationStatus': moderationStatus,
        'outOfStock': outOfStock,
        'variants': variants == null ? [] : List<dynamic>.from(variants!.map((x) => x)),
        'avgRating': avgRating,
      };
}

class ImageItem {
  ImageItem({
    this.filePath,
    this.small,
  });

  factory ImageItem.fromJson(Map<String, dynamic> json) => ImageItem(
        filePath: json['filePath'] as String? ?? '',
        small: json['small'] as String? ?? '',
      );
  String? filePath;
  String? small;

  Map<String, dynamic> toJson() => {
        'filePath': filePath,
        'small': small,
      };
}

class TotalPosts {
  TotalPosts({
    this.value,
    this.relation,
  });

  factory TotalPosts.fromJson(Map<String, dynamic> json) => TotalPosts(
        value: json['value'] as num? ?? 0,
        relation: json['relation'] as String? ?? '',
      );
  num? value;
  String? relation;

  Map<String, dynamic> toJson() => {
        'value': value,
        'relation': relation,
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
        large: json['large'] as String? ?? '',
        medium: json['medium'] as String? ?? '',
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

class Location {
  Location({
    this.lat,
    this.long,
  });

  factory Location.fromJson(Map<String, dynamic> json) => Location(
        lat: json['lat'] as String? ?? '',
        long: json['long'] as String? ?? '',
      );
  String? lat;
  String? long;

  Map<String, dynamic> toJson() => {
        'lat': lat,
        'long': long,
      };
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
        offerName: json['offerName'] == null ? null : OfferName.fromJson(json['offerName'] as Map<String, dynamic>),
        images: json['images'] == null ? null : Images.fromJson(json['images'] as Map<String, dynamic>),
        webimages: json['webimages'] == null ? null : Images.fromJson(json['webimages'] as Map<String, dynamic>),
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
        'listComboProducts': listComboProducts == null ? [] : List<dynamic>.from(listComboProducts!.map((x) => x)),
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
  });

  factory FinalPriceList.fromJson(Map<String, dynamic> json) => FinalPriceList(
        basePrice: json['basePrice'] as num? ?? 0,
        finalPrice: json['finalPrice'] as num? ?? 0,
        discountPrice: json['discountPrice'] as num? ?? 0,
        sellerPrice: json['sellerPrice'] as num? ?? 0,
        discountPercentage: json['discountPercentage'] as num? ?? 0,
        discountType: json['discountType'] as num? ?? 0,
        taxRate: json['taxRate'] as num? ?? 0,
        discount: json['discount'] as num? ?? 0,
        discountValue: json['discountValue'] as num? ?? 0,
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

  Map<String, dynamic> toJson() => {
        'basePrice': basePrice,
        'finalPrice': finalPrice,
        'discountPrice': discountPrice,
        'sellerPrice': sellerPrice,
        'discountPercentage': discountPercentage,
        'discountType': discountType,
        'taxRate': taxRate,
        'discount': discount,
        'discountValue': discountValue,
      };
}
