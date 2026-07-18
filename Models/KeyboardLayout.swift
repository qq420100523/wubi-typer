import Foundation

// MARK: - 五笔86 键盘布局与参考数据

/// 字根键盘信息
struct WubiKeyInfo {
    let key: String       // 字母键
    let zone: Int         // 分区 (1-5)
    let pos: Int          // 区内位置 (1-5)
    let name: String      // 键名
    let roots: String     // 字根
    let recognitionCode: String // 识别码
}

/// 五笔86 键盘布局、简码与参考数据
enum KeyboardLayout {
    /// 按行排列的键位顺序（每行一个数组）
    static let rows: [[String]] = [
        ["q", "w", "e", "r", "t", "y", "u", "i", "o", "p"],
        ["a", "s", "d", "f", "g", "h", "j", "k", "l"],
        ["z", "x", "c", "v", "b", "n", "m"],
    ]

    /// 分区名称
    static let zoneNames: [Int: String] = [
        1: "横区 (GFDSA)",
        2: "竖区 (HJKLM)",
        3: "撇区 (TREWQ)",
        4: "捺区 (YUIOP)",
        5: "折区 (NBVCX)",
    ]

    /// 字根键盘详细数据
    static let keyboard: [String: WubiKeyInfo] = [
        "a": WubiKeyInfo(key: "a", zone: 1, pos: 5, name: "工", roots: "               ", recognitionCode: ""),
        "b": WubiKeyInfo(key: "b", zone: 5, pos: 2, name: "子", roots: "              ", recognitionCode: "⿱"),
        "c": WubiKeyInfo(key: "c", zone: 5, pos: 4, name: "又", roots: "       ", recognitionCode: ""),
        "d": WubiKeyInfo(key: "d", zone: 1, pos: 3, name: "大", roots: "             ", recognitionCode: "⿻"),
        "e": WubiKeyInfo(key: "e", zone: 3, pos: 3, name: "月", roots: "                  ", recognitionCode: "⿻"),
        "f": WubiKeyInfo(key: "f", zone: 1, pos: 2, name: "土", roots: "           ", recognitionCode: "⿱"),
        "g": WubiKeyInfo(key: "g", zone: 1, pos: 1, name: "王", roots: "      ", recognitionCode: "⿰"),
        "h": WubiKeyInfo(key: "h", zone: 2, pos: 1, name: "目", roots: "          ", recognitionCode: "⿰"),
        "i": WubiKeyInfo(key: "i", zone: 4, pos: 3, name: "水", roots: "                  ", recognitionCode: "⿻"),
        "j": WubiKeyInfo(key: "j", zone: 2, pos: 2, name: "日", roots: "             ", recognitionCode: "⿱"),
        "k": WubiKeyInfo(key: "k", zone: 2, pos: 3, name: "口", roots: "  ", recognitionCode: "⿻"),
        "l": WubiKeyInfo(key: "l", zone: 2, pos: 4, name: "田", roots: "             〇", recognitionCode: ""),
        "m": WubiKeyInfo(key: "m", zone: 2, pos: 5, name: "山", roots: "               ", recognitionCode: ""),
        "n": WubiKeyInfo(key: "n", zone: 5, pos: 1, name: "已", roots: "                                       ", recognitionCode: "⿰"),
        "o": WubiKeyInfo(key: "o", zone: 4, pos: 4, name: "火", roots: "       ", recognitionCode: ""),
        "p": WubiKeyInfo(key: "p", zone: 4, pos: 5, name: "之", roots: "     ", recognitionCode: ""),
        "q": WubiKeyInfo(key: "q", zone: 3, pos: 5, name: "金", roots: "                     ", recognitionCode: ""),
        "r": WubiKeyInfo(key: "r", zone: 3, pos: 2, name: "白", roots: "         ", recognitionCode: "⿱"),
        "s": WubiKeyInfo(key: "s", zone: 1, pos: 4, name: "木", roots: "     ", recognitionCode: ""),
        "t": WubiKeyInfo(key: "t", zone: 3, pos: 1, name: "禾", roots: "          ", recognitionCode: "⿰"),
        "u": WubiKeyInfo(key: "u", zone: 4, pos: 2, name: "立", roots: "              ", recognitionCode: "⿱"),
        "v": WubiKeyInfo(key: "v", zone: 5, pos: 3, name: "女", roots: "        ", recognitionCode: "⿻"),
        "w": WubiKeyInfo(key: "w", zone: 3, pos: 4, name: "人", roots: "      ", recognitionCode: ""),
        "x": WubiKeyInfo(key: "x", zone: 5, pos: 5, name: "纟", roots: "             ", recognitionCode: ""),
        "y": WubiKeyInfo(key: "y", zone: 4, pos: 1, name: "言", roots: "            ", recognitionCode: "⿰"),
        "z": WubiKeyInfo(key: "z", zone: 0, pos: 0, name: "学", roots: "学习键", recognitionCode: ""),
    ]

    /// 键位顺序（用于字根表渲染）
    static let keyOrder: [String] = [
        "g", "f", "d", "s", "a",
        "h", "j", "k", "l", "m",
        "t", "r", "e", "w", "q",
        "y", "u", "i", "o", "p",
        "n", "b", "v", "c", "x",
    ]

    /// 一级简码
    static let yijianJianma: [String: String] = [
        "g": "一", "f": "地", "d": "在", "s": "要", "a": "工",
        "h": "上", "j": "是", "k": "中", "l": "国", "m": "同",
        "t": "和", "r": "的", "e": "有", "w": "人", "q": "我",
        "y": "主", "u": "产", "i": "不", "o": "为", "p": "这",
        "n": "民", "b": "了", "v": "发", "c": "以", "x": "经",
    ]

    /// 二级简码（部分常见字）
    static let erjianJianma: [String: String] = [
        "gg": "五", "gf": "于", "gd": "天", "gs": "末", "ga": "开",
        "fg": "寺", "ff": "封", "fd": "地", "fs": "霜", "fa": "城",
        "dg": "大", "df": "夺", "dd": "然", "ds": "李", "da": "左",
        "sg": "本", "sf": "村", "sd": "林", "ss": "林", "sa": "权",
        "ag": "工", "af": "式", "ad": "区", "as": "东", "aa": "式",
        "hg": "睛", "hf": "睦", "hd": "眼", "hs": "睡", "ha": "眩",
        "jg": "量", "jf": "时", "jd": "晨", "js": "暗", "ja": "晚",
        "kg": "号", "kf": "叶", "kd": "顺", "ks": "呆", "ka": "呀",
        "lg": "车", "lf": "轩", "ld": "因", "ls": "困", "la": "囗",
        "mg": "同", "mf": "财", "md": "央", "ms": "朵", "ma": "曲",
        "tg": "生", "tf": "行", "td": "知", "ts": "条", "ta": "长",
        "rg": "后", "rf": "持", "rd": "拓", "rs": "打", "ra": "找",
        "eg": "且", "ef": "肝", "ed": "须", "es": "采", "ea": "肛",
        "wg": "全", "wf": "什", "wd": "化", "ws": "代", "wa": "他",
        "qg": "金", "qf": "针", "qd": "钱", "qs": "钉", "qa": "氏",
        "yg": "主", "yf": "计", "yd": "庆", "ys": "订", "ya": "度",
        "ug": "立", "uf": "妆", "ud": "关", "us": "前", "ua": "并",
        "ig": "水", "if": "江", "id": "没", "is": "酒", "ia": "汉",
        "og": "业", "of": "灶", "od": "类", "os": "米", "oa": "炒",
        "pg": "之", "pf": "社", "pd": "实", "ps": "写", "pa": "家",
        "ng": "民", "nf": "敢", "nd": "取", "ns": "耻", "na": "职",
        "bg": "了", "bf": "子", "bd": "也", "bs": "承", "ba": "际",
        "vg": "发", "vf": "妇", "vd": "如", "vs": "杂", "va": "毁",
        "cg": "以", "cf": "戏", "cd": "观", "cs": "邓", "ca": "双",
        "xg": "经", "xf": "给", "xd": "细", "xs": "纲", "xa": "纪",
    ]

    /// 获取按键对应的分区
    /// - Parameter key: 小写字母键
    /// - Returns: 分区编号（0 表示未知/学习键）
    static func zone(for key: String) -> Int {
        keyboard[key.lowercased()]?.zone ?? 0
    }
}
