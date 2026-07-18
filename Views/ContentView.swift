import SwiftUI

/// 主视图 — 侧边栏导航
@MainActor
struct ContentView: View {
    @State private var viewModel = PracticeViewModel()
    @State private var selectedSidebar: SidebarItem? = .practice
    @State private var showArticlePicker = false
    @Environment(\.scenePhase) private var scenePhase

    /// 侧边栏导航项
    enum SidebarItem: String, CaseIterable, Identifiable {
        case practice = "练习"
        case mistakes = "错字本"
        case roots = "字根表"
        case jianma = "简码"
        case rules = "规则"
        case settings = "设置"

        var id: String { rawValue }

        var icon: String {
            switch self {
            case .practice: return "keyboard"
            case .mistakes: return "exclamationmark.triangle"
            case .roots: return "square.grid.3x3"
            case .jianma: return "keyboard.badge.ellipsis"
            case .rules: return "book"
            case .settings: return "gearshape"
            }
        }
    }

    var body: some View {
        NavigationSplitView {
            sidebar
                .navigationSplitViewColumnWidth(min: 160, ideal: 180)
        } detail: {
            mainContent
        }
        .frame(minWidth: 650, minHeight: 550)
        .onReceive(NotificationCenter.default.publisher(for: .loadFromClipboard)) { _ in
            viewModel.loadFromClipboard()
            selectedSidebar = .practice
        }
        .onReceive(NotificationCenter.default.publisher(for: .restart)) { _ in
            viewModel.restart()
        }
        .onReceive(NotificationCenter.default.publisher(for: .togglePause)) { _ in
            viewModel.togglePause()
        }
        .onReceive(NotificationCenter.default.publisher(for: .openSettings)) { _ in
            selectedSidebar = .settings
        }
        .onChange(of: scenePhase) { _, phase in
            switch phase {
            case .active: viewModel.resumeTimer()
            case .inactive, .background: viewModel.suspendTimer()
            @unknown default: break
            }
        }
        .onChange(of: selectedSidebar) { _, newValue in
            if newValue != .practice {
                viewModel.suspendTimer()
            }
        }
        .alert(viewModel.userAlertMessage ?? "", isPresented: Binding(
            get: { viewModel.userAlertMessage != nil },
            set: { if !$0 { viewModel.userAlertMessage = nil } }
        )) {
            Button("确定", role: .cancel) { viewModel.userAlertMessage = nil }
        }
    }

    // MARK: - 侧边栏

    private var sidebar: some View {
        List(selection: $selectedSidebar) {
            Section("五笔打字练习器") {
                ForEach(SidebarItem.allCases) { item in
                    Label(item.rawValue, systemImage: item.icon)
                        .tag(item)
                }
            }

            SidebarStatsView(session: viewModel.session, stats: viewModel.stats)
        }
        .listStyle(.sidebar)
    }

    // MARK: - 主内容区

    @ViewBuilder
    private var mainContent: some View {
        switch selectedSidebar {
        case .practice:
            VStack(spacing: 8) {
                // 模式选择器
                ModeSelectorView(viewModel: viewModel)
                    .padding(.horizontal)

                // 主练习区
                PracticeView(viewModel: viewModel)

                // 工具栏
                toolbar
                    .padding(.horizontal)
                    .padding(.bottom, 8)
            }

        case .mistakes:
            MistakeListView()

        case .roots:
            WubiRootKeyboardView()

        case .jianma:
            ShortCodeView()

        case .rules:
            WubiRulesView()

        case .settings:
            SettingsView(viewModel: viewModel)

        case nil:
            Text("选择一个功能")
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    // MARK: - 工具栏

    private var toolbar: some View {
        HStack(spacing: 8) {
            // 载入文本、选择文章 — 仅文章练习模式
            if viewModel.session.isPassageMode {
                Button(action: {
                    viewModel.loadFromClipboard()
                }) {
                    Label("载入文本", systemImage: "clipboard")
                }
                .help("按 ⌘⇧V 从剪贴板载入文本")

                Button(action: {
                    showArticlePicker.toggle()
                }) {
                    Label("选择文章", systemImage: "book")
                }
                .popover(isPresented: $showArticlePicker) {
                    ArticleListView(viewModel: viewModel)
                }
            }

            Spacer()

            // 重打
            Button(action: {
                viewModel.restart()
            }) {
                Label("重打", systemImage: "arrow.counterclockwise")
            }
            .disabled(!viewModel.isActive)
            .help("按 ⌘R 重新开始")

            // 暂停/继续
            Button(action: {
                viewModel.togglePause()
            }) {
                Label(
                    viewModel.session.isPaused ? "继续" : "暂停",
                    systemImage: viewModel.session.isPaused ? "play.fill" : "pause.fill"
                )
            }
            .disabled(viewModel.session.isCompleted || !viewModel.isActive)
            .help("按 Esc 暂停/继续")
        }
    }
}

// MARK: - 侧边栏统计子视图
private struct SidebarStatsView: View {
    let session: PracticeSession
    let stats: TypingStats

    private var statusIcon: String {
        if session.isCompleted { return "checkmark.circle.fill" }
        if session.isPaused { return "pause.circle.fill" }
        if session.startTime != nil { return "circle.fill" }
        return "circle"
    }

    private var statusColor: Color {
        if session.isCompleted { return .green }
        if session.isPaused { return .orange }
        if session.startTime != nil { return .blue }
        return .secondary
    }

    private var statusText: String {
        if session.isCompleted { return "已完成" }
        if session.isPaused { return "已暂停" }
        if session.startTime != nil { return "练习中" }
        return "待开始"
    }

    var body: some View {
        Section("状态") {
            VStack(alignment: .leading, spacing: 4) {
                Label(statusText, systemImage: statusIcon)
                    .font(.caption)
                    .foregroundColor(statusColor)

                Label("模式: \(session.mode.rawValue)",
                      systemImage: "gearshape")
                    .font(.caption)

                if session.mode == .article || session.isPassageMode {
                    Label("\(stats.targetLength) 字",
                          systemImage: "text.alignleft")
                        .font(.caption)
                } else {
                    Label("\(session.charPool.count) 字",
                          systemImage: "text.alignleft")
                        .font(.caption)
                }

                if session.isCompleted {
                    Label(stats.formattedSpeed,
                          systemImage: "gauge.with.needle")
                        .font(.caption)
                        .foregroundColor(.green)
                }
            }
            .padding(.vertical, 4)
        }
        Section("统计") {
            VStack(alignment: .leading, spacing: 4) {
                Label("用时: \(stats.formattedTime)", systemImage: "clock")
                Label("速度: \(stats.formattedSpeed)", systemImage: "gauge.with.needle")
                Label("准确率: \(stats.formattedAccuracy)", systemImage: "target")
                Label("击键: \(stats.formattedKeystroke)", systemImage: "keyboard")
                Label("正确字符: \(stats.correctCount)", systemImage: "checkmark.circle")
                Label("错误字符: \(stats.errorCount)", systemImage: "xmark.circle")
                Label("总按键: \(stats.keystrokeCount)", systemImage: "hand.tap")
                Label("退格次数: \(stats.backspaceCount)", systemImage: "delete.backward")
                Label("总字数: \(stats.targetLength)", systemImage: "text.alignleft")
                Label("已输入: \(stats.totalTyped)", systemImage: "arrow.right.circle")
                Label("重打次数: \(session.restartCount)", systemImage: "arrow.counterclockwise")
            }
            .font(.caption)
            .padding(.vertical, 4)
        }
    }
}

#Preview {
    ContentView()
        .frame(width: 800, height: 600)
}
