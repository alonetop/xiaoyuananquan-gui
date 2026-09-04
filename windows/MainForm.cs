using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.Drawing;
using System.IO;
using System.Reflection;
using System.Text;
using System.Threading.Tasks;
using System.Windows.Forms;

namespace XiaoyuanAnQuanTongGUI
{
    internal sealed class MainForm : Form
    {
        private const string CoreResource = "XiaoyuanAnQuanTong.Core.exe";
        private const string UpstreamUrl = "https://github.com/hangone/study-xiaoyuananquantong";

        private readonly TextBox provinceField = new TextBox { Text = "江苏省" };
        private readonly TextBox schoolField = new TextBox();
        private readonly TextBox accountField = new TextBox();
        private readonly TextBox passwordField = new TextBox { UseSystemPasswordChar = true };
        private readonly Button startButton = new Button { Text = "开始运行", AutoSize = true };
        private readonly Button stopButton = new Button { Text = "停止", AutoSize = true, Enabled = false };
        private readonly Button folderButton = new Button { Text = "打开结果文件夹", AutoSize = true };
        private readonly Label statusLabel = new Label { Text = "就绪", AutoSize = true, TextAlign = ContentAlignment.MiddleRight };
        private readonly RichTextBox logView = new RichTextBox();
        private readonly Label responseLabel = new Label { Text = "程序暂时不需要额外输入", AutoSize = true };
        private readonly TextBox responseField = new TextBox { Enabled = false };
        private readonly Button sendButton = new Button { Text = "发送", AutoSize = true, Enabled = false };
        private readonly PromptEngine promptEngine = new PromptEngine();
        private readonly Dictionary<PromptKind, int> promptCounts = new Dictionary<PromptKind, int>();

        private Process child;
        private StreamWriter childInput;
        private bool closing;

        private string SupportDirectory => Path.Combine(
            Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData),
            "XiaoyuanAnQuanTong GUI");

        internal MainForm()
        {
            Text = "校园安全通";
            StartPosition = FormStartPosition.CenterScreen;
            MinimumSize = new Size(720, 610);
            ClientSize = new Size(800, 690);
            Font = new Font("Microsoft YaHei UI", 9F);
            AutoScaleMode = AutoScaleMode.Dpi;
            BuildInterface();
        }

        private void BuildInterface()
        {
            var root = new TableLayoutPanel
            {
                Dock = DockStyle.Fill,
                Padding = new Padding(22, 18, 22, 16),
                ColumnCount = 1,
                RowCount = 9
            };
            root.RowStyles.Add(new RowStyle(SizeType.AutoSize));
            root.RowStyles.Add(new RowStyle(SizeType.AutoSize));
            root.RowStyles.Add(new RowStyle(SizeType.AutoSize));
            root.RowStyles.Add(new RowStyle(SizeType.AutoSize));
            root.RowStyles.Add(new RowStyle(SizeType.Percent, 100));
            root.RowStyles.Add(new RowStyle(SizeType.AutoSize));
            root.RowStyles.Add(new RowStyle(SizeType.AutoSize));
            root.RowStyles.Add(new RowStyle(SizeType.AutoSize));
            root.RowStyles.Add(new RowStyle(SizeType.AutoSize));

            var title = new Label { Text = "校园安全通图形客户端", Font = new Font(Font.FontFamily, 17F, FontStyle.Bold), AutoSize = true, Margin = new Padding(0, 0, 0, 4) };
            var subtitle = new Label { Text = "填写一次后点击开始。账号和密码仅发送给本机命令行程序，本客户端不会保存。", AutoSize = true, ForeColor = SystemColors.GrayText, Margin = new Padding(0, 0, 0, 12) };
            root.Controls.Add(title, 0, 0);
            root.Controls.Add(subtitle, 0, 1);
            root.Controls.Add(BuildForm(), 0, 2);
            root.Controls.Add(BuildButtonRow(), 0, 3);

            logView.Dock = DockStyle.Fill;
            logView.ReadOnly = true;
            logView.DetectUrls = false;
            logView.BackColor = SystemColors.Window;
            logView.ForeColor = SystemColors.WindowText;
            logView.Font = new Font("Consolas", 10F);
            logView.Margin = new Padding(0, 10, 0, 8);
            root.Controls.Add(logView, 0, 4);

            responseLabel.ForeColor = SystemColors.GrayText;
            responseLabel.Margin = new Padding(0, 0, 0, 5);
            root.Controls.Add(responseLabel, 0, 5);
            root.Controls.Add(BuildResponseRow(), 0, 6);
            root.Controls.Add(BuildCreditRow(), 0, 7);

            var warning = new Label
            {
                Text = "提示：原程序会自动处理课程和考试。请先确认学校及平台允许此类操作。原程序使用 HTTP 连接，敏感信息传输存在风险。",
                AutoSize = true,
                MaximumSize = new Size(740, 0),
                ForeColor = Color.DarkOrange,
                Margin = new Padding(0, 8, 0, 0)
            };
            root.Controls.Add(warning, 0, 8);
            Controls.Add(root);

            startButton.Click += async (_, __) => await StartRunAsync();
            stopButton.Click += (_, __) => StopRun();
            folderButton.Click += (_, __) => OpenResultFolder();
            sendButton.Click += (_, __) => SendResponse();
            responseField.KeyDown += (_, e) =>
            {
                if (e.KeyCode == Keys.Enter) { SendResponse(); e.SuppressKeyPress = true; }
            };
            FormClosing += (_, __) => { closing = true; StopChildOnClose(); };
        }

        private Control BuildForm()
        {
            var panel = new TableLayoutPanel { Dock = DockStyle.Top, AutoSize = true, ColumnCount = 2, RowCount = 4, Margin = new Padding(0, 0, 0, 6) };
            panel.ColumnStyles.Add(new ColumnStyle(SizeType.Absolute, 82));
            panel.ColumnStyles.Add(new ColumnStyle(SizeType.Percent, 100));
            AddFormRow(panel, 0, "省份：", provinceField, "默认江苏省");
            AddFormRow(panel, 1, "学校：", schoolField, "支持输入学校名称关键词");
            AddFormRow(panel, 2, "账号：", accountField, "平台账号");
            AddFormRow(panel, 3, "密码：", passwordField, "平台密码");
            return panel;
        }

        private static void AddFormRow(TableLayoutPanel panel, int row, string label, TextBox field, string placeholder)
        {
            var text = new Label { Text = label, Dock = DockStyle.Fill, TextAlign = ContentAlignment.MiddleRight, Margin = new Padding(0, 4, 8, 4) };
            field.Dock = DockStyle.Top;
            field.Margin = new Padding(0, 4, 0, 4);
            field.AccessibleDescription = placeholder;
            panel.Controls.Add(text, 0, row);
            panel.Controls.Add(field, 1, row);
        }

        private Control BuildButtonRow()
        {
            var panel = new FlowLayoutPanel { Dock = DockStyle.Top, AutoSize = true, FlowDirection = FlowDirection.LeftToRight, WrapContents = false, Margin = new Padding(0, 3, 0, 0) };
            panel.Controls.Add(startButton);
            panel.Controls.Add(stopButton);
            panel.Controls.Add(folderButton);
            panel.Controls.Add(new Label { Width = 22 });
            panel.Controls.Add(statusLabel);
            return panel;
        }

        private Control BuildResponseRow()
        {
            var panel = new TableLayoutPanel { Dock = DockStyle.Top, AutoSize = true, ColumnCount = 2, Margin = new Padding(0) };
            panel.ColumnStyles.Add(new ColumnStyle(SizeType.Percent, 100));
            panel.ColumnStyles.Add(new ColumnStyle(SizeType.AutoSize));
            responseField.Dock = DockStyle.Top;
            responseField.AccessibleDescription = "出现多个学校或程序再次询问时，在这里输入";
            panel.Controls.Add(responseField, 0, 0);
            panel.Controls.Add(sendButton, 1, 0);
            return panel;
        }

        private Control BuildCreditRow()
        {
            var panel = new FlowLayoutPanel { Dock = DockStyle.Top, AutoSize = true, FlowDirection = FlowDirection.LeftToRight, Margin = new Padding(0, 9, 0, 0) };
            panel.Controls.Add(new Label { Text = "图形客户端作者：掠过古城的风 · GitHub 原作者：hangone", AutoSize = true, ForeColor = SystemColors.GrayText, Margin = new Padding(0, 5, 14, 0) });
            var upstream = new LinkLabel { Text = "原项目 GitHub", AutoSize = true, Margin = new Padding(0, 5, 14, 0) };
            upstream.LinkClicked += (_, __) => OpenUrl(UpstreamUrl);
            var about = new LinkLabel { Text = "关于与许可", AutoSize = true, Margin = new Padding(0, 5, 0, 0) };
            about.LinkClicked += (_, __) => new AboutForm(SupportDirectory).ShowDialog(this);
            panel.Controls.Add(upstream);
            panel.Controls.Add(about);
            return panel;
        }

        private async Task StartRunAsync()
        {
            if (child != null) return;
            if (string.IsNullOrWhiteSpace(schoolField.Text)) { Warn("请填写学校名称"); return; }
            if (string.IsNullOrWhiteSpace(accountField.Text)) { Warn("请填写账号"); return; }
            if (string.IsNullOrEmpty(passwordField.Text)) { Warn("请填写密码"); return; }

            try
            {
                var executable = PrepareExecutable();
                logView.Clear();
                promptEngine.Reset();
                promptCounts.Clear();
                AppendLog("正在启动…\r\n");

                var info = new ProcessStartInfo(executable)
                {
                    WorkingDirectory = SupportDirectory,
                    UseShellExecute = false,
                    CreateNoWindow = true,
                    WindowStyle = ProcessWindowStyle.Hidden,
                    RedirectStandardInput = true,
                    RedirectStandardOutput = true,
                    RedirectStandardError = true
                };
                info.EnvironmentVariables["PYTHONUNBUFFERED"] = "1";
                info.EnvironmentVariables["PYTHONIOENCODING"] = "utf-8";

                child = new Process { StartInfo = info, EnableRaisingEvents = true };
                if (!child.Start()) throw new InvalidOperationException("命令行核心没有启动");
                childInput = new StreamWriter(child.StandardInput.BaseStream, new UTF8Encoding(false)) { AutoFlush = true };
                SetRunning(true);
                statusLabel.Text = "运行中";

                var stdout = ReadStreamAsync(child.StandardOutput.BaseStream, true);
                var stderr = ReadStreamAsync(child.StandardError.BaseStream, false);
                await Task.Run(() => child.WaitForExit());
                await Task.WhenAll(stdout, stderr);
                var exitCode = child.ExitCode;
                if (closing) CleanupProcess(); else FinishRun(exitCode);
            }
            catch (Exception error)
            {
                AppendLog("\r\n启动失败：" + error.Message + "\r\n");
                StopChildOnClose();
                CleanupProcess();
                SetRunning(false);
                statusLabel.Text = "启动失败";
            }
        }

        private string PrepareExecutable()
        {
            Directory.CreateDirectory(SupportDirectory);
            var target = Path.Combine(SupportDirectory, "XiaoyuanAnQuanTong-windows-x64.exe");
            using (var source = Assembly.GetExecutingAssembly().GetManifestResourceStream(CoreResource))
            {
                if (source == null) throw new InvalidOperationException("应用内缺少命令行核心");
                using (var destination = File.Create(target)) source.CopyTo(destination);
            }
            return target;
        }

        private async Task ReadStreamAsync(Stream stream, bool inspectPrompts)
        {
            var decoder = new UTF8Encoding(false, false).GetDecoder();
            var bytes = new byte[1024];
            var chars = new char[2048];
            while (true)
            {
                var read = await stream.ReadAsync(bytes, 0, bytes.Length);
                if (read == 0) break;
                var charCount = decoder.GetChars(bytes, 0, read, chars, 0, false);
                var text = new string(chars, 0, charCount);
                Ui(() =>
                {
                    AppendLog(text);
                    if (inspectPrompts) ProcessPrompts(text);
                });
            }
        }

        private void ProcessPrompts(string text)
        {
            foreach (var prompt in promptEngine.Feed(text)) HandlePrompt(prompt);
        }

        private void HandlePrompt(PromptKind prompt)
        {
            promptCounts.TryGetValue(prompt, out var previous);
            var count = previous + 1;
            promptCounts[prompt] = count;

            if (prompt == PromptKind.Choice)
            {
                RequestManualInput("找到多个学校，请输入学校序号");
                return;
            }
            if (count > 1)
            {
                RequestManualInput("程序再次询问“" + ShortName(prompt) + "”，请修改后手动发送");
                return;
            }

            switch (prompt)
            {
                case PromptKind.Province: SendLine(provinceField.Text); break;
                case PromptKind.School: SendLine(schoolField.Text); break;
                case PromptKind.Account: SendLine(accountField.Text); break;
                case PromptKind.Password:
                    var password = passwordField.Text;
                    SendLine(password);
                    passwordField.Clear();
                    break;
            }
        }

        private static string ShortName(PromptKind prompt)
        {
            switch (prompt)
            {
                case PromptKind.Province: return "省份";
                case PromptKind.School: return "学校";
                case PromptKind.Choice: return "学校序号";
                case PromptKind.Account: return "账号";
                default: return "密码";
            }
        }

        private void RequestManualInput(string message)
        {
            responseLabel.Text = message;
            responseField.Enabled = true;
            sendButton.Enabled = true;
            responseField.Focus();
        }

        private void SendResponse()
        {
            if (child == null) return;
            SendLine(responseField.Text);
            responseField.Clear();
            responseField.Enabled = false;
            sendButton.Enabled = false;
            responseLabel.Text = "已发送，等待程序响应…";
        }

        private void SendLine(string value)
        {
            try { childInput?.WriteLine(value ?? string.Empty); }
            catch (Exception error) { AppendLog("\r\n发送输入失败：" + error.Message + "\r\n"); }
        }

        private void StopRun()
        {
            try { if (child != null && !child.HasExited) child.Kill(); }
            catch { }
            statusLabel.Text = "正在停止…";
        }

        private void StopChildOnClose()
        {
            try { if (child != null && !child.HasExited) child.Kill(); }
            catch { }
        }

        private void FinishRun(int status)
        {
            CleanupProcess();
            SetRunning(false);
            statusLabel.Text = status == 0 ? "已完成" : "已结束（状态 " + status + "）";
            responseLabel.Text = status == 0 ? "运行完成，可打开结果文件夹查看证书" : "程序已结束，请查看上方日志";
        }

        private void CleanupProcess()
        {
            childInput?.Dispose();
            childInput = null;
            child?.Dispose();
            child = null;
        }

        private void SetRunning(bool running)
        {
            startButton.Enabled = !running;
            stopButton.Enabled = running;
            if (!running) { responseField.Enabled = false; sendButton.Enabled = false; }
        }

        private void AppendLog(string text)
        {
            logView.SelectionStart = logView.TextLength;
            logView.SelectionLength = 0;
            logView.SelectionColor = SystemColors.WindowText;
            logView.AppendText(text);
            logView.ScrollToCaret();
        }

        private void OpenResultFolder()
        {
            Directory.CreateDirectory(SupportDirectory);
            Process.Start("explorer.exe", SupportDirectory);
        }

        private static void OpenUrl(string url)
        {
            Process.Start(new ProcessStartInfo(url) { UseShellExecute = true });
        }

        private void Ui(Action action)
        {
            if (closing || IsDisposed) return;
            if (InvokeRequired) BeginInvoke(action); else action();
        }

        private void Warn(string message)
        {
            MessageBox.Show(this, message, "校园安全通", MessageBoxButtons.OK, MessageBoxIcon.Warning);
        }
    }
}
