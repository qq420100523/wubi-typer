import SwiftUI

/// 字根表视图
/// 以键盘布局展示五笔86全部字根，按分区着色，支持滚动浏览
struct WubiRootKeyboardView: View {
    private static let keySize: CGFloat = 100
    private static let keySpacing: CGFloat = 6

    var body: some View {
        ScrollView([.vertical, .horizontal]) {
            VStack(alignment: .leading, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("五笔86字根表")
                        .font(.title2)
                        .bold()
                    Text("五笔将汉字字根分为五个区，每个区对应键盘上的一组按键")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                // 分区图例
                HStack(spacing: 16) {
                    ForEach(1...5, id: \.self) { zone in
                        HStack(spacing: 4) {
                            Circle()
                                .fill(zoneColor(zone))
                                .frame(width: 10, height: 10)
                            Text(KeyboardLayout.zoneNames[zone] ?? "")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                }

                // 键盘分区布局
                VStack(spacing: Self.keySpacing) {
                    ForEach(KeyboardLayout.rows.indices, id: \.self) { rowIndex in
                        HStack(spacing: Self.keySpacing) {
                            if rowIndex == 1 {
                                Color.clear.frame(width: Self.keySpacing * 2)
                            }
                            if rowIndex == 2 {
                                Color.clear.frame(width: Self.keySpacing * 5)
                            }

                            ForEach(KeyboardLayout.rows[rowIndex], id: \.self) { key in
                                if let info = KeyboardLayout.keyboard[key.uppercased()] ?? KeyboardLayout.keyboard[key.lowercased()] {
                                    keyCard(info: info)
                                }
                            }
                        }
                    }
                }            }
            .padding()
        }
    }

    /// 单个键位的字根卡片
    private func keyCard(info: WubiKeyInfo) -> some View {
        VStack(spacing: 2) {
            HStack {
                Text(info.name)
                    .font(.system(size: 14))
                    .foregroundColor(.primary)
                    .padding(.leading, 4)
                Spacer()
                Text(info.recognitionCode)
                    .font(Font.custom(RadicalFontManager.fontName, size: 16))
                    .foregroundColor(.red)
                    .lineSpacing(2)
                    .padding(.trailing, 4)
            }
            Text(info.roots)
                .font(Font.custom(RadicalFontManager.fontName, size: 10))
                .foregroundColor(.secondary)
                .lineSpacing(2)
                .lineLimit(nil)
                .multilineTextAlignment(.center)
                .padding(4)
                .frame(maxHeight: .infinity)

            HStack {
                Text(info.key.uppercased())
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(zoneColor(info.zone))
                Text("\(info.zone)\(info.pos)")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(zoneColor(info.zone))
            }
        }
        .frame(width: Self.keySize - 10, height: Self.keySize)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(zoneColor(info.zone).opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(zoneColor(info.zone).opacity(0.3), lineWidth: 1)
                )
        )
    }

    /// 获取分区颜色（委托给 Color.wubiZone）
    private func zoneColor(_ zone: Int) -> Color {
        Color.wubiZone(zone)
    }
}

#Preview {
    WubiRootKeyboardView()
        .frame(width: 650, height: 500)
}
