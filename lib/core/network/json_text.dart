// JSON 文本提取与解析：隔离模型回复或外部文本包裹 JSON 时的容错规则。
import 'dart:convert';

/// JSON 文本的受控提取能力。
///
/// 该方法只处理常见的 Markdown 代码块或前后说明文本，不尝试修复非法 JSON；无法提取
/// 或解析失败时返回 `null`，避免把不确定内容继续传入业务层。
abstract final class JsonText {
  /// 从文本中提取第一个完整 JSON 对象并解析。
  static Map<String, dynamic>? tryDecodeObject(String source) {
    final candidate = _extractCandidate(source);
    if (candidate == null) {
      return null;
    }
    try {
      final decoded = jsonDecode(candidate);
      return decoded is Map<String, dynamic> ? decoded : null;
    } on FormatException {
      return null;
    }
  }

  /// 判断字符串本身是否可解析为 JSON 值。
  static bool isValid(String source) {
    try {
      jsonDecode(source);
      return true;
    } on FormatException {
      return false;
    }
  }

  static String? _extractCandidate(String source) {
    final text = source.trim();
    if (text.isEmpty) {
      return null;
    }

    final firstObject = text.indexOf('{');
    final lastObject = text.lastIndexOf('}');
    if (firstObject != -1 && lastObject >= firstObject) {
      return text.substring(firstObject, lastObject + 1).trim();
    }

    final firstArray = text.indexOf('[');
    final lastArray = text.lastIndexOf(']');
    if (firstArray != -1 && lastArray >= firstArray) {
      return text.substring(firstArray, lastArray + 1).trim();
    }
    return null;
  }
}
