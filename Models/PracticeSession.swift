import Foundation

/// 练习模式
enum PracticeMode: String, CaseIterable, Identifiable {
    case random = "随机练习"
    case zone1 = "横区字"
    case zone2 = "竖区字"
    case zone3 = "撇区字"
    case zone4 = "捺区字"
    case zone5 = "折区字"
    case common0_500 = "常用前 500 字"
    case common500_1000 = "常用中 500 字"
    case common1000_15000 = "常用后 500 字"
    case mistakes = "错字复习"
    case phrase = "词组练习"
    case article = "文章练习"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .random: return "shuffle"
        case .zone1, .zone2, .zone3, .zone4, .zone5: return "square.grid.3x3"
        case .common0_500, .common500_1000, .common1000_15000: return "star"
        case .mistakes: return "exclamationmark.triangle"
        case .phrase: return "text.word.spacing"
        case .article: return "book"
        }
    }

    /// 是否为单字模式
    var isSingleChar: Bool {
        switch self {
        case .random, .zone1, .zone2, .zone3, .zone4, .zone5, .common0_500, .common500_1000, .common1000_15000, .mistakes:
            return true
        case .phrase, .article:
            return false
        }
    }
}

/// 练习会话的状态
struct PracticeSession {
    // MARK: - 模式
    /// 当前练习模式
    var mode: PracticeMode = .random

    // MARK: - 单字模式状态
    /// 字符池（当前模式的所有可选字）
    var charPool: [String] = []
    /// 当前字符索引
    var poolIndex: Int = 0

    // MARK: - 词组模式状态
    /// 词组池
    var phrasePool: [PhraseEntry] = []
    /// 当前词组索引
    var phraseIndex: Int = 0

    // MARK: - 文章模式状态
    /// 文章字符数组（每个元素是一个字 + 状态）
    var passageChars: [PassageChar] = []
    /// 文章当前索引
    var passageIndex: Int = 0
    /// 当前文章 ID
    var passageId: String?

    // MARK: - 通用状态
    /// 目标文本（单字模式下是当前字，文章模式下是整篇文章）
    var targetText: String
    /// 用户已输入的内容
    var typedText: String
    /// 首次按键时间
    var startTime: Date?
    /// 暂停累积时间（秒）
    var pausedDuration: TimeInterval
    /// 最后一次暂停开始时间
    var pauseStartTime: Date?
    /// 是否已完成
    var isCompleted: Bool
    /// 是否暂停
    var isPaused: Bool
    /// 按键历史
    var keystrokeCount: Int
    /// 退格次数
    var backspaceCount: Int
    /// 错误按键次数
    var errorCount: Int
    /// 重打次数
    var restartCount: Int
    /// 正确字符数
    var correctCount: Int

    init(targetText: String = "") {
        self.targetText = targetText
        self.typedText = ""
        self.startTime = nil
        self.pausedDuration = 0
        self.pauseStartTime = nil
        self.isCompleted = false
        self.isPaused = false
        self.keystrokeCount = 0
        self.backspaceCount = 0
        self.errorCount = 0
        self.restartCount = 0
        self.correctCount = 0
    }

    /// 当前已输入的字符与目标文本的比较结果
    var comparisons: [(character: Character, state: CharState)] {
        let typed = Array(typedText)
        let target = Array(targetText)
        var result: [(Character, CharState)] = []
        result.reserveCapacity(typed.count)
        for (index, char) in typed.enumerated() {
            if index < target.count {
                result.append(char == target[index] ? (char, .correct) : (char, .wrong))
            } else {
                result.append((char, .extra))
            }
        }
        return result
    }

    /// 目标文本中尚未输入的部分
    var remainingText: String {
        if typedText.count >= targetText.count {
            return ""
        }
        let targetChars = Array(targetText)
        return String(targetChars[typedText.count...])
    }

    /// 当前输入位置
    var currentPosition: Int {
        typedText.count
    }

    /// 当前需要输入的字符
    var currentTargetChar: Character? {
        guard currentPosition < targetText.count else { return nil }
        let targetChars = Array(targetText)
        return targetChars[currentPosition]
    }

    /// 是否为单字模式
    var isSingleCharMode: Bool { mode.isSingleChar }

    /// 是否为文章模式
    var isPassageMode: Bool { mode == .article }

    /// 是否为词组模式
    var isPhraseMode: Bool { mode == .phrase }

    enum CharState {
        case correct    // 正确
        case wrong      // 错误
        case extra      // 多余
        case pending    // 待输入
    }
}

/// 文章模式下的字符状态
struct PassageChar {
    let char: Character
    let code: String?
    var status: PassageCharStatus
}

enum PassageCharStatus {
    case pending
    case correct
    case wrong
}
