import 'dart:typed_data';
import 'package:cloudinary_public/cloudinary_public.dart';

class CloudinaryApi {
  // Cloudinary credentials
  static const String _cloudName = 'ddqouziau';
  static const String _uploadPreset = 'phuckk';

  final CloudinaryPublic _cloudinary = CloudinaryPublic(
    _cloudName,
    _uploadPreset,
    cache: false,
  );

  /// Upload ảnh lên Cloudinary từ bytes (dành cho web)
  /// Trả về URL của ảnh đã upload
  Future<String> uploadImageFromBytes(
    Uint8List imageBytes,
    String fileName, {
    String? folder,
  }) async {
    try {
      CloudinaryResponse response = await _cloudinary.uploadFile(
        CloudinaryFile.fromBytesData(
          imageBytes,
          identifier: fileName,
          folder: folder,
          resourceType: CloudinaryResourceType.Image,
        ),
      );
      return response.secureUrl;
    } catch (e) {
      throw Exception('Lỗi khi upload ảnh lên Cloudinary: $e');
    }
  }

  /// Upload ảnh lên Cloudinary từ file path (dành cho mobile/desktop)
  /// Trả về URL của ảnh đã upload
  Future<String> uploadImageFromPath(String filePath, {String? folder}) async {
    try {
      CloudinaryResponse response = await _cloudinary.uploadFile(
        CloudinaryFile.fromFile(
          filePath,
          folder: folder,
          resourceType: CloudinaryResourceType.Image,
        ),
      );
      return response.secureUrl;
    } catch (e) {
      throw Exception('Lỗi khi upload ảnh lên Cloudinary: $e');
    }
  }

  /// Upload nhiều ảnh cùng lúc từ bytes (dành cho web)
  /// Trả về danh sách URLs
  Future<List<String>> uploadMultipleImagesFromBytes(
    List<Uint8List> imageBytesList,
    List<String> fileNames, {
    String? folder,
  }) async {
    if (imageBytesList.length != fileNames.length) {
      throw Exception('Số lượng ảnh và tên file không khớp');
    }

    List<String> urls = [];
    for (int i = 0; i < imageBytesList.length; i++) {
      try {
        String url = await uploadImageFromBytes(
          imageBytesList[i],
          fileNames[i],
          folder: folder,
        );
        urls.add(url);
      } catch (e) {
        // Có thể log error nhưng vẫn tiếp tục upload các ảnh còn lại
        print('Lỗi upload ảnh ${fileNames[i]}: $e');
      }
    }
    return urls;
  }

  /// Upload nhiều ảnh cùng lúc từ file paths (dành cho mobile/desktop)
  /// Trả về danh sách URLs
  Future<List<String>> uploadMultipleImagesFromPath(
    List<String> filePaths, {
    String? folder,
  }) async {
    List<String> urls = [];
    for (int i = 0; i < filePaths.length; i++) {
      try {
        String url = await uploadImageFromPath(filePaths[i], folder: folder);
        urls.add(url);
      } catch (e) {
        // Có thể log error nhưng vẫn tiếp tục upload các ảnh còn lại
        print('Lỗi upload ảnh ${filePaths[i]}: $e');
      }
    }
    return urls;
  }

  /// Lấy URL ảnh với transformation (resize, crop, etc.)
  String getTransformedImageUrl(
    String publicId, {
    int? width,
    int? height,
    String? crop,
    String? gravity,
    int? quality,
  }) {
    String transformations = '';

    if (width != null) transformations += 'w_$width,';
    if (height != null) transformations += 'h_$height,';
    if (crop != null) transformations += 'c_$crop,';
    if (gravity != null) transformations += 'g_$gravity,';
    if (quality != null) transformations += 'q_$quality,';

    // Xóa dấu phẩy cuối cùng
    if (transformations.isNotEmpty) {
      transformations = transformations.substring(
        0,
        transformations.length - 1,
      );
    }

    return 'https://res.cloudinary.com/$_cloudName/image/upload/$transformations/$publicId';
  }

  /// Lấy thumbnail URL
  String getThumbnailUrl(String publicId, {int size = 200}) {
    return getTransformedImageUrl(
      publicId,
      width: size,
      height: size,
      crop: 'fill',
      gravity: 'auto',
      quality: 80,
    );
  }
}
