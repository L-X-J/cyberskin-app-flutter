// API JSON 的类型校验、兼容字段读取与统一布尔值解码。

/// App API 兼容 JSON 数据的受控读取函数集合。
///
/// 所有 DTO 都通过本类保留未知字段并在必填字段异常时抛出 [FormatException]，
/// 以避免脏数据被静默转换成错误的业务状态。
abstract final class ApiJson {
  /// 将动态对象转换为字符串键 JSON 对象。
  static Map<String, dynamic> object(Object? value, {String field = 'data'}) {
    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }
    throw FormatException('$field 必须是 JSON 对象。');
  }

  /// 将动态对象转换为 JSON 对象列表。
  static List<Map<String, dynamic>> objectList(
    Object? value, {
    String field = 'data',
  }) {
    if (value is! List) {
      throw FormatException('$field 必须是 JSON 数组。');
    }
    return value
        .map((item) => object(item, field: '$field 元素'))
        .toList(growable: false);
  }

  /// 读取可选字符串；非字符串值视为无效契约。
  static String? string(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value == null) {
      return null;
    }
    if (value is String) {
      return value;
    }
    throw FormatException('$key 必须是字符串。');
  }

  /// 读取必填字符串。
  static String requiredString(Map<String, dynamic> json, String key) {
    final value = string(json, key);
    if (value == null) {
      throw FormatException('$key 为必填字段。');
    }
    return value;
  }

  /// 读取兼容整数；JSON 数字必须没有小数部分。
  static int? integer(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value == null) {
      return null;
    }
    if (value is int) {
      return value;
    }
    if (value is num && value == value.roundToDouble()) {
      return value.toInt();
    }
    if (value is String) {
      final parsed = int.tryParse(value);
      if (parsed != null) {
        return parsed;
      }
      throw FormatException('$key 必须是整数。');
    }
    throw FormatException('$key 必须是整数。');
  }

  /// 读取必填整数。
  static int requiredInteger(Map<String, dynamic> json, String key) {
    final value = integer(json, key);
    if (value == null) {
      throw FormatException('$key 为必填字段。');
    }
    return value;
  }

  /// 统一读取布尔值，兼容 `bool`、`0/1`、`true/false` 与 `Y/N`。
  ///
  /// 缺失字段由调用方提供 fail-closed 默认值；其他无法识别值必须显式失败，
  /// 防止服务端变更被误展示为功能已开启。
  static bool? boolean(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value == null) {
      return null;
    }
    if (value is bool) {
      return value;
    }
    if (value is num && (value == 0 || value == 1)) {
      return value == 1;
    }
    if (value is String) {
      return switch (value.trim().toLowerCase()) {
        'true' || '1' || 'y' => true,
        'false' || '0' || 'n' => false,
        _ => throw FormatException('$key 不是可识别的布尔值。'),
      };
    }
    throw FormatException('$key 必须是布尔兼容值。');
  }

  /// 深拷贝开放 JSON 对象，避免调用方持有可变传输层引用。
  static Map<String, dynamic> additionalProperties(
    Map<String, dynamic> json,
    Set<String> knownKeys,
  ) => Map<String, dynamic>.unmodifiable(
    Map<String, dynamic>.fromEntries(
      json.entries.where((entry) => !knownKeys.contains(entry.key)),
    ),
  );
}
