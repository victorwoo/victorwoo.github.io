---
layout: post
date: 2025-06-25 08:00:00
updated: 2025-06-25 08:00:00
title: "PowerShell 技能连载 - 剪贴板与 GUI 互操作"
description: PowerTip of the Day - Clipboard and GUI Interop in PowerShell
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
- clipboard
- gui
- interop
---

_适用于 PowerShell 5.1 及以上版本（Windows），剪贴板功能需要 Windows 环境_

PowerShell 不仅仅是命令行工具——它可以与 Windows 图形界面深度交互。从读写剪贴板、弹出消息框、打开文件对话框，到操控 GUI 窗口和发送按键，PowerShell 可以成为连接命令行和桌面操作的桥梁。在日常工作中，这些功能可以大幅简化重复性的 GUI 操作。

本文将讲解剪贴板操作、消息框、文件对话框，以及窗口自动化的技巧。

<!-- more -->

## 剪贴板操作

```powershell
# 设置剪贴板内容（文本）
Set-Clipboard -Value "Hello from PowerShell!"
Write-Host "已复制到剪贴板" -ForegroundColor Green

# 获取剪贴板内容
$clipContent = Get-Clipboard
Write-Host "剪贴板内容：$clipContent"

# 复制命令输出到剪贴板
Get-Process | Select-Object Name, Id,
    @{N='内存MB'; E={[math]::Round($_.WorkingSet64/1MB, 1)}} |
    Sort-Object 内存MB -Descending |
    Select-Object -First 10 |
    Format-Table -AutoSize |
    Out-String | Set-Clipboard
Write-Host "进程列表已复制到剪贴板" -ForegroundColor Green

# 复制文件路径到剪贴板
Get-ChildItem "C:\Projects" -Filter *.ps1 -Recurse |
    Select-Object -ExpandProperty FullName |
    Set-Clipboard
Write-Host "已复制所有 .ps1 文件路径" -ForegroundColor Green

# 从剪贴板读取并处理
$clipboardText = Get-Clipboard
if ($clipboardText -match '^\d{1,3}(\.\d{1,3}){3}$') {
    Write-Host "检测到 IP 地址：$clipboardText" -ForegroundColor Cyan
    Test-NetConnection -ComputerName $clipboardText -Port 443 |
        Select-Object ComputerName, TcpTestSucceeded
}
```

执行结果示例：

```
已复制到剪贴板
剪贴板内容：Hello from PowerShell!
进程列表已复制到剪贴板
```

## 消息框与交互

```powershell
# 简单消息框
Add-Type -AssemblyName PresentationFramework

[System.Windows.MessageBox]::Show(
    "部署已完成",
    "提示",
    [System.Windows.MessageBoxButton]::OK,
    [System.Windows.MessageBoxImage]::Information
)

# 确认对话框
$result = [System.Windows.MessageBox]::Show(
    "确定要重启服务 MyApp 吗？",
    "确认操作",
    [System.Windows.MessageBoxButton]::YesNo,
    [System.Windows.MessageBoxImage]::Warning
)

if ($result -eq 'Yes') {
    Restart-Service "MyApp"
    Write-Host "服务已重启" -ForegroundColor Green
} else {
    Write-Host "操作已取消" -ForegroundColor Yellow
}

# 带超时的通知（使用 Balloon Tip）
function Show-BalloonTip {
    param(
        [string]$Title = "PowerShell",
        [string]$Message,
        [int]$DurationMs = 5000
    )

    Add-Type -AssemblyName System.Windows.Forms

    $notify = New-Object System.Windows.Forms.NotifyIcon
    $notify.Icon = [System.Drawing.SystemIcons]::Information
    $notify.BalloonTipTitle = $Title
    $notify.BalloonTipText = $Message
    $notify.Visible = $true
    $notify.ShowBalloonTip($DurationMs)

    Start-Sleep -Milliseconds ($DurationMs + 500)
    $notify.Dispose()
}

Show-BalloonTip -Title "部署完成" -Message "MyApp v2.5.0 已成功部署到生产环境"
```

执行结果示例：

```
# 弹出 Windows 消息框
# 系统托盘弹出通知气泡
```

## 文件和文件夹对话框

```powershell
# 打开文件选择对话框
Add-Type -AssemblyName System.Windows.Forms

$openFileDialog = New-Object System.Windows.Forms.OpenFileDialog
$openFileDialog.Title = "选择 CSV 文件"
$openFileDialog.Filter = "CSV 文件 (*.csv)|*.csv|所有文件 (*.*)|*.*"
$openFileDialog.Multiselect = $true

if ($openFileDialog.ShowDialog() -eq 'OK') {
    foreach ($file in $openFileDialog.FileNames) {
        Write-Host "已选择：$file" -ForegroundColor Green
        Import-Csv $file | Select-Object -First 5
    }
}

# 保存文件对话框
$saveDialog = New-Object System.Windows.Forms.SaveFileDialog
$saveDialog.Title = "保存报告"
$saveDialog.Filter = "HTML 报告 (*.html)|*.html|CSV 文件 (*.csv)|*.csv"
$saveDialog.FileName = "report-$(Get-Date -Format 'yyyyMMdd').html"

if ($saveDialog.ShowDialog() -eq 'OK') {
    Write-Host "保存到：$($saveDialog.FileName)" -ForegroundColor Green
    # 生成报告...
}

# 文件夹浏览对话框
$folderDialog = New-Object System.Windows.Forms.FolderBrowserDialog
$folderDialog.Description = "选择项目目录"
$folderDialog.ShowNewFolderButton = $true

if ($folderDialog.ShowDialog() -eq 'OK') {
    $selectedPath = $folderDialog.SelectedPath
    Write-Host "已选择目录：$selectedPath" -ForegroundColor Green

    $files = Get-ChildItem $selectedPath -Recurse -File
    Write-Host "目录中有 $($files.Count) 个文件"
}
```

执行结果示例：

```
# 弹出标准的 Windows 文件选择对话框
已选择：C:\Data\customers.csv
保存到：C:\Reports\report-20250625.html
已选择目录：C:\Projects\MyApp
目录中有 245 个文件
```

## 窗口自动化

```powershell
# 使用 SendKeys 自动化 GUI 操作
Add-Type -AssemblyName System.Windows.Forms

# 模拟键盘快捷键
function Send-Keys {
    param([string]$Keys, [int]$DelayMs = 500)

    Start-Sleep -Milliseconds $DelayMs
    [System.Windows.Forms.SendKeys]::SendWait($Keys)
}

# Ctrl+C 复制
Send-Keys "^c"

# Alt+Tab 切换窗口
Send-Keys "%{TAB}"

# 打开运行对话框 (Win+R)
Send-Keys "^{ESC}r"

# 输入文本
Start-Sleep -Seconds 2
Send-Keys "notepad.exe{ENTER}"

# 自动化记事本操作示例
Start-Sleep -Seconds 2
Send-Keys "这段文字由 PowerShell 自动输入"

# 保存 (Ctrl+S)
Start-Sleep -Milliseconds 500
Send-Keys "^s"

# 输入文件名
Start-Sleep -Seconds 1
Send-Keys "auto-generated.txt{ENTER}"
```

执行结果示例：

```
# 自动化操作 GUI 窗口
```

## 实用工具函数

```powershell
# 快速复制 IP 配置
function Copy-IPConfig {
    $ipConfig = Get-NetIPAddress -AddressFamily IPv4 |
        Where-Object { $_.InterfaceAlias -notmatch 'Loopback' } |
        Select-Object InterfaceAlias, IPAddress, PrefixLength |
        Format-Table -AutoSize |
        Out-String

    Set-Clipboard -Value $ipConfig
    Write-Host "IP 配置已复制到剪贴板" -ForegroundColor Green
}

# 快速复制文件内容
function Copy-FileContent {
    param([Parameter(Mandatory)][string]$Path)
    Get-Content $Path -Raw | Set-Clipboard
    Write-Host "文件内容已复制：$Path ($((Get-Item $Path).Length) bytes)" -ForegroundColor Green
}

# 快速打开选中文件所在目录
function Open-FileLocation {
    param([Parameter(Mandatory)][string]$Path)
    $dir = Split-Path $Path -Parent
    Start-Process explorer.exe $dir
}

Copy-IPConfig
Copy-FileContent -Path "C:\Config\appsettings.json"
```

执行结果示例：

```
IP 配置已复制到剪贴板
文件内容已复制：C:\Config\appsettings.json (2048 bytes)
```

## 注意事项

1. **剪贴板安全**：剪贴板内容可能包含敏感信息（密码、Token），操作完应清空剪贴板
2. **GUI 依赖**：剪贴板和 GUI 操作需要交互式桌面会话，在无头环境（Server Core、SSH 远程）中不可用
3. **SendKeys 时序**：窗口自动化依赖时序，网络延迟或系统负载可能导致失败。添加合理的 `Start-Sleep`
4. **STA 模式**：某些 GUI 操作需要单线程单元（STA）模式，PowerShell 5.1 默认为 STA，PowerShell 7 默认为 MTA
5. **管理员权限**：某些 GUI 操作（如操控其他用户的窗口）需要管理员权限
6. **用户体验**：自动化 GUI 操作时应通知用户，避免在用户不知情时操控窗口
