import Foundation
import Observation

/// 错字记录条目
struct MistakeEntry: Codable, Identifiable {
    let char: String
    let code: String?
    var count: Int

    var id: String { char }
}

/// 错字本管理器
/// 记录用户经常打错的字及其错误次数，自动持久化到本地文件
@MainActor
@Observable
final class MistakeTracker {
    private static let fileName = "wubi-mistakes.json"

    /// 错字字典，key 为汉字字符
    private(set) var mistakes: [String: MistakeEntry] = [:] {
        didSet { scheduleSave() }
    }

    static let shared = MistakeTracker()

    private var saveTask: Task<Void, Never>?

    init() {
        load()
    }

    /// 记录一次错误输入
    /// - Parameters:
    ///   - char: 打错的字
    ///   - code: 该字的五笔编码
    func recordMistake(for char: Character, code: String?) {
        let key = String(char)
        if var entry = mistakes[key] {
            entry.count += 1
            mistakes[key] = entry
        } else {
            mistakes[key] = MistakeEntry(char: key, code: code, count: 1)
        }
    }

    /// 记录一次正确输入（减少错字计数，归零时移除）
    func recordCorrect(for char: Character) {
        let key = String(char)
        guard var entry = mistakes[key] else { return }
        entry.count -= 1
        if entry.count <= 0 {
            mistakes.removeValue(forKey: key)
        } else {
            mistakes[key] = entry
        }
    }

    /// 按错误次数降序排列的错字列表
    var sortedMistakes: [MistakeEntry] {
        mistakes.values.sorted { $0.count > $1.count }
    }

    var count: Int { mistakes.count }

    /// 清空所有错字记录
    func clear() {
        mistakes = [:]
        save()
    }

    var isEmpty: Bool { mistakes.isEmpty }

    /// 防抖持久化（500ms 内多次修改只存一次）
    private func scheduleSave() {
        saveTask?.cancel()
        saveTask = Task { [weak self] in
            try? await Task.sleep(for: .seconds(0.5))
            self?.save()
        }
    }

    private func save() {
        StorageService.save(mistakes, to: Self.fileName)
    }

    private func load() {
        let dict: [String: MistakeEntry]? = StorageService.load([String: MistakeEntry].self, from: Self.fileName)
        mistakes = dict ?? [:]
    }
}
