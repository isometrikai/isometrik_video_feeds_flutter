import 'dart:convert';

PostModerationData? postModerationDataFromJson(String str) {
  try {
    final decoded = json.decode(str);
    if (decoded is! Map<String, dynamic>) return null;
    final data = decoded['data'];
    if (data is Map<String, dynamic>) {
      return PostModerationData.fromMap(data);
    }
    return PostModerationData.fromMap(decoded);
  } catch (_) {
    return null;
  }
}

/// Latest moderation record for a post (`GET /api/v1/moderation/latest`).
class PostModerationData {
  const PostModerationData({
    this.id,
    this.contentId,
    this.status,
    this.textReport,
    this.mediaReports = const [],
  });

  factory PostModerationData.fromMap(Map<String, dynamic> json) {
    final outerReport = json['content_report'];
    Map<String, dynamic>? nested;
    if (outerReport is Map<String, dynamic>) {
      final inner = outerReport['content_report'];
      nested = inner is Map<String, dynamic> ? inner : outerReport;
    }

    final textRaw = nested?['text_report'];
    final mediaRaw = nested?['media_report'];

    return PostModerationData(
      id: json['id'] as String?,
      contentId: json['content_id'] as String?,
      status: json['status'] as String?,
      textReport: textRaw is Map<String, dynamic>
          ? PostModerationTextReport.fromMap(textRaw)
          : null,
      mediaReports: mediaRaw is List
          ? mediaRaw
              .whereType<Map<String, dynamic>>()
              .map(PostModerationMediaReport.fromMap)
              .toList()
          : const [],
    );
  }

  final String? id;
  final String? contentId;
  final String? status;
  final PostModerationTextReport? textReport;
  final List<PostModerationMediaReport> mediaReports;

  bool get isCaptionFlagged => textReport?.isFlagged == true;

  PostModerationMediaReport? mediaReportFor({
    required int index,
    String? url,
    String? assetId,
  }) {
    for (final report in mediaReports) {
      if (report.mediaIndex == index) return report;
      final reportAsset = report.assetId?.trim();
      final itemAsset = assetId?.trim();
      if (reportAsset != null &&
          reportAsset.isNotEmpty &&
          reportAsset == itemAsset) {
        return report;
      }
      final reportUrl = report.url?.trim();
      final itemUrl = url?.trim();
      if (reportUrl != null &&
          reportUrl.isNotEmpty &&
          reportUrl == itemUrl) {
        return report;
      }
    }
    return null;
  }
}

class PostModerationTextReport {
  const PostModerationTextReport({
    this.result,
    this.content,
    this.provider,
    this.isInappropriate = false,
  });

  factory PostModerationTextReport.fromMap(Map<String, dynamic> json) =>
      PostModerationTextReport(
        result: json['result'] as String?,
        content: json['content'] as String?,
        provider: json['provider'] as String?,
        isInappropriate: json['is_inappropriate'] == true,
      );

  final String? result;
  final String? content;
  final String? provider;
  final bool isInappropriate;

  bool get isFlagged {
    final normalized = (result ?? '').toLowerCase().trim();
    return normalized == 'flagged' || isInappropriate;
  }

  String get displayReason {
    final providerName = (provider ?? '').toLowerCase();
    if (providerName.contains('language')) {
      return 'Caption flagged for inappropriate content based on Google Language analysis';
    }
    return 'Caption flagged for inappropriate content.';
  }
}

class PostModerationMediaReport {
  const PostModerationMediaReport({
    this.url,
    this.result,
    this.details,
    this.assetId,
    this.mediaIndex,
    this.mediaType,
  });

  factory PostModerationMediaReport.fromMap(Map<String, dynamic> json) =>
      PostModerationMediaReport(
        url: json['url'] as String?,
        result: json['result'] as String?,
        details: json['details'] as String?,
        assetId: json['asset_id'] as String?,
        mediaIndex: (json['media_index'] as num?)?.toInt(),
        mediaType: json['media_type'] as String?,
      );

  final String? url;
  final String? result;
  final String? details;
  final String? assetId;
  final int? mediaIndex;
  final String? mediaType;

  bool get isFlagged => (result ?? '').toLowerCase().trim() == 'flagged';

  bool get isApproved => (result ?? '').toLowerCase().trim() == 'approved';
}
