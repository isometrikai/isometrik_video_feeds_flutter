import 'dart:io';

import 'package:ism_video_reel_player_example/domain/domain.dart';

class GoogleCloudStorageUploaderUseCase extends BaseUseCase {
  GoogleCloudStorageUploaderUseCase(this._repository);

  final SocialRepository _repository;

  Future<String?> executeGoogleCloudStorageUploader({
    required File file,
    required String fileName,
    required String userId,
    required String fileExtension,
    Function(double)? onProgress,
    String? cloudFolderName,
  }) async {
    final response = await _repository.uploadMediaToGoogleCloud(
      fileName: fileName,
      file: file,
      userId: userId,
      fileExtension: fileExtension,
      onProgress: onProgress,
      cloudFolderName: cloudFolderName,
    );
    return response;
  }
}
