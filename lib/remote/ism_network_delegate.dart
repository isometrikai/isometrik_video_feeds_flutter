import 'dart:convert';

import 'package:ism_video_reel_player/core/core.dart';

/// Response class with raw string data and pagination info
class IsmNetworkResponse {
  const IsmNetworkResponse({
    required this.isSuccess,
    this.data,
    this.errorMessage,
    this.statusCode = 200,
    this.pagination,
  });

  final bool isSuccess;
  final String? data;
  final String? errorMessage;
  final int statusCode;
  final IsmPagination? pagination;

  /// Decode the data string to Map
  Map<String, dynamic>? decode() {
    if (data == null || data!.isEmpty) return null;
    try {
      return jsonDecode(data!) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  /// Decode the data string to List
  List<dynamic>? decodeList() {
    if (data == null || data!.isEmpty) return null;
    try {
      return jsonDecode(data!) as List<dynamic>;
    } catch (_) {
      return null;
    }
  }

  @override
  String toString() =>
      'IsmNetworkResponse(isSuccess: $isSuccess, statusCode: $statusCode, pagination: $pagination)';
}

/// Pagination info
class IsmPagination {
  factory IsmPagination.fromMap(Map<String, dynamic> map) => IsmPagination(
        currentPage: (map['page'] ?? map['currentPage'] ?? 1) as int,
        totalPages: (map['totalPages'] ?? map['total_pages'] ?? 1) as int,
        pageSize:
            (map['pageSize'] ?? map['page_size'] ?? map['limit'] ?? 10) as int,
        totalItems: (map['total'] ?? map['totalItems'] ?? 0) as int,
      );
  const IsmPagination({
    required this.currentPage,
    required this.totalPages,
    required this.pageSize,
    required this.totalItems,
  });

  final int currentPage;
  final int totalPages;
  final int pageSize;
  final int totalItems;

  bool get hasNextPage => currentPage < totalPages;
  bool get hasPreviousPage => currentPage > 1;
  int get nextPage => hasNextPage ? currentPage + 1 : currentPage;
  int get previousPage => hasPreviousPage ? currentPage - 1 : currentPage;

  Map<String, dynamic> toMap() => {
        'currentPage': currentPage,
        'totalPages': totalPages,
        'pageSize': pageSize,
        'totalItems': totalItems,
      };

  @override
  String toString() =>
      'IsmPagination(page: $currentPage/$totalPages, size: $pageSize, total: $totalItems)';
}

/// Callback type for network calls
typedef IsmNetworkHandler = Future<IsmNetworkResponse> Function(
  String methodName,
  Map<String, dynamic> params,
);

/// Callback for paginated results
typedef IsmPaginatedCallback = void Function(
  IsmNetworkResponse response,
  int currentPage,
  bool isLastPage,
);

/// A singleton class that delegates network calls to external project.
///
/// Usage:
/// ```dart
/// // Step 1: Set handler in your project (once at startup)
/// IsmNetworkDelegate.instance.setHandler((methodName, params) async {
///   final response = await yourApi.call(methodName, params);
///   return IsmNetworkResponse(
///     isSuccess: true,
///     data: jsonEncode(response),
///     pagination: IsmPagination(...),
///   );
/// });
///
/// // Step 2: SDK calls fetch when needed
/// final response = await IsmNetworkDelegate.instance.fetch(
///   'getCollections',
///   {'page': 1, 'limit': 10},
/// );
/// ```
class IsmNetworkDelegate {
  /// Private constructor
  IsmNetworkDelegate._();

  /// Single instance
  static final IsmNetworkDelegate _instance = IsmNetworkDelegate._();

  /// Access the singleton instance
  static IsmNetworkDelegate get instance => _instance;

  /// The registered handler from external project
  IsmNetworkHandler? _handler;

  /// Sets the network handler callback
  void setHandler(IsmNetworkHandler handler) {
    _handler = handler;
  }

  /// Checks if handler is registered
  bool get hasHandler => _handler != null;

  /// Removes the registered handler
  void clearHandler() {
    _handler = null;
  }

  /// Fetches data using the registered handler
  ///
  /// [methodName] - The method identifier (e.g., 'getCollections')
  /// [params] - Parameters as Map
  Future<IsmNetworkResponse> fetch(
    String methodName,
    Map<String, dynamic> params,
  ) async {
    if (_handler == null) {
      return const IsmNetworkResponse(
        isSuccess: false,
        errorMessage: 'Handler not set. Call setHandler() first.',
        statusCode: 0,
      );
    }

    try {
      return await _handler!(methodName, params);
    } catch (e) {
      return IsmNetworkResponse(
        isSuccess: false,
        errorMessage: e.toString(),
        statusCode: 0,
      );
    }
  }

  /// Fetches data with pagination params
  Future<IsmNetworkResponse> fetchPaginated(
    String methodName, {
    Map<String, dynamic>? params,
    int page = 1,
    int limit = 10,
  }) async =>
      fetch(methodName, {...?params, 'page': page, 'limit': limit});

  /// Loads next page based on previous response
  Future<IsmNetworkResponse> fetchNextPage(
    String methodName,
    IsmNetworkResponse previousResponse, {
    Map<String, dynamic>? params,
  }) async {
    final pagination = previousResponse.pagination;
    if (pagination == null || !pagination.hasNextPage) {
      return const IsmNetworkResponse(
        isSuccess: false,
        errorMessage: 'No more pages',
        statusCode: 0,
      );
    }

    return fetchPaginated(
      methodName,
      params: params,
      page: pagination.nextPage,
      limit: pagination.pageSize,
    );
  }

  /// Fetches all pages and returns via callback
  Future<void> fetchAllPages(
    String methodName, {
    Map<String, dynamic>? params,
    int startPage = 1,
    int limit = 10,
    required IsmPaginatedCallback onPageLoaded,
    bool stopOnError = true,
  }) async {
    var currentPage = startPage;
    var hasMore = true;

    while (hasMore) {
      final response = await fetchPaginated(
        methodName,
        params: params,
        page: currentPage,
        limit: limit,
      );

      final isLastPage = response.pagination?.hasNextPage != true;
      onPageLoaded(response, currentPage, isLastPage);

      if (!response.isSuccess && stopOnError) break;

      hasMore = response.pagination?.hasNextPage == true;
      currentPage++;
    }
  }

  /// Fetches and returns ApiResult with parsed response
  Future<ApiResult<T>> fetchWithResult<T>(
    String methodName,
    Map<String, dynamic> params, {
    required T Function(Map<String, dynamic>) fromJson,
  }) async {
    final response = await fetch(methodName, params);

    if (response.isSuccess) {
      final decoded = response.decode();
      if (decoded != null) {
        try {
          return ApiResult<T>(
            data: fromJson(decoded),
            statusCode: response.statusCode,
          );
        } catch (e) {
          return ApiResult<T>(
            error: AppError('Parse error: $e'),
            statusCode: response.statusCode,
          );
        }
      }
      return ApiResult<T>(data: null, statusCode: response.statusCode);
    }

    return ApiResult<T>(
      error: AppError(response.errorMessage ?? 'Unknown error'),
      statusCode: response.statusCode,
    );
  }
}

/// Common method names
abstract class IsmNetworkMethods {
  static const String getCollections = 'getCollections';
  static const String getMentionedUsers = 'getMentionedUsers';
  static const String getTimelinePosts = 'getTimelinePosts';
  static const String getFollowingPosts = 'getFollowingPosts';
  static const String getTrendingPosts = 'getTrendingPosts';
  static const String getForYouPosts = 'getForYouPosts';
  static const String getPostComments = 'getPostComments';
  static const String searchUsers = 'searchUsers';
  static const String searchTags = 'searchTags';
  static const String getTaggedPosts = 'getTaggedPosts';
  static const String getSavedPosts = 'getSavedPosts';
  static const String getUserPosts = 'getUserPosts';
  static const String getPostDetails = 'getPostDetails';
  static const String createPost = 'createPost';
  static const String deletePost = 'deletePost';
  static const String likePost = 'likePost';
  static const String savePost = 'savePost';
  static const String followUser = 'followUser';
  static const String reportPost = 'reportPost';
  static const String commentAction = 'commentAction';
}
