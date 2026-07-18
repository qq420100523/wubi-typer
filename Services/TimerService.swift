import Foundation

private let timerInterval: TimeInterval = 1.0
private let elapsedUpdateThreshold: TimeInterval = 0.4

/// 练习计时服务
/// 管理单次练习的计时器生命周期，提供暂停/恢复时的时间修正
@MainActor
final class TimerService {
    private var timer: Timer?
    private(set) var elapsed: TimeInterval = 0
    /// 计时更新回调，参数为已过时间（秒）
    var onUpdate: ((TimeInterval) -> Void)?

    var isRunning: Bool { timer != nil }

    /// 启动计时器
    /// - Parameters:
    ///   - startTime: 本次练习的起始时间
    ///   - pausedDuration: 已累积的暂停时长，用于从总时间中扣除
    func start(startTime: Date, pausedDuration: TimeInterval) {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: timerInterval, repeats: true) { [weak self] _ in
            guard let self else { return }
            Task { @MainActor in
                let raw = Date().timeIntervalSince(startTime)
                let newElapsed = raw - pausedDuration
                if abs(newElapsed - self.elapsed) >= elapsedUpdateThreshold {
                    self.elapsed = newElapsed
                    self.onUpdate?(newElapsed)
                }
            }
        }
    }

    /// 停止计时器
    func stop() {
        timer?.invalidate()
        timer = nil
    }
}
