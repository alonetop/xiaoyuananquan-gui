import Foundation

@main
struct PromptParserTests {
    static func require(_ condition: @autoclosure () -> Bool, _ message: String) {
        if !condition() {
            FileHandle.standardError.write(Data(("FAIL: " + message + "\n").utf8))
            exit(1)
        }
    }

    static func main() {
        let parser = PromptParser()
        require(parser.feed("请输入学校所").isEmpty, "partial prompt must be buffered")
        require(parser.feed("在省份[回车默认江苏省]：") == [.province], "fragmented province prompt")
        require(parser.feed("说明\n请输入学校名称[关键词也可以]：请输入账号：") == [.school, .account], "multiple prompts in one chunk")
        parser.reset()
        require(parser.feed("请输入学校序号：") == [.choice], "school choice prompt")
        require(parser.feed("请输入密码：") == [.password], "password prompt")
        print("PromptParserTests passed")
    }
}
