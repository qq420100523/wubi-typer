import SwiftUI
import AppKit

/// 基于 NSTextView 的文本显示/编辑器
/// 支持对照文本的逐字着色（正确/错误）、光标高亮、滚动追踪，以及可编辑输入模式
struct TextViewer: NSViewRepresentable {
    /// 可选的富文本（对照模式用）
    var attributedText: NSAttributedString
    /// 文本绑定（输入模式用双向绑定）
    @Binding var text: String
    /// 光标位置（对照模式指示当前输入位置）
    var cursorPosition: Int
    /// 文本版本号，变化时触发滚动到光标
    var textVersion: Int
    /// 外观版本号，变化时触发全文重绘（深色/浅色切换）
    var appearanceVersion: Int
    /// 字号
    var fontSize: CGFloat = 18
    /// 最新变化的字符索引（-1 表示全量刷新）
    var changedIndex: Int = -1
    /// 是否可编辑（输入模式）
    var isEditable: Bool = false
    /// 焦点变化回调（输入模式用）
    var onFocusChange: ((Bool) -> Void)?

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSScrollView()
        scrollView.hasVerticalScroller = true
        scrollView.autohidesScrollers = true
        scrollView.borderType = .noBorder
        scrollView.drawsBackground = false

        let textView = EditableTextView()
        textView.isEditable = isEditable
        textView.isSelectable = true
        textView.drawsBackground = false
        textView.textContainerInset = NSSize(width: 8, height: 8)
        textView.textContainer?.lineFragmentPadding = 0
        textView.font = NSFont.monospacedSystemFont(ofSize: fontSize, weight: .regular)
        textView.isVerticallyResizable = true
        textView.autoresizingMask = [.width]
        textView.maxSize = NSSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)

        if isEditable {
            textView.delegate = context.coordinator
        }

        scrollView.documentView = textView
        context.coordinator.textView = textView
        context.coordinator.scrollView = scrollView

        return scrollView
    }

    func updateNSView(_ scrollView: NSScrollView, context: Context) {
        guard let textView = context.coordinator.textView as? EditableTextView,
              let ts = textView.textStorage else { return }

        textView.onBecomeFirstResponder = { [onFocusChange] in
            onFocusChange?(true)
        }

        if isEditable {
            // 输入模式：仅同步纯文本内容
            if ts.string != text {
                ts.setAttributedString(NSAttributedString(string: text, attributes: [
                    .font: NSFont.monospacedSystemFont(ofSize: fontSize, weight: .regular),
                    .foregroundColor: NSColor.labelColor,
                ]))
            }
            context.coordinator.onTextChange = { [binding = _text] newText in
                binding.wrappedValue = newText
            }
            context.coordinator.isFirstUpdate = false
            return
        }

        // 对照模式：渲染带颜色的富文本
        let fullLength = attributedText.length

        if context.coordinator.isFirstUpdate || changedIndex < 0
            || appearanceVersion != context.coordinator.lastAppearanceVersion {
            ts.setAttributedString(attributedText)
            textView.layoutManager?.ensureLayout(for: textView.textContainer!)
            context.coordinator.isFirstUpdate = false
            context.coordinator.lastAppearanceVersion = appearanceVersion
        } else {
            if changedIndex >= 0 && changedIndex < fullLength {
                let newAttrs = attributedText.attributes(at: changedIndex, effectiveRange: nil)
                ts.setAttributes(newAttrs, range: NSRange(location: changedIndex, length: 1))
            }
        }

        // 更新光标下划线
        let oldCursor = context.coordinator.lastCursorPosition
        if oldCursor >= 0 && oldCursor < fullLength && oldCursor != cursorPosition {
            let oldRange = NSRange(location: oldCursor, length: 1)
            ts.removeAttribute(.underlineStyle, range: oldRange)
            ts.removeAttribute(.underlineColor, range: oldRange)
            let oldAttrs = attributedText.attributes(at: oldCursor, effectiveRange: nil)
            if let fg = oldAttrs[.foregroundColor] as? NSColor {
                ts.addAttribute(.foregroundColor, value: fg, range: oldRange)
            }
        }

        if cursorPosition >= 0 && cursorPosition < fullLength {
            let cursorRange = NSRange(location: cursorPosition, length: 1)
            ts.addAttribute(.underlineStyle, value: NSUnderlineStyle.single.rawValue, range: cursorRange)
            let resolvedAccent = NSColor.resolve { NSColor.controlAccentColor }
            ts.addAttribute(.underlineColor, value: resolvedAccent, range: cursorRange)
        }

        context.coordinator.lastCursorPosition = cursorPosition

        guard textVersion != context.coordinator.lastTextVersion else { return }
        context.coordinator.lastTextVersion = textVersion

        // 自动滚动到光标位置
        guard let layoutManager = textView.layoutManager,
              let textContainer = textView.textContainer else { return }

        let glyphRange = layoutManager.glyphRange(forCharacterRange: NSRange(location: cursorPosition, length: 0), actualCharacterRange: nil)
        guard glyphRange.location != NSNotFound else {
            scrollToBottom(scrollView, textView: textView)
            return
        }

        let cursorRect = layoutManager.boundingRect(forGlyphRange: glyphRange, in: textContainer)
        let targetY = cursorRect.origin.y

        let clipView = scrollView.contentView
        let halfHeight = clipView.bounds.height / 2
        let targetOffset = max(0, min(targetY - halfHeight, textView.bounds.height - clipView.bounds.height))

        let currentOffset = clipView.bounds.origin.y
        if abs(targetOffset - currentOffset) > 0.5 {
            NSAnimationContext.beginGrouping()
            NSAnimationContext.current.duration = 0
            clipView.setBoundsOrigin(NSPoint(x: 0, y: targetOffset))
            NSAnimationContext.endGrouping()
        }
    }

    /// 滚动到底部
    private func scrollToBottom(_ scrollView: NSScrollView, textView: NSTextView) {
        let clipView = scrollView.contentView
        let targetOffset = max(0, textView.bounds.height - clipView.bounds.height)
        NSAnimationContext.beginGrouping()
        NSAnimationContext.current.duration = 0
        clipView.setBoundsOrigin(NSPoint(x: 0, y: targetOffset))
        NSAnimationContext.endGrouping()
    }

    /// 协调器，处理 NSTextView 代理回调
    class Coordinator: NSObject, NSTextViewDelegate {
        weak var textView: NSTextView?
        weak var scrollView: NSScrollView?
        var lastTextVersion: Int = -1
        var isFirstUpdate: Bool = true
        var lastAppearanceVersion: Int = -1
        var lastCursorPosition: Int = 0
        /// 文本变化回调（输入模式）
        var onTextChange: ((String) -> Void)?

        func textDidChange(_ notification: Notification) {
            guard let textView, let onTextChange else { return }
            onTextChange(textView.string)
        }
    }
}

/// 可拦截 becomeFirstResponder 的 NSTextView 子类
/// 用于将焦点事件传递给 SwiftUI
private class EditableTextView: NSTextView {
    var onBecomeFirstResponder: (() -> Void)?

    override func becomeFirstResponder() -> Bool {
        let result = super.becomeFirstResponder()
        if result { onBecomeFirstResponder?() }
        return result
    }
}
