; GitHub Monitor - Inno Setup 安装脚本
; 使用方法: 用 Inno Setup Compiler 打开此文件，按 Ctrl+F9 编译

#define MyAppName "GitHub Monitor"
#define MyAppVersion "1.0"
#define MyAppPublisher "GitHub Monitor"

[Setup]
AppId={{B4F8A1D6-3E2C-4F9B-8D7A-1C5E6F3A2B9D}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppPublisher={#MyAppPublisher}
DefaultDirName={autopf}\{#MyAppName}
DefaultGroupName={#MyAppName}
OutputDir=.\dist
OutputBaseFilename=GitHub-Monitor-Setup
Compression=lzma
SolidCompression=yes
WizardStyle=modern
; 不需要管理员权限，安装到当前用户目录
PrivilegesRequired=lowest

[Languages]
Name: "chinesesimplified"; MessagesFile: "compiler:Languages\ChineseSimplified.isl"

[Files]
Source: "github-monitor.ps1"; DestDir: "{app}"; Flags: ignoreversion
Source: "start-monitor.vbs"; DestDir: "{app}"; Flags: ignoreversion
Source: "GitHub_Invertocat_Black.png"; DestDir: "{app}"; Flags: ignoreversion
Source: "GitHub_Invertocat_White.png"; DestDir: "{app}"; Flags: ignoreversion

[Icons]
; 启动文件夹 — 开机自启
Name: "{userstartup}\{#MyAppName}"; Filename: "{app}\start-monitor.vbs"; WorkingDir: "{app}"; Comment: "GitHub 连通性监控"
; 开始菜单
Name: "{group}\{#MyAppName}"; Filename: "{app}\start-monitor.vbs"; WorkingDir: "{app}"
Name: "{group}\卸载 {#MyAppName}"; Filename: "{uninstallexe}"

; 卸载前先关闭正在运行的程序
[UninstallRun]
Filename: "taskkill"; Parameters: "/f /im powershell.exe /fi ""WINDOWTITLE eq GitHub Monitor*"""; Flags: runhidden

; 清理运行时产生的文件 + 整个安装目录
[UninstallDelete]
Type: files; Name: "{app}\monitor.log"
Type: dirifempty; Name: "{app}"

[Run]
; 安装完成后立即启动
Filename: "{app}\start-monitor.vbs"; Description: "立即启动 {#MyAppName}"; Flags: nowait postinstall skipifsilent
