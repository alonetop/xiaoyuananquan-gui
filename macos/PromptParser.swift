import Foundation

enum Prompt: String, CaseIterable {
    case province = "请输入学校所在省份[回车默认江苏省]："
    case school = "请输入学校名称[关键词也可以]："
    case choice = "请输入学校序号："
    case account = "请输入账号："
    case password = "请输入密码："
}

final class PromptParser {
    private var buffer = ""

    func reset() {
        buffer = ""
    }

    func feed(_ text: String) -> [Prompt] {
        buffer += text
        var prompts: [Prompt] = []

        while true {
            var earliest: (Prompt, Range<String.Index>)?
            for prompt in Prompt.allCases {
                if let range = buffer.range(of: prompt.rawValue),
                   earliest == nil || range.lowerBound < earliest!.1.lowerBound {
                    earliest = (prompt, range)
                }
            }

            guard let (prompt, range) = earliest else {
                if buffer.count > 4096 {
                    buffer = String(buffer.suffix(2048))
                }
                return prompts
            }

            buffer.removeSubrange(buffer.startIndex..<range.upperBound)
            prompts.append(prompt)
        }
    }
}
