import 'package:flutter/material.dart';
import 'package:ism_video_reel_player/ism_video_reel_player.dart';

// class TabDataModel {
//   TabDataModel({
//     required this.title,
//     this.postList = const [],
//     this.timeLinePosts = const [],
//     this.onCreatePost,
//     this.onTapMore,
//     this.showBlur,
//     this.productList,
//     this.onPressSave,
//     this.onPressLike,
//     this.onPressFollow,
//     this.onLoadMore,
//     this.onRefresh,
//     this.onTapCartIcon,
//     this.placeHolderWidget,
//     this.postSectionType = PostSectionType.following,
//     this.onTapComment,
//     this.onTapShare,
//     this.isCreatePostButtonVisible,
//     this.startingPostIndex = 0,
//     this.onTapUserProfile,
//   });
//
//   final String title;
//   final List<PostDataModel>? postList;
//   final List<TimeLineData>? timeLinePosts;
//   final Future<String?> Function()? onCreatePost;
//   final Future<List<TimeLineData>> Function(PostSectionType?)? onLoadMore;
//   final Future<dynamic> Function(TimeLineData, String userId)? onTapMore;
//   final bool? showBlur;
//   final List<FeaturedProductDataItem>? productList;
//   final Future<bool> Function(String postId, bool isSavedPost)? onPressSave;
//   final Future<bool> Function(String, String, bool)? onPressLike;
//   final Future<bool> Function(String)? onPressFollow;
//   final Future<bool> Function()? onRefresh;
//   final Future<List<SocialProductData>>? Function(String, String)? onTapCartIcon;
//   final Widget? placeHolderWidget;
//   final PostSectionType? postSectionType;
//   final Future<num>? Function(String, int)? onTapComment;
//   final Function(String)? onTapShare;
//   final Function(String)? onTapUserProfile;
//   final bool? isCreatePostButtonVisible;
//   final int? startingPostIndex;
// }

class TabDataModel {
  TabDataModel({
    required this.title,
    required this.reelsDataList,
  });

  final String title;
  final List<ReelsData> reelsDataList;

// final tabs = [
//   TabDataModel(
//     title: 'Following',
//     postList: followingPosts,
//     footerBuilder: (context, post) => Row(
//       mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//       children: [
//         IconButton(
//           icon: Icon(Icons.favorite_border),
//           onPressed: () => print("Liked ${post.id}"),
//         ),
//         IconButton(
//           icon: Icon(Icons.comment),
//           onPressed: () => print("Commented on ${post.id}"),
//         ),
//         IconButton(
//           icon: Icon(Icons.share),
//           onPressed: () => print("Shared ${post.id}"),
//         ),
//       ],
//     ),
//   ),
//   TabDataModel(
//     title: 'Trending',
//     postList: trendingPosts,
//     footerBuilder: (context, post) => Column(
//       children: [
//         Text(post.title, style: TextStyle(fontWeight: FontWeight.bold)),
//         SizedBox(height: 4),
//         Row(
//           children: [
//             ElevatedButton(
//               onPressed: () => print("Buy ${post.id}"),
//               child: Text("Buy"),
//             ),
//             SizedBox(width: 8),
//             OutlinedButton(
//               onPressed: () => print("Wishlist ${post.id}"),
//               child: Text("Wishlist"),
//             ),
//           ],
//         ),
//       ],
//     ),
//   ),
// ];
}

class ReelsData {
  ReelsData({
    required this.mediaUrl,
    required this.thumbnailUrl,
    required this.mediaType,
    this.profilePhoto,
    this.userName,
    this.firstName,
    this.lastName,
    this.hasTags,
    this.isVerifiedUser,
    this.isSelfProfile,
    this.isFollow,
    this.isLiked,
    this.likesCount,
    this.onPressSave,
    this.onPressLike,
    this.onPressFollow,
    this.onRefresh,
    this.onTapCartIcon,
    this.placeHolderWidget,
    this.onTapComment,
    this.onTapShare,
    this.onTapUserProfile,
    this.onPressFollowFollowing,
    this.footerWidget,
    this.actionWidget,
    this.description,
    this.onTapReport,
    this.showBlur,
    this.productCount,
    this.onPressMoreButton,
    this.commentCount,
    this.postStatus,
    this.isCreatePostButtonVisible,
    this.isScheduledPost,
    this.isSavedPost,
  });

  final String mediaUrl;
  final String thumbnailUrl;
  final int mediaType;
  final String? userName;
  final String? firstName;
  final String? lastName;
  final String? profilePhoto;
  final bool? isVerifiedUser;
  final bool? isSelfProfile;
  final String? description;
  final bool? isFollow;
  bool? isLiked;
  int? likesCount;
  final List<String>? hasTags;
  final ReelsWidgetBuilder? footerWidget;
  final ReelsWidgetBuilder? actionWidget;

  final Future<bool> Function(String postId, bool isSavedPost)? onPressSave;
  final Future<bool> Function(String, String, bool)? onPressLike;
  final Future<bool> Function(String)? onPressFollow;
  final Future<bool> Function()? onRefresh;
  // final Future<num>? Function(String, String)? onTapCartIcon;
  final VoidCallback? onTapCartIcon;
  final Future<bool> Function()? onPressFollowFollowing;
  final VoidCallback? onPressMoreButton;
  final Widget? placeHolderWidget;
  final VoidCallback? onTapComment;
  final VoidCallback? onTapShare;
  final Function()? onTapUserProfile;
  final Function()? onTapReport;
  final bool? showBlur;
  final int? productCount;
  final int? commentCount;
  final int? postStatus;
  final bool? isCreatePostButtonVisible;
  final bool? isScheduledPost;
  final bool? isSavedPost;
}
