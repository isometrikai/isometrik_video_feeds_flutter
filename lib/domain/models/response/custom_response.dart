class CustomResponse<T> {
  CustomResponse({required this.data, this.responseCode = 200});

  final T? data;
  final int? responseCode;
}
