import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:ism_video_reel_player/di/di.dart';
import 'package:ism_video_reel_player/domain/domain.dart';
import 'package:ism_video_reel_player/presentation/presentation.dart';
import 'package:ism_video_reel_player/res/res.dart';
import 'package:ism_video_reel_player/utils/utils.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';

class SocialPostInsightView extends StatefulWidget {
  const SocialPostInsightView({
    super.key,
    this.postData,
    this.postId,
  });

  final TimeLineData? postData;
  final String? postId;

  @override
  State<StatefulWidget> createState() => _SocialPostInsightViewState();
}

class _SocialPostInsightViewState extends State<SocialPostInsightView> {
  late final TimeLineData? _postData;
  late final String? _postId;
  final _socialPostBloc = IsmInjectionUtils.getBloc<SocialPostBloc>();

  @override
  void initState() {
    _postData = widget.postData;
    _postId = widget.postId;
    log('post insight data: ${_postData?.toMap()}');
    _socialPostBloc.add(GetPostInsightDetailsEvent(postId: _postId, data: _postData));
    super.initState();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: IsrColors.white,
        appBar: IsmCustomAppBarWidget(
          titleText: IsrTranslationFile.postInsight,
          titleStyle: IsrStyles.primaryText18.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        body: BlocConsumer<SocialPostBloc, SocialPostState>(
          bloc: _socialPostBloc,
          buildWhen: (previousState, currentState) =>
              (currentState is PostInsightDetails && currentState.postId == _postId) ||
              (currentState is PostInsightDetailsLoading && currentState.postId == _postId),
          listenWhen: (previousState, currentState) =>
              (currentState is PostInsightDetails && currentState.postId == _postId) ||
              (currentState is PostInsightDetailsLoading && currentState.postId == _postId),
          listener: (context, state) {
            _postData = (state is PostInsightDetails) ? state.postData : _postData;
            log('post insight data: ${_postData?.toMap()}');
          },
          builder: (context, state) => SafeArea(
            child: Stack(
              children: [
                RefreshIndicator.adaptive(
                  child: _buildBody(),
                  onRefresh: () async {
                    _socialPostBloc
                        .add(GetPostInsightDetailsEvent(postId: _postId, data: _postData));
                  },
                ),
                if (state is PostInsightDetailsLoading)
                  Center(
                    child: Utility.loaderWidget(),
                  ),
              ],
            ),
          ),
        ),
      );

  Widget _buildBody() => SingleChildScrollView(
        padding: IsrDimens.edgeInsetsAll(IsrDimens.sixteen),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildPostPreview(),
            IsrDimens.boxHeight(IsrDimens.twentyFour),
            _buildOverviewSection(),
            IsrDimens.boxHeight(IsrDimens.twentyFour),
            _buildCircularGraphSection(
              title: IsrTranslationFile.views,
              mainLabel: IsrTranslationFile.views,
              mainValue: _postData?.engagementMetrics?.views?.toDouble() ?? 0,
              selectedLabel: IsrTranslationFile.followers,
              selectedValue: 0,
              // needed from API
              unselectedLabel: IsrTranslationFile.nonFollowers,
            ),
            IsrDimens.boxHeight(IsrDimens.twentyFour),
            _buildCircularGraphSection(
              title: IsrTranslationFile.interactions,
              mainLabel: IsrTranslationFile.interactions,
              mainValue: _calculateTotalInteractions(),
              selectedLabel: IsrTranslationFile.followers,
              selectedValue: 0,
              // needed from API
              unselectedLabel: IsrTranslationFile.nonFollowers,
            ),
            IsrDimens.boxHeight(IsrDimens.twentyFour),
            _buildStatisticsSection(),
            IsrDimens.boxHeight(IsrDimens.twentyFour),
            _buildProfileActivitySection(),
          ],
        ),
      );

  Widget _buildPostPreview() {
    final imageUrl = _postData?.media?.first.mediaType?.mediaType == MediaType.video
        ? _postData?.media?.first.previewUrl
        : _postData?.media?.first.url;

    return Column(
      children: [
        Container(
          width: 116.responsiveDimension,
          height: 169.responsiveDimension,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12.responsiveDimension),
            color: IsrColors.colorF5F5F5,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12.responsiveDimension),
            child: imageUrl != null && imageUrl.isNotEmpty
                ? AppImage.network(
                    imageUrl,
                    fit: BoxFit.cover,
                    width: 116.responsiveDimension,
                    height: 169.responsiveDimension,
                  )
                : Icon(
                    Icons.image,
                    color: IsrColors.color9B9B9B,
                    size: IsrDimens.forty,
                  ),
          ),
        ),
        IsrDimens.boxHeight(IsrDimens.twelve),
        _buildPostTimestamp(),
        IsrDimens.boxHeight(IsrDimens.twelve),
        _buildInteractionIcons(),
      ],
    );
  }

  Widget _buildPostTimestamp() {
    var formattedDate = '';
    if (_postData?.publishedAt != null && _postData?.publishedAt?.isNotEmpty == true) {
      try {
        final dateTime = DateTime.parse(_postData!.publishedAt!);
        formattedDate = DateFormat('MMMM d \'at\' h:mm a').format(dateTime);
      } catch (e) {
        formattedDate = _postData?.publishedAt ?? '';
      }
    }

    return Text(
      formattedDate,
      style: IsrStyles.primaryText12,
    );
  }

  Widget _buildInteractionIcons() {
    final likes = _postData?.engagementMetrics?.likeTypes?.like?.toInt() ?? 0;
    final comments = _postData?.engagementMetrics?.comments?.toInt() ?? 0;
    final shares = _postData?.engagementMetrics?.shares?.toInt() ?? 0;
    final saves = _postData?.engagementMetrics?.saves?.toInt() ?? 0;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildInteractionIcon(
          AssetConstants.icHeartIconSelected,
          likes.toString(),
        ),
        IsrDimens.twentyFour.responsiveHorizontalSpace,
        _buildInteractionIcon(
          AssetConstants.icCommentIcon,
          comments.toString(),
        ),
        IsrDimens.twentyFour.responsiveHorizontalSpace,
        _buildInteractionIcon(
          AssetConstants.icSharePostIcon,
          shares.toString(),
        ),
        IsrDimens.twentyFour.responsiveHorizontalSpace,
        _buildInteractionIcon(
          AssetConstants.icSaveSelectedIcon,
          saves.toString(),
        ),
      ],
    );
  }

  Widget _buildInteractionIcon(String iconPath, String count) => Column(
        children: [
          AppImage.svg(
            iconPath,
            width: IsrDimens.fourteen,
            height: IsrDimens.fourteen,
            color: '535353'.toColor(),
          ),
          IsrDimens.boxHeight(IsrDimens.four),
          Text(
            count,
            style: IsrStyles.primaryText12,
          ),
        ],
      );

  Widget _buildOverviewSection() {
    final views = _postData?.engagementMetrics?.views?.toInt() ?? 0;
    final interactions = _calculateTotalInteractions();
    final profileActivity = 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          IsrTranslationFile.overview,
          style: IsrStyles.primaryText14Bold,
        ),
        IsrDimens.boxHeight(IsrDimens.sixteen),
        _buildOverviewItem(IsrTranslationFile.views, views.toString()),
        IsrDimens.boxHeight(IsrDimens.sixteen),
        _buildOverviewItem(IsrTranslationFile.interactions, interactions.toString()),
        IsrDimens.boxHeight(IsrDimens.sixteen),
        Divider(
            height: 1.responsiveDimension,
            color: IsrColors.colorDBDBDB,
            thickness: 1.responsiveDimension),
        IsrDimens.boxHeight(IsrDimens.sixteen),
        _buildOverviewItem(IsrTranslationFile.profileActivity, profileActivity.toString()),
      ],
    );
  }

  Widget _buildOverviewItem(String label, String value) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: IsrStyles.primaryText12.copyWith(
              color: '767676'.toColor(),
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: IsrStyles.primaryText12.copyWith(
              color: '767676'.toColor(),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      );

  Widget _buildCircularGraphSection({
    required String title,
    required String mainLabel,
    required num mainValue,
    required String selectedLabel,
    required num selectedValue,
    required String unselectedLabel,
  }) {
    final selectedPercentage = mainValue > 0 ? ((selectedValue / mainValue) * 100) : 0;
    final nonselectedPercentage = 100 - selectedPercentage;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            title,
            style: IsrStyles.primaryText14Bold,
          ),
        ),
        IsrDimens.boxHeight(IsrDimens.sixteen),
        Text(
          mainValue.toInt().toString(),
          style: IsrStyles.primaryText18.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          mainLabel,
          style: IsrStyles.primaryText12.copyWith(
              fontSize: IsrDimens.twelve, fontWeight: FontWeight.w500, color: '767676'.toColor()),
        ),
        16.responsiveVerticalSpace,
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          spacing: 16.responsiveDimension,
          children: [
            Expanded(
              child: _buildChartLegend(
                label: selectedLabel,
                percentage: selectedPercentage.toStringAsFixed(1),
                color: 'C548BD'.toColor(),
                isAlignLeft: false,
              ),
            ),
            SizedBox(
              width: 64.responsiveDimension,
              height: 64.responsiveDimension,
              child: CircularPercentIndicator(
                radius: 32.responsiveDimension,
                lineWidth: 10.responsiveDimension,
                percent: selectedPercentage / 100,
                circularStrokeCap: CircularStrokeCap.square,
                progressColor: 'C548BD'.toColor(),
                backgroundColor: '967AE3'.toColor(),
                reverse: true,
                animation: true,
                animationDuration: 1000,
              ),
            ),
            Expanded(
              child: _buildChartLegend(
                label: unselectedLabel,
                percentage: nonselectedPercentage.toStringAsFixed(1),
                color: '967AE3'.toColor(),
              ),
            ),
          ],
        ),
        IsrDimens.boxHeight(IsrDimens.eight),
      ],
    );
  }

  Widget _buildChartLegend(
          {required String label,
          required String percentage,
          required Color color,
          bool isAlignLeft = true}) =>
      Column(
        crossAxisAlignment: isAlignLeft ? CrossAxisAlignment.start : CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '$percentage%',
            style: IsrStyles.primaryText16Bold,
          ),
          Row(
            mainAxisAlignment: isAlignLeft ? MainAxisAlignment.start : MainAxisAlignment.end,
            children: [
              if (!isAlignLeft) ...[
                Text(
                  label,
                  style: IsrStyles.primaryText12,
                ),
                IsrDimens.eight.responsiveHorizontalSpace,
              ],
              Container(
                width: 6.responsiveDimension,
                height: 6.responsiveDimension,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
              if (isAlignLeft) ...[
                IsrDimens.eight.responsiveHorizontalSpace,
                Text(
                  label,
                  style: IsrStyles.primaryText12,
                ),
              ],
            ],
          ),
        ],
      );

  Widget _buildStatisticsSection() {
    final likes = _postData?.engagementMetrics?.likeTypes?.like?.toInt() ?? 0;
    final saves = _postData?.engagementMetrics?.saves?.toInt() ?? 0;
    final shares = _postData?.engagementMetrics?.shares?.toInt() ?? 0;
    final comments = _postData?.engagementMetrics?.comments?.toInt() ?? 0;
    final accountEngaged = 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          IsrTranslationFile.statistics,
          style: IsrStyles.primaryText14Bold,
        ),
        IsrDimens.boxHeight(IsrDimens.sixteen),
        _buildStatisticItem(IsrTranslationFile.likes, likes.toString()),
        IsrDimens.boxHeight(IsrDimens.sixteen),
        _buildStatisticItem(IsrTranslationFile.saves, saves.toString()),
        IsrDimens.boxHeight(IsrDimens.sixteen),
        _buildStatisticItem(IsrTranslationFile.shares, shares.toString()),
        IsrDimens.boxHeight(IsrDimens.sixteen),
        _buildStatisticItem(IsrTranslationFile.comments, comments.toString()),
        IsrDimens.boxHeight(IsrDimens.sixteen),
        Divider(
            height: 1.responsiveDimension,
            color: IsrColors.colorDBDBDB,
            thickness: 1.responsiveDimension),
        IsrDimens.boxHeight(IsrDimens.sixteen),
        _buildStatisticItem(IsrTranslationFile.accountEngaged, accountEngaged.toString()),
      ],
    );
  }

  Widget _buildStatisticItem(String label, String value) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: IsrStyles.primaryText12.copyWith(color: '767676'.toColor()),
          ),
          Text(
            value,
            style: IsrStyles.primaryText12.copyWith(color: '767676'.toColor()),
          ),
        ],
      );

  Widget _buildProfileActivitySection() {
    final profileVisits = _postData?.engagementMetrics?.views?.toInt() ?? 0;
    final follows = 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          IsrTranslationFile.profileActivity,
          style: IsrStyles.primaryText14Bold,
        ),
        IsrDimens.boxHeight(IsrDimens.sixteen),
        _buildStatisticItem(IsrTranslationFile.profileVisits, profileVisits.toString()),
        IsrDimens.boxHeight(IsrDimens.sixteen),
        _buildStatisticItem(IsrTranslationFile.follows, follows.toString()),
      ],
    );
  }

  int _calculateTotalInteractions() {
    final likes = _postData?.engagementMetrics?.likeTypes?.like?.toInt() ?? 0;
    final comments = _postData?.engagementMetrics?.comments?.toInt() ?? 0;
    final shares = _postData?.engagementMetrics?.shares?.toInt() ?? 0;
    final saves = _postData?.engagementMetrics?.saves?.toInt() ?? 0;
    return likes + comments + shares + saves;
  }
}
