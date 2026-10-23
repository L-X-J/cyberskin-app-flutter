// 已展示弹窗广告 ID 的持久化存储，基于 SharedPreferences。
import 'package:shared_preferences/shared_preferences.dart';

/// 跨会话记录用户已看过的弹窗广告 ID，防止重复展示。
final class SeenAdStore {
  static const String _key = 'seen_popup_ad_ids';

  /// 判断指定广告是否已被用户看过。
  Future<bool> isSeen(int id) async {
    final prefs = await SharedPreferences.getInstance();
    final ids = prefs.getStringList(_key) ?? <String>[];
    return ids.contains(id.toString());
  }

  /// 将指定广告标记为已看过；重复调用幂等。
  Future<void> markSeen(int id) async {
    final prefs = await SharedPreferences.getInstance();
    final ids = List<String>.from(prefs.getStringList(_key) ?? <String>[]);
    final key = id.toString();
    if (!ids.contains(key)) {
      ids.add(key);
      await prefs.setStringList(_key, ids);
    }
  }
}
