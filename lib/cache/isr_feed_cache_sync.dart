import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:ism_video_reel_player/cache/isr_feed_cache_repository.dart';
import 'package:ism_video_reel_player/di/di.dart';
import 'package:ism_video_reel_player/presentation/presentation.dart';

/// Mirrors SDK social actions into [IsrFeedCacheRepository] and purges follow-sensitive feeds on unfollow.
class IsrFeedCacheSync {
  IsrFeedCacheSync._();

  static final IsrFeedCacheSync instance = IsrFeedCacheSync._();

  StreamSubscription<IsmSocialActionState>? _cubitSub;
  bool _attached = false;

  void attach() {
    if (_attached) return;
    _attached = true;
    final cubit = IsmSocialActionCubit.instance();
    _cubitSub = cubit.stream.listen(_onSocialAction, onError: (_) {});
  }

  void detach() {
    _cubitSub?.cancel();
    _cubitSub = null;
    _attached = false;
  }

  void _onSocialAction(IsmSocialActionState state) {
    if (!IsrFeedCacheRepository.instance.isEnabled) return;

    if (state is IsmDeletedPostActionListenerState) {
      final id = state.postId;
      if (id != null && id.isNotEmpty) {
        unawaited(IsrFeedCacheRepository.instance.removePostEverywhere(id));
      }
      return;
    }

    if (state is IsmUserChangedActionListenerState) {
      unawaited(
        IsrFeedCacheRepository.instance.reopenForOwner(state.userId),
      );
      return;
    }

    if (state is IsmFollowActionListenerState && !state.isFollowing) {
      final userId = state.userId;
      if (userId.isEmpty) return;
      unawaited(_purgeUnfollowedAuthor(userId));
    }
  }

  Future<void> _purgeUnfollowedAuthor(String userId) async {
    await IsrFeedCacheRepository.instance.removePostsByAuthor(userId);
    try {
      final bloc = IsmInjectionUtils.getBloc<SocialPostBloc>();
      bloc.add(PurgeAuthorFromFollowFeedsEvent(userId));
    } catch (e) {
      debugPrint('[IsrFeedCacheSync] purge author: $e');
    }
  }
}
