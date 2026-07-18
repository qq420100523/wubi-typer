import SwiftUI

/// 练习模式选择器 — 显示所有可用模式的按钮行
@MainActor
struct ModeSelectorView: View {
    @Bindable var viewModel: PracticeViewModel
    @State private var showModeConfirmation = false
    @State private var pendingMode: PracticeMode?
    @State private var showZoneMenu = false
    @State private var showCommonMenu = false

    private static let zoneModes: [PracticeMode] = [.zone1, .zone2, .zone3, .zone4, .zone5]
    private static let commonModes: [PracticeMode] = [.common0_500, .common500_1000, .common1000_15000]

    private var sessionHasActivity: Bool {
        viewModel.session.startTime != nil || viewModel.session.typedText.count > 0
    }

    private func isGroupActive(_ group: [PracticeMode]) -> Bool {
        group.contains(viewModel.session.mode)
    }

    private func selectMode(_ mode: PracticeMode) {
        if mode != viewModel.session.mode, sessionHasActivity {
            viewModel.suspendTimer()
            pendingMode = mode
            showModeConfirmation = true
        } else {
            viewModel.setMode(mode)
        }
    }

    private func modeLabel(_ text: String, isActive: Bool) -> some View {
        Text(text)
            .font(.caption.weight(isActive ? .semibold : .regular))
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(isActive ? Color.accentColor : Color(nsColor: .controlBackgroundColor))
            .foregroundColor(isActive ? Color(nsColor: .alternateSelectedControlTextColor) : .primary)
            .clipShape(RoundedRectangle(cornerRadius: 6))
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(isActive ? Color.accentColor : Color(nsColor: .separatorColor),
                            lineWidth: isActive ? 1.5 : 0.5)
            )
    }

    private func popoverContent(modes: [PracticeMode], isShowing: Binding<Bool>) -> some View {
        VStack(spacing: 2) {
            ForEach(modes) { mode in
                let modeActive = viewModel.session.mode == mode
                Button(action: { isShowing.wrappedValue = false; selectMode(mode) }) {
                    Text(mode.rawValue)
                        .font(.body.weight(modeActive ? .semibold : .regular))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(modeActive ? Color.accentColor : Color.clear)
                        .foregroundColor(modeActive ? Color(nsColor: .alternateSelectedControlTextColor) : .primary)
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(6)
        .frame(width: 140)
    }

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                Button(action: { selectMode(.random) }) {
                    modeLabel(PracticeMode.random.rawValue, isActive: viewModel.session.mode == .random)
                }
                .buttonStyle(.plain)

                Button(action: { showZoneMenu.toggle() }) {
                    modeLabel("分区字", isActive: isGroupActive(Self.zoneModes))
                }
                .buttonStyle(.plain)
                .popover(isPresented: $showZoneMenu, arrowEdge: .top) {
                    popoverContent(modes: Self.zoneModes, isShowing: $showZoneMenu)
                }

                Button(action: { showCommonMenu.toggle() }) {
                    modeLabel("高频字", isActive: isGroupActive(Self.commonModes))
                }
                .buttonStyle(.plain)
                .popover(isPresented: $showCommonMenu, arrowEdge: .top) {
                    popoverContent(modes: Self.commonModes, isShowing: $showCommonMenu)
                }

                Button(action: { selectMode(.mistakes) }) {
                    modeLabel(PracticeMode.mistakes.rawValue, isActive: viewModel.session.mode == .mistakes)
                }
                .buttonStyle(.plain)

                Button(action: { selectMode(.phrase) }) {
                    modeLabel(PracticeMode.phrase.rawValue, isActive: viewModel.session.mode == .phrase)
                }
                .buttonStyle(.plain)

                Button(action: { selectMode(.article) }) {
                    modeLabel(PracticeMode.article.rawValue, isActive: viewModel.session.mode == .article)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 4)
        }
        .padding(.vertical, 6)
        .confirmationDialog("切换模式", isPresented: $showModeConfirmation) {
            Button("切换", role: .destructive) {
                if let mode = pendingMode { viewModel.setMode(mode) }
            }
            Button("取消", role: .cancel) {
                viewModel.resumeTimer()
                pendingMode = nil
            }
        } message: {
            Text("当前练习进度将会丢失，确定要切换模式吗？")
        }
    }
}

#Preview {
    ModeSelectorView(viewModel: PracticeViewModel())
        .frame(width: 500)
        .padding()
}
