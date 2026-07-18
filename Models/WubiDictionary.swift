import Foundation
import OSLog

/// 单个字的完整信息
struct WubiCharacterDetail {
    let character: Character
    /// 五笔86编码
    let code: String?
    /// 拆字序列（※分隔的 radical 编码）
    let decomposition: String?
    /// 拼音（多音字用下划线分隔）
    let pinyin: String?
    /// 字符集（如 GB2312）
    let charset: String?
}

/// 五笔86版编码词典
@MainActor
final class WubiDictionary {
    private var dict: [Character: String] = [:]
    private var details: [Character: WubiCharacterDetail] = [:]
    private(set) var isLoaded = false

    static let shared = WubiDictionary()

    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "WubiTypingTrainer", category: "WubiDictionary")

    private init() {}

    /// 从内嵌资源加载词库
    /// - Returns: true 表示加载成功，false 表示失败
    @discardableResult
    func loadBuiltin() -> Bool {
        guard !isLoaded else { return true }
        guard let url = Bundle.main.url(forResource: "wubi86_dict", withExtension: "txt") else {
            logger.error("词库文件未找到")
            return false
        }
        return load(from: url)
    }

    /// 从指定路径加载词库
    /// - Returns: true 表示加载成功
    @discardableResult
    func load(from url: URL) -> Bool {
        do {
            let content = try String(contentsOf: url, encoding: .utf8)
            var newDict: [Character: String] = [:]
            var newDetails: [Character: WubiCharacterDetail] = [:]
            for line in content.components(separatedBy: .newlines) {
                let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !trimmed.isEmpty, !trimmed.hasPrefix("#") else { continue }
                let parts = trimmed.split(separator: " ", maxSplits: 1, omittingEmptySubsequences: true)
                guard parts.count == 2, let char = parts.first?.first else { continue }
                let value = String(parts.last!).trimmingCharacters(in: .whitespaces)

                if value.hasPrefix("[") {
                    let inner = value.dropFirst().dropLast()
                    let fields = inner.split(separator: ",", maxSplits: 3, omittingEmptySubsequences: false)

                    let decomposition = fields.count >= 1
                        ? String(fields[0]).trimmingCharacters(in: .whitespaces).replacingOccurrences(of: "※", with: " ")
                        : nil
                    let codeField = fields.count >= 2
                        ? String(fields[1]).trimmingCharacters(in: .whitespaces).replacingOccurrences(of: "※", with: "")
                        : nil
                    let pinyin = fields.count >= 3
                        ? String(fields[2]).trimmingCharacters(in: .whitespaces).replacingOccurrences(of: "※", with: "")
                        : nil
                    let charset = fields.count >= 4
                        ? String(fields[3]).trimmingCharacters(in: .whitespaces).replacingOccurrences(of: "※", with: "")
                        : nil

                    if let code = codeField, !code.isEmpty {
                        newDict[char] = code
                    }
                    newDetails[char] = WubiCharacterDetail(
                        character: char,
                        code: codeField,
                        decomposition: decomposition,
                        pinyin: pinyin,
                        charset: charset
                    )
                } else {
                    newDict[char] = value
                    newDetails[char] = WubiCharacterDetail(
                        character: char,
                        code: value,
                        decomposition: nil,
                        pinyin: nil,
                        charset: nil
                    )
                }
            }
            self.dict = newDict
            self.details = newDetails
            self.isLoaded = true
            logger.notice("词库加载完成: \(newDict.count) 个条目")
            return true
        } catch {
            logger.error("词库加载失败: \(error.localizedDescription)")
            return false
        }
    }

    /// 查询单个字的编码（同步）
    func code(for character: Character) -> String? {
        dict[character]
    }

    /// 查询单个字的拆字分解数组
    func decomposition(for character: Character) -> [String] {
        guard let detail = detail(for: character),
              let decomp = detail.decomposition else { return [] }
        return decomp.split(separator: " ").filter { !$0.isEmpty }.map(String.init)
    }

    /// 查询单个字的完整信息
    func detail(for character: Character) -> WubiCharacterDetail? {
        details[character]
    }

    /// 查询一段文本每个字的编码
    func codes(for text: String) -> [(Character, String?)] {
        text.map { ($0, dict[$0]) }
    }

    var count: Int { dict.count }

    /// 所有已加载的字
    var allChars: [String] { dict.keys.map(String.init) }
}
