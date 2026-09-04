# 校园安全通图形客户端

为 [hangone/study-xiaoyuananquantong](https://github.com/hangone/study-xiaoyuananquantong) 制作的 macOS 与 Windows 图形客户端。发行包已经内置命令行核心，不需要安装 Python、打开终端或另行下载原项目。

> **重要提示**：原项目会自动处理课程、提交考试并下载证书。请先确认学校和平台允许此类操作。原项目当前使用明文 HTTP 连接，账号与密码在传输过程中存在被截获的风险。

## 下载

请从 [GitHub Releases](https://github.com/alonetop/xiaoyuananquan-gui/releases/latest) 下载最新版本。

| 系统 | 文件 | 支持范围 |
| --- | --- | --- |
| macOS | `校园安全通-macOS-arm64.zip` | macOS 12 或更高版本，Apple Silicon（M1/M2/M3/M4 等） |
| Windows | `校园安全通-Windows-x64-Setup.exe` | Windows 10/11，x64 |

Release 同时提供 `SHA256SUMS.txt`，可用于验证文件完整性。

## 使用方法

### macOS

1. 下载并解压 `校园安全通-macOS-arm64.zip`。
2. 首次启动时右键“校园安全通.app”，选择“打开”，再确认打开。
3. 填写省份、学校、账号和密码，点击“开始运行”。
4. 如匹配到多个学校，在窗口底部输入学校序号并发送。
5. 完成后点击“打开结果文件夹”查看证书。

### Windows

1. 下载并运行 `校园安全通-Windows-x64-Setup.exe`。
2. 因发行包没有商业代码签名，SmartScreen 可能提示风险；确认文件校验值正确后，选择“更多信息 → 仍要运行”。
3. 完成安装后，从开始菜单或桌面快捷方式启动“校园安全通”。
4. 填写信息并点击“开始运行”；多学校选择和证书目录操作与 macOS 版一致。

账号和密码不会写入配置文件。密码发送给本机命令行核心后会立即从界面清除。

## 功能

- 省份、学校、账号、密码图形表单
- 自动响应命令行核心的常规输入提示
- 多学校匹配时的序号选择
- 实时中文日志及运行状态
- 停止当前任务
- 一键打开证书/结果目录
- 深色和浅色环境下均保持日志可读
- 内置作者、原项目、源码及开源许可信息

结果目录：

- macOS：`~/Library/Application Support/XiaoyuanAnQuanTong GUI/`
- Windows：`%LOCALAPPDATA%\XiaoyuanAnQuanTong GUI\`

## 作者与上游项目

- 图形客户端作者：**掠过古城的风**
- GitHub 原作者：**hangone**
- 原项目：[hangone/study-xiaoyuananquantong](https://github.com/hangone/study-xiaoyuananquantong)
- 本项目首次修改日期：**2026-09-04**

本项目固定封装原项目 `v1.0.0` 的官方发行文件，并在构建时强制校验 SHA-256：

```text
macOS ARM64  4556bc947caa2ea387ffb18a3649014035d5ed90ad6a3ef622ff896ac8d56d24
Windows x64  dbc5a84bc3c4c8ae208dfd1695b1e43db585a3a556d8da6de5c76be1ba889f88
```

详细修改和版权信息见 [NOTICE.md](NOTICE.md)。

Windows 安装器使用的 Inno Setup 简体中文翻译来自 Kira 维护的开源翻译项目，并保留其 MIT License。

## 从源码构建

仓库不提交预编译二进制。构建脚本会从原项目 `v1.0.0` Release 下载对应核心，校验哈希后再封装。

### 构建 macOS ARM64

需要 macOS、Xcode Command Line Tools 和 Swift：

```bash
./scripts/build-macos.sh
```

产物位于 `dist/校园安全通-macOS-arm64.zip`。

### 构建 Windows x64 安装程序

需要 Windows 10/11、.NET SDK（含 .NET Framework 4.8 targeting pack）和 Inno Setup 6：

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\build-windows.ps1
```

产物位于 `dist\校园安全通-Windows-x64-Setup.exe`。

### 测试提示解析器

macOS：

```bash
mkdir -p .build
swiftc macos/PromptParser.swift tests/PromptParserTests.swift -o .build/prompt-parser-tests
.build/prompt-parser-tests
```

Windows 或安装了 .NET 8 SDK 的系统：

```powershell
dotnet run --project tests\PromptEngineTests.csproj
```

测试只使用模拟文本，不会登录平台或使用真实账号。

## 自动构建和发布

推送 `v*` 标签会触发 GitHub Actions：分别构建 macOS 和 Windows 发行包、运行提示解析测试、生成 `SHA256SUMS.txt`，并创建同名 GitHub Release。也可以从 Actions 页面手动触发构建，此时只生成临时构建产物，不创建 Release。

## 安全、规则与免责声明

- 原项目接口地址使用 HTTP，而非 HTTPS；即使图形客户端本身不保存密码，也无法消除网络传输风险。
- 自动完成课程或考试可能违反学校规定、平台条款或学术诚信要求。使用者必须自行确认已经获得授权。
- 无签名软件可能触发 macOS Gatekeeper、Windows SmartScreen 或杀毒软件提示。请从本仓库 Release 下载并核对 SHA-256。
- 本项目与相关学校或平台没有隶属、授权或背书关系。
- 本软件按现状提供，不承担因使用、账号限制、数据丢失或平台规则变化产生的责任。

## 开源许可

本项目整体按 [GNU Affero General Public License v3.0](LICENSE) 发布。你可以在遵守许可证的前提下运行、研究、修改和再发布；分发修改后的程序时，必须保留版权与许可说明，并向接收者提供对应完整源码。交互界面的“关于与许可”入口也提供许可证和源码位置。
