#define AppName "校园安全通图形客户端"
#define AppVersion "1.1.0"
#define AppPublisher "掠过古城的风"
#define AppExeName "XiaoyuanAnQuanTongGUI.exe"

[Setup]
AppId={{1A68891B-E5E9-4B94-95F3-024665E4CF07}
AppName={#AppName}
AppVersion={#AppVersion}
AppPublisher={#AppPublisher}
AppPublisherURL=https://github.com/alonetop/xiaoyuananquan-gui
AppSupportURL=https://github.com/alonetop/xiaoyuananquan-gui/issues
AppUpdatesURL=https://github.com/alonetop/xiaoyuananquan-gui/releases
DefaultDirName={localappdata}\Programs\XiaoyuanAnQuanTongGUI
DefaultGroupName=校园安全通
DisableProgramGroupPage=yes
PrivilegesRequired=lowest
OutputDir=..\dist
OutputBaseFilename=校园安全通-Windows-x64-Setup
Compression=lzma2
SolidCompression=yes
WizardStyle=modern
LicenseFile=..\LICENSE
UninstallDisplayName={#AppName}
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
VersionInfoVersion=1.1.0.0
VersionInfoCompany={#AppPublisher}
VersionInfoDescription={#AppName} 安装程序
VersionInfoProductName={#AppName}
VersionInfoProductVersion={#AppVersion}

[Languages]
Name: "chinesesimp"; MessagesFile: "ChineseSimplified.isl"

[Tasks]
Name: "desktopicon"; Description: "创建桌面快捷方式"; GroupDescription: "附加任务："; Flags: unchecked

[Files]
Source: "..\windows\bin\Release\net48\XiaoyuanAnQuanTongGUI.exe"; DestDir: "{app}"; Flags: ignoreversion

[Icons]
Name: "{group}\校园安全通"; Filename: "{app}\{#AppExeName}"
Name: "{autodesktop}\校园安全通"; Filename: "{app}\{#AppExeName}"; Tasks: desktopicon

[Run]
Filename: "{app}\{#AppExeName}"; Description: "启动校园安全通"; Flags: nowait postinstall skipifsilent
