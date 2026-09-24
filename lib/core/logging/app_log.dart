// 应用统一日志边界：封装日志框架、异步文件输出、脱敏和接口日志策略。
import 'dart:convert';
import 'dart:io';

import 'package:logger/logger.dart' as logger_package;
import 'package:path_provider/path_provider.dart';

import 'app_log_configuration.dart';
import 'log_file_writer.dart';

/// 业务代码依赖的统一日志接口。
///
/// 第三方日志框架只允许出现在本目录的具体实现中，调用方通过该接口记录日志，
/// 便于测试替换并防止日志框架 API 扩散到业务模块。
abstract interface class AppLog {
  /// 当前是否启用 API 交互汇总日志。
  bool get apiLoggingEnabled;

  /// 记录调试信息。
  void debug(String message, {Object? data});

  /// 记录普通运行信息。
  void info(String message, {Object? data});

  /// 记录可恢复警告。
  void warning(String message, {Object? data, Object? error});

  /// 记录错误与堆栈。
  void error(
    String message, {
    Object? data,
    Object? error,
    StackTrace? stackTrace,
  });

  /// 记录一次完整 API 交互；请求、响应和耗时合并为一条日志。
  ///
  /// 文件传输只记录方法、脱敏请求头、清理后的地址、状态和耗时。
  void apiExchange({
    required String method,
    required Uri uri,
    required Map<String, String> headers,
    Map<String, Object?> pathParameters,
    Map<String, Object?> queryParameters,
    Object? body,
    required int? statusCode,
    required Duration duration,
    Object? response,
    Object? error,
    bool isFileTransfer,
  });

  /// 记录页面路由变化。
  void route({
    required String previous,
    required String current,
    required bool isBack,
    String? removed,
    String? routeType,
  });

  /// 刷新缓冲并释放文件句柄。
  Future<void> close();
}

/// 默认的无操作日志实现，供 Widget 测试和显式禁用场景使用。
final class NoopAppLog implements AppLog {
  /// 创建无操作日志实现。
  const NoopAppLog();

  @override
  bool get apiLoggingEnabled => false;

  @override
  void apiExchange({
    required String method,
    required Uri uri,
    required Map<String, String> headers,
    Map<String, Object?> pathParameters = const <String, Object?>{},
    Map<String, Object?> queryParameters = const <String, Object?>{},
    Object? body,
    required int? statusCode,
    required Duration duration,
    Object? response,
    Object? error,
    bool isFileTransfer = false,
  }) {}

  @override
  Future<void> close() async {}

  @override
  void debug(String message, {Object? data}) {}

  @override
  void error(
    String message, {
    Object? data,
    Object? error,
    StackTrace? stackTrace,
  }) {}

  @override
  void info(String message, {Object? data}) {}

  @override
  void route({
    required String previous,
    required String current,
    required bool isBack,
    String? removed,
    String? routeType,
  }) {}

  @override
  void warning(String message, {Object? data, Object? error}) {}
}

/// 基于 `logger` 的生产日志实现。
///
/// 文件输出使用有界队列和异步 sink，并按大小轮转。普通日志始终进入文件；API
/// 日志额外受 [AppLogConfiguration.apiLoggingEnabled] 控制，并对头部和载荷脱敏。
final class AppLogger implements AppLog {
  AppLogger._({
    required this._logger,
    required this._configuration,
    required this._fileWriter,
  });

  /// 初始化异步文件日志。
  ///
  /// 默认写入 Application Support 下的 `logs/`。单元测试可传入 [logDirectory]
  /// 隔离文件系统；若目录解析或文件初始化失败，则降级为控制台日志，不能阻塞启动。
  static Future<AppLogger> initialize({
    AppLogConfiguration? configuration,
    Directory? logDirectory,
  }) async {
    final resolvedConfiguration =
        configuration ?? AppLogConfiguration.fromEnvironment();
    LogFileWriter? fileWriter;
    try {
      final directory =
          logDirectory ??
          Directory('${(await getApplicationSupportDirectory()).path}/logs');
      fileWriter = LogFileWriter(directory: directory);
      await fileWriter.initialize();
      final outputs = <logger_package.LogOutput>[
        if (resolvedConfiguration.consoleOutputEnabled)
          logger_package.ConsoleOutput(),
        _FileWriterOutput(fileWriter),
      ];
      final packageLogger = _createLogger(outputs);
      await packageLogger.init;
      return AppLogger._(
        logger: packageLogger,
        configuration: resolvedConfiguration,
        fileWriter: fileWriter,
      );
    } on Object catch (initializationError, stackTrace) {
      await fileWriter?.close();
      final fallback = AppLogger._(
        logger: _createLogger(<logger_package.LogOutput>[
          logger_package.ConsoleOutput(),
        ]),
        configuration: resolvedConfiguration,
        fileWriter: null,
      );
      await fallback._logger.init;
      fallback.error(
        '文件日志初始化失败，已降级为控制台输出。',
        error: initializationError,
        stackTrace: stackTrace,
      );
      return fallback;
    }
  }

  /// 创建把每一行交给 [onLine] 的测试日志器。
  static Future<AppLogger> forTesting({
    required void Function(String line) onLine,
    required AppLogConfiguration configuration,
  }) async {
    final packageLogger = _createLogger(<logger_package.LogOutput>[
      _CallbackLogOutput(onLine),
    ]);
    await packageLogger.init;
    return AppLogger._(
      logger: packageLogger,
      configuration: configuration,
      fileWriter: null,
    );
  }

  /// 单条日志允许保留的最大字符串长度，避免接口异常返回撑爆本地文件。
  static const int _maxStringLength = 8000;

  /// 递归序列化允许的最大深度，防止动态对象产生无界日志。
  static const int _maxDepth = 8;

  /// `logger` 框架实例。
  final logger_package.Logger _logger;

  /// 当前运行配置。
  final AppLogConfiguration _configuration;

  /// 当前进程的独立异步文件写入器。
  final LogFileWriter? _fileWriter;

  /// 按调用顺序缓存待异步写盘的日志，避免并发请求在日志中乱序。
  Future<void> _writeQueue = Future<void>.value();

  /// 关闭开始后拒绝新的日志事件。
  bool _closed = false;

  /// 并发关闭调用共享同一个任务。
  Future<void>? _closeFuture;

  @override
  bool get apiLoggingEnabled => _configuration.apiLoggingEnabled;

  /// 创建统一无 ANSI 色彩的日志框架实例。
  static logger_package.Logger _createLogger(
    List<logger_package.LogOutput> outputs,
  ) => logger_package.Logger(
    filter: logger_package.ProductionFilter(),
    printer: logger_package.SimplePrinter(printTime: true, colors: false),
    output: logger_package.MultiOutput(outputs),
    level: logger_package.Level.debug,
  );

  @override
  void apiExchange({
    required String method,
    required Uri uri,
    required Map<String, String> headers,
    Map<String, Object?> pathParameters = const <String, Object?>{},
    Map<String, Object?> queryParameters = const <String, Object?>{},
    Object? body,
    required int? statusCode,
    required Duration duration,
    Object? response,
    Object? error,
    bool isFileTransfer = false,
  }) {
    if (!apiLoggingEnabled) {
      return;
    }
    final payload = <String, Object?>{
      'category': 'api.exchange',
      'method': method,
      'headers': _sanitizeHeaders(headers),
      'url': _safeUrl(uri, isFileTransfer: isFileTransfer),
      if (!isFileTransfer)
        'parameters': _sanitize(<String, Object?>{
          if (pathParameters.isNotEmpty) 'path': pathParameters,
          if (queryParameters.isNotEmpty) 'query': queryParameters,
          'body': ?body,
        }, isRequest: true),
      'statusCode': statusCode,
      'durationMs': duration.inMilliseconds,
      if (!isFileTransfer) 'response': _sanitize(response, isRequest: false),
      if (error != null) 'error': 'request failed',
    };
    _write(() {
      if (error != null || statusCode == null || statusCode >= 400) {
        _logger.e(_encode(payload));
      } else {
        _logger.i(_encode(payload));
      }
    });
  }

  @override
  Future<void> close() => _closeFuture ??= _close();

  /// 停止接收日志，等待队列完成后释放输出资源。
  Future<void> _close() async {
    _closed = true;
    await _writeQueue;
    await _logger.close();
    await _fileWriter?.close();
  }

  @override
  void debug(String message, {Object? data}) =>
      _write(() => _logger.d(_applicationMessage(message, data)));

  @override
  void error(
    String message, {
    Object? data,
    Object? error,
    StackTrace? stackTrace,
  }) => _write(
    () => _logger.e(
      _applicationMessage(message, data),
      error: error,
      stackTrace: stackTrace,
    ),
  );

  @override
  void info(String message, {Object? data}) =>
      _write(() => _logger.i(_applicationMessage(message, data)));

  @override
  void route({
    required String previous,
    required String current,
    required bool isBack,
    String? removed,
    String? routeType,
  }) {
    _write(
      () => _logger.i(
        _encode(<String, Object?>{
          'category': 'route',
          'previous': previous,
          'current': current,
          'isBack': isBack,
          if (removed?.isNotEmpty == true) 'removed': removed,
          if (routeType?.isNotEmpty == true) 'routeType': routeType,
        }),
      ),
    );
  }

  @override
  void warning(String message, {Object? data, Object? error}) =>
      _write(() => _logger.w(_applicationMessage(message, data), error: error));

  /// 串行提交日志到 `logger` 的缓冲输出，文件 IO 由输出 sink 异步完成。
  void _write(void Function() write) {
    if (_closed) {
      return;
    }
    _writeQueue = _writeQueue.then((_) {
      write();
    });
  }

  /// 将普通应用日志编码为统一结构。
  String _applicationMessage(String message, Object? data) =>
      _encode(<String, Object?>{
        'category': 'app',
        'message': message,
        if (data case final value?) 'data': _sanitize(value, isRequest: false),
      });

  /// 将结构化日志编码为单行 JSON，便于后续导出和检索。
  String _encode(Map<String, Object?> value) => jsonEncode(value);

  /// URL 中的 query 可能携带邮箱或短时签名，文件传输一律丢弃 query。
  String _safeUrl(Uri uri, {required bool isFileTransfer}) {
    final cleaned = uri.replace(
      userInfo: '',
      fragment: '',
      query: isFileTransfer ? '' : null,
      queryParameters: isFileTransfer
          ? null
          : <String, String>{
              for (final entry in uri.queryParameters.entries)
                entry.key: _isSensitiveField(entry.key, isRequest: true)
                    ? '<redacted>'
                    : _truncate(entry.value),
            },
    );
    return cleaned.toString();
  }

  /// 对请求头做大小写无关脱敏。
  Map<String, String> _sanitizeHeaders(Map<String, String> headers) =>
      headers.map((key, value) {
        final normalized = key.toLowerCase();
        final sensitive =
            normalized == 'authorization' ||
            normalized == 'clientid' ||
            normalized == 'cookie' ||
            normalized == 'set-cookie' ||
            normalized.contains('token') ||
            normalized.contains('identity') ||
            normalized.contains('secret') ||
            normalized.contains('password') ||
            normalized.contains('api-key');
        return MapEntry(key, sensitive ? '<redacted>' : _truncate(value));
      });

  /// 递归脱敏动态 JSON 数据，并限制深度、集合长度和字符串长度。
  Object? _sanitize(Object? value, {required bool isRequest, int depth = 0}) {
    if (value == null || value is num || value is bool) {
      return value;
    }
    if (depth >= _maxDepth) {
      return '<truncated: max depth>';
    }
    if (value is String) {
      return _truncate(
        value.replaceAll(
          RegExp(r'[\w.+-]+@[\w.-]+\.[A-Za-z]{2,}'),
          '<redacted>',
        ),
      );
    }
    if (value is Map) {
      final result = <String, Object?>{};
      var count = 0;
      for (final entry in value.entries) {
        if (count >= 100) {
          result['<truncated>'] = '${value.length - count} more entries';
          break;
        }
        final key = entry.key.toString();
        result[key] = _isSensitiveField(key, isRequest: isRequest)
            ? '<redacted>'
            : _sanitize(entry.value, isRequest: isRequest, depth: depth + 1);
        count++;
      }
      return result;
    }
    if (value is Iterable) {
      return value
          .take(100)
          .map(
            (item) => _sanitize(item, isRequest: isRequest, depth: depth + 1),
          )
          .toList(growable: false);
    }
    return _truncate(value.toString());
  }

  /// 判断动态字段是否包含凭证、验证码或个人身份信息。
  bool _isSensitiveField(String key, {required bool isRequest}) {
    final normalized = key.toLowerCase().replaceAll(RegExp('[^a-z0-9]'), '');
    if (normalized.contains('password') ||
        normalized.contains('secret') ||
        normalized.contains('token') ||
        normalized == 'authorization' ||
        normalized == 'clientid' ||
        normalized.contains('cookie') ||
        normalized == 'uploadurl' ||
        normalized == 'objectkey' ||
        normalized == 'filename' ||
        normalized == 'nickname' ||
        normalized == 'fullname' ||
        normalized == 'content' ||
        normalized == 'imageurls' ||
        normalized == 'avatarurl') {
      return true;
    }
    return normalized == 'email' || (isRequest && normalized == 'code');
  }

  /// 限制单个字符串写入长度。
  String _truncate(String value) {
    if (value.length <= _maxStringLength) {
      return value;
    }
    return '${value.substring(0, _maxStringLength)}<truncated>';
  }
}

/// 测试专用输出，把框架格式化后的每一行交给回调。
final class _CallbackLogOutput extends logger_package.LogOutput {
  /// 创建回调输出。
  _CallbackLogOutput(this._onLine);

  /// 日志行接收器。
  final void Function(String line) _onLine;

  @override
  void output(logger_package.OutputEvent event) {
    for (final line in event.lines) {
      _onLine(line);
    }
  }
}

/// 将格式化日志行交给独立的异步文件队列。
final class _FileWriterOutput extends logger_package.LogOutput {
  /// 创建异步文件输出。
  _FileWriterOutput(this._writer);

  /// 持有文件生命周期的写入器。
  final LogFileWriter _writer;

  @override
  void output(logger_package.OutputEvent event) {
    for (final line in event.lines) {
      _writer.write(line);
    }
  }
}
