import Foundation

/// 本地持久化存储服务
/// 基于 JSON 编码将数据读写到 App Support 目录
enum StorageService {
    private static let baseDir: URL = {
        let paths = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)
        let dir = paths[0].appendingPathComponent("WubiTypingTrainer")
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }()

    /// 获取指定文件的完整路径
    static func fileURL(fileName: String) -> URL {
        baseDir.appendingPathComponent(fileName)
    }

    /// 将 Codable 对象保存到文件
    static func save<T: Encodable>(_ value: T, to fileName: String) {
        guard let data = try? JSONEncoder().encode(value) else { return }
        try? data.write(to: fileURL(fileName: fileName), options: .atomic)
    }

    /// 从文件加载 Codable 对象
    static func load<T: Decodable>(_ type: T.Type, from fileName: String) -> T? {
        let url = fileURL(fileName: fileName)
        guard let data = try? Data(contentsOf: url),
              let decoded = try? JSONDecoder().decode(type, from: data)
        else { return nil }
        return decoded
    }
}
