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
        // 同一会话已有活动时只更新，不重复创建。
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

        // iOS 16.2+ 提供更细粒度的授权状态。
        // areActivitiesEnabled 为 false 时说明用户在「设置」里关闭了该 App 的 Live Activity，
        // 此时打印提示而非静默忽略，方便排查。
        // areActivitiesEnabled 为 false 表示用户在「设置」里关闭了该 App 的 Live Activity，
        // 或设备/系统不支持。iOS 系统在首次 Activity.request() 时自动弹授权提示，无需主动申请。
        let info = ActivityAuthorizationInfo()
        guard info.areActivitiesEnabled else {
            print("[PlaybackActivity] Live Activities not enabled — check Settings → Cyberskin → Live Activities, and that NSSupportsLiveActivities is set in Info.plist with a Widget Extension target present")
            return
        }

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
            print("[PlaybackActivity] Live Activity started: id=\(activity?.id ?? "nil"), title=\(title)")
        } catch {
            // 最常见原因：Widget Extension target 未建立，或 Info.plist 缺少 NSSupportsLiveActivities。
            print("[PlaybackActivity] Activity.request() failed: \(error)")
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
