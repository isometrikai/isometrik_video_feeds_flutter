import 'dart:convert';

class ResponseClass {
  factory ResponseClass.error(
    String error, {
    String? title,
    int statusCode = 1000,
  }) =>
      ResponseClass(
        title: title ?? 'Error',
        data: error,
        hasError: true,
        statusCode: statusCode,
      );

  factory ResponseClass.success(String message) => ResponseClass(
        title: 'Success',
        data: message,
        hasError: false,
        statusCode: 200,
      );

  factory ResponseClass.fromMap(Map<String, dynamic> map) => ResponseClass(
        title: map['title'] as String?,
        data: map['data'] as String,
        hasError: map['hasError'] as bool,
        statusCode: map['statusCode'] as int,
      );

  factory ResponseClass.fromJson(
    String source,
  ) =>
      ResponseClass.fromMap(json.decode(source) as Map<String, dynamic>);

  const ResponseClass({
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

  ResponseClass copyWith({
    String? title,
    String? data,
    bool? hasError,
    int? statusCode,
  }) =>
      ResponseClass(
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
  String toString() => 'ResponseClass(title: $title, data: $data, hasError: $hasError, statusCode: $statusCode)';

  @override
  bool operator ==(covariant ResponseClass other) {
    if (identical(this, other)) return true;

    return other.title == title && other.data == data && other.hasError == hasError && other.statusCode == statusCode;
  }

  @override
  int get hashCode => title.hashCode ^ data.hashCode ^ hasError.hashCode ^ statusCode.hashCode;
}
