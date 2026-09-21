// 显式结果类型：让 Repository 边界明确表达成功值与失败原因。
import '../error/app_failure.dart';

/// 跨 Repository 边界使用的显式成功或失败结果。
sealed class Result<T> {
  const Result._();

  /// 创建成功结果。
  const factory Result.ok(T value) = Success<T>;

  /// 创建失败结果。
  const factory Result.failure(AppFailure failure) = Failure<T>;

  /// 当前结果是否包含成功值。
  bool get isSuccess => this is Success<T>;

  /// 成功时返回对应值，失败时返回 `null`。
  T? get valueOrNull => switch (this) {
    Success<T>(:final value) => value,
    Failure<T>() => null,
  };

  /// 失败时返回对应错误，成功时返回 `null`。
  AppFailure? get failureOrNull => switch (this) {
    Success<T>() => null,
    Failure<T>(:final failure) => failure,
  };
}

/// [Result] 的成功分支。
final class Success<T> extends Result<T> {
  /// 创建成功结果。
  const Success(this.value) : super._();

  /// 成功返回的值。
  final T value;
}

/// [Result] 的失败分支。
final class Failure<T> extends Result<T> {
  /// 创建失败结果。
  const Failure(this.failure) : super._();

  /// 结构化失败信息。
  final AppFailure failure;
}
