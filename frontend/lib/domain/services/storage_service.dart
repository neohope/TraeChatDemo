import '../../utils/result.dart';

/// 存储服务接口
/// 
/// 定义了文件上传和下载的方法
abstract class StorageService {
  /// 上传文件
  /// 
  /// [filePath] 本地文件路径
  /// [fileType] 文件类型，如'image'、'audio'、'video'、'file'
  /// 返回上传后的文件URL
  Future<Result<String>> uploadFile({
    required String filePath,
    required String fileType,
  });
  
  /// 下载文件
  /// 
  /// [fileUrl] 文件URL
  /// [localPath] 保存到本地的路径
  /// 返回下载后的本地文件路径
  Future<Result<String>> downloadFile({
    required String fileUrl,
    required String localPath,
  });
  
  /// 删除文件
  /// 
  /// [fileUrl] 要删除的文件URL
  Future<Result<void>> deleteFile(String fileUrl);
  
  /// 获取文件信息
  /// 
  /// [fileUrl] 文件URL
  /// 返回文件信息，包括大小、类型等
  Future<Result<Map<String, dynamic>>> getFileInfo(String fileUrl);
  
  /// 生成缩略图
  /// 
  /// [fileUrl] 原始图片URL
  /// [width] 缩略图宽度
  /// [height] 缩略图高度
  /// 返回缩略图URL
  Future<Result<String>> generateThumbnail({
    required String fileUrl,
    required int width,
    required int height,
  });
}