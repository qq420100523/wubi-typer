import SwiftUI

/// 五笔86输入规则说明视图
/// 涵盖单字全码、末笔识别码、简码、词组输入、键名字等规则
struct WubiRulesView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("五笔86输入规则")
                    .font(.title2)
                    .bold()

                // 规则段落
                ruleSection(title: "一、单字全码") {
                    Text("按书写顺序取字根编码，最多取 **4 码**。")

                    ruleCase(label: "刚好4个字根") {
                        Text("按顺序全部取。如 ")
                        + codeText("照")
                        + Text(" = 日+刀+口+灬 = ")
                        + codeText("JVKO")
                    }

                    ruleCase(label: "超过4个字根") {
                        Text("取第1、2、3、末。如 ")
                        + codeText("赣")
                        + Text(" = 立+早+夂+贝 = ")
                        + codeText("UJTM")
                    }

                    ruleCase(label: "不足4个字根") {
                        Text("依次取完后，补加")
                        + Text("末笔字型识别码").bold()
                    }
                }

                ruleSection(title: "二、末笔识别码") {
                    Text("当字根不足4码时，用最后一笔的笔画类型 × 字型结构来确定识别码。")

                    VStack(spacing: 0) {
                        HStack {
                            Text("").frame(width: 60)
                            Text("左右型").frame(maxWidth: .infinity)
                            Text("上下型").frame(maxWidth: .infinity)
                            Text("杂合型").frame(maxWidth: .infinity)
                        }
                        .font(.caption.bold())
                        .padding(.vertical, 6)
                        .background(Color(nsColor: .controlBackgroundColor))

                        Divider()

                        ForEach(recognitionCodeRows, id: \.0) { row in
                            HStack {
                                Text(row.0).bold().frame(width: 60)
                                Text(row.1).frame(maxWidth: .infinity)
                                Text(row.2).frame(maxWidth: .infinity)
                                Text(row.3).frame(maxWidth: .infinity)
                            }
                            .font(.system(.caption, design: .monospaced))
                            .padding(.vertical, 4)
                            Divider()
                        }
                    }
                    .background(Color(nsColor: .textBackgroundColor))
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(Color(nsColor: .separatorColor), lineWidth: 1)
                    )

                    let exampleText = Text("例：") + codeText("叭") + Text(" = 口+八，末笔捺(4)，左右型(1) → 识别码 ") + codeText("Y") + Text("，全码 ") + codeText("KWY")
                    exampleText
                        .font(.caption)
                        .padding(.top, 4)
                }

                ruleSection(title: "三、简码输入") {
                    ruleCase(label: "一级简码") {
                        Text("按 1 个字母 + 空格。如 ")
                        + codeText("我 → Q + 空格")
                        + Text("（共25个高频字）")
                    }
                    ruleCase(label: "二级简码") {
                        Text("按 2 个字母 + 空格。如 ")
                        + codeText("五 → GG + 空格")
                    }
                    ruleCase(label: "三级简码") {
                        Text("按 3 个字母 + 空格。如 ")
                        + codeText("想 → SHN + 空格")
                    }
                }

                ruleSection(title: "四、词组输入") {
                    ruleCase(label: "两字词") {
                        Text("每字各取前两码。如 ")
                        + codeText("中国")
                        + Text(" = 中(KH)+国(LG) = ")
                        + codeText("KHLG")
                    }
                    ruleCase(label: "三字词") {
                        Text("前两字各取第一码，最后一字取前两码。如 ")
                        + codeText("计算机")
                        + Text(" = 言(Y)+竹(T)+木(S) = ")
                        + codeText("YTSM")
                    }
                    ruleCase(label: "四字及以上") {
                        Text("前三字各取第一码，最后一字取第一码。如 ")
                        + codeText("中华人民共和国")
                        + Text(" = ")
                        + codeText("KWWL")
                    }
                }

                ruleSection(title: "五、键名字") {
                    Text("每个键的键名字连按4次即可输入。如 ")
                    + codeText("王 → GGGG")
                    + Text("，")
                    + codeText("大 → DDDD")
                    + Text("，")
                    + codeText("金 → QQQQ")
                }
            }
            .padding()
        }
    }

    /// 规则分区标题
    @ViewBuilder
    private func ruleSection(title: String, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
                .foregroundColor(.primary)
            content()
                .font(.callout)
                .foregroundColor(.secondary)
        }
    }

    /// 规则示例条目（左侧标签 + 右侧内容）
    @ViewBuilder
    private func ruleCase(label: String, @ViewBuilder content: () -> some View) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Text(label)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.accentColor)
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(Color.accentColor.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 4))

            content()
                .font(.callout)
        }
        .padding(.leading, 8)
    }

    /// 将文本渲染为等宽蓝色代码样式
    private func codeText(_ text: String) -> Text {
        Text(text)
            .font(.system(.callout, design: .monospaced))
            .foregroundColor(.blue)
    }

    /// 末笔识别码表：笔画 × 字型
    private let recognitionCodeRows: [(String, String, String, String)] = [
        ("横 (1)", "G", "F", "D"),
        ("竖 (2)", "H", "J", "K"),
        ("撇 (3)", "T", "R", "E"),
        ("捺 (4)", "Y", "U", "I"),
        ("折 (5)", "N", "B", "V"),
    ]
}

#Preview {
    WubiRulesView()
        .frame(width: 500, height: 700)
}
