using System;
using System.Linq;
using XiaoyuanAnQuanTongGUI;

internal static class PromptEngineTests
{
    private static void Require(bool condition, string message)
    {
        if (!condition) throw new Exception("FAIL: " + message);
    }

    private static void Main()
    {
        var parser = new PromptEngine();
        Require(parser.Feed("请输入学校所").Count == 0, "partial prompt must be buffered");
        Require(parser.Feed("在省份[回车默认江苏省]：").SequenceEqual(new[] { PromptKind.Province }), "fragmented province prompt");
        Require(parser.Feed("说明\n请输入学校名称[关键词也可以]：请输入账号：").SequenceEqual(new[] { PromptKind.School, PromptKind.Account }), "multiple prompts in one chunk");
        parser.Reset();
        Require(parser.Feed("请输入学校序号：").SequenceEqual(new[] { PromptKind.Choice }), "school choice prompt");
        Require(parser.Feed("请输入密码：").SequenceEqual(new[] { PromptKind.Password }), "password prompt");
        Console.WriteLine("PromptEngineTests passed");
    }
}
