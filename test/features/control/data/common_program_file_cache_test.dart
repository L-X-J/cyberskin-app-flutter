// 文件缓存的有效期和完整程序来源回归，不连接平台设备或真实网络。
import 'dart:convert';
import 'dart:io';

import 'package:cyberskin_app/features/control/data/common_program_file_cache.dart';
import 'package:cyberskin_app/features/rhythm/domain/entities/rhythm.dart';
import 'package:flutter/services.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_test/flutter_test.dart';

class _Cache extends Fake implements BaseCacheManager {
  FileInfo? value;
  Duration? writtenMaxAge;
  String? writtenUrl;
  Uint8List? writtenBytes;
  int removals = 0;

  @override
  Future<FileInfo?> getFileFromCache(
    String key, {
    bool ignoreMemCache = false,
  }) async => value;

  @override
  Future<void> removeFile(String key) async {
    value = null;
    removals++;
  }

  @override
  Future<Never> putFile(
    String url,
    Uint8List fileBytes, {
    String? key,
    String? eTag,
    Duration maxAge = const Duration(days: 30),
    String fileExtension = 'file',
  }) async {
    writtenUrl = url;
    writtenMaxAge = maxAge;
    writtenBytes = fileBytes;
    // 模拟磁盘不可写，同时核对生产代码交给 CacheManager 的缓存参数。
    throw const FileSystemException('Read-only test cache');
  }
}

class _Downloads extends FileService {
  String? url;
  bool offline = false;
  List<Object> rows = List.generate(
    4,
    (i) => <String, Object>{
      'start-end': '00:0$i-00:0${i + 1}',
      'des': 'Segment $i',
      'command_data': 't:50',
    },
  );

  @override
  Future<FileServiceResponse> get(
    String url, {
    Map<String, String>? headers,
  }) async {
    this.url = url;
    expect(headers?.keys, ['Accept']);
    if (offline) throw const SocketException('Offline');
    return _Response(Uint8List.fromList(utf8.encode(jsonEncode(rows))));
  }
}

class _Response implements FileServiceResponse {
  _Response(this.bytes);
  final Uint8List bytes;
  @override
  Stream<List<int>> get content => Stream.value(bytes);
  @override
  int get contentLength => bytes.length;
  @override
  int get statusCode => 200;
  @override
  String? get eTag => null;
  @override
  String get fileExtension => '.json';
  @override
  DateTime get validTill => DateTime.now().add(const Duration(days: 365));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const url = 'https://store.example/program.json';
  late Directory directory;
  late _Cache cache;
  late _Downloads downloads;
  late CommonProgramFileCache files;

  setUp(() async {
    directory = await Directory.systemTemp.createTemp(
      'cyberskin_program_cache_',
    );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/path_provider'),
          (call) async => directory.path,
        );
    cache = _Cache();
    downloads = _Downloads();
    files = CommonProgramFileCache(cache: cache, downloads: downloads);
  });
  tearDown(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/path_provider'),
          null,
        );
    await directory.delete(recursive: true);
  });

  Future<void> seed(Duration remaining) async {
    final file = await IOFileSystem('programs').createFile('program.json');
    await file.writeAsString(jsonEncode(downloads.rows));
    cache.value = FileInfo(
      file,
      FileSource.Cache,
      DateTime.now().add(remaining),
      url,
    );
  }

  test('下载全部4段，缓存稳定URL且有效期不被服务端365天延长', () async {
    final cues = await files.load(url: url, downloadUrl: '$url?signature=new');
    expect(cues, hasLength(4));
    expect(downloads.url, '$url?signature=new');
    expect(cache.writtenUrl, url);
    expect(cache.writtenMaxAge, const Duration(days: 30));
    expect(jsonDecode(utf8.decode(cache.writtenBytes!)), downloads.rows);
    final preview = Rhythm(
      segmentCount: 4,
      previewSegments: cues
          .take(3)
          .map((s) => RhythmSegment(s.toJson()))
          .toList(),
    );
    expect(preview.segments, isEmpty);
    expect(preview.hasCompleteProgram, isFalse);
  });

  test('有效缓存不下载、不因读取或签名更新续期', () async {
    await seed(const Duration(days: 1));
    final expires = cache.value!.validTill;
    expect(
      await files.load(url: url, downloadUrl: '$url?signature=changed'),
      hasLength(4),
    );
    expect(downloads.url, isNull);
    expect(cache.writtenMaxAge, isNull);
    expect(cache.value!.validTill, expires);
  });

  test('到期缓存移除，断网也不回退播放旧文件', () async {
    await seed(const Duration(seconds: -1));
    downloads.offline = true;
    expect(await files.readCached(url), isNull);
    expect(cache.removals, 1);
    await expectLater(
      files.load(url: url, downloadUrl: url),
      throwsA(isA<SocketException>()),
    );
  });

  test('非标准JSON拒绝并且不写入缓存', () async {
    downloads.rows = [
      {'durationSec': 1, 'channels': <Object>[]},
    ];
    await expectLater(
      files.load(url: url, downloadUrl: url),
      throwsFormatException,
    );
    expect(cache.writtenBytes, isNull);
  });
}
