// To parse this JSON data, do
//
//     final createPostResponse = createPostResponseFromJson(jsonString);

import 'dart:convert';

import 'package:ism_video_reel_player/domain/domain.dart';

CreatePostResponse createPostResponseFromJson(String str) =>
    CreatePostResponse.fromJson(json.decode(str) as Map<String, dynamic>);

String createPostResponseToJson(CreatePostResponse data) => json.encode(data.toJson());

class CreatePostResponse {
  factory CreatePostResponse.fromJson(Map<String, dynamic> json) => CreatePostResponse(
        message: json['message'] as String? ?? '',
        data: json['data'] == null ? null : OldData.fromJson(json['data'] as Map<String, dynamic>),
        newData: json['newData'] == null ? null : NewData.fromJson(json['newData'] as Map<String, dynamic>),
      );

  CreatePostResponse({
    this.message,
    this.data,
    this.newData,
  });
  String? message;
  OldData? data;
  NewData? newData;

  Map<String, dynamic> toJson() => {
        'message': message,
        'data': data?.toJson(),
        'newData': newData?.toJson(),
      };
}

class OldData {
  OldData({
    this.result,
    this.ops,
    this.insertedCount,
    this.insertedIds,
  });

  factory OldData.fromJson(Map<String, dynamic> json) => OldData(
        result: json['result'] == null ? null : ResultItem.fromJson(json['result'] as Map<String, dynamic>),
        ops: json['ops'] == null
            ? []
            : List<Op>.from((json['ops'] as List).map((x) => Op.fromJson(x as Map<String, dynamic>))),
        insertedCount: json['insertedCount'] as num? ?? 0,
        insertedIds:
            json['insertedIds'] == null ? null : InsertedIds.fromJson(json['insertedIds'] as Map<String, dynamic>),
      );
  ResultItem? result;
  List<Op>? ops;
  num? insertedCount;
  InsertedIds? insertedIds;

  Map<String, dynamic> toJson() => {
        'result': result?.toJson(),
        'ops': ops == null ? [] : List<dynamic>.from(ops!.map((x) => x.toJson())),
        'insertedCount': insertedCount,
        'insertedIds': insertedIds?.toJson(),
      };
}

class InsertedIds {
  InsertedIds({
    this.the0,
  });

  factory InsertedIds.fromJson(Map<String, dynamic> json) => InsertedIds(
        the0: json['0'] as String? ?? '',
      );
  String? the0;

  Map<String, dynamic> toJson() => {
        '0': the0,
      };
}

class Op {
  Op({
    this.title,
    this.imageUrl1,
    this.thumbnailUrl1,
    this.mediaType1,
    this.userId,
    this.createdOn,
    this.timeStamp,
    this.distinctViews,
    this.totalViews,
    this.comments,
    this.imageUrl1Width,
    this.imageUrl1Height,
    this.likesCount,
    this.mentionedUsers,
    this.postStatus,
    this.postStatusText,
    this.shareCount,
    this.commentCount,
    this.userName,
    this.userStoreId,
    this.storeData,
    this.userType,
    this.userTypeText,
    this.firstName,
    this.lastName,
    this.fullName,
    this.fullNameWithSpace,
    this.profilepic,
    this.profileCoverImage,
    this.channelId,
    this.channelImageUrl,
    this.channelName,
    this.channelStatus,
    this.categoryId,
    this.categoryName,
    this.categoryUrl,
    this.musicId,
    this.musicData,
    this.location,
    this.place,
    this.countrySname,
    this.city,
    this.placeId,
    this.likes,
    this.orientation,
    this.isStar,
    this.knownByName,
    this.trendingScore,
    this.allowDownload,
    this.allowComment,
    this.allowDuet,
    this.productIds,
    this.productData,
    this.cityForPost,
    this.countryForPost,
    this.locationForPost,
    this.isPrivate,
    this.shoutOutFor,
    this.buyerId,
    this.sellerId,
    this.orderId,
    this.isShoutoutPost,
    this.visibleOnSellerProfile,
    this.scheduleTime,
    this.id,
    this.orderDetails,
  });

  factory Op.fromJson(Map<String, dynamic> json) => Op(
        title: json['title'] as String? ?? '',
        imageUrl1: json['imageUrl1'] as String? ?? '',
        thumbnailUrl1: json['thumbnailUrl1'] as String? ?? '',
        mediaType1: json['mediaType1'] as num? ?? 0,
        userId: json['userId'] as String? ?? '',
        createdOn: json['createdOn'] == null ? null : json['createdOn'] as String? ?? '',
        timeStamp: json['timeStamp'] as num? ?? 0,
        distinctViews: json['distinctViews'] as dynamic,
        totalViews: json['totalViews'] as dynamic,
        comments: json['comments'] as dynamic,
        imageUrl1Width: json['imageUrl1Width'],
        imageUrl1Height: json['imageUrl1Height'],
        likesCount: json['likesCount'] as num? ?? 0,
        mentionedUsers:
            json['mentionedUsers'] == null ? [] : List<dynamic>.from((json['mentionedUsers'] as List).map((x) => x)),
        postStatus: json['postStatus'] as num? ?? 0,
        postStatusText: json['postStatusText'] as String? ?? '',
        shareCount: json['shareCount'] as num? ?? 0,
        commentCount: json['commentCount'] as num? ?? 0,
        userName: json['userName'] as String? ?? '',
        userStoreId: json['userStoreId'] as String? ?? '',
        storeData: json['storeData'] == null ? null : StoreData.fromJson(json['storeData'] as Map<String, dynamic>),
        userType: json['userType'] as num? ?? 0,
        userTypeText: json['userTypeText'] as String? ?? '',
        firstName: json['firstName'] as String? ?? '',
        lastName: json['lastName'] as String? ?? '',
        fullName: json['fullName'] as String? ?? '',
        fullNameWithSpace: json['fullNameWithSpace'] as String? ?? '',
        profilepic: json['profilepic'] as String? ?? '',
        profileCoverImage: json['profileCoverImage'] as String? ?? '',
        channelId: json['channelId'] as String? ?? '',
        channelImageUrl: json['channelImageUrl'] as String? ?? '',
        channelName: json['channelName'] as String? ?? '',
        channelStatus: json['channelStatus'] as String? ?? '',
        categoryId: json['categoryId'] as String? ?? '',
        categoryName: json['categoryName'] as String? ?? '',
        categoryUrl: json['categoryUrl'] as String? ?? '',
        musicId: json['musicId'] as String? ?? '',
        musicData: json['musicData'] == null ? null : MusicData.fromJson(json['musicData'] as Map<String, dynamic>),
        location: json['location'] == null ? null : LocationItem.fromJson(json['location'] as Map<String, dynamic>),
        place: json['place'] as String? ?? '',
        countrySname: json['countrySname'] as String? ?? '',
        city: json['city'] as String? ?? '',
        placeId: json['placeId'] as String? ?? '',
        likes: json['likes'] == null ? [] : List<dynamic>.from((json['likes'] as List).map((x) => x)),
        orientation: json['orientation'] as num? ?? 0,
        isStar: json['isStar'] as bool? ?? false,
        knownByName: json['knownByName'] as String? ?? '',
        trendingScore: json['trending_score'] as num? ?? 0,
        allowDownload: json['allowDownload'] as bool? ?? false,
        allowComment: json['allowComment'] as bool? ?? false,
        allowDuet: json['allowDuet'] as bool? ?? false,
        productIds: json['productIds'] == null ? [] : List<dynamic>.from((json['productIds'] as List).map((x) => x)),
        productData: json['productData'] == null ? [] : List<dynamic>.from((json['productData'] as List).map((x) => x)),
        cityForPost: json['cityForPost'] as String? ?? '',
        countryForPost: json['countryForPost'] as String? ?? '',
        locationForPost: json['locationForPost'] == null
            ? null
            : LocationForPost.fromJson(json['locationForPost'] as Map<String, dynamic>),
        isPrivate: json['isPrivate'] as num? ?? 0,
        shoutOutFor: json['shoutOutFor'] as String? ?? '',
        buyerId: json['buyerId'] as String? ?? '',
        sellerId: json['sellerId'] as String? ?? '',
        orderId: json['orderId'] as String? ?? '',
        isShoutoutPost: json['isShoutoutPost'] as bool? ?? false,
        visibleOnSellerProfile: json['visibleOnSellerProfile'] as bool? ?? false,
        scheduleTime: json['scheduleTime'] as num? ?? 0,
        id: json['_id'] as String? ?? '',
        orderDetails:
            json['orderDetails'] == null ? null : MusicData.fromJson(json['orderDetails'] as Map<String, dynamic>),
      );
  String? title;
  String? imageUrl1;
  String? thumbnailUrl1;
  num? mediaType1;
  String? userId;
  String? createdOn;
  num? timeStamp;
  dynamic distinctViews;
  dynamic totalViews;
  dynamic comments;
  dynamic imageUrl1Width;
  dynamic imageUrl1Height;
  num? likesCount;
  List<dynamic>? mentionedUsers;
  num? postStatus;
  String? postStatusText;
  num? shareCount;
  num? commentCount;
  String? userName;
  String? userStoreId;
  StoreData? storeData;
  num? userType;
  String? userTypeText;
  String? firstName;
  String? lastName;
  String? fullName;
  String? fullNameWithSpace;
  String? profilepic;
  String? profileCoverImage;
  String? channelId;
  String? channelImageUrl;
  String? channelName;
  String? channelStatus;
  String? categoryId;
  String? categoryName;
  String? categoryUrl;
  String? musicId;
  MusicData? musicData;
  LocationItem? location;
  String? place;
  String? countrySname;
  String? city;
  String? placeId;
  List<dynamic>? likes;
  num? orientation;
  bool? isStar;
  String? knownByName;
  num? trendingScore;
  bool? allowDownload;
  bool? allowComment;
  bool? allowDuet;
  List<dynamic>? productIds;
  List<dynamic>? productData;
  String? cityForPost;
  String? countryForPost;
  LocationForPost? locationForPost;
  num? isPrivate;
  String? shoutOutFor;
  String? buyerId;
  String? sellerId;
  String? orderId;
  bool? isShoutoutPost;
  bool? visibleOnSellerProfile;
  num? scheduleTime;
  String? id;
  MusicData? orderDetails;

  Map<String, dynamic> toJson() => {
        'title': title,
        'imageUrl1': imageUrl1,
        'thumbnailUrl1': thumbnailUrl1,
        'mediaType1': mediaType1,
        'userId': userId,
        'createdOn': createdOn,
        'timeStamp': timeStamp,
        'distinctViews': distinctViews,
        'totalViews': totalViews,
        'comments': comments,
        'imageUrl1Width': imageUrl1Width,
        'imageUrl1Height': imageUrl1Height,
        'likesCount': likesCount,
        'mentionedUsers': mentionedUsers == null ? [] : List<dynamic>.from(mentionedUsers!.map((x) => x)),
        'postStatus': postStatus,
        'postStatusText': postStatusText,
        'shareCount': shareCount,
        'commentCount': commentCount,
        'userName': userName,
        'userStoreId': userStoreId,
        'storeData': storeData?.toJson(),
        'userType': userType,
        'userTypeText': userTypeText,
        'firstName': firstName,
        'lastName': lastName,
        'fullName': fullName,
        'fullNameWithSpace': fullNameWithSpace,
        'profilepic': profilepic,
        'profileCoverImage': profileCoverImage,
        'channelId': channelId,
        'channelImageUrl': channelImageUrl,
        'channelName': channelName,
        'channelStatus': channelStatus,
        'categoryId': categoryId,
        'categoryName': categoryName,
        'categoryUrl': categoryUrl,
        'musicId': musicId,
        'musicData': musicData?.toJson(),
        'location': location?.toJson(),
        'place': place,
        'countrySname': countrySname,
        'city': city,
        'placeId': placeId,
        'likes': likes == null ? [] : List<dynamic>.from(likes!.map((x) => x)),
        'orientation': orientation,
        'isStar': isStar,
        'knownByName': knownByName,
        'trending_score': trendingScore,
        'allowDownload': allowDownload,
        'allowComment': allowComment,
        'allowDuet': allowDuet,
        'productIds': productIds == null ? [] : List<dynamic>.from(productIds!.map((x) => x)),
        'productData': productData == null ? [] : List<dynamic>.from(productData!.map((x) => x)),
        'cityForPost': cityForPost,
        'countryForPost': countryForPost,
        'locationForPost': locationForPost?.toJson(),
        'isPrivate': isPrivate,
        'shoutOutFor': shoutOutFor,
        'buyerId': buyerId,
        'sellerId': sellerId,
        'orderId': orderId,
        'isShoutoutPost': isShoutoutPost,
        'visibleOnSellerProfile': visibleOnSellerProfile,
        'scheduleTime': scheduleTime,
        '_id': id,
        'orderDetails': orderDetails?.toJson(),
      };
}

class LocationItem {
  LocationItem({
    this.longitude,
    this.latitude,
  });

  factory LocationItem.fromJson(Map<String, dynamic> json) => LocationItem(
        longitude: json['longitude'] as num? ?? 0,
        latitude: json['latitude'] as num? ?? 0,
      );
  num? longitude;
  num? latitude;

  Map<String, dynamic> toJson() => {
        'longitude': longitude,
        'latitude': latitude,
      };
}

class LocationForPost {
  LocationForPost({
    this.lat,
    this.lon,
  });

  factory LocationForPost.fromJson(Map<String, dynamic> json) => LocationForPost(
        lat: json['lat'] as num? ?? 0,
        lon: json['lon'] as num? ?? 0,
      );
  num? lat;
  num? lon;

  Map<String, dynamic> toJson() => {
        'lat': lat,
        'lon': lon,
      };
}

class StoreData {
  StoreData({
    this.name,
    this.slug,
  });

  factory StoreData.fromJson(Map<String, dynamic> json) => StoreData(
        name: json['name'] as String? ?? '',
        slug: json['slug'] as String? ?? '',
      );
  String? name;
  String? slug;

  Map<String, dynamic> toJson() => {
        'name': name,
        'slug': slug,
      };
}

class ResultItem {
  ResultItem({
    this.ok,
    this.n,
    this.opTime,
  });

  factory ResultItem.fromJson(Map<String, dynamic> json) => ResultItem(
        ok: json['ok'] as num? ?? 0,
        n: json['n'] as num? ?? 0,
        opTime: json['opTime'] == null ? null : OpTime.fromJson(json['opTime'] as Map<String, dynamic>),
      );
  num? ok;
  num? n;
  OpTime? opTime;

  Map<String, dynamic> toJson() => {
        'ok': ok,
        'n': n,
        'opTime': opTime?.toJson(),
      };
}

class OpTime {
  OpTime({
    this.ts,
    this.t,
  });

  factory OpTime.fromJson(Map<String, dynamic> json) => OpTime(
        ts: json['ts'] as String? ?? '',
        t: json['t'] as num? ?? 0,
      );
  String? ts;
  num? t;

  Map<String, dynamic> toJson() => {
        'ts': ts,
        't': t,
      };
}

class NewData {
  NewData({
    this.isPrivate,
    this.id,
    this.title,
    this.imageUrl1,
    this.thumbnailUrl1,
    this.mediaType1,
    this.userId,
    this.createdOn,
    this.timeStamp,
    this.distinctViews,
    this.totalViews,
    this.comments,
    this.imageUrl1Width,
    this.imageUrl1Height,
    this.likesCount,
    this.mentionedUsers,
    this.postStatus,
    this.shareCount,
    this.commentCount,
    this.userName,
    this.firstName,
    this.lastName,
    this.fullName,
    this.fullNameWithSpace,
    this.profilepic,
    this.profileCoverImage,
    this.channelId,
    this.channelImageUrl,
    this.channelName,
    this.channelStatus,
    this.categoryId,
    this.categoryName,
    this.categoryUrl,
    this.musicId,
    this.location,
    this.place,
    this.countrySname,
    this.city,
    this.placeId,
    this.orientation,
    this.totalViewCount,
    this.distinctViewsCount,
    this.allowDownload,
    this.allowDuet,
    this.postStatusText,
    this.isBookMarked,
    this.followStatus,
    this.liked,
    this.postId,
  });

  factory NewData.fromJson(Map<String, dynamic> json) => NewData(
        isPrivate: json['isPrivate'] as num? ?? 0,
        id: json['_id'] as String? ?? '',
        title: json['title'] as String? ?? '',
        imageUrl1: json['imageUrl1'] as String? ?? '',
        thumbnailUrl1: json['thumbnailUrl1'] as String? ?? '',
        mediaType1: json['mediaType1'] as num? ?? 0,
        userId: json['userId'] as String? ?? '',
        createdOn: json['createdOn'] == null ? null : json['createdOn'] as String? ?? '',
        timeStamp: json['timeStamp'] as num? ?? 0,
        distinctViews: json['distinctViews'] as num? ?? 0,
        totalViews: json['totalViews'] == null ? [] : List<dynamic>.from((json['totalViews'] as List).map((x) => x)),
        comments: json['comments'] == null ? [] : List<dynamic>.from((json['comments'] as List).map((x) => x)),
        imageUrl1Width: json['imageUrl1Width'],
        imageUrl1Height: json['imageUrl1Height'],
        likesCount: json['likesCount'] as num? ?? 0,
        mentionedUsers:
            json['mentionedUsers'] == null ? [] : List<dynamic>.from((json['mentionedUsers'] as List).map((x) => x)),
        postStatus: json['postStatus'] as num? ?? 0,
        shareCount: json['shareCount'] as num? ?? 0,
        commentCount: json['commentCount'] as num? ?? 0,
        userName: json['userName'] as String? ?? '',
        firstName: json['firstName'] as String? ?? '',
        lastName: json['lastName'] as String? ?? '',
        fullName: json['fullName'] as String? ?? '',
        fullNameWithSpace: json['fullNameWithSpace'] as String? ?? '',
        profilepic: json['profilepic'] as String? ?? '',
        profileCoverImage: json['profileCoverImage'] as String? ?? '',
        channelId: json['channelId'] as String? ?? '',
        channelImageUrl: json['channelImageUrl'] as String? ?? '',
        channelName: json['channelName'] as String? ?? '',
        channelStatus: json['channelStatus'] as String? ?? '',
        categoryId: json['categoryId'] as String? ?? '',
        categoryName: json['categoryName'] as String? ?? '',
        categoryUrl: json['categoryUrl'] as String? ?? '',
        musicId: json['musicId'] as String? ?? '',
        location: json['location'] == null ? null : LocationItem.fromJson(json['location'] as Map<String, dynamic>),
        place: json['place'] as String? ?? '',
        countrySname: json['countrySname'] as String? ?? '',
        city: json['city'] as String? ?? '',
        placeId: json['placeId'] as String? ?? '',
        orientation: json['orientation'] as num? ?? 0,
        totalViewCount: json['totalViewCount'] as num? ?? 0,
        distinctViewsCount: json['distinctViewsCount'] as num? ?? 0,
        allowDownload: json['allowDownload'] as bool? ?? false,
        allowDuet: json['allowDuet'] as bool? ?? false,
        postStatusText: json['postStatusText'] as String? ?? '',
        isBookMarked: json['isBookMarked'] as bool? ?? false,
        followStatus: json['followStatus'] as num? ?? 0,
        liked: json['liked'] as bool? ?? false,
        postId: json['postId'] as String? ?? '',
      );
  num? isPrivate;
  String? id;
  String? title;
  String? imageUrl1;
  String? thumbnailUrl1;
  num? mediaType1;
  String? userId;
  String? createdOn;
  num? timeStamp;
  num? distinctViews;
  List<dynamic>? totalViews;
  List<dynamic>? comments;
  dynamic imageUrl1Width;
  dynamic imageUrl1Height;
  num? likesCount;
  List<dynamic>? mentionedUsers;
  num? postStatus;
  num? shareCount;
  num? commentCount;
  String? userName;
  String? firstName;
  String? lastName;
  String? fullName;
  String? fullNameWithSpace;
  String? profilepic;
  String? profileCoverImage;
  String? channelId;
  String? channelImageUrl;
  String? channelName;
  String? channelStatus;
  String? categoryId;
  String? categoryName;
  String? categoryUrl;
  String? musicId;
  LocationItem? location;
  String? place;
  String? countrySname;
  String? city;
  String? placeId;
  num? orientation;
  num? totalViewCount;
  num? distinctViewsCount;
  bool? allowDownload;
  bool? allowDuet;
  String? postStatusText;
  bool? isBookMarked;
  num? followStatus;
  bool? liked;
  String? postId;

  Map<String, dynamic> toJson() => {
        'isPrivate': isPrivate,
        '_id': id,
        'title': title,
        'imageUrl1': imageUrl1,
        'thumbnailUrl1': thumbnailUrl1,
        'mediaType1': mediaType1,
        'userId': userId,
        'createdOn': createdOn,
        'timeStamp': timeStamp,
        'distinctViews': distinctViews,
        'totalViews': totalViews == null ? [] : List<dynamic>.from(totalViews!.map((x) => x)),
        'comments': comments == null ? [] : List<dynamic>.from(comments!.map((x) => x)),
        'imageUrl1Width': imageUrl1Width,
        'imageUrl1Height': imageUrl1Height,
        'likesCount': likesCount,
        'mentionedUsers': mentionedUsers == null ? [] : List<dynamic>.from(mentionedUsers!.map((x) => x)),
        'postStatus': postStatus,
        'shareCount': shareCount,
        'commentCount': commentCount,
        'userName': userName,
        'firstName': firstName,
        'lastName': lastName,
        'fullName': fullName,
        'fullNameWithSpace': fullNameWithSpace,
        'profilepic': profilepic,
        'profileCoverImage': profileCoverImage,
        'channelId': channelId,
        'channelImageUrl': channelImageUrl,
        'channelName': channelName,
        'channelStatus': channelStatus,
        'categoryId': categoryId,
        'categoryName': categoryName,
        'categoryUrl': categoryUrl,
        'musicId': musicId,
        'location': location?.toJson(),
        'place': place,
        'countrySname': countrySname,
        'city': city,
        'placeId': placeId,
        'orientation': orientation,
        'totalViewCount': totalViewCount,
        'distinctViewsCount': distinctViewsCount,
        'allowDownload': allowDownload,
        'allowDuet': allowDuet,
        'postStatusText': postStatusText,
        'isBookMarked': isBookMarked,
        'followStatus': followStatus,
        'liked': liked,
        'postId': postId,
      };
}
