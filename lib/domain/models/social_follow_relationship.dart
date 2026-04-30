import 'package:ism_video_reel_player/domain/models/response/follow_requests_list_response.dart';

/// Central rules for follow vs request vs requested UI.
///
/// Uses [`is_following`], [`is_private`], numeric [`follow_status`], string
/// [`follow_relationship`] (e.g. `pending_out`), and optional [`is_requested`].
class FollowRelationshipUi {
  FollowRelationshipUi._();

  /// Parses `is_requested` / `isRequested` from JSON (bool or 0/1).
  static bool? parseRequested(dynamic value) {
    if (value == null) return null;
    if (value is bool) return value;
    if (value is num) return value != 0;
    return null;
  }

  /// User has a pending outgoing follow request (show **Requested**, cancel flow).
  static bool isRelationshipRequested({
    bool? isRequested,
    num? followStatus,
  }) {
    if (isRequested == true) return true;
    return followStatus?.toInt() == FollowRelationshipStatus.requested;
  }

  /// Primary action shows **Request** (vs **Follow**): not following, private account,
  /// and no pending request yet.
  static bool showRequestPrimaryLabel({
    required bool isFollowing,
    required bool isPrivateAccount,
    bool? isRequested,
    num? followStatus,
  }) {
    if (isFollowing) return false;
    if (isRelationshipRequested(
      isRequested: isRequested,
      followStatus: followStatus,
    )) {
      return false;
    }
    return isPrivateAccount;
  }

  /// Result state after POST `/follows` succeeds (until profile/post refresh).
  static bool followingFromFollowResponse({
    bool? isRequested,
    num? followStatus,
  }) {
    if (isRelationshipRequested(
      isRequested: isRequested,
      followStatus: followStatus,
    )) {
      return false;
    }
    final fs = followStatus?.toInt();
    if (fs == FollowRelationshipStatus.following) return true;
    return true;
  }

  static bool pendingFromFollowResponse({
    bool? isRequested,
    num? followStatus,
  }) =>
      isRelationshipRequested(
        isRequested: isRequested,
        followStatus: followStatus,
      );
}
