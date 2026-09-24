// 异步日志文件写入器：维护有界队列、串行 IO、文件轮转和可等待的 flush。
import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:io';

/// 单文件写入与轮转配置。
final class LogFileWriterConfiguration {
  /// 创建文件写入配置。
  const LogFileWriterConfiguration({
    this.maxFileBytes = 2 * 1024 * 1024,
    this.maxRotatedFiles = 5,
    this.maxQueueLength = 1000,
  }) : assert(maxFileBytes > 0),
       assert(maxRotatedFiles >= 0),
       assert(maxQueueLength > 0);

  /// 单个日志文件的最大字节数。
  final int maxFileBytes;

  /// 除当前文件外最多保留的轮转文件数。
  final int maxRotatedFiles;

  /// 磁盘写入受阻时允许等待的最大日志行数。
  final int maxQueueLength;
}

/// 将日志行异步追加到本地文件，并按容量轮转旧文件。
///
/// 文件 IO 由 Dart `IOSink` 异步完成；单 isolate 内的队列保证日志顺序，队列满时
/// 丢弃新日志并通过 `onError` 报告，避免日志异常反向阻塞业务请求。
final class LogFileWriter {
  /// 创建异步日志文件写入器。
  LogFileWriter({
    required this.directory,
    this.configuration = const LogFileWriterConfiguration(),
    this.onError,
  });

  /// 日志文件所在目录。
  final Directory directory;

  /// 文件大小、归档保留数量及待写队列上限。
  final LogFileWriterConfiguration configuration;

  /// 文件 IO 失败的隔离回调。
  final void Function(Object error, StackTrace stackTrace)? onError;

  /// 尚未由文件 sink 消费的单行日志。
  final Queue<String> _pending = Queue<String>();

  /// 当前文件的异步 sink。
  IOSink? _sink;

  /// 已写入或已提交给 sink 的当前文件字节数，避免异步写入时用磁盘长度作轮转判断。
  int _currentBytes = 0;

  /// 同一进程内为归档文件提供无冲突后缀。
  int _archiveSequence = 0;

  /// 串行泵正在工作时为 true。
  bool _draining = false;

  /// 当前 drain 完成通知，用于等待 flush 而不轮询。
  Completer<void>? _drainCompleter;

  /// 写入器已经关闭时为 true。
  bool _closed = false;

  /// 当前文件路径。
  String get currentFilePath => '${directory.path}/latest.log';

  /// 创建日志目录并打开当前文件。
  Future<void> initialize() async {
    await directory.create(recursive: true);
    final current = File(currentFilePath);
    _currentBytes = current.existsSync() ? current.lengthSync() : 0;
    _sink = current.openWrite(mode: FileMode.writeOnlyAppend);
  }

  /// 将单条日志加入有界异步队列。
  void write(String line) {
    if (_closed) {
      return;
    }
    if (_pending.length >= configuration.maxQueueLength) {
      _report(StateError('日志待写队列已满，丢弃一条日志。'), StackTrace.current);
      return;
    }
    _pending.addLast(line);
    _scheduleDrain();
  }

  /// 等待已接收日志落盘并刷新 sink。
  Future<void> flush() async {
    while (_draining || _pending.isNotEmpty) {
      if (!_draining) {
        _scheduleDrain();
      }
      final completion = _drainCompleter;
      if (completion != null) {
        await completion.future;
      }
    }
    await _sink?.flush();
  }

  /// 刷新并释放文件 sink；重复关闭是安全的。
  Future<void> close() async {
    if (_closed) {
      return;
    }
    await flush();
    _closed = true;
    await _sink?.flush();
    await _sink?.close();
    _sink = null;
  }

  /// 启动唯一的串行队列消费者。
  void _scheduleDrain() {
    if (_draining) {
      return;
    }
    _draining = true;
    _drainCompleter = Completer<void>();
    unawaited(_drain());
  }

  /// 串行写入队列内容，IO 失败不会向业务调用方传播。
  Future<void> _drain() async {
    try {
      while (_pending.isNotEmpty) {
        final line = _pending.removeFirst();
        final lineBytes = utf8.encode('$line\n').length;
        await _rotateIfNeeded(lineBytes);
        _sink!.writeln(line);
        _currentBytes += lineBytes;
      }
      await _sink?.flush();
    } on Object catch (error, stackTrace) {
      _report(error, stackTrace);
      // 磁盘不可写时丢弃当前队列，保留业务线程可继续运行的边界。
      _pending.clear();
    } finally {
      _draining = false;
      _drainCompleter?.complete();
      _drainCompleter = null;
      if (_pending.isNotEmpty && !_closed) {
        _scheduleDrain();
      }
    }
  }

  /// 写入前检查容量并轮转当前文件。
  Future<void> _rotateIfNeeded(int lineBytes) async {
    final file = File(currentFilePath);
    if (_currentBytes == 0 ||
        _currentBytes + lineBytes <= configuration.maxFileBytes) {
      return;
    }

    await _sink?.flush();
    await _sink?.close();
    _sink = null;
    final timestamp = DateTime.now().toUtc().toIso8601String().replaceAll(
      RegExp('[^0-9]'),
      '',
    );
    final archive = File(
      '${directory.path}/$timestamp-${_archiveSequence++}.log',
    );
    await file.rename(archive.path);
    await _pruneArchives();
    _sink = File(currentFilePath).openWrite(mode: FileMode.writeOnlyAppend);
    _currentBytes = 0;
  }

  /// 删除超过保留上限的最旧归档。
  Future<void> _pruneArchives() async {
    final archives = <File>[];
    await for (final entity in directory.list()) {
      if (entity is File &&
          entity.path.endsWith('.log') &&
          entity.path != currentFilePath) {
        archives.add(entity);
      }
    }
    archives.sort((left, right) => left.path.compareTo(right.path));
    final overflow = archives.length - configuration.maxRotatedFiles;
    for (final archive in archives.take(overflow > 0 ? overflow : 0)) {
      await archive.delete();
    }
  }

  /// 隔离日志错误观察器自身的异常。
  void _report(Object error, StackTrace stackTrace) {
    try {
      onError?.call(error, stackTrace);
    } on Object {
      // 错误观察器不得影响应用运行或日志队列清理。
    }
  }
}
