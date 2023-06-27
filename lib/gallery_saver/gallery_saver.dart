import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:gallery_saver/files.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart';

import 'files.dart';

class StringTuple {
  String firstTuple;
  String secondTuple;

  StringTuple(this.firstTuple, this.secondTuple);
}

class GallerySaver {
  static const String channelName = 'gallery_saver';
  static const String methodSaveImage = 'saveImage';
  static const String methodSaveVideo = 'saveVideo';

  static const String pleaseProvidePath = 'Please provide valid file path.';
  static const MethodChannel _channel = const MethodChannel(channelName);

  static Future<bool?> save(
      String path, {
        String? albumName,
        bool toDcim = false,
        Map<String, String>? headers,
      }) async {
    File? tempFile;
    if (path.isEmpty) {
      throw ArgumentError(pleaseProvidePath);
    }

    final extension_method = identifyExtension(path);

    if (!isLocalFilePath(path)) {
      tempFile = await _downloadFile(path, extension_method.firstTuple, extension_method.secondTuple, headers: headers);
      path = tempFile.path;
    }
    bool? result = await _channel.invokeMethod(
      methodSaveVideo,
      <String, dynamic>{'path': path, 'albumName': albumName, 'toDcim': toDcim},
    );
    if (tempFile != null) {
      tempFile.delete();
    }
    return result;
  }



  /// (file extension, method name)
  static StringTuple identifyExtension(String path) {
    for(int i = 0; i < imageFormats.length; i++) {
      final extension = imageFormats[i];
      if(path.contains(extension)) {
        return StringTuple(extension, methodSaveImage);
      }
    };
    for(int i = 0; i < videoFormats.length; i++) {
      final extension = videoFormats[i];
      if(path.contains(extension)) {
        return StringTuple(extension, methodSaveVideo);
      }
    };
    assert(true);
    return StringTuple('', '');
  }

  static Future<File> _downloadFile(
      String url,
      String extension,
      String method,
      {Map<String, String>? headers}
      ) async {
    print('gallery_saver: ' + url);
    print('gallery_saver: ' + headers.toString());
    http.Client _client = new http.Client();
    var req = await _client.get(Uri.parse(url), headers: headers);
    if (req.statusCode >= 400) {
      throw HttpException(req.statusCode.toString());
    }
    var bytes = req.bodyBytes;
    String dir = (await getTemporaryDirectory()).path;
    File file = new File('$dir/${basename(url, extension)}');
    await file.writeAsBytes(bytes);
    print('gallery_saver: ' + 'File size:${await file.length()}');
    print('gallery_saver: ' + file.path);
    return file;
  }

  static var counter = 0;
  static basename(String url, String extension) {
    counter++;
    return counter.toString() + extension;
  }
}
