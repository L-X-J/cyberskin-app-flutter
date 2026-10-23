import ActivityKit
import Flutter
import Foundation

// cyberskin/now_playing 通道的接收端；管理 Live Activity 生命周期。
// iOS 16.1+ 可用；旧版本所有调用静默跳过，不影响其他功能。

/// 应用侧 Live Activity 管理器；由 AppDelegate 创建并注册通道。
@available(iOS 16.1, *)
final class PlaybackActivityManager {
    private var activity: Activity<PlaybackActivityAttributes>?

    /// 注册到 Flutter 引擎的方法通道处理器。
    func register(binaryMessenger messenger: FlutterBinaryMessenger) {
        let channel = FlutterMethodChannel(
            name: "cyberskin/now_playing",
            binaryMessenger: messenger
        )
        channel.setMethodCallHandler { [weak self] call, result in
            self?.handle(call, result: result)
        }
    }

    private func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        let args = call.arguments as? [String: Any]
        switch call.method {
        case "start":
            start(
                title: args?["title"] as? String ?? "Cyberskin",
                source: args?["source"] as? String ?? "",
                totalSeconds: args?["totalSeconds"] as? Int ?? 0,
                remainingSeconds: args?["remainingSeconds"] as? Int ?? 0,
                phase: args?["phase"] as? String ?? "running"
            )
            result(nil)
        case "update":
            update(
                remainingSeconds: args?["remainingSeconds"] as? Int ?? 0,
                phase: args?["phase"] as? String ?? "running"
            )
            result(nil)
        case "end":
            end()
            result(nil)
        default:
            result(FlutterMethodNotImplemented)
        }
    }

    private func start(
        title: String,
        source: String,
        totalSeconds: Int,
        remainingSeconds: Int,
        phase: String
    ) {
        // 同一会话已有活动时只更新；不允许同时存在两个 Live Activity。
        if let existing = activity {
            Task {
                await existing.update(
                    ActivityContent(
                        state: PlaybackActivityAttributes.ContentState(
                            remainingSeconds: remainingSeconds,
                            phase: phase
                        ),
                        staleDate: nil
                    )
                )
            }
            return
        }

        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }

        let attrs = PlaybackActivityAttributes(
            title: title,
            source: source,
            totalSeconds: totalSeconds
        )
        let state = PlaybackActivityAttributes.ContentState(
            remainingSeconds: remainingSeconds,
            phase: phase
        )
        let content = ActivityContent(state: state, staleDate: nil)
        do {
            activity = try Activity.request(
                attributes: attrs,
                content: content,
                pushType: nil
            )
        } catch {
            // 设备不支持 Live Activity 时静默跳过（如 iPhone SE 无灵动岛仍可锁屏显示）。
        }
    }

    private func update(remainingSeconds: Int, phase: String) {
        guard let existing = activity else { return }
        let state = PlaybackActivityAttributes.ContentState(
            remainingSeconds: remainingSeconds,
            phase: phase
        )
        Task {
            await existing.update(
                ActivityContent(state: state, staleDate: nil)
            )
        }
    }

    private func end() {
        guard let existing = activity else { return }
        activity = nil
        Task {
            await existing.end(nil, dismissalPolicy: .immediate)
        }
    }
}
