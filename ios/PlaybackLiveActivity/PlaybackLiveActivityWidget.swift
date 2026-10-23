import ActivityKit
import SwiftUI
import WidgetKit

// 灵动岛和锁屏 Live Activity 视图；使用 PlaybackActivityAttributes 的共享模型。

@main
struct PlaybackLiveActivityBundle: WidgetBundle {
    var body: some Widget {
        PlaybackLiveActivityWidget()
    }
}

struct PlaybackLiveActivityWidget: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: PlaybackActivityAttributes.self) { context in
            // 锁屏 / 通知横幅视图
            LockScreenView(attributes: context.attributes, state: context.state)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
        } dynamicIsland: { context in
            DynamicIsland {
                // 展开视图（长按灵动岛时）
                DynamicIslandExpandedRegion(.leading) {
                    expandedLeading(state: context.state)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    expandedTrailing(
                        totalSeconds: context.attributes.totalSeconds,
                        remainingSeconds: context.state.remainingSeconds
                    )
                }
                DynamicIslandExpandedRegion(.bottom) {
                    expandedBottom(
                        title: context.attributes.title,
                        totalSeconds: context.attributes.totalSeconds,
                        remainingSeconds: context.state.remainingSeconds,
                        phase: context.state.phase
                    )
                }
            } compactLeading: {
                // 紧凑左侧：小图标
                Image(systemName: "wave.3.forward")
                    .foregroundStyle(.cyan)
                    .font(.system(size: 12, weight: .semibold))
            } compactTrailing: {
                // 紧凑右侧：环形进度
                CompactProgressRing(
                    totalSeconds: context.attributes.totalSeconds,
                    remainingSeconds: context.state.remainingSeconds
                )
                .frame(width: 20, height: 20)
            } minimal: {
                // 最小模式（有其他 App Live Activity 竞争时）：只显示进度环
                CompactProgressRing(
                    totalSeconds: context.attributes.totalSeconds,
                    remainingSeconds: context.state.remainingSeconds
                )
                .frame(width: 20, height: 20)
            }
        }
    }

    @ViewBuilder
    private func expandedLeading(state: PlaybackActivityAttributes.ContentState) -> some View {
        let icon = state.phase == "paused" ? "pause.fill" : "wave.3.forward"
        Image(systemName: icon)
            .foregroundStyle(.cyan)
            .font(.system(size: 20, weight: .semibold))
    }

    @ViewBuilder
    private func expandedTrailing(totalSeconds: Int, remainingSeconds: Int) -> some View {
        ExpandedProgressRing(totalSeconds: totalSeconds, remainingSeconds: remainingSeconds)
            .frame(width: 44, height: 44)
    }

    @ViewBuilder
    private func expandedBottom(
        title: String,
        totalSeconds: Int,
        remainingSeconds: Int,
        phase: String
    ) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(.white)
            Text(phaseLabel(phase: phase, remainingSeconds: remainingSeconds))
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func phaseLabel(phase: String, remainingSeconds: Int) -> String {
        switch phase {
        case "paused":      return "Paused"
        case "interrupted": return "Interrupted — open Cyberskin"
        default:
            let min = remainingSeconds / 60
            let sec = remainingSeconds % 60
            return String(format: "%d:%02d remaining", min, sec)
        }
    }
}

// MARK: - Lock Screen View

private struct LockScreenView: View {
    let attributes: PlaybackActivityAttributes
    let state: PlaybackActivityAttributes.ContentState

    var body: some View {
        HStack(spacing: 12) {
            // 进度环
            ExpandedProgressRing(
                totalSeconds: attributes.totalSeconds,
                remainingSeconds: state.remainingSeconds
            )
            .frame(width: 44, height: 44)

            VStack(alignment: .leading, spacing: 2) {
                Text(attributes.title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                Text(timeLabel)
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .foregroundStyle(.tertiary)
                .font(.system(size: 12))
        }
    }

    private var timeLabel: String {
        switch state.phase {
        case "paused":      return "Paused"
        case "interrupted": return "Interrupted"
        default:
            let r = state.remainingSeconds
            return String(format: "%d:%02d remaining", r / 60, r % 60)
        }
    }
}

// MARK: - Progress Ring Components

/// 紧凑模式（灵动岛边缘）的细环。
private struct CompactProgressRing: View {
    let totalSeconds: Int
    let remainingSeconds: Int

    private var progress: Double {
        guard totalSeconds > 0 else { return 0 }
        let elapsed = Double(totalSeconds - remainingSeconds)
        return min(elapsed / Double(totalSeconds), 1.0)
    }

    var body: some View {
        ZStack {
            Circle().stroke(Color.white.opacity(0.25), lineWidth: 2)
            Circle()
                .trim(from: 0, to: progress)
                .stroke(Color.cyan, style: StrokeStyle(lineWidth: 2, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.linear(duration: 1), value: progress)
        }
    }
}

/// 展开模式下较大的进度环，中间显示剩余时间。
private struct ExpandedProgressRing: View {
    let totalSeconds: Int
    let remainingSeconds: Int

    private var progress: Double {
        guard totalSeconds > 0 else { return 0 }
        let elapsed = Double(totalSeconds - remainingSeconds)
        return min(elapsed / Double(totalSeconds), 1.0)
    }

    var body: some View {
        ZStack {
            Circle().stroke(Color.white.opacity(0.2), lineWidth: 3.5)
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    Color.cyan,
                    style: StrokeStyle(lineWidth: 3.5, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.linear(duration: 1), value: progress)
            Text(shortTime)
                .font(.system(size: 10, weight: .semibold, design: .monospaced))
                .foregroundStyle(.white)
        }
    }

    private var shortTime: String {
        let r = remainingSeconds
        if r >= 3600 {
            return String(format: "%dh", r / 3600)
        }
        return String(format: "%d:%02d", r / 60, r % 60)
    }
}
