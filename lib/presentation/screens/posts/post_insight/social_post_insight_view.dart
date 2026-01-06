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

enum LocationType { cities, states, countries }

class _SocialPostInsightViewState extends State<SocialPostInsightView> {
  TimeLineData? _postData;
  InsightsData? _postInsight;
  late final String? _postId;
  final _socialPostBloc = IsmInjectionUtils.getBloc<SocialPostBloc>();
  LocationType _selectedLocationType = LocationType.countries;

  @override
  void initState() {
    _postData = widget.postData;
    _postId = widget.postId;
    log('post insight data: ${_postData?.toMap()}');
    _socialPostBloc
        .add(GetPostInsightDetailsEvent(postId: _postId, data: _postData));
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
              (currentState is PostInsightDetails &&
                  currentState.postId == _postId) ||
              (currentState is PostInsightDetailsLoading &&
                  currentState.postId == _postId),
          listenWhen: (previousState, currentState) =>
              (currentState is PostInsightDetails &&
                  currentState.postId == _postId) ||
              (currentState is PostInsightDetailsLoading &&
                  currentState.postId == _postId),
          listener: (context, state) {
            _postData =
                (state is PostInsightDetails) ? state.postData : _postData;
            _postInsight =
                (state is PostInsightDetails) ? state.insightData?.data : null;
            log('post insight data: ${_postData?.toMap()}');
          },
          builder: (context, state) => SafeArea(
            child: Stack(
              children: [
                RefreshIndicator.adaptive(
                  child: _buildBody(),
                  onRefresh: () async {
                    _socialPostBloc.add(GetPostInsightDetailsEvent(
                        postId: _postId, data: _postData));
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
              mainValue: _postInsight?.summary?.views ??
                  _postData?.engagementMetrics?.views ??
                  0,
              selectedLabel: IsrTranslationFile.followers,
              selectedValue: _postInsight?.followerSplit?.viewsFollowers ?? 0,
              // needed from API
              unselectedLabel: IsrTranslationFile.nonFollowers,
            ),
            IsrDimens.boxHeight(IsrDimens.twentyFour),
            _buildCircularGraphSection(
              title: IsrTranslationFile.interactions,
              mainLabel: IsrTranslationFile.interactions,
              mainValue: _postInsight?.summary?.interactions ??
                  _calculateTotalInteractions(),
              selectedLabel: IsrTranslationFile.followers,
              selectedValue:
                  _postInsight?.followerSplit?.interactionsFollowers ?? 0,
              // needed from API
              unselectedLabel: IsrTranslationFile.nonFollowers,
            ),
            IsrDimens.boxHeight(IsrDimens.twentyFour),
            _buildStatisticsSection(),
            IsrDimens.boxHeight(IsrDimens.twentyFour),
            _buildProfileActivitySection(),
            IsrDimens.boxHeight(IsrDimens.twentyFour),
            if (_postInsight?.locations?.cities?.isNotEmpty == true ||
                _postInsight?.locations?.states?.isNotEmpty == true ||
                _postInsight?.locations?.countries?.isNotEmpty == true) ...[
              _buildLocationSectionSection(),
              IsrDimens.boxHeight(IsrDimens.twentyFour),
            ],
          ],
        ),
      );

  Widget _buildPostPreview() {
    final imageUrl =
        _postData?.media?.first.mediaType?.mediaType == MediaType.video
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
    if (_postData?.publishedAt != null &&
        _postData?.publishedAt?.isNotEmpty == true) {
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
    final likes = _postInsight?.summary?.likes ??
        _postData?.engagementMetrics?.likeTypes?.like?.toInt() ??
        0;
    final comments = _postInsight?.summary?.comments ??
        _postData?.engagementMetrics?.comments?.toInt() ??
        0;
    final shares = _postInsight?.summary?.shares ??
        _postData?.engagementMetrics?.shares?.toInt() ??
        0;
    final saves = _postInsight?.summary?.saves ??
        _postData?.engagementMetrics?.saves?.toInt() ??
        0;

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
    final views = _postInsight?.summary?.views ??
        _postData?.engagementMetrics?.views?.toInt() ??
        0;
    final interactions =
        _postInsight?.summary?.interactions ?? _calculateTotalInteractions();
    final profileActivity =
        (_postInsight?.summary?.profileActivity?.follows ?? 0) +
            (_postInsight?.summary?.profileActivity?.profileVisits ?? 0);

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
        _buildOverviewItem(
            IsrTranslationFile.interactions, interactions.toString()),
        IsrDimens.boxHeight(IsrDimens.sixteen),
        Divider(
            height: 1.responsiveDimension,
            color: IsrColors.colorDBDBDB,
            thickness: 1.responsiveDimension),
        IsrDimens.boxHeight(IsrDimens.sixteen),
        _buildOverviewItem(
            IsrTranslationFile.profileActivity, profileActivity.toString()),
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
    final selectedPercentage =
        mainValue > 0 ? ((selectedValue / mainValue) * 100) : 0;
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
              fontSize: IsrDimens.twelve,
              fontWeight: FontWeight.w500,
              color: '767676'.toColor()),
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
                percent: (selectedPercentage / 100).clamp(0.0, 1.0),
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
        crossAxisAlignment:
            isAlignLeft ? CrossAxisAlignment.start : CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '$percentage%',
            style: IsrStyles.primaryText16Bold,
          ),
          Row(
            mainAxisAlignment:
                isAlignLeft ? MainAxisAlignment.start : MainAxisAlignment.end,
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
    final likes = _postInsight?.summary?.likes ??
        _postData?.engagementMetrics?.likeTypes?.like?.toInt() ??
        0;
    final comments = _postInsight?.summary?.comments ??
        _postData?.engagementMetrics?.comments?.toInt() ??
        0;
    final shares = _postInsight?.summary?.shares ??
        _postData?.engagementMetrics?.shares?.toInt() ??
        0;
    final saves = _postInsight?.summary?.saves ??
        _postData?.engagementMetrics?.saves?.toInt() ??
        0;
    final accountEngaged = _postInsight?.summary?.accountsEngaged ?? 0;

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
        _buildStatisticItem(
            IsrTranslationFile.accountEngaged, accountEngaged.toString()),
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
    final profileVisits =
        _postInsight?.summary?.profileActivity?.profileVisits ?? 0;
    final follows = _postInsight?.summary?.profileActivity?.follows ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          IsrTranslationFile.profileActivity,
          style: IsrStyles.primaryText14Bold,
        ),
        IsrDimens.boxHeight(IsrDimens.sixteen),
        _buildStatisticItem(
            IsrTranslationFile.profileVisits, profileVisits.toString()),
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

  Widget _buildLocationSectionSection() {
    final totalViews = _postInsight?.summary?.views ?? 0;
    final countryList = _postInsight?.locations?.countries ?? [];
    final statesLst = _postInsight?.locations?.states ?? [];
    final cityList = _postInsight?.locations?.cities ?? [];

    var currentList = <PlaceViews>[];
    switch (_selectedLocationType) {
      case LocationType.countries:
        currentList = countryList;
        break;
      case LocationType.states:
        currentList = statesLst;
        break;
      case LocationType.cities:
        currentList = cityList;
        break;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              IsrTranslationFile.topLocations,
              style: IsrStyles.primaryText14Bold,
            ),
            IsrDimens.boxHeight(IsrDimens.sixteen),
            Expanded(
                child: _buildLocationTypeSelector(
                    currentList.length, statesLst.length, cityList.length)),
          ],
        ),
        IsrDimens.boxHeight(IsrDimens.sixteen),
        ...switch (_selectedLocationType) {
          LocationType.countries =>
            countryList.map((e) => _buildLocationBar(e, totalViews)),
          LocationType.states =>
            statesLst.map((e) => _buildLocationBar(e, totalViews)),
          LocationType.cities =>
            cityList.map((e) => _buildLocationBar(e, totalViews)),
        },
      ],
    );
  }

  Widget _buildLocationTypeSelector(
          int countriesLength, int statesLength, int citiesLength) =>
      Row(
        mainAxisAlignment: MainAxisAlignment.end,
        spacing: 12.responsiveDimension,
        children: [
          if (citiesLength > 0)
            _buildLocationTab(
              label: 'Cities',
              type: LocationType.cities,
            ),
          if (statesLength > 0)
            _buildLocationTab(
              label: 'States',
              type: LocationType.states,
            ),
          if (countriesLength > 0)
            _buildLocationTab(
              label: 'Countries',
              type: LocationType.countries,
            ),
        ],
      );

  Widget _buildLocationTab({
    required String label,
    required LocationType type,
  }) {
    final isSelected = _selectedLocationType == type;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedLocationType = type;
        });
      },
      child: Text(
        label,
        style: IsrStyles.primaryText12.copyWith(
          color: isSelected ? IsrColors.appColor : '#767676'.color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildLocationBar(PlaceViews location, num totalViews) {
    var locationName = '';
    switch (_selectedLocationType) {
      case LocationType.countries:
        locationName = location.country ?? '';
        break;
      case LocationType.states:
        locationName = location.state ?? '';
        break;
      case LocationType.cities:
        // For cities, the name might be in country field or state field
        locationName = location.city ?? '';
        break;
    }

    final progress = (location.views?.toDouble() ?? 0.0) /
        (totalViews.toDouble().takeIf((e) => e > 0) ?? 1);
    final percentage = progress * 100;

    return Row(
      mainAxisSize: MainAxisSize.max,
      mainAxisAlignment: MainAxisAlignment.center,
      spacing: 28.responsiveDimension,
      children: [
        SizedBox(
          width: 90.responsiveDimension,
          child: Text(
            locationName,
            style: IsrStyles.primaryText12.copyWith(
              fontWeight: FontWeight.w500,
              color: '767676'.toColor(),
            ),
            textAlign: TextAlign.end,
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ),
        Expanded(
          child: SizedBox(
            height: 13.responsiveDimension,
            child: Stack(
              children: [
                Container(
                  width: double.infinity,
                  height: 13.responsiveDimension,
                  decoration: BoxDecoration(
                    color: IsrColors.appColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(2.responsiveDimension),
                  ),
                ),
                FractionallySizedBox(
                  widthFactor: progress.clamp(0.0, 1.0),
                  child: Container(
                    height: 13.responsiveDimension,
                    decoration: BoxDecoration(
                      color: IsrColors.appColor,
                      borderRadius:
                          BorderRadius.circular(2.responsiveDimension),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        SizedBox(
          width: 45.responsiveDimension,
          child: Text(
            '${percentage.toStringAsFixed(1)}%',
            style: IsrStyles.primaryText12.copyWith(
              color: '767676'.toColor(),
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.end,
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ),
      ],
    );
  }
}
