import Foundation

/// 内容加载器
/// 从 App Bundle 中加载字频文件、词组文件等本地资源
enum ContentLoader {
    /// 从指定文件中加载常用字列表
    /// - Parameter fileName: 文件名（不含扩展名）
    /// - Returns: 单字字符串数组
    static func loadFrequentChars(fileName: String) -> [String] {
        guard let url = Bundle.main.url(forResource: fileName, withExtension: "txt"),
              let content = try? String(contentsOf: url, encoding: .utf8)
        else { return [] }
        return content
            .components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { $0.count == 1 && !$0.trimmingCharacters(in: .whitespaces).isEmpty }
    }

    /// 加载词组文件（wubi_words.txt）
    /// - Returns: 打乱后的词组数组
    static func loadPhrases() -> [String] {
        guard let url = Bundle.main.url(forResource: "wubi_words", withExtension: "txt"),
              let content = try? String(contentsOf: url, encoding: .utf8)
        else { return [] }
        return content
            .components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { $0.count >= 2 }
            .shuffled()
    }
}
