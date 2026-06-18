import 'package:flutter/services.dart';

class ExportedTimetableFile {
  const ExportedTimetableFile({
    required this.fileName,
    required this.displayPath,
  });

  final String fileName;
  final String displayPath;
}

class PickedTimetableJsonFile {
  const PickedTimetableJsonFile({required this.fileName, required this.json});

  final String fileName;
  final String json;
}

class AndroidTimetableFileGateway {
  const AndroidTimetableFileGateway({
    MethodChannel channel = const MethodChannel(channelName),
  }) : _channel = channel;

  static const String channelName = 'kiro_time/timetable_files';

  final MethodChannel _channel;

  Future<ExportedTimetableFile> exportTimetableJson({
    required String fileName,
    required String json,
    required bool overwrite,
  }) async {
    final result = await _channel.invokeMapMethod<String, Object?>(
      'exportTimetableJson',
      <String, Object?>{
        'fileName': fileName,
        'json': json,
        'overwrite': overwrite,
      },
    );
    if (result == null) {
      throw const FormatException('Android 导出没有返回文件信息');
    }
    return ExportedTimetableFile(
      fileName: result['fileName']?.toString() ?? fileName,
      displayPath: result['displayPath']?.toString() ?? 'Download/KiroTime',
    );
  }

  Future<PickedTimetableJsonFile?> pickTimetableJson() async {
    final result = await _channel.invokeMapMethod<String, Object?>(
      'pickTimetableJson',
    );
    if (result == null) {
      return null;
    }
    return PickedTimetableJsonFile(
      fileName: result['fileName']?.toString() ?? 'unknown.json',
      json: result['json']?.toString() ?? '',
    );
  }

  Future<bool> fileExistsInDownloads(String fileName) async {
    final result = await _channel.invokeMethod<bool>(
      'fileExistsInDownloads',
      <String, Object?>{'fileName': fileName},
    );
    return result ?? false;
  }
}
