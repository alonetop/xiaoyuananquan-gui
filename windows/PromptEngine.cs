using System;
using System.Collections.Generic;

namespace XiaoyuanAnQuanTongGUI
{
    internal enum PromptKind
    {
        Province,
        School,
        Choice,
        Account,
        Password
    }

    internal sealed class PromptEngine
    {
        private static readonly KeyValuePair<PromptKind, string>[] Prompts =
        {
            new KeyValuePair<PromptKind, string>(PromptKind.Province, "请输入学校所在省份[回车默认江苏省]："),
            new KeyValuePair<PromptKind, string>(PromptKind.School, "请输入学校名称[关键词也可以]："),
            new KeyValuePair<PromptKind, string>(PromptKind.Choice, "请输入学校序号："),
            new KeyValuePair<PromptKind, string>(PromptKind.Account, "请输入账号："),
            new KeyValuePair<PromptKind, string>(PromptKind.Password, "请输入密码：")
        };

        private string buffer = string.Empty;

        internal void Reset()
        {
            buffer = string.Empty;
        }

        internal IReadOnlyList<PromptKind> Feed(string text)
        {
            buffer += text;
            var found = new List<PromptKind>();

            while (true)
            {
                var bestIndex = -1;
                var bestLength = 0;
                var bestKind = PromptKind.Province;

                foreach (var prompt in Prompts)
                {
                    var index = buffer.IndexOf(prompt.Value, StringComparison.Ordinal);
                    if (index >= 0 && (bestIndex < 0 || index < bestIndex))
                    {
                        bestIndex = index;
                        bestLength = prompt.Value.Length;
                        bestKind = prompt.Key;
                    }
                }

                if (bestIndex < 0)
                {
                    if (buffer.Length > 4096)
                    {
                        buffer = buffer.Substring(buffer.Length - 2048);
                    }
                    return found;
                }

                buffer = buffer.Substring(bestIndex + bestLength);
                found.Add(bestKind);
            }
        }
    }
}
