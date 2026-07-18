import SwiftUI

/// 简码一览视图
/// 展示一级简码（25 个高频字）和二级简码（部分常见字），方便用户查阅记忆
struct ShortCodeView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // 一级简码区
                VStack(alignment: .leading, spacing: 8) {
                    Text("一级简码")
                        .font(.title2)
                        .bold()
                    Text("25个最高频汉字，按一个键加空格即可输入")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 6), count: 5), spacing: 6) {
                        let sortedKeys = KeyboardLayout.keyOrder
                        ForEach(sortedKeys, id: \.self) { key in
                            if let char = KeyboardLayout.yijianJianma[key] {
                                jianmaCard(key: key.uppercased(), char: char, zone: KeyboardLayout.zone(for: key))
                            }
                        }
                    }
                }

                Divider()

                // 二级简码区
                VStack(alignment: .leading, spacing: 8) {
                    Text("二级简码（常见字）")
                        .font(.title2)
                        .bold()
                    Text("按两个键加空格即可输入。以下是部分常见二级简码字。")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 6), count: 5), spacing: 6) {
                        let sorted = KeyboardLayout.erjianJianma.sorted { $0.key < $1.key }
                        ForEach(sorted, id: \.key) { code, char in
                            VStack(spacing: 2) {
                                Text(char)
                                    .font(.system(size: 18, weight: .medium))
                                Text(code.uppercased())
                                    .font(.system(size: 10, design: .monospaced))
                                    .foregroundColor(.blue)
                            }
                            .frame(width: 70, height: 50)
                            .background(
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(Color(nsColor: .controlBackgroundColor))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 6)
                                            .stroke(Color(nsColor: .separatorColor), lineWidth: 0.5)
                                    )
                            )
                        }
                    }
                }
            }
            .padding()
        }
    }

    /// 一级简码卡片视图
    private func jianmaCard(key: String, char: String, zone: Int) -> some View {
        VStack(spacing: 4) {
            Text(char)
                .font(.system(size: 24, weight: .bold))
            Text(key)
                .font(.system(size: 12, weight: .medium, design: .monospaced))
                .foregroundColor(Color.wubiZone(zone))
        }
        .frame(width: 80, height: 70)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.wubiZone(zone).opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.wubiZone(zone).opacity(0.3), lineWidth: 1)
                )
        )
    }
}

#Preview {
    ShortCodeView()
        .frame(width: 500, height: 600)
}
