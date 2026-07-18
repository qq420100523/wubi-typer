import Foundation

/// 词组编码计算
/// 根据五笔词组取码规则（二字词/三字词/多字词）计算编码和拆字
extension WubiDictionary {
    /// 计算词组的五笔编码
    /// - Parameter text: 词组文本（2 个及以上汉字）
    /// - Returns: 大写编码字符串，空字符串表示无法编码
    func computePhraseCode(for text: String) -> String {
        let chars = Array(text)
        guard !chars.isEmpty else { return "" }
        
        let codes = chars.map { code(for: $0) ?? "" }
        
        var result = ""
        for (i, n) in phraseIndices(count: chars.count) {
            guard i < codes.count else { break }
            result += codes[i].prefix(n)
        }
        return result.uppercased()
    }

    /// 构建词组的拆字分解
    /// - Parameter text: 词组文本
    /// - Returns: 空格分隔的拆字序列，与编码规则对应
    func computePhraseDecomposition(for text: String) -> String {
        let chars = Array(text)
        guard !chars.isEmpty else { return "" }

        let radicalsPerChar = chars.map { decomposition(for: $0) }

        var result: [String] = []
        for (i, n) in phraseIndices(count: chars.count) {
            guard i < radicalsPerChar.count else { break }
            result.append(contentsOf: radicalsPerChar[i].prefix(n))
        }
        return result.joined(separator: " ")
    }

    /// 词组取码索引规则
    /// - 二字词：各取前 2 段 → (0,2)(1,2)
    /// - 三字词：前两字各取 1 段，第三字取 2 段 → (0,1)(1,1)(2,2)
    /// - 四字及以上：前三字各取 1 段，最后一字取 1 段 → (0,1)(1,1)(2,1)(last,1)
    private func phraseIndices(count: Int) -> [(Int, Int)] {
        switch count {
        case 2: return [(0, 2), (1, 2)]
        case 3: return [(0, 1), (1, 1), (2, 2)]
        default: return [(0, 1), (1, 1), (2, 1), (count - 1, 1)]
        }
    }
}
