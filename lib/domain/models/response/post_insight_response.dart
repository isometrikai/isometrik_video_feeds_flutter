import 'dart:convert';

InsightsResponse insightsResponseFromJson(String str) =>
    InsightsResponse.fromMap((json.decode(str) as Map<String, dynamic>?) ?? {});

class InsightsResponse {
  InsightsResponse({
    this.status,
    this.message,
    this.statusCode,
    this.code,
    this.data,
  });

  factory InsightsResponse.fromMap(Map<String, dynamic> json) =>
      InsightsResponse(
        status: json['status'] as String? ?? '',
        message: json['message'] as String? ?? '',
        statusCode: json['statusCode'] as num? ?? 0,
        code: json['code'] as String? ?? '',
        data: json['data'] == null
            ? null
            : InsightsData.fromMap(
          json['data'] as Map<String, dynamic>,
        ),
      );

  String? status;
  String? message;
  num? statusCode;
  String? code;
  InsightsData? data;

  Map<String, dynamic> toMap() => {
    'status': status,
    'message': message,
    'statusCode': statusCode,
    'code': code,
    'data': data?.toMap(),
  };
}

class InsightsData {
  InsightsData({
    this.id,
    this.summary,
    this.timeSeries,
    this.locations,
    this.followerSplit,
  });

  factory InsightsData.fromMap(Map<String, dynamic> json) => InsightsData(
    id: json['id'] as String? ?? '',
    summary: json['summary'] == null
        ? null
        : InsightsSummary.fromMap(
      json['summary'] as Map<String, dynamic>,
    ),
    timeSeries: json['timeseries'] == null
        ? []
        : List<InsightsTimeSeries>.from(
      (json['timeseries'] as List).map(
            (x) => InsightsTimeSeries.fromMap(
          x as Map<String, dynamic>,
        ),
      ),
    ),
    locations: json['locations'] == null
        ? null
        : Locations.fromMap(json['locations'] as Map<String, dynamic>),
    followerSplit: json['follower_split'] == null
        ? null
        : FollowerSplit.fromMap(
      json['follower_split'] as Map<String, dynamic>,
    ),
  );

  String? id;
  InsightsSummary? summary;
  List<InsightsTimeSeries>? timeSeries;
  Locations? locations;
  FollowerSplit? followerSplit;

  Map<String, dynamic> toMap() => {
    'id': id,
    'summary': summary?.toMap(),
    'timeseries': timeSeries == null
        ? []
        : List<dynamic>.from(timeSeries!.map((x) => x.toMap())),
    'locations': locations?.toMap(),
    'follower_split': followerSplit?.toMap(),
  };
}

class InsightsSummary {
  InsightsSummary({
    this.views,
    this.interactions,
    this.likes,
    this.saves,
    this.shares,
    this.comments,
    this.hides,
    this.reports,
    this.accountsEngaged,
    this.lastEventAt,
    this.profileActivity,
  });

  factory InsightsSummary.fromMap(Map<String, dynamic> json) =>
      InsightsSummary(
        views: json['views'] as num? ?? 0,
        interactions: json['interactions'] as num? ?? 0,
        likes: json['likes'] as num? ?? 0,
        saves: json['saves'] as num? ?? 0,
        shares: json['shares'] as num? ?? 0,
        comments: json['comments'] as num? ?? 0,
        hides: json['hides'] as num? ?? 0,
        reports: json['reports'] as num? ?? 0,
        accountsEngaged: json['accounts_engaged'] as num? ?? 0,
        lastEventAt: json['last_event_at'] as String? ?? '',
        profileActivity: json['profile_activity'] == null
            ? null
            : ProfileActivity.fromMap(
          json['profile_activity'] as Map<String, dynamic>,
        ),
      );

  num? views;
  num? interactions;
  num? likes;
  num? saves;
  num? shares;
  num? comments;
  num? hides;
  num? reports;
  num? accountsEngaged;
  String? lastEventAt;
  ProfileActivity? profileActivity;

  Map<String, dynamic> toMap() => {
    'views': views,
    'interactions': interactions,
    'likes': likes,
    'saves': saves,
    'shares': shares,
    'comments': comments,
    'hides': hides,
    'reports': reports,
    'accounts_engaged': accountsEngaged,
    'last_event_at': lastEventAt,
    'profile_activity': profileActivity?.toMap(),
  };
}

class ProfileActivity {
  ProfileActivity({
    this.profileVisits,
    this.follows,
  });

  factory ProfileActivity.fromMap(Map<String, dynamic> json) =>
      ProfileActivity(
        profileVisits: json['profile_visits'] as num? ?? 0,
        follows: json['follows'] as num? ?? 0,
      );

  num? profileVisits;
  num? follows;

  Map<String, dynamic> toMap() => {
    'profile_visits': profileVisits,
    'follows': follows,
  };
}

class InsightsTimeSeries {
  InsightsTimeSeries({
    this.bucket,
    this.views,
    this.interactions,
    this.likes,
    this.saves,
    this.shares,
    this.comments,
  });

  factory InsightsTimeSeries.fromMap(Map<String, dynamic> json) =>
      InsightsTimeSeries(
        bucket: json['bucket'] as String? ?? '',
        views: json['views'] as num? ?? 0,
        interactions: json['interactions'] as num? ?? 0,
        likes: json['likes'] as num? ?? 0,
        saves: json['saves'] as num? ?? 0,
        shares: json['shares'] as num? ?? 0,
        comments: json['comments'] as num? ?? 0,
      );

  String? bucket;
  num? views;
  num? interactions;
  num? likes;
  num? saves;
  num? shares;
  num? comments;

  Map<String, dynamic> toMap() => {
    'bucket': bucket,
    'views': views,
    'interactions': interactions,
    'likes': likes,
    'saves': saves,
    'shares': shares,
    'comments': comments,
  };
}

class Locations {
  Locations({
    this.countries,
    this.states,
    this.cities,
  });

  factory Locations.fromMap(Map<String, dynamic> json) => Locations(
    countries: json['countries'] == null
        ? []
        : List<PlaceViews>.from(
        (json['countries'] as List).map((x) => PlaceViews.fromMap(x as Map<String,dynamic>))),
    states: json['states'] == null
        ? []
        : List<PlaceViews>.from(
        (json['states'] as List).map((x) => PlaceViews.fromMap(x as Map<String,dynamic>))),
    cities: json['cities'] == null
        ? []
        : List<PlaceViews>.from(
        (json['cities'] as List).map((x) => PlaceViews.fromMap(x as Map<String,dynamic>))),
  );

  List<PlaceViews>? countries;
  List<PlaceViews>? states;
  List<PlaceViews>? cities;

  Map<String, dynamic> toMap() => {
    'countries': countries == null
        ? []
        : List<dynamic>.from(countries!.map((x) => x.toMap())),
    'states': states == null
        ? []
        : List<dynamic>.from(states!.map((x) => x.toMap())),
    'cities': cities == null
        ? []
        : List<dynamic>.from(cities!.map((x) => x.toMap())),
  };
}

class PlaceViews {
  PlaceViews({
    this.country,
    this.state,
    this.city,
    this.views,
    this.pct,
  });

  factory PlaceViews.fromMap(Map<String, dynamic> json) => PlaceViews(
    country: json['country'] as String? ?? '',
    state: json['state'] as String? ?? '',
    city: json['city'] as String? ?? '',
    views: json['views'] as num? ?? 0,
    pct: json['pct'] as num? ?? 0,
  );

  String? country;
  String? state;
  String? city;
  num? views;
  num? pct;

  Map<String, dynamic> toMap() => {
    'country': country,
    'state': state,
    'city': city,
    'views': views,
    'pct': pct,
  };
}

class FollowerSplit {
  FollowerSplit({
    this.viewsFollowers,
    this.viewsNonFollowers,
    this.interactionsFollowers,
    this.interactionsNonFollowers,
    this.viewsFollowersPct,
    this.viewsNonFollowersPct,
    this.interactionsFollowersPct,
    this.interactionsNonFollowersPct,
  });

  factory FollowerSplit.fromMap(Map<String, dynamic> json) =>
      FollowerSplit(
        viewsFollowers: json['views_followers'] as num? ?? 0,
        viewsNonFollowers: json['views_non_followers'] as num? ?? 0,
        interactionsFollowers:
        json['interactions_followers'] as num? ?? 0,
        interactionsNonFollowers:
        json['interactions_non_followers'] as num? ?? 0,
        viewsFollowersPct:
        (json['views_followers_pct'] as num?)?.toDouble() ?? 0.0,
        viewsNonFollowersPct:
        (json['views_non_followers_pct'] as num?)?.toDouble() ?? 0.0,
        interactionsFollowersPct:
        (json['interactions_followers_pct'] as num?)?.toDouble() ?? 0.0,
        interactionsNonFollowersPct:
        (json['interactions_non_followers_pct'] as num?)?.toDouble() ?? 0.0,
      );

  num? viewsFollowers;
  num? viewsNonFollowers;
  num? interactionsFollowers;
  num? interactionsNonFollowers;
  double? viewsFollowersPct;
  double? viewsNonFollowersPct;
  double? interactionsFollowersPct;
  double? interactionsNonFollowersPct;

  Map<String, dynamic> toMap() => {
    'views_followers': viewsFollowers,
    'views_non_followers': viewsNonFollowers,
    'interactions_followers': interactionsFollowers,
    'interactions_non_followers': interactionsNonFollowers,
    'views_followers_pct': viewsFollowersPct,
    'views_non_followers_pct': viewsNonFollowersPct,
    'interactions_followers_pct': interactionsFollowersPct,
    'interactions_non_followers_pct': interactionsNonFollowersPct,
  };
}
