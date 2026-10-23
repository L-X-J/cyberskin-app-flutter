import ActivityKit
import Foundation

// Live Activity 的静态内容（启动后不变）与动态状态（每次 update 刷新）。
// 本文件需同时加入 Runner 和 PlaybackLiveActivity 两个 target 的 Compile Sources。

/// 设备播放 Live Activity 的静态与动态数据模型。
public struct PlaybackActivityAttributes: ActivityAttributes {
    /// 启动时确定的会话信息；标题在运行期间不变化。
    public struct ContentState: Codable, Hashable {
        /// 当前剩余总秒数。
        public var remainingSeconds: Int
        /// 运行状态：running / paused / interrupted / completed。
        public var phase: String

        public init(remainingSeconds: Int, phase: String) {
            self.remainingSeconds = remainingSeconds
            self.phase = phase
        }
    }

    /// 用户可见的播放名称，例如节奏或训练课程标题。
    public var title: String
    /// 来源业务，rhythm / training，仅用于日志区分。
    public var source: String
    /// 整个序列的总秒数，用于计算进度环。
    public var totalSeconds: Int

    public init(title: String, source: String, totalSeconds: Int) {
        self.title = title
        self.source = source
        self.totalSeconds = totalSeconds
    }
}
