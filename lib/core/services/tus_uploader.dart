import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:hb_social/core/services/app_exception.dart';

class TusUploadConfig {
  final Uri endpoint;
  final int chunkBytes;
  final Map<String, String> headers;

  const TusUploadConfig({required this.endpoint, required this.chunkBytes, required this.headers});

  factory TusUploadConfig.fromJson(Map<String, dynamic> json) => TusUploadConfig(
    endpoint: Uri.parse(json['endpoint'].toString()),
    chunkBytes: (json['chunk_bytes'] as num?)?.toInt() ?? 8 * 1024 * 1024,
    headers: {for (final entry in Map<String, dynamic>.from(json['headers'] as Map? ?? const {}).entries) entry.key: entry.value.toString()},
  );
}

class TusUploader {
  final Dio _dio;
  const TusUploader(this._dio);

  Future<Uri> upload({required TusUploadConfig config, required Uint8List bytes, required String fileName, required String mimeType, required ValueChanged<double> onProgress, CancelToken? cancelToken}) async {
    final response = await _dio.postUri<void>(config.endpoint, data: Stream<List<int>>.value(const []), cancelToken: cancelToken, options: Options(headers: {
      ...config.headers,
      'Tus-Resumable': '1.0.0',
      'Upload-Length': '${bytes.length}',
      'Upload-Metadata': 'filetype ${base64Encode(utf8.encode(mimeType))},title ${base64Encode(utf8.encode(fileName))}',
    }, validateStatus: (status) => status == 201));
    final location = response.headers.value('location');
    if (location == null || location.isEmpty) throw const AppException('reels.errors.upload_failed');
    final uploadUri = config.endpoint.resolve(location);
    var offset = 0;
    while (offset < bytes.length) {
      final end = (offset + config.chunkBytes).clamp(0, bytes.length);
      final chunk = Uint8List.sublistView(bytes, offset, end);
      offset = await _patchWithResume(uploadUri, chunk, offset, cancelToken);
      onProgress(offset / bytes.length);
    }
    return uploadUri;
  }

  Future<int> _patchWithResume(Uri location, Uint8List chunk, int offset, CancelToken? cancelToken) async {
    const delays = [2, 4, 8];
    for (var attempt = 0; attempt <= delays.length; attempt++) {
      try {
        final response = await _dio.patchUri<void>(location, data: Stream<List<int>>.value(chunk), cancelToken: cancelToken, options: Options(headers: {'Tus-Resumable': '1.0.0', 'Upload-Offset': '$offset', 'Content-Type': 'application/offset+octet-stream', 'Content-Length': '${chunk.length}'}, validateStatus: (status) => status == 204));
        return int.tryParse(response.headers.value('upload-offset') ?? '') ?? offset + chunk.length;
      } on DioException catch (error) {
        if (CancelToken.isCancel(error)) rethrow;
        if (attempt == delays.length) throw const AppException('reels.errors.upload_failed');
        await Future<void>.delayed(Duration(seconds: delays[attempt]));
        final remoteOffset = await _remoteOffset(location, cancelToken);
        if (remoteOffset != offset) return remoteOffset;
      }
    }
    throw const AppException('reels.errors.upload_failed');
  }

  Future<int> _remoteOffset(Uri location, CancelToken? cancelToken) async {
    final response = await _dio.headUri<void>(location, cancelToken: cancelToken, options: Options(headers: const {'Tus-Resumable': '1.0.0'}, validateStatus: (status) => status == 200 || status == 204));
    return int.tryParse(response.headers.value('upload-offset') ?? '') ?? 0;
  }
}