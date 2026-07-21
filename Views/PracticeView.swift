import SwiftUI

/// 练习主视图 — 根据模式切换单字视图或文章视图
@MainActor
struct PracticeView: View {
    @Bindable var viewModel: PracticeViewModel
    @FocusState private var inputFocused: Bool
    @FocusState private var singleCharFocused: Bool
    @Environment(\.colorScheme) private var colorScheme

    private let minFontSize: Double = 18
    private let maxFontSize: Double = 48
    @State private var previousCursorPos: Int = 0
    /// 手动管理字号持久化（不使用 @AppStorage 以避免订阅全局 UserDefaults 通知）
    @State private var textFontSize: Double = UserDefaults.standard.double(forKey: "textFontSize") != 0
        ? UserDefaults.standard.double(forKey: "textFontSize")
        : 28

    var body: some View {
        VStack(spacing: 0) {
            if viewModel.isSingleCharActive {
                singleCharPracticeView
            } else {
                passagePracticeView
            }
        }
        .background(Color(nsColor: .windowBackgroundColor))
        .onChange(of: textFontSize) { _, newValue in
            UserDefaults.standard.set(newValue, forKey: "textFontSize")
        }
    }

    // MARK: - 单字/词组练习视图

    private var singleCharProgress: String {
        let suffix: String
        if viewModel.session.isPhraseMode {
            let total = viewModel.session.phrasePool.count
            let current = min(viewModel.session.phraseIndex, total)
            suffix = "第 \(current)/\(total) 词"
        } else {
            let total = viewModel.session.charPool.count
            let current = min(viewModel.session.poolIndex, total)
            suffix = "第 \(current)/\(total) 字"
        }
        if let batch = viewModel.currentBatchNumber {
            return "\(suffix) · 第 \(batch)/\(viewModel.totalBatches) 批"
        }
        return suffix
    }

    private var singleCharPracticeView: some View {
        VStack(spacing: 20) {
            HStack {
                Text(viewModel.session.mode.rawValue)
                    .font(.headline)
                    .foregroundColor(.secondary)
                Spacer()
                Text(singleCharProgress)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .monospacedDigit()
            }
            .padding(.horizontal)
            .padding(.top, 12)

            Spacer()

            Text(viewModel.currentDisplayChar)
                .font(.system(size: 72, weight: .bold, design: .default))
                .foregroundColor(targetCharColor)
                .frame(height: 100)

            if viewModel.showWubiHints, let code = viewModel.currentCharCode {
                Text(code.uppercased())
                    .font(.system(size: 24, design: .monospaced))
                    .foregroundColor(.blue)
                    .bold()

                HStack(spacing: 12) {
                    if let decomp = viewModel.currentDecomposition, !decomp.isEmpty {
                        Text("〔\(decomp)〕")
                            .font(Font.custom(RadicalFontManager.fontName, size: 16))
                    }
                    if let pinyin = viewModel.currentPinyin, !pinyin.isEmpty {
                        Text(pinyin)
                            .font(.caption)
                            .foregroundColor(.secondary.opacity(0.7))
                    }
                    if let cs = viewModel.currentCharset, !cs.isEmpty {
                        Text(cs)
                            .font(.caption2)
                            .foregroundColor(.secondary.opacity(0.5))
                    }
                }
            }

            TextField("输入文字", text: $viewModel.inputText)
                .textFieldStyle(.roundedBorder)
                .font(.system(size: 24, design: .monospaced))
                .frame(width: 250)
                .multilineTextAlignment(.center)
                .focused($singleCharFocused)
                .disabled(viewModel.session.isCompleted || viewModel.session.isPaused)
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(viewModel.session.isPaused ? Color.orange : Color.clear, lineWidth: 1.5)
                )
                .overlay(alignment: .topTrailing) {
                    if viewModel.session.isCompleted {
                        Label("完成!", systemImage: "checkmark.circle.fill")
                            .foregroundColor(.green)
                            .font(.caption)
                            .offset(x: 0, y: -18)
                    } else if viewModel.session.isPaused {
                        Label("已暂停", systemImage: "pause.circle.fill")
                            .foregroundColor(.orange)
                            .font(.caption)
                            .offset(x: 0, y: -18)
                    }
                }

            HStack(spacing: 16) {
                Button("跳过") {
                    viewModel.restartSingleChar()
                }
                .buttonStyle(.bordered)
            }
            .padding(.top, 8)

            Spacer()
        }
        .onAppear {
            singleCharFocused = true
        }
        .onChange(of: singleCharFocused) { _, focused in
            if focused, viewModel.session.isPaused, viewModel.isActive {
                viewModel.togglePause()
            } else if !focused, viewModel.isActive, !viewModel.session.isPaused {
                viewModel.togglePause()
            }
        }
    }

    private var targetCharColor: Color {
        switch viewModel.feedbackType {
        case .correct: return .green
        case .wrong: return .red
        case .none: return .primary
        }
    }

    // MARK: - 文章/文本练习视图

    private var passagePracticeView: some View {
        VStack(spacing: 0) {
            ProgressBarView(progress: viewModel.stats.progress, isCompleted: viewModel.session.isCompleted)
                .padding(.horizontal)
                .padding(.top, 8)

            ReferenceTextView(
                targetChars: viewModel.targetTextChars,
                typedChars: viewModel.typedTextChars,
                cursorPos: viewModel.session.typedText.count,
                previousCursorPos: previousCursorPos,
                fontSize: CGFloat(textFontSize),
                appearanceVersion: colorScheme == .dark ? 1 : 0,
                passageVersion: viewModel.passageVersion
            )
            .onChange(of: viewModel.session.typedText.count) { _, newPos in
                previousCursorPos = newPos
            }
            .padding(.horizontal)
            .padding(.top, 12)

            FontSizeAdjustBar(fontSize: $textFontSize, minFontSize: minFontSize, maxFontSize: maxFontSize)
                .padding(.horizontal)
                .padding(.top, 6)

            Divider().padding(.horizontal).padding(.vertical, 8)

            if viewModel.showWubiHints {
                let hints = viewModel.currentCharHints
                WubiHintBar(
                    character: hints.character,
                    code: hints.code,
                    decomposition: hints.decomposition,
                    charset: hints.charset,
                    wubiHint: viewModel.currentWubiHint
                )
                .padding(.horizontal)
                .padding(.bottom, 6)
            }

            InputArea(
                text: $viewModel.inputText,
                isCompleted: viewModel.session.isCompleted,
                isPaused: viewModel.session.isPaused,
                isActive: viewModel.isActive,
                fontSize: CGFloat(textFontSize),
                onTogglePause: { viewModel.togglePause() }
            )
            .padding(.horizontal)
            .padding(.bottom, 12)
        }
        .onAppear { inputFocused = true }
    }
}

/// 进度条组件
private struct ProgressBarView: View, Equatable {
    let progress: Double
    let isCompleted: Bool

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color(nsColor: .controlBackgroundColor))
                    .frame(height: 8)

                RoundedRectangle(cornerRadius: 4)
                    .fill(isCompleted ? Color.green : Color.blue)
                    .frame(width: geo.size.width * CGFloat(progress), height: 8)
                    .animation(.easeInOut(duration: 0.2), value: progress)
            }
        }
        .frame(height: 8)
    }
}

/// 对照文本显示组件
/// 使用 TextViewer 渲染，正确字符标绿、错误字符标红 + 背景高亮
private struct ReferenceTextView: View, Equatable {
    let targetChars: [Character]
    let typedChars: [Character]
    let cursorPos: Int
    let previousCursorPos: Int
    let fontSize: CGFloat
    let appearanceVersion: Int
    let passageVersion: Int

    static func == (lhs: ReferenceTextView, rhs: ReferenceTextView) -> Bool {
        lhs.targetChars == rhs.targetChars &&
        lhs.typedChars == rhs.typedChars &&
        lhs.cursorPos == rhs.cursorPos &&
        lhs.fontSize == rhs.fontSize &&
        lhs.appearanceVersion == rhs.appearanceVersion &&
        lhs.passageVersion == rhs.passageVersion
    }

    private var changedIndex: Int {
        if cursorPos > 0 && cursorPos == previousCursorPos + 1 {
            return cursorPos - 1
        }
        return -1
    }

    var body: some View {
        GeometryReader { geo in
            if targetChars.isEmpty {
                Text("载入文本后此处显示对照内容")
                    .foregroundColor(.secondary)
                    .font(.system(size: fontSize, design: .monospaced))
                    .padding(8)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                    .background(Color(nsColor: .textBackgroundColor))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color(nsColor: .separatorColor), lineWidth: 1)
                    )
            } else {
                let nsAttr = buildAttrString(targetChars: targetChars, typedChars: typedChars)
                TextViewer(
                    attributedText: nsAttr,
                    text: .constant(""),
                    cursorPosition: cursorPos,
                    textVersion: passageVersion * 65536 + cursorPos,
                    appearanceVersion: appearanceVersion,
                    fontSize: fontSize,
                    changedIndex: changedIndex
                )
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color(nsColor: .separatorColor), lineWidth: 1)
                )
            }
        }
    }

    private func buildAttrString(targetChars: [Character], typedChars: [Character]) -> NSAttributedString {
        let font = NSFont.monospacedSystemFont(ofSize: fontSize, weight: .regular)
        let dimmedColor = NSColor.resolve { NSColor.labelColor.withAlphaComponent(0.35) }
        let greenColor = NSColor.resolve { NSColor.systemGreen }
        let redColor = NSColor.resolve { NSColor.systemRed }

        let text = String(targetChars)
        let result = NSMutableAttributedString(string: text, attributes: [.font: font, .foregroundColor: dimmedColor])

        guard !typedChars.isEmpty else { return result }

        result.beginEditing()
        var location = 0
        for (index, ch) in targetChars.enumerated() {
            let len = String(ch).utf16.count
            let range = NSRange(location: location, length: len)
            if index < typedChars.count {
                if typedChars[index] == ch {
                    result.addAttribute(.foregroundColor, value: greenColor, range: range)
                } else {
                    result.addAttribute(.foregroundColor, value: redColor, range: range)
                    result.addAttribute(.backgroundColor, value: redColor.withAlphaComponent(0.25), range: range)
                }
            }
            location += len
        }
        result.endEditing()
        return result
    }
}

// MARK: - Wubi 编码提示

private struct WubiHintBar: View, Equatable {
    let character: Character?
    let code: String?
    let decomposition: String?
    let charset: String?
    let wubiHint: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "character.book.closed.fill")
                .foregroundColor(.secondary)
                .font(.caption)

            if let char = character {
                Text("当前: ")
                    .font(.caption)
                    .foregroundColor(.secondary)
                let displayChar = char.isNewline ? "↵" : String(char)
                Text(displayChar)
                    .font(.system(size: 18, design: .monospaced))
                    .bold()
                if let c = code {
                    Text(c.uppercased())
                        .font(.system(size: 16, design: .monospaced))
                        .foregroundColor(.blue)
                        .bold()
                } else {
                    Text("?")
                        .font(.system(size: 16, design: .monospaced))
                        .foregroundColor(.orange)
                }

                if let decomp = decomposition, !decomp.isEmpty {
                    Text("〔\(decomp)〕")
                        .font(Font.custom(RadicalFontManager.fontName, size: 14))
                        .foregroundColor(.secondary)
                }

                if let cs = charset, !cs.isEmpty {
                    Text(cs)
                        .font(.system(size: 9, design: .monospaced))
                        .foregroundColor(.secondary.opacity(0.5))
                        .padding(.horizontal, 4)
                        .padding(.vertical, 1)
                        .background(Color(nsColor: .controlBackgroundColor))
                        .clipShape(RoundedRectangle(cornerRadius: 3))
                }
            }

            if !wubiHint.isEmpty {
                Text("|")
                    .foregroundColor(.secondary)
                Text(wubiHint)
                    .font(.system(size: 14, design: .monospaced))
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
        .padding(8)
        .background(Color(nsColor: .controlBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 6))
    }
}

// MARK: - 输入区

private struct InputArea: View, Equatable {
    @Binding var text: String
    let isCompleted: Bool
    let isPaused: Bool
    let isActive: Bool
    let fontSize: CGFloat
    let onTogglePause: () -> Void

    static func == (lhs: InputArea, rhs: InputArea) -> Bool {
        lhs.isCompleted == rhs.isCompleted &&
        lhs.isPaused == rhs.isPaused &&
        lhs.isActive == rhs.isActive &&
        lhs.fontSize == rhs.fontSize
    }

    private var borderColor: Color {
        if isCompleted { return .green }
        if isPaused { return .orange }
        return Color(nsColor: .separatorColor)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text("输入:")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                if isCompleted {
                    Label("完成!", systemImage: "checkmark.circle.fill")
                        .foregroundColor(.green)
                        .font(.caption)
                } else if isPaused {
                    Label("已暂停", systemImage: "pause.circle.fill")
                        .foregroundColor(.orange)
                        .font(.caption)
                }
            }

            TextViewer(
                attributedText: NSAttributedString(string: text, attributes: [
                    .font: NSFont.monospacedSystemFont(ofSize: fontSize, weight: .regular),
                    .foregroundColor: NSColor.labelColor,
                ]),
                text: $text,
                cursorPosition: 0,
                textVersion: 0,
                appearanceVersion: 0,
                fontSize: fontSize,
                isEditable: true,
                onFocusChange: { focused in
                    if focused, isPaused, isActive {
                        onTogglePause()
                    } else if !focused, !isPaused, isActive {
                        onTogglePause()
                    }
                }
            )
            .frame(minHeight: 60, maxHeight: 120)
            .background(Color(nsColor: .textBackgroundColor))
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(borderColor, lineWidth: 1.5)
            )
            .opacity(isCompleted ? 0.6 : 1)
        }
    }
}

// MARK: - 字号调节

private struct FontSizeAdjustBar: View, Equatable {
    @Binding var fontSize: Double
    let minFontSize: Double
    let maxFontSize: Double

    static func == (lhs: FontSizeAdjustBar, rhs: FontSizeAdjustBar) -> Bool {
        lhs.fontSize == rhs.fontSize
    }

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "textformat.size")
                .foregroundColor(.secondary)
                .font(.caption)

            Button(action: { fontSize = max(minFontSize, fontSize - 2) }) {
                Image(systemName: "minus.circle")
            }
            .buttonStyle(.borderless)
            .help("缩小字号")
            .keyboardShortcut("-", modifiers: .command)

            Text("\(Int(fontSize))")
                .font(.system(.caption, design: .monospaced))
                .foregroundColor(.secondary)
                .frame(minWidth: 24)

            Button(action: { fontSize = min(maxFontSize, fontSize + 2) }) {
                Image(systemName: "plus.circle")
            }
            .buttonStyle(.borderless)
            .help("放大字号")
            .keyboardShortcut("=", modifiers: .command)

            Button(action: { fontSize = 28 }) {
                Image(systemName: "arrow.counterclockwise")
                    .font(.caption2)
            }
            .buttonStyle(.borderless)
            .help("重置字号")

            Spacer()
        }
    }
}

// MARK: - NSColor 外观解析辅助
extension NSColor {
    static func resolve(_ maker: () -> NSColor) -> NSColor {
        var color = NSColor.labelColor
        NSApplication.shared.effectiveAppearance.performAsCurrentDrawingAppearance {
            color = maker()
        }
        return color
    }
}

#Preview {
    PracticeView(viewModel: PracticeViewModel())
        .frame(width: 600, height: 550)
}
