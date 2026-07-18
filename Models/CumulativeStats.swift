import Foundation
import Observation

/// 累积统计数据（可持久化）
struct CumulativeStatsData: Codable {
    var totalChars: Int
    var correctChars: Int
    var totalTime: TimeInterval
}

/// 累积统计管理器
/// 跨练习会话累积总字数、正确字数、总用时，自动持久化到本地文件
@MainActor
@Observable
final class CumulativeStats {
    private static let fileName = "wubi-cumulative-stats.json"

    /// 当前累积数据，变更时自动保存
    private(set) var data: CumulativeStatsData {
        didSet { save() }
    }

    static let shared = CumulativeStats()

    private init() {
        guard let loaded: CumulativeStatsData = StorageService.load(CumulativeStatsData.self, from: Self.fileName) else {
            data = CumulativeStatsData(totalChars: 0, correctChars: 0, totalTime: 0)
            return
        }
        data = loaded
    }

    /// 记录一次练习结果
    /// - Parameters:
    ///   - totalChars: 本次练习总字符数
    ///   - correctChars: 本次练习正确字符数
    ///   - time: 本次练习耗时（秒）
    func record(totalChars: Int, correctChars: Int, time: TimeInterval) {
        var d = data
        d.totalChars += totalChars
        d.correctChars += correctChars
        d.totalTime += time
        data = d
    }

    /// 总准确率
    var accuracy: Double {
        guard data.totalChars > 0 else { return 1.0 }
        return Double(data.correctChars) / Double(data.totalChars)
    }

    /// 平均速度（字/分钟）
    var averageSpeed: Double {
        guard data.totalTime > 0 else { return 0 }
        return (Double(data.correctChars) / data.totalTime) * 60
    }

    /// 格式化总用时
    var formattedTime: String {
        let minutes = Int(data.totalTime) / 60
        let seconds = Int(data.totalTime) % 60
        if minutes > 0 {
            return "\(minutes)分\(seconds)秒"
        }
        return "\(seconds)秒"
    }

    /// 重置统计数据
    func reset() {
        data = CumulativeStatsData(totalChars: 0, correctChars: 0, totalTime: 0)
    }

    private func save() {
        StorageService.save(data, to: Self.fileName)
    }
}
