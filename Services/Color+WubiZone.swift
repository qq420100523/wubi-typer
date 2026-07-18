import SwiftUI

/// 五笔分区颜色
/// 将键盘的 1~5 区映射为不同颜色，用于字根表、简码表等界面
extension Color {
    /// 获取指定分区对应的颜色
    /// - Parameter zone: 分区编号（1-5）
    /// - Returns: 对应颜色，超出范围返回灰色
    static func wubiZone(_ zone: Int) -> Color {
        let colors: [Int: Color] = [
            1: .red,
            2: .teal,
            3: .blue,
            4: .green,
            5: .yellow,
        ]
        return colors[zone] ?? .gray
    }
}
