import AppKit
import Foundation

final class AppDelegate: NSObject, NSApplicationDelegate, NSWindowDelegate {
    private var window: NSWindow!
    private let provinceField = NSTextField(string: "江苏省")
    private let schoolField = NSTextField()
    private let accountField = NSTextField()
    private let passwordField = NSSecureTextField()
    private let startButton = NSButton(title: "开始运行", target: nil, action: nil)
    private let stopButton = NSButton(title: "停止", target: nil, action: nil)
    private let openFolderButton = NSButton(title: "打开结果文件夹", target: nil, action: nil)
    private let repositoryButton = NSButton(title: "原项目 GitHub", target: nil, action: nil)
    private let legalButton = NSButton(title: "关于与许可", target: nil, action: nil)
    private let logView = NSTextView()
    private let responseLabel = NSTextField(labelWithString: "程序暂时不需要额外输入")
    private let responseField = NSTextField()
    private let sendButton = NSButton(title: "发送", target: nil, action: nil)
    private let statusLabel = NSTextField(labelWithString: "就绪")

    private var process: Process?
    private var inputHandle: FileHandle?
    private var outputRemainder = Data()
    private let promptParser = PromptParser()
    private var promptCounts: [Prompt: Int] = [:]
    private let outputQueue = DispatchQueue(label: "local.codex.xiaoyuananquan.output")

    private lazy var supportDirectory: URL = {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        return base.appendingPathComponent("XiaoyuanAnQuanTong GUI", isDirectory: true)
    }()

    func applicationDidFinishLaunching(_ notification: Notification) {
        buildInterface()
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { true }

    func applicationWillTerminate(_ notification: Notification) {
        process?.terminate()
    }

    private func buildInterface() {
        window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 760, height: 650),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.title = "校园安全通"
        window.sharingType = .readOnly
        window.backgroundColor = .windowBackgroundColor
        window.center()
        window.minSize = NSSize(width: 660, height: 560)
        window.delegate = self

        let content = NSView(frame: window.contentLayoutRect)
        content.autoresizingMask = [.width, .height]
        window.contentView = content

        let title = NSTextField(labelWithString: "校园安全通图形客户端")
        title.font = .systemFont(ofSize: 22, weight: .semibold)

        let subtitle = NSTextField(wrappingLabelWithString: "填写一次后点击开始。账号和密码仅发送给本机命令行程序，本客户端不会保存。")
        subtitle.textColor = .secondaryLabelColor

        let form = NSGridView(views: [
            [makeLabel("省份"), provinceField],
            [makeLabel("学校"), schoolField],
            [makeLabel("账号"), accountField],
            [makeLabel("密码"), passwordField]
        ])
        form.column(at: 0).xPlacement = .trailing
        form.column(at: 0).width = 70
        form.column(at: 1).xPlacement = .fill
        form.rowSpacing = 10
        form.columnSpacing = 12

        provinceField.placeholderString = "默认江苏省"
        schoolField.placeholderString = "支持输入学校名称关键词"
        accountField.placeholderString = "平台账号"
        passwordField.placeholderString = "平台密码"

        startButton.target = self
        startButton.action = #selector(startRun)
        startButton.keyEquivalent = "\r"
        startButton.bezelStyle = .rounded

        stopButton.target = self
        stopButton.action = #selector(stopRun)
        stopButton.isEnabled = false

        openFolderButton.target = self
        openFolderButton.action = #selector(openResultFolder)

        repositoryButton.target = self
        repositoryButton.action = #selector(openRepository)
        repositoryButton.bezelStyle = .inline

        legalButton.target = self
        legalButton.action = #selector(showLegalNotice)
        legalButton.bezelStyle = .inline

        let buttonRow = NSStackView(views: [startButton, stopButton, openFolderButton, NSView(), statusLabel])
        buttonRow.orientation = .horizontal
        buttonRow.spacing = 10
        buttonRow.alignment = .centerY

        logView.isEditable = false
        logView.isSelectable = true
        logView.isRichText = false
        logView.importsGraphics = false
        logView.font = .monospacedSystemFont(ofSize: 12.5, weight: .regular)
        logView.textColor = .textColor
        logView.textContainerInset = NSSize(width: 10, height: 10)
        logView.backgroundColor = NSColor.textBackgroundColor
        let scrollView = NSScrollView()
        scrollView.documentView = logView
        scrollView.hasVerticalScroller = true
        scrollView.borderType = .bezelBorder

        responseLabel.textColor = .secondaryLabelColor
        responseField.placeholderString = "出现多个学校或程序再次询问时，在这里输入"
        responseField.isEnabled = false
        responseField.target = self
        responseField.action = #selector(sendResponse)
        sendButton.target = self
        sendButton.action = #selector(sendResponse)
        sendButton.isEnabled = false

        let responseRow = NSStackView(views: [responseField, sendButton])
        responseRow.orientation = .horizontal
        responseRow.spacing = 8
        responseField.setContentHuggingPriority(.defaultLow, for: .horizontal)

        let credits = NSTextField(labelWithString: "图形客户端作者：掠过古城的风   ·   GitHub 原作者：hangone")
        credits.textColor = .secondaryLabelColor
        credits.font = .systemFont(ofSize: 11.5, weight: .medium)
        let creditRow = NSStackView(views: [credits, NSView(), repositoryButton, legalButton])
        creditRow.orientation = .horizontal
        creditRow.alignment = .centerY
        creditRow.spacing = 8

        let warning = NSTextField(wrappingLabelWithString: "提示：原程序会自动处理课程和考试。请先确认学校及平台允许此类操作。原程序使用 HTTP 连接，敏感信息传输存在风险。")
        warning.textColor = .systemOrange
        warning.font = .systemFont(ofSize: 11)

        let stack = NSStackView(views: [title, subtitle, form, buttonRow, scrollView, responseLabel, responseRow, creditRow, warning])
        stack.orientation = .vertical
        stack.alignment = .leading
        stack.spacing = 12
        stack.translatesAutoresizingMaskIntoConstraints = false
        content.addSubview(stack)

        form.translatesAutoresizingMaskIntoConstraints = false
        buttonRow.translatesAutoresizingMaskIntoConstraints = false
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        responseRow.translatesAutoresizingMaskIntoConstraints = false
        creditRow.translatesAutoresizingMaskIntoConstraints = false
        warning.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: content.leadingAnchor, constant: 22),
            stack.trailingAnchor.constraint(equalTo: content.trailingAnchor, constant: -22),
            stack.topAnchor.constraint(equalTo: content.topAnchor, constant: 20),
            stack.bottomAnchor.constraint(equalTo: content.bottomAnchor, constant: -18),
            form.widthAnchor.constraint(equalTo: stack.widthAnchor),
            buttonRow.widthAnchor.constraint(equalTo: stack.widthAnchor),
            scrollView.widthAnchor.constraint(equalTo: stack.widthAnchor),
            scrollView.heightAnchor.constraint(greaterThanOrEqualToConstant: 240),
            responseRow.widthAnchor.constraint(equalTo: stack.widthAnchor),
            creditRow.widthAnchor.constraint(equalTo: stack.widthAnchor),
            warning.widthAnchor.constraint(equalTo: stack.widthAnchor)
        ])

        appendLog("运行日志会显示在这里。填写信息并点击“开始运行”。\n")
    }

    private func makeLabel(_ text: String) -> NSTextField {
        let label = NSTextField(labelWithString: text + "：")
        label.alignment = .right
        return label
    }

    @objc private func startRun() {
        guard process == nil else { return }
        guard !schoolField.stringValue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            showAlert("请填写学校名称")
            return
        }
        guard !accountField.stringValue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            showAlert("请填写账号")
            return
        }
        guard !passwordField.stringValue.isEmpty else {
            showAlert("请填写密码")
            return
        }

        do {
            let executable = try prepareExecutable()
            logView.string = ""
            outputRemainder.removeAll()
            promptParser.reset()
            promptCounts.removeAll()
            appendLog("正在启动…\n")

            let task = Process()
            let outputPipe = Pipe()
            let inputPipe = Pipe()
            task.executableURL = executable
            task.currentDirectoryURL = supportDirectory
            task.standardOutput = outputPipe
            task.standardError = outputPipe
            task.standardInput = inputPipe
            var environment = ProcessInfo.processInfo.environment
            environment["PYTHONUNBUFFERED"] = "1"
            environment["PYTHONIOENCODING"] = "utf-8"
            task.environment = environment

            try task.run()
            try? outputPipe.fileHandleForWriting.close()
            try? inputPipe.fileHandleForReading.close()
            process = task
            inputHandle = inputPipe.fileHandleForWriting
            setRunning(true)
            statusLabel.stringValue = "运行中"
            appendLog("内置核心已启动，正在等待响应…\n")

            let outputHandle = outputPipe.fileHandleForReading
            outputQueue.async { [weak self] in
                while true {
                    let data = outputHandle.availableData
                    if data.isEmpty { break }
                    DispatchQueue.main.async { [weak self] in
                        self?.consumeOutput(data)
                    }
                }
                task.waitUntilExit()
                let status = task.terminationStatus
                DispatchQueue.main.async { [weak self] in
                    guard let self = self, self.process === task else { return }
                    self.processDidFinish(status: status)
                }
            }
        } catch {
            showAlert("启动失败", detail: error.localizedDescription)
            process = nil
            inputHandle = nil
            setRunning(false)
        }
    }

    private func prepareExecutable() throws -> URL {
        guard let bundled = Bundle.main.url(forResource: "XiaoyuanAnQuanTong-macos-arm64", withExtension: nil) else {
            throw NSError(domain: "GUI", code: 1, userInfo: [NSLocalizedDescriptionKey: "应用内缺少命令行程序"])
        }
        try FileManager.default.createDirectory(at: supportDirectory, withIntermediateDirectories: true)
        let target = supportDirectory.appendingPathComponent("XiaoyuanAnQuanTong-macos-arm64")
        if FileManager.default.fileExists(atPath: target.path) {
            try FileManager.default.removeItem(at: target)
        }
        try FileManager.default.copyItem(at: bundled, to: target)
        try FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: target.path)
        return target
    }

    private func consumeOutput(_ data: Data) {
        outputRemainder.append(data)
        var decoded = ""
        var consumed = 0
        let maxTrim = min(3, outputRemainder.count)
        for trim in 0...maxTrim {
            let length = outputRemainder.count - trim
            if let value = String(data: outputRemainder.prefix(length), encoding: .utf8) {
                decoded = value
                consumed = length
                break
            }
        }
        guard consumed > 0 else { return }
        outputRemainder.removeFirst(consumed)
        appendLog(decoded)
        processPrompts(in: decoded)
    }

    private func processPrompts(in text: String) {
        for prompt in promptParser.feed(text) {
            handle(prompt)
        }
    }

    private func handle(_ prompt: Prompt) {
        let count = (promptCounts[prompt] ?? 0) + 1
        promptCounts[prompt] = count

        if prompt == .choice {
            requestManualInput("找到多个学校，请输入学校序号")
            return
        }

        if count > 1 {
            requestManualInput("程序再次询问“\(shortName(prompt))”，请修改后手动发送")
            return
        }

        switch prompt {
        case .province:
            appendLog("\n→ 已自动填写省份\n")
            sendLine(provinceField.stringValue)
        case .school:
            appendLog("\n→ 已自动填写学校\n")
            sendLine(schoolField.stringValue)
        case .account:
            appendLog("\n→ 已自动填写账号（内容已隐藏）\n")
            sendLine(accountField.stringValue)
        case .password:
            let password = passwordField.stringValue
            appendLog("\n→ 已自动填写密码（内容已隐藏）\n")
            sendLine(password)
            passwordField.stringValue = ""
        case .choice:
            break
        }
    }

    private func shortName(_ prompt: Prompt) -> String {
        switch prompt {
        case .province: return "省份"
        case .school: return "学校"
        case .choice: return "学校序号"
        case .account: return "账号"
        case .password: return "密码"
        }
    }

    private func requestManualInput(_ message: String) {
        appendLog("\n→ \(message)\n")
        responseLabel.stringValue = message
        responseField.isEnabled = true
        sendButton.isEnabled = true
        window.makeFirstResponder(responseField)
    }

    @objc private func sendResponse() {
        guard process != nil else { return }
        sendLine(responseField.stringValue)
        appendLog("→ 已发送补充输入\n")
        responseField.stringValue = ""
        responseField.isEnabled = false
        sendButton.isEnabled = false
        responseLabel.stringValue = "已发送，等待程序响应…"
    }

    private func sendLine(_ value: String) {
        guard let data = (value + "\n").data(using: .utf8) else { return }
        do {
            try inputHandle?.write(contentsOf: data)
        } catch {
            appendLog("\n发送输入失败：\(error.localizedDescription)\n")
        }
    }

    @objc private func stopRun() {
        appendLog("\n正在请求停止内置核心…\n")
        process?.terminate()
        statusLabel.stringValue = "正在停止…"
    }

    @objc private func openResultFolder() {
        do {
            try FileManager.default.createDirectory(at: supportDirectory, withIntermediateDirectories: true)
            NSWorkspace.shared.open(supportDirectory)
        } catch {
            showAlert("无法打开结果文件夹", detail: error.localizedDescription)
        }
    }

    @objc private func openRepository() {
        if let url = URL(string: "https://github.com/hangone/study-xiaoyuananquantong") {
            NSWorkspace.shared.open(url)
        }
    }

    @objc private func showLegalNotice() {
        let alert = NSAlert()
        alert.messageText = "关于校园安全通图形客户端"
        alert.informativeText = """
        图形客户端作者：掠过古城的风
        GitHub 原作者：hangone
        修改日期：2026-09-04

        本软件按 GNU Affero General Public License v3.0 发布，不提供任何担保。你可以依照该许可证复制、修改和再发布本软件。

        原项目：https://github.com/hangone/study-xiaoyuananquantong
        客户端源码：https://github.com/alonetop/xiaoyuananquan-gui
        """
        alert.addButton(withTitle: "查看许可证")
        alert.addButton(withTitle: "关闭")
        if alert.runModal() == .alertFirstButtonReturn,
           let licenseURL = Bundle.main.url(forResource: "LICENSE", withExtension: nil) {
            NSWorkspace.shared.open(licenseURL)
        }
    }

    private func processDidFinish(status: Int32) {
        if !outputRemainder.isEmpty {
            let text = String(decoding: outputRemainder, as: UTF8.self)
            appendLog(text)
            outputRemainder.removeAll()
        }
        try? inputHandle?.close()
        process = nil
        inputHandle = nil
        setRunning(false)
        appendLog("\n内置核心已结束（状态 \(status)）。\n")
        statusLabel.stringValue = status == 0 ? "已完成" : "已结束（状态 \(status)）"
        responseLabel.stringValue = status == 0 ? "运行完成，可打开结果文件夹查看证书" : "程序已结束，请查看上方日志"
    }

    private func setRunning(_ running: Bool) {
        startButton.isEnabled = !running
        stopButton.isEnabled = running
        if !running {
            responseField.isEnabled = false
            sendButton.isEnabled = false
        }
    }

    private func appendLog(_ text: String) {
        let attributes: [NSAttributedString.Key: Any] = [
            .foregroundColor: NSColor.textColor,
            .font: NSFont.monospacedSystemFont(ofSize: 12.5, weight: .regular)
        ]
        logView.textStorage?.append(NSAttributedString(string: text, attributes: attributes))
        logView.scrollToEndOfDocument(nil)
    }

    private func showAlert(_ message: String, detail: String? = nil) {
        let alert = NSAlert()
        alert.messageText = message
        alert.informativeText = detail ?? ""
        alert.alertStyle = .warning
        alert.runModal()
    }
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.setActivationPolicy(.regular)
app.run()
