import SwiftUI

/// 文章选择列表视图
/// 支持选择内置文章、导入自定义文章，以及按需从外部来源获取文章
@MainActor
struct ArticleListView: View {
    @Bindable var viewModel: PracticeViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var articleListVM = ArticleListViewModel()
    @State private var showImportSheet = false
    @State private var importTitle = ""
    @State private var importText = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "book.fill")
                    .foregroundColor(.accentColor)
                Text("选择练习文章")
                    .font(.headline)
                Spacer()
                Button("导入文章") {
                    showImportSheet.toggle()
                }
                .font(.caption)
            }

            Divider()

            if articleListVM.allArticles.isEmpty, articleListVM.zhihuArticles.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "text.alignleft")
                        .font(.largeTitle)
                        .foregroundColor(.secondary)
                    Text("暂无可用文章")
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List {
                    Section("内置文章") {
                        ForEach(articleListVM.allArticles) { article in
                            articleRow(article)
                        }
                    }

                    if !articleListVM.zhihuArticles.isEmpty {
                        Section("知乎日报") {
                            ForEach(articleListVM.zhihuArticles) { article in
                                Button(action: {
                                    viewModel.startArticle(article.asArticleEntry)
                                    dismiss()
                                }) {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(article.title)
                                            .font(.body)
                                            .foregroundColor(.primary)
                                            .lineLimit(2)
                                        HStack(spacing: 8) {
                                            Text("知乎日报")
                                                .font(.caption2)
                                                .padding(.horizontal, 4)
                                                .padding(.vertical, 1)
                                                .background(Color.green.opacity(0.1))
                                                .foregroundColor(.green)
                                                .clipShape(RoundedRectangle(cornerRadius: 3))
                                            Text(article.bodyText.count > 0 ? "\(article.bodyText.count) 字" : "")
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                            Text(article.updatedAt, style: .date)
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                            Button(action: { articleListVM.saveZhihuArticle(article) }) {
                                                Image(systemName: "square.and.arrow.down")
                                                    .font(.caption)
                                                    .foregroundColor(.accentColor)
                                                    .offset(y: -2)
                                            }
                                            .buttonStyle(.plain)
                                            .help("保存到自定义文章")
                                        }
                                    }
                                }
                                .buttonStyle(.plain)
                                .padding(.vertical, 2)
                            }
                        }
                    }
                }
                .listStyle(.sidebar)
            }

            Divider()

            externalSources
        }
        .padding()
        .frame(width: 440, height: 480)
        .sheet(isPresented: $showImportSheet) {
            importSheet
        }
        .onAppear {
            articleListVM.loadCustomArticles()
        }
    }

    /// 外部文章来源按钮区（可在此追加新来源）
    private var externalSources: some View {
        VStack(spacing: 8) {
            Button(action: { articleListVM.fetchZhihu() }) {
                HStack {
                    Image(systemName: "newspaper")
                        .foregroundColor(.green)
                    Text("从知乎日报获取")
                        .foregroundColor(.primary)
                    Spacer()
                    if articleListVM.isRefreshingZhihu {
                        ProgressView()
                            .controlSize(.small)
                    } else {
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(10)
                .background(Color(nsColor: .controlBackgroundColor))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            .buttonStyle(.plain)
            .disabled(articleListVM.isRefreshingZhihu)

            if let msg = articleListVM.zhihuSuccessMessage {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                        .font(.caption)
                    Text(msg)
                        .font(.caption)
                        .foregroundColor(.green)
                }
                .transition(.opacity)
            } else if let error = articleListVM.zhihuError {
                HStack {
                    Image(systemName: "exclamationmark.triangle")
                        .foregroundColor(.orange)
                        .font(.caption)
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Button("重试") { articleListVM.fetchZhihu() }
                        .font(.caption)
                }
            }
        }
    }

    // MARK: - 文章行

    private func articleRow(_ article: ArticleEntry) -> some View {
        Button(action: {
            viewModel.startArticle(article)
            dismiss()
        }) {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(article.title)
                        .font(.body)
                        .foregroundColor(.primary)
                    if articleListVM.isCustom(article) {
                        Text("自定义")
                            .font(.caption2)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.orange.opacity(0.15))
                            .foregroundColor(.orange)
                            .clipShape(RoundedRectangle(cornerRadius: 4))
                    }
                    Spacer()
                    if articleListVM.isCustom(article) {
                        Button(role: .destructive) {
                            articleListVM.deleteCustom(article)
                        } label: {
                            Image(systemName: "trash")
                                .font(.caption)
                        }
                        .buttonStyle(.plain)
                        .help("删除此文章")
                    }
                }
                Text("\(article.text.count) 字")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .buttonStyle(.plain)
        .padding(.vertical, 4)
        .contextMenu {
            if articleListVM.isCustom(article) {
                Button("删除", role: .destructive) {
                    articleListVM.deleteCustom(article)
                }
            }
        }
    }

    // MARK: - 导入 sheet

    private var importSheet: some View {
        VStack(spacing: 16) {
            Text("导入自定义文章")
                .font(.headline)

            TextField("文章标题", text: $importTitle)
                .textFieldStyle(.roundedBorder)

            TextEditor(text: $importText)
                .font(.system(size: 14, design: .monospaced))
                .frame(minHeight: 150)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color(nsColor: .separatorColor), lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: 8))

            HStack {
                Text("字数: \(importText.count)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                Button("取消") {
                    showImportSheet = false
                }
                .keyboardShortcut(.escape)

                Button("导入") {
                    if let _ = articleListVM.importCustomArticle(title: importTitle, text: importText) {
                        importTitle = ""
                        importText = ""
                        showImportSheet = false
                    }
                }
                .keyboardShortcut(.return)
                .disabled(importTitle.trimmingCharacters(in: .whitespaces).isEmpty ||
                          importText.trimmingCharacters(in: .whitespaces).count < 2)
            }
        }
        .padding()
        .frame(width: 400, height: 350)
    }
}

#Preview {
    ArticleListView(viewModel: PracticeViewModel())
}
