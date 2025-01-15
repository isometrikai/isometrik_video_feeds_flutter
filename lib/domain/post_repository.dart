import 'package:injectable/injectable.dart';
import 'package:ism_video_reel_player/export.dart';

@lazySingleton
class PostRepository extends BaseRepository {
  final _dataSource = isrGetIt<DataSourceImpl>();

  Future<ResponseModel> createPost({
    required bool isLoading,
    Map<String, dynamic>? createPostRequest,
  }) async {
    final header = await _dataSource.getHeader();
    return await _dataSource.getNetworkManager().postApiService().createPost(
          isLoading: isLoading,
          header: header,
          createPostRequest: createPostRequest,
        );
  }

  @override
  void deleteAllSecuredValues() {
    _dataSource.getStorageManager().deleteAllSecuredValues();
  }

  @override
  void deleteSecuredValue(String key) {
    _dataSource.getStorageManager().deleteSecuredValue(key);
  }

  @override
  Future<String> getSecuredValue(String key) => _dataSource.getStorageManager().getSecuredValue(key);

  @override
  void saveValueSecurely(String key, String value) {
    _dataSource.getStorageManager().saveValueSecurely(key, value);
  }

  @override
  void saveValue(String key, dynamic value, SavedValueDataType savedValueDataType) {
    _dataSource.getStorageManager().saveValue(key, value, savedValueDataType);
  }

  @override
  dynamic getValue(String key, SavedValueDataType savedValueDataType) =>
      _dataSource.getStorageManager().getValue(key, savedValueDataType);

  @override
  void clearData() {
    _dataSource.getStorageManager().clearData();
  }
}
