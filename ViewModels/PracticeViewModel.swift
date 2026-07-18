import Foundation
import SwiftUI

private let correctTransitionDelay: TimeInterval = 0.6
private let wrongTransitionDelay: TimeInterval = 1.2

/// 练习主视图模型
/// 管理所有练习模式的业务逻辑：单字、词组、文章，包括输入处理、计时、反馈等
@Observable
@MainActor
final class PracticeViewModel {
    // MARK: - 公开状态
    var session: PracticeSession
    var showWubiHints = true
    /// 仅显示 GB2312 字符，过滤 GBK 扩展字符
    var limitToGB2312 = true
    var inputText: String = "" {
        didSet { handleInputChange(oldValue: oldValue) }
    }

    // MARK: - 单字模式状态
    var currentDisplayChar: String = ""
    var currentCharCode: String?
    var currentDecomposition: String?
    var currentPinyin: String?
    var currentCharset: String?
    var feedbackText: String = ""
    var feedbackType: FeedbackType = .none
    fileprivate var isTransitioning = false

    // MARK: - 私有状态
    fileprivate let timerService = TimerService()
    fileprivate var elapsed: TimeInterval = 0
    var targetTextChars: [Character] = []
    var typedTextChars: [Character] = []
    fileprivate let wubiDict = WubiDictionary.shared
    fileprivate let mistakeTracker = MistakeTracker.shared
    fileprivate let cumulativeStats = CumulativeStats.shared

    /// 向用户显示一次性提示消息（ContentView 观察此属性显示 Alert）
    var userAlertMessage: String?

    // MARK: - 计算属性

    var stats: TypingStats {
        TypingStats(
            elapsedTime: max(elapsed, 0),
            correctCount: session.correctCount,
            errorCount: session.errorCount,
            totalTyped: session.typedText.count,
            keystrokeCount: session.keystrokeCount,
            backspaceCount: session.backspaceCount,
            targetLength: session.targetText.count
        )
    }

    var currentWubiHint: String {
        guard showWubiHints else { return "" }
        if session.isSingleCharMode || session.isPhraseMode {
            if let code = currentCharCode {
                return "\(currentDisplayChar) [\(code.uppercased())]"
            }
            return currentDisplayChar.isEmpty ? "" : "\(currentDisplayChar) [?]"
        }
        let startPos = session.typedText.count
        var hintChars: [Character] = []
        for i in startPos..<targetTextChars.count {
            let ch = targetTextChars[i]
            if ch != "\n" && ch != "\r" {
                hintChars.append(ch)
                if hintChars.count >= 3 { break }
            }
        }
        let codes = hintChars.map { char -> String in
            if let code = wubiDict.code(for: char) {
                return "\(char) [\(code.uppercased())]"
            }
            return "\(char) [?]"
        }
        return codes.joined(separator: "  ")
    }

    var currentCharHints: (character: Character?, code: String?, decomposition: String?, pinyin: String?, charset: String?) {
        if session.isSingleCharMode || session.isPhraseMode {
            let char = currentDisplayChar.first
            return (char, currentCharCode, currentDecomposition, currentPinyin, currentCharset)
        }
        guard session.typedText.count < targetTextChars.count else { return (nil, nil, nil, nil, nil) }
        let char = targetTextChars[session.typedText.count]
        let detail = wubiDict.detail(for: char)
        return (char, detail?.code, detail?.decomposition, detail?.pinyin, detail?.charset)
    }

    var isActive: Bool {
        session.startTime != nil || !session.typedText.isEmpty
    }

    var isSingleCharActive: Bool {
        session.isSingleCharMode || session.isPhraseMode
    }

    // MARK: - 初始化

    init() {
        self.session = PracticeSession()
        timerService.onUpdate = { [weak self] elapsed in
            self?.elapsed = elapsed
        }
        let loadResult = wubiDict.loadBuiltin()
        if !loadResult {
            userAlertMessage = "词库加载失败，部分功能不可用"
        }
        setMode(.random)
    }
}

// MARK: - 模式管理

extension PracticeViewModel {
    fileprivate func filteredChars() -> [String] {
        if limitToGB2312 {
            return wubiDict.allChars.filter { ch in
                guard let first = ch.first,
                      let detail = wubiDict.detail(for: first) else { return true }
                return detail.charset == nil || detail.charset == "GB2312" || detail.charset == ""
            }
        }
        return wubiDict.allChars
    }

    func setMode(_ mode: PracticeMode) {
        reset()
        session.mode = mode

        switch mode {
        case .random:
            let chars = Array(filteredChars().shuffled())
            session.charPool = chars
            session.poolIndex = 0
            if !chars.isEmpty { showNextChar() }

        case .zone1, .zone2, .zone3, .zone4, .zone5:
            let firstLetters: String
            switch mode {
            case .zone1: firstLetters = "gfdsa"
            case .zone2: firstLetters = "hjklm"
            case .zone3: firstLetters = "trewq"
            case .zone4: firstLetters = "yuiop"
            case .zone5: firstLetters = "nbvcx"
            default: firstLetters = ""
            }
            let chars = filteredChars().filter { ch in
                guard let first = ch.first, let code = wubiDict.code(for: first) else { return false }
                return firstLetters.contains(code.prefix(1).lowercased())
            }
            session.charPool = chars.shuffled()
            session.poolIndex = 0
            if !chars.isEmpty { showNextChar() }

        case .common0_500, .common500_1000, .common1000_15000:
            let fileName: String
            switch mode {
            case .common0_500: fileName = "FrequentlyCharacters0-500"
            case .common500_1000: fileName = "FrequentlyCharacters500-1000"
            case .common1000_15000: fileName = "FrequentlyCharacters1000-15000"
            default: fileName = "FrequentlyCharacters0-500"
            }
            let chars = ContentLoader.loadFrequentChars(fileName: fileName).shuffled()
            session.charPool = chars
            session.poolIndex = 0
            if !chars.isEmpty { showNextChar() }

        case .mistakes:
            let mistakeChars = mistakeTracker.sortedMistakes.map { $0.char }
            if mistakeChars.isEmpty {
                userAlertMessage = "错字本为空，已切换至随机练习模式"
                session.mode = .random
                setMode(.random)
                return
            }
            session.charPool = mistakeChars.shuffled()
            session.poolIndex = 0
            if !mistakeChars.isEmpty { showNextChar() }

        case .phrase:
            session.phrasePool = ContentLoader.loadPhrases()
            session.phraseIndex = 0
            if !session.phrasePool.isEmpty { showNextPhrase() }

        case .article:
            let welcome = "欢迎使用五笔打字练习器！\n请点击下方「选择文章」或「载入文本」按钮加载练习文本。"
            loadText(welcome)
        }
    }

    func startArticle(_ article: ArticleEntry) {
        reset()
        session.mode = .article
        session.passageId = article.id
        session.targetText = article.text
        targetTextChars = Array(session.targetText)

        var chars: [PassageChar] = []
        for ch in article.text {
            chars.append(PassageChar(char: ch, code: wubiDict.code(for: ch), status: .pending))
        }
        session.passageChars = chars
        session.passageIndex = 0
        advanceToNextPendingChar()
    }

    fileprivate func showNextChar() {
        guard !session.charPool.isEmpty else { return }
        if session.poolIndex >= session.charPool.count {
            session.charPool.shuffle()
            session.poolIndex = 0
        }

        let char = session.charPool[session.poolIndex]
        session.poolIndex += 1
        currentDisplayChar = char
        currentCharCode = char.first.flatMap { wubiDict.code(for: $0) }
        if let first = char.first {
            let detail = wubiDict.detail(for: first)
            currentDecomposition = detail?.decomposition
            currentPinyin = detail?.pinyin
            currentCharset = detail?.charset
        }
        session.targetText = char
        targetTextChars = Array(session.targetText)

        inputText = ""
        feedbackText = ""
        feedbackType = .none
        isTransitioning = false
        session.typedText = ""
        typedTextChars = []
        session.isCompleted = false
    }

    fileprivate func showNextPhrase() {
        guard !session.phrasePool.isEmpty else { return }
        if session.phraseIndex >= session.phrasePool.count {
            session.phrasePool.shuffle()
            session.phraseIndex = 0
        }

        let phrase = session.phrasePool[session.phraseIndex]
        session.phraseIndex += 1
        currentDisplayChar = phrase
        currentCharCode = wubiDict.computePhraseCode(for: phrase)
        currentDecomposition = wubiDict.computePhraseDecomposition(for: phrase)
        currentPinyin = nil
        currentCharset = nil
        session.targetText = phrase
        targetTextChars = Array(session.targetText)

        inputText = ""
        feedbackText = ""
        feedbackType = .none
        isTransitioning = false
        session.typedText = ""
        typedTextChars = []
        session.isCompleted = false
    }

}

// MARK: - 输入处理

extension PracticeViewModel {
    fileprivate func handleInputChange(oldValue: String) {
        guard !isTransitioning else { return }

        if session.isSingleCharMode || session.isPhraseMode {
            handleSingleCharInput(oldValue: oldValue)
            return
        }

        handlePassageInput(oldValue: oldValue)
    }

    fileprivate func handleSingleCharInput(oldValue: String) {
        if session.isPaused || session.isCompleted { return }

        if inputText.count < oldValue.count {
            session.backspaceCount += 1
            return
        }

        let newChars = inputText.dropFirst(oldValue.count)
        for char in newChars {
            if session.startTime == nil {
                session.startTime = Date()
                startTimer()
            }

            session.keystrokeCount += 1
            session.typedText.append(char)
        }

        guard inputText.count >= session.targetText.count else { return }

        if inputText == session.targetText {
            onCorrect()
        } else {
            onWrong()
        }
    }

    fileprivate func handlePassageInput(oldValue: String) {
        guard !session.isPaused, !session.isCompleted else { return }

        let charDiff = inputText.count - oldValue.count
        if charDiff < 0 {
            session.backspaceCount += -charDiff
        } else if charDiff > 0 {
            session.keystrokeCount += charDiff
        }

        // 全量重算：从 inputText 直接同步，支持光标任意位置编辑
        session.typedText = inputText
        typedTextChars = Array(inputText)

        var correct = 0
        var error = 0
        for (i, ch) in typedTextChars.enumerated() {
            if i < targetTextChars.count {
                if ch == targetTextChars[i] {
                    correct += 1
                } else {
                    error += 1
                }
            } else {
                error += 1
            }
        }

        // 仅对新增字符记录错字（双端扫描定位实际插入位置，支持光标任意位置编辑）
        if charDiff > 0 {
            let oldChars = Array(oldValue)
            var insertPos = 0
            while insertPos < oldChars.count, insertPos < typedTextChars.count, oldChars[insertPos] == typedTextChars[insertPos] {
                insertPos += 1
            }
            for offset in 0..<charDiff {
                let i = insertPos + offset
                if i < targetTextChars.count {
                    let ch = typedTextChars[i]
                    let targetChar = targetTextChars[i]
                    if ch != targetChar {
                        mistakeTracker.recordMistake(for: targetChar, code: wubiDict.code(for: targetChar))
                    }
                }
            }
        }

        session.correctCount = correct
        session.errorCount = error

        if session.startTime == nil, !inputText.isEmpty {
            session.startTime = Date()
            startTimer()
        }

        if typedTextChars.count >= targetTextChars.count {
            completeSession()
        }
    }

    fileprivate func onCorrect() {
        session.correctCount += 1

        feedbackText = "正确！"
        feedbackType = .correct
        isTransitioning = true

        if let char = currentDisplayChar.first {
            mistakeTracker.recordCorrect(for: char)
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + correctTransitionDelay) { [weak self] in
            guard let self = self else { return }
            self.isTransitioning = false
            guard !self.session.isPaused else { return }
            if self.session.isPhraseMode {
                self.showNextPhrase()
            } else {
                self.showNextChar()
            }
        }
    }

    fileprivate func onWrong() {
        session.errorCount += 1

        feedbackText = "错误！正确文字：\(currentDisplayChar)"
        feedbackType = .wrong

        if let char = currentDisplayChar.first {
            mistakeTracker.recordMistake(for: char, code: currentCharCode)
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + wrongTransitionDelay) { [weak self] in
            guard let self = self, !self.session.isPaused else { return }
            if self.session.isPhraseMode {
                self.showNextPhrase()
            } else {
                self.showNextChar()
            }
        }
    }
}

// MARK: - 计时器

extension PracticeViewModel {
    fileprivate func startTimer() {
        guard let start = session.startTime else { return }
        timerService.start(startTime: start, pausedDuration: session.pausedDuration)
    }

    fileprivate func completeSession() {
        timerService.stop()
        session.isPaused = false
        session.isCompleted = true

        cumulativeStats.record(
            totalChars: session.typedText.count,
            correctChars: session.correctCount,
            time: elapsed
        )
    }
}

// MARK: - 公共操作

extension PracticeViewModel {
    fileprivate func advanceToNextPendingChar() {
        while session.passageIndex < session.passageChars.count {
            let ch = session.passageChars[session.passageIndex]
            if ch.status == .pending { break }
            session.passageIndex += 1
        }
    }

    func loadText(_ text: String) {
        reset()
        let cleaned = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleaned.isEmpty else { return }
        if session.mode != .article {
            session.mode = .article
        }
        session.targetText = cleaned
        targetTextChars = Array(session.targetText)
        session.passageChars = cleaned.map { PassageChar(char: $0, code: wubiDict.code(for: $0), status: .pending) }
        session.passageIndex = 0
        inputText = ""
    }

    func reset() {
        timerService.stop()
        let oldMode = session.mode
        let oldTarget = session.targetText
        session = PracticeSession(targetText: oldTarget)
        session.mode = oldMode
        targetTextChars = Array(session.targetText)
        typedTextChars = []
        inputText = ""
        elapsed = 0
        currentDisplayChar = ""
        currentCharCode = nil
        currentDecomposition = nil
        currentPinyin = nil
        currentCharset = nil
        feedbackText = ""
        feedbackType = .none
        isTransitioning = false
    }

    func restart() {
        let mode = session.mode
        if session.isPassageMode, let id = session.passageId {
            let article = ArticleData.all.first(where: { $0.id == id })
            if let article = article {
                startArticle(article)
                return
            }
        }
        reset()
        session.mode = mode
        setMode(mode)
    }

    func restartSingleChar() {
        session.restartCount += 1
        if session.isPhraseMode {
            showNextPhrase()
        } else {
            showNextChar()
        }
    }

    func togglePause() {
        if session.isPaused {
            session.isPaused = false
            if let pauseStart = session.pauseStartTime {
                session.pausedDuration += Date().timeIntervalSince(pauseStart)
                session.pauseStartTime = nil
            }
            if session.startTime != nil {
                startTimer()
            }
        } else {
            session.isPaused = true
            session.pauseStartTime = Date()
            timerService.stop()
        }
    }

    /// 应用进入后台/被最小化时暂停计时器
    func suspendTimer() {
        guard !session.isPaused, !session.isCompleted, session.startTime != nil, timerService.isRunning else { return }
        timerService.stop()
        session.pauseStartTime = Date()
    }

    /// 应用回到前台时恢复计时器
    func resumeTimer() {
        guard !session.isPaused, !session.isCompleted, let pauseStart = session.pauseStartTime else { return }
        session.pausedDuration += Date().timeIntervalSince(pauseStart)
        session.pauseStartTime = nil
        if session.startTime != nil {
            startTimer()
        }
    }

    func loadFromClipboard() {
        if let string = NSPasteboard.general.string(forType: .string) {
            loadText(string)
        }
    }
}

/// 反馈类型
enum FeedbackType {
    case none
    case correct
    case wrong
}
