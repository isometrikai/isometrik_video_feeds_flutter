import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ism_video_reel_player/domain/domain.dart';
import 'package:ism_video_reel_player/isr_video_reel_config.dart';
import 'package:ism_video_reel_player/presentation/presentation.dart';
import 'package:ism_video_reel_player/presentation/screens/posts/follow_requests/follow_requests_theme_resolver.dart';
import 'package:ism_video_reel_player/res/res.dart';
import 'package:ism_video_reel_player/utils/utils.dart';

/// Lists follow requests (incoming / outgoing). Expects [FollowRequestsCubit] above this widget
/// (see [IsrAppNavigator.navigateToFollowRequests]).
class FollowRequestsView extends StatelessWidget {
  const FollowRequestsView({super.key});

  @override
  Widget build(BuildContext context) => DefaultTabController(
        length: 2,
        child: Scaffold(
          backgroundColor: FollowRequestsThemeResolver.scaffoldBackground,
          appBar: IsmCustomAppBarWidget(
            titleText: IsrTranslationFile.followRequests,
            backgroundColor: FollowRequestsThemeResolver.scaffoldBackground,
            iconColor: FollowRequestsThemeResolver.textPrimary,
            titleColor: FollowRequestsThemeResolver.textPrimary,
            statusBarIconBrightness:
                FollowRequestsThemeResolver.statusBarIconBrightness,
            statusBarBrightness:
                FollowRequestsThemeResolver.statusBarBrightness,
            showDivider: true,
            dividerColor: FollowRequestsThemeResolver.divider,
          ),
          body: Column(
            children: [
              Material(
                color: FollowRequestsThemeResolver.surface,
                child: TabBar(
                  labelColor: FollowRequestsThemeResolver.primary,
                  unselectedLabelColor:
                      FollowRequestsThemeResolver.textSecondary,
                  indicatorColor: FollowRequestsThemeResolver.primary,
                  tabs: [
                    Tab(text: IsrTranslationFile.incoming),
                    Tab(text: IsrTranslationFile.outgoing),
                  ],
                ),
              ),
              Expanded(
                child: BlocBuilder<FollowRequestsCubit, FollowRequestsState>(
                  builder: (context, state) => TabBarView(
                    children: [
                      _RequestList(
                        items: state.incoming,
                        loading: state.incomingLoading,
                        emptyMessage: IsrTranslationFile.noIncomingRequests,
                        onScrollEnd: () => context
                            .read<FollowRequestsCubit>()
                            .loadIncoming(refresh: false),
                        onRefresh: () async {
                          await context
                              .read<FollowRequestsCubit>()
                              .loadIncoming(refresh: true);
                        },
                        trailing: (item) => Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            AppButton(
                              title: IsrTranslationFile.decline,
                              type: ButtonType.primary,
                              width: 100.responsiveDimension,
                              height: 32.responsiveDimension,
                              onPress: () => context
                                  .read<FollowRequestsCubit>()
                                  .declineRequest(item),
                              textStyle: IsrStyles.primaryText12.copyWith(
                                color: FollowRequestsThemeResolver.onPrimary,
                              ),
                            ),
                            SizedBox(width: 8.responsiveDimension),
                            AppButton(
                              title: IsrTranslationFile.accept,
                              type: ButtonType.primary,
                              width: 100.responsiveDimension,
                              height: 32.responsiveDimension,
                              onPress: () => context
                                  .read<FollowRequestsCubit>()
                                  .acceptRequest(item),
                              textStyle: IsrStyles.primaryText12.copyWith(
                                color: FollowRequestsThemeResolver.onPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      _RequestList(
                        items: state.outgoing,
                        loading: state.outgoingLoading,
                        emptyMessage: IsrTranslationFile.noOutgoingRequests,
                        onScrollEnd: () => context
                            .read<FollowRequestsCubit>()
                            .loadOutgoing(refresh: false),
                        onRefresh: () async {
                          await context
                              .read<FollowRequestsCubit>()
                              .loadOutgoing(refresh: true);
                        },
                        trailing: (item) => AppButton(
                          title: IsrTranslationFile.cancelRequest,
                          type: ButtonType.primary,
                          width: 100.responsiveDimension,
                          height: 32.responsiveDimension,
                          onPress: () => context
                              .read<FollowRequestsCubit>()
                              .cancelOutgoingRequest(item),
                          textStyle: IsrStyles.primaryText12.copyWith(
                            color: FollowRequestsThemeResolver.onPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
}

class _RequestList extends StatelessWidget {
  const _RequestList({
    required this.items,
    required this.loading,
    required this.emptyMessage,
    required this.onScrollEnd,
    required this.onRefresh,
    required this.trailing,
  });

  final List<FollowRequestItem> items;
  final bool loading;
  final String emptyMessage;
  final VoidCallback onScrollEnd;
  final Future<void> Function() onRefresh;
  final Widget Function(FollowRequestItem) trailing;

  @override
  Widget build(BuildContext context) {
    if (loading && items.isEmpty) {
      return Center(child: Utility.loaderWidget(isAdaptive: false));
    }
    if (items.isEmpty) {
      return Center(
        child: Padding(
          padding:
              IsrDimens.edgeInsetsSymmetric(horizontal: IsrDimens.twentyFour),
          child: Text(
            emptyMessage,
            textAlign: TextAlign.center,
            style: IsrStyles.primaryText14.copyWith(
              color: FollowRequestsThemeResolver.textSecondary,
            ),
          ),
        ),
      );
    }

    return NotificationListener<ScrollNotification>(
      onNotification: (n) {
        final m = n.metrics;

        if (m.maxScrollExtent > 0 && m.pixels >= m.maxScrollExtent - 80) {
          onScrollEnd();
        }
        return false;
      },
      child: RefreshIndicator(
        color: FollowRequestsThemeResolver.primary,
        onRefresh: onRefresh,
        child: ListView.separated(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: IsrDimens.edgeInsetsSymmetric(vertical: IsrDimens.eight),
          itemCount: items.length,
          separatorBuilder: (_, __) => Divider(
            height: 1,
            color: FollowRequestsThemeResolver.divider,
            indent: 16.responsiveDimension + 48.responsiveDimension + 12,
          ),
          itemBuilder: (context, index) {
            final item = items[index];
            final u = item.user;

            return Padding(
              padding: IsrDimens.edgeInsetsSymmetric(
                horizontal: 16.responsiveDimension,
                vertical: 8.responsiveDimension,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: TapHandler(
                      onTap: () => _openUserProfileFromRequest(item.user),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Container(
                            width: 48.responsiveDimension,
                            height: 48.responsiveDimension,
                            decoration:
                                const BoxDecoration(shape: BoxShape.circle),
                            child: ClipOval(
                              child: AppImage.network(
                                u.avatarUrl.isEmptyOrNull ? '' : u.avatarUrl!,
                                height: 48.responsiveDimension,
                                width: 48.responsiveDimension,
                                fit: BoxFit.cover,
                                isProfileImage: true,
                                name: u.fullName ?? '',
                              ),
                            ),
                          ),
                          SizedBox(width: 4.responsiveDimension),
                          Expanded(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  u.username.isEmptyOrNull
                                      ? '@unKnownUser'
                                      : u.username!,
                                  style: IsrStyles.primaryText16Bold.copyWith(
                                    color:
                                        FollowRequestsThemeResolver.textPrimary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  u.fullName.isEmptyOrNull
                                      ? u.displayName.isEmptyOrNull
                                          ? 'unknown user'
                                          : u.displayName!
                                      : u.fullName!,
                                  style: IsrStyles.primaryText14.copyWith(
                                    color: FollowRequestsThemeResolver
                                        .textSecondary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  trailing(item),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

void _openUserProfileFromRequest(SocialUserData user) {
  final id = user.id;
  if (id == null || id.isEmpty) return;
  IsrVideoReelConfig.postConfig.postCallBackConfig?.onProfileClick?.call(
    null,
    id,
    user.isFollowing,
  );
}
