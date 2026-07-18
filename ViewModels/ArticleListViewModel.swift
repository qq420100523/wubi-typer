import Foundation
import Observation

/// 文章列表视图模型
/// 管理内置文章、用户自定义文章，支持按需从外部源（如知乎日报）获取文章
@MainActor
@Observable
final class ArticleListViewModel {
    private(set) var customArticles: [ArticleEntry] = []
    private(set) var zhihuArticles: [ZhihuArticle] = []
    var isRefreshingZhihu = false
    var zhihuError: String?
    var zhihuSuccessMessage: String?

    private let storageKey = "wubi-custom-articles"

    /// 全部可用文章（内置 + 自定义）
    var allArticles: [ArticleEntry] {
        ArticleData.all + customArticles
    }

    /// 从 UserDefaults 加载自定义文章
    func loadCustomArticles() {
        guard let data = UserDefaults.standard.data(forKey: storageKey),
              let articles = try? JSONDecoder().decode([ArticleEntry].self, from: data)
        else { return }
        customArticles = articles
    }

    /// 将自定义文章持久化到 UserDefaults
    private func saveCustomArticles() {
        guard let data = try? JSONEncoder().encode(customArticles) else { return }
        UserDefaults.standard.set(data, forKey: storageKey)
    }

    /// 导入一篇自定义文章
    func importCustomArticle(title: String, text: String) -> ArticleEntry? {
        let trimmedTitle = title.trimmingCharacters(in: .whitespaces)
        let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty, trimmedText.count >= 2 else { return nil }

        let article = ArticleEntry(id: "custom_\(Date().timeIntervalSince1970)", title: trimmedTitle, text: trimmedText)
        customArticles.append(article)
        saveCustomArticles()
        return article
    }

    /// 删除一篇自定义文章
    func deleteCustom(_ article: ArticleEntry) {
        customArticles.removeAll { $0.id == article.id }
        saveCustomArticles()
    }

    /// 将知乎文章保存为自定义文章
    func saveZhihuArticle(_ article: ZhihuArticle) {
        let entry = article.asArticleEntry
        let savedId = "saved_zhihu_\(article.storyId)"
        let saved = ArticleEntry(id: savedId, title: entry.title, text: entry.text)
        if !customArticles.contains(where: { $0.id == savedId }) {
            customArticles.append(saved)
            saveCustomArticles()
        }
    }

    /// 判断是否为自定义文章
    func isCustom(_ article: ArticleEntry) -> Bool {
        article.id.hasPrefix("custom_") || article.id.hasPrefix("saved_zhihu_")
    }

    // MARK: - 知乎日报

    /// 从网络获取知乎日报文章
    func fetchZhihu() {
        guard !isRefreshingZhihu else { return }
        isRefreshingZhihu = true
        zhihuError = nil

        Task {
            let articles = await ZhihuDailyService.shared.fetchLatest()
            await MainActor.run {
                zhihuArticles = articles
                isRefreshingZhihu = false
                if articles.isEmpty {
                    zhihuError = "获取失败，请检查网络连接后重试"
                } else {
                    zhihuSuccessMessage = "已获取 \(articles.count) 篇知乎文章"
                    Task {
                        try? await Task.sleep(for: .seconds(2))
                        zhihuSuccessMessage = nil
                    }
                }
            }
        }
    }
}
