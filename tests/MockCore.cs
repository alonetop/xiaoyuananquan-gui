using System;
using System.Text;

internal static class MockCore
{
    private static void Main()
    {
        Console.OutputEncoding = new UTF8Encoding(false);
        Console.Write("请输入学校所在省份[回车默认江苏省]：");
        var province = Console.ReadLine();
        Console.WriteLine("收到省份：" + province);
        Console.Write("请输入学校名称[关键词也可以]：");
        Console.ReadLine();
        Console.WriteLine("[1] 测试第一学校");
        Console.WriteLine("[2] 测试第二学校");
        Console.Write("请输入学校序号：");
        var choice = Console.ReadLine();
        Console.WriteLine("已选择：" + choice);
        Console.Write("请输入账号：");
        var account = Console.ReadLine();
        Console.WriteLine("收到账号：" + account);
        Console.Write("请输入密码：");
        var password = Console.ReadLine() ?? string.Empty;
        Console.WriteLine("模拟运行完成；密码长度：" + password.Length);
    }
}
