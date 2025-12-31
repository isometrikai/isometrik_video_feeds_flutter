import 'package:ism_video_reel_player/utils/extensions.dart';

class ReportRequest {

  ReportRequest({
    required this.contentId,
    required this.additionalDetails,
    required this.reasonId,
    required this.type,
    required this.reason,
  });

  /// Convert JSON → Object
  factory ReportRequest.fromJson(Map<String, dynamic> json) => ReportRequest(
      contentId: json.stringOrNull('content_id'),
      additionalDetails: json.stringOrNull('additional_details'),
      reasonId: json.stringOrNull('reason_id'),
      type: json.stringOrNull('type'),
      reason: json.stringOrNull('reason'),
    );
  final String? contentId;
  final String? additionalDetails;
  final String? reasonId;
  final String? type;
  final String? reason;

  /// Convert Object → JSON
  Map<String, dynamic> toJson() => {
      'content_id': contentId,
      'additional_details': additionalDetails,
      'reason_id': reasonId,
      'type': type,
      'reason': reason,
    };
}
