using System;
using System.Diagnostics;
using System.Drawing;
using System.IO;
using System.Reflection;
using System.Windows.Forms;

namespace XiaoyuanAnQuanTongGUI
{
    internal sealed class AboutForm : Form
    {
        private const string UpstreamUrl = "https://github.com/hangone/study-xiaoyuananquantong";
        private const string ClientUrl = "https://github.com/alonetop/xiaoyuananquan-gui";

        internal AboutForm(string supportDirectory)
        {
            Text = "关于与开源许可";
            StartPosition = FormStartPosition.CenterParent;
            FormBorderStyle = FormBorderStyle.FixedDialog;
            MaximizeBox = false;
            MinimizeBox = false;
            ClientSize = new Size(540, 360);
            Font = new Font("Microsoft YaHei UI", 9F);

            var text = new Label
            {
                AutoSize = false,
                Location = new Point(24, 22),
                Size = new Size(492, 228),
                Text = "校园安全通图形客户端 v1.1.0\r\n\r\n" +
                       "图形客户端作者：掠过古城的风\r\n" +
                       "GitHub 原作者：hangone\r\n" +
                       "修改日期：2026-09-04\r\n\r\n" +
                       "本软件按 GNU Affero General Public License v3.0 发布。" +
                       "你可以依照该许可证复制、修改和再发布本软件。\r\n\r\n" +
                       "本软件不提供任何明示或默示担保；使用风险由使用者自行承担。"
            };

            var upstream = MakeLink("原项目 GitHub", UpstreamUrl, 24, 255);
            var client = MakeLink("客户端完整源码", ClientUrl, 150, 255);
            var license = new Button { Text = "查看 AGPL-3.0", Location = new Point(286, 250), Size = new Size(118, 30) };
            license.Click += (_, __) => OpenLicense(supportDirectory);
            var close = new Button { Text = "关闭", DialogResult = DialogResult.OK, Location = new Point(416, 250), Size = new Size(100, 30) };

            Controls.AddRange(new Control[] { text, upstream, client, license, close });
            AcceptButton = close;
            CancelButton = close;
        }

        private static LinkLabel MakeLink(string text, string url, int x, int y)
        {
            var link = new LinkLabel { Text = text, AutoSize = true, Location = new Point(x, y + 7) };
            link.LinkClicked += (_, __) => OpenUrl(url);
            return link;
        }

        private static void OpenUrl(string url)
        {
            Process.Start(new ProcessStartInfo(url) { UseShellExecute = true });
        }

        private static void OpenLicense(string supportDirectory)
        {
            Directory.CreateDirectory(supportDirectory);
            var target = Path.Combine(supportDirectory, "LICENSE.txt");
            using (var source = Assembly.GetExecutingAssembly().GetManifestResourceStream("XiaoyuanAnQuanTong.LICENSE"))
            using (var destination = File.Create(target))
            {
                if (source == null) throw new InvalidOperationException("应用内缺少许可证文件");
                source.CopyTo(destination);
            }
            Process.Start(new ProcessStartInfo(target) { UseShellExecute = true });
        }
    }
}
