// 节奏列表加载、删除及错误状态编排。
import 'package:get/get.dart';

import '../../../domain/entities/rhythm.dart';
import '../../../domain/repositories/rhythm_repository.dart';

/// 管理当前账号节奏列表和接口请求状态。
final class RhythmHomeController extends GetxController {
  /// 创建实例；依赖及初始状态由调用方提供。
  RhythmHomeController(this.repository);

  /// 节奏持久化的唯一访问入口。
  final RhythmRepository repository;

  /// 当前账号的节奏列表。
  final items = <Rhythm>[].obs;

  /// 加载中、保存中及草稿变更等独立操作状态。
  final loading = false.obs, acting = false.obs;

  /// 可展示错误及名称字段错误，互不覆盖。
  final error = RxnString();
  @override
  void onInit() {
    super.onInit();
    refreshList();
  }

  /// 刷新列表，失败保留已有内容供重试。
  Future<void> refreshList() async {
    if (loading.value) return;
    loading.value = true;
    error.value = null;
    final result = await repository.list();
    if (isClosed) return;
    if (result.isSuccess) {
      items.assignAll(result.valueOrNull!);
    } else {
      error.value = result.failureOrNull!.message;
    }
    loading.value = false;
  }

  /// 读取最新节奏详情后再进入运行或编辑。
  Future<Rhythm?> detail(Rhythm item) async {
    if (acting.value || item.id == null) return null;
    acting.value = true;
    final result = await repository.getById(item.id!);
    acting.value = false;
    if (isClosed) return null;
    if (result.isFailure) error.value = result.failureOrNull!.message;
    return result.valueOrNull;
  }

  /// 远端删除成功后才移除列表项。
  Future<void> delete(Rhythm item) async {
    if (acting.value || item.id == null) return;
    acting.value = true;

    final result = await repository.delete(item.id!);
    acting.value = false;
    if (result.isSuccess) {
      items.removeWhere((r) => r.id == item.id);
    } else {
      error.value = result.failureOrNull!.message;
    }
  }
}
