import 'dart:convert';

class ResponseModel {
  factory ResponseModel.error(
    String error, {
    String? title,
    int statusCode = 1000,
  }) =>
      ResponseModel(
        title: title ?? 'Error',
        data: error,
        hasError: true,
        statusCode: statusCode,
      );

  factory ResponseModel.success(String message) => ResponseModel(
        title: 'Success',
        data: message,
        hasError: false,
        statusCode: 200,
      );

  factory ResponseModel.fromMap(Map<String, dynamic> map) => ResponseModel(
        title: map['title'] as String?,
        data: map['data'] as String,
        hasError: map['hasError'] as bool,
        statusCode: map['statusCode'] as int,
      );

  factory ResponseModel.fromJson(
    String source,
  ) =>
      ResponseModel.fromMap(json.decode(source) as Map<String, dynamic>);

  const ResponseModel({
    this.title,
    required this.data,
    required this.hasError,
    this.statusCode = 1000,
  });

  Map<String, dynamic> decode() => jsonDecode(data) as Map<String, dynamic>;

  final String? title;
  final String data;
  final bool hasError;
  final int statusCode;

  ResponseModel copyWith({
    String? title,
    String? data,
    bool? hasError,
    int? statusCode,
  }) =>
      ResponseModel(
        title: title ?? this.title,
        data: data ?? this.data,
        hasError: hasError ?? this.hasError,
        statusCode: statusCode ?? this.statusCode,
      );

  Map<String, dynamic> toMap() => <String, dynamic>{
        'title': title,
        'data': data,
        'hasError': hasError,
        'statusCode': statusCode,
      };

  String toJson() => json.encode(toMap());

  @override
  String toString() => 'ResponseModel(title: $title, data: $data, hasError: $hasError, statusCode: $statusCode)';

  @override
  bool operator ==(covariant ResponseModel other) {
    if (identical(this, other)) return true;

    return other.title == title && other.data == data && other.hasError == hasError && other.statusCode == statusCode;
  }

  @override
  int get hashCode => title.hashCode ^ data.hashCode ^ hasError.hashCode ^ statusCode.hashCode;
}
