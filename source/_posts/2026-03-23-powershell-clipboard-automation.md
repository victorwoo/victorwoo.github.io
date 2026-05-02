---
layout: post
date: 2026-03-23 08:00:00
updated: 2026-03-23 08:00:00
title: "PowerShell 技能连载 - 剪贴板与系统交互"
description: PowerTip of the Day - Clipboard and System Interaction in PowerShell
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
- clipboard
- ui-automation
- system-interaction
- productivity
---

_适用于 PowerShell 7.0 及以上版本_

很多运维人员习惯在终端里做所有事情，却忽略了 PowerShell 与桌面环境交互的能力。日常工作中，我们经常需要在浏览器里复制一段 JSON、在 Excel 里复制一列数据、在日志系统中截取错误信息，然后粘贴到脚本中处理。如果能直接在脚本中读写剪贴板，就能省去中间的文件保存步骤，让数据流转更顺畅。

除了剪贴板操作，PowerShell 还可以通过 .NET 的互操作能力枚举系统窗口、控制窗口焦点，甚至模拟键盘输入来自动化 GUI 应用。这些技巧在处理那些没有提供命令行接口的传统软件时尤为实用——比如操作老旧的 ERP 系统、向不支持 API 的工具批量输入数据等。

本文将从三个层面展开：首先介绍剪贴板的读写与数据转换，然后演示如何枚举和管理系统窗口，最后通过 SendKeys 实现简单的 GUI 自动化操作。

## 剪贴板读写与数据转换

PowerShell 内置了 `Get-Clipboard` 和 `Set-Clipboard` 两个 cmdlet，可以方便地读取和设置剪贴板内容。结合正则表达式和对象转换，可以快速对剪贴板中的数据进行提取、清洗和格式化处理。这在处理从网页或 Excel 中复制的表格数据时特别高效。

```powershell
# 基础剪贴板操作
# 读取剪贴板内容
$clipContent = Get-Clipboard
Write-Host "当前剪贴板内容（前 100 字符）:"
Write-Host ($clipContent.Substring(0, [Math]::Min(100, $clipContent.Length)))

# 将处理结果写回剪贴板
$processed = $clipContent | ForEach-Object { $_.Trim() } | Where-Object { $_ -ne '' }
$processed | Set-Clipboard
Write-Host "`n已清洗剪贴板内容，去除空行和首尾空格"

# 实用场景：从剪贴板提取 IP 地址
function Get-ClipboardIpAddresses {
    $text = Get-Clipboard -Raw
    if (-not $text) {
        Write-Warning "剪贴板为空"
        return
    }
    $ipPattern = '\b(?:(?:25[0-5]|2[0-4]\d|[01]?\d\d?)\.){3}(?:25[0-5]|2[0-4]\d|[01]?\d\d?)\b'
    $matches = [regex]::Matches($text, $ipPattern)
    $ips = $matches | ForEach-Object { $_.Value } | Sort-Object -Unique
    return $ips
}

$ips = Get-ClipboardIpAddresses
if ($ips) {
    Write-Host "`n从剪贴板提取到 $($ips.Count) 个 IP 地址:"
    $ips | ForEach-Object { Write-Host "  $_" }
    # 将结果写回剪贴板，方便粘贴到其他工具
    $ips -join "`r`n" | Set-Clipboard
    Write-Host "已将 IP 列表写回剪贴板"
}

# 实用场景：剪贴板 JSON 格式化
function Format-ClipboardJson {
    $text = (Get-Clipboard -Raw).Trim()
    if ($text -match '^\{|\[') {
        try {
            $obj = $text | ConvertFrom-Json
            $formatted = $obj | ConvertTo-Json -Depth 10
            $formatted | Set-Clipboard
            Write-Host "JSON 已格式化并写回剪贴板"
        }
        catch {
            Write-Warning "剪贴板内容不是有效的 JSON: $($_.Exception.Message)"
        }
    }
    else {
        Write-Warning "剪贴板内容不以 { 或 [ 开头，可能不是 JSON"
    }
}

# 实用场景：剪贴板文本大小写转换工具
function Convert-ClipboardCase {
    param(
        [ValidateSet('Upper', 'Lower', 'Title', 'Camel')]
        [string]$Style = 'Upper'
    )
    $text = Get-Clipboard -Raw
    if (-not $text) { return }
    $result = switch ($Style) {
        'Upper' { $text.ToUpper() }
        'Lower' { $text.ToLower() }
        'Title' {
            (Get-Culture).TextInfo.ToTitleCase($text.ToLower())
        }
        'Camel' {
            $words = $text -split '\s+'
            ($words[0].ToLower()) + (($words[1..($words.Length - 1)] | ForEach-Object {
                if ($_.Length -gt 0) {
                    $_.Substring(0, 1).ToUpper() + $_.Substring(1).ToLower()
                }
            }) -join '')
        }
    }
    $result | Set-Clipboard
    Write-Host "已将剪贴板文本转换为 $Style 格式"
}
```

执行结果示例：

```
当前剪贴板内容（前 100 字符）:
Server 192.168.1.10 is responding
Server 192.168.1.20 is down
Server 10.0.0.5 is responding

已清洗剪贴板内容，去除空行和首尾空格

从剪贴板提取到 3 个 IP 地址:
  10.0.0.5
  192.168.1.10
  192.168.1.20
已将 IP 列表写回剪贴板
```

## 窗口枚举与焦点管理

在自动化 GUI 操作之前，通常需要先找到目标窗口。Windows 系统通过句柄（Handle）标识每个窗口，PowerShell 可以借助 .NET 的 `System.Diagnostics.Process` 类和 P/Invoke 调用 Win32 API 来枚举、定位和控制系统窗口。这在需要对特定应用程序进行自动化操作时是关键的准备步骤。

```powershell
# 使用 Add-Type 加载 Win32 API
Add-Type @"
using System;
using System.Runtime.InteropServices;
using System.Text;
public class Win32Api {
    [DllImport("user32.dll")]
    public static extern bool SetForegroundWindow(IntPtr hWnd);

    [DllImport("user32.dll")]
    public static extern bool ShowWindow(IntPtr hWnd, int nCmdShow);

    [DllImport("user32.dll")]
    public static extern bool IsWindowVisible(IntPtr hWnd);

    [DllImport("user32.dll", SetLastError = true, CharSet = CharSet.Auto)]
    public static extern int GetWindowTextLength(IntPtr hWnd);

    [DllImport("user32.dll", CharSet = CharSet.Auto)]
    public static extern int GetWindowText(IntPtr hWnd, StringBuilder lpString, int nMaxCount);

    public const int SW_RESTORE = 9;
    public const int SW_MINIMIZE = 6;
    public const int SW_MAXIMIZE = 3;
}
"@

# 枚举所有可见窗口及其标题
function Get-VisibleWindow {
    $processes = Get-Process | Where-Object {
        $_.MainWindowHandle -ne 0 -and
        $_.MainWindowTitle -ne ''
    }
    foreach ($proc in $processes) {
        $sb = New-Object System.Text.StringBuilder 256
        [Win32Api]::GetWindowText($proc.MainWindowHandle, $sb, 256) | Out-Null
        [PSCustomObject]@{
            ProcessName = $proc.ProcessName
            Title       = $sb.ToString()
            Handle      = $proc.MainWindowHandle
            Id          = $proc.Id
            Memory      = [Math]::Round($proc.WorkingSet64 / 1MB, 2)
        }
    }
}

# 列出当前所有可见窗口
$windows = Get-VisibleWindow
Write-Host "当前可见窗口（共 $($windows.Count) 个）:"
Write-Host ("{0,-20} {1,-40} {2,10} {3,8}" -f "进程", "标题", "PID", "内存(MB)")
Write-Host ("-" * 82)
foreach ($w in $windows) {
    $title = if ($w.Title.Length -gt 38) { $w.Title.Substring(0, 35) + "..." } else { $w.Title }
    Write-Host ("{0,-20} {1,-40} {2,10} {3,8}" -f $w.ProcessName, $title, $w.Id, $w.Memory)
}

# 将指定窗口切换到前台
function Set-WindowFocus {
    param(
        [Parameter(Mandatory)]
        [string]$ProcessName
    )
    $proc = Get-Process -Name $ProcessName -ErrorAction SilentlyContinue |
        Where-Object { $_.MainWindowHandle -ne 0 } |
        Select-Object -First 1
    if (-not $proc) {
        Write-Warning "未找到进程: $ProcessName"
        return
    }
    [Win32Api]::ShowWindow($proc.MainWindowHandle, [Win32Api]::SW_RESTORE) | Out-Null
    [Win32Api]::SetForegroundWindow($proc.MainWindowHandle) | Out-Null
    Write-Host "已将 $ProcessName 窗口切换到前台 (PID: $($proc.Id))"
}

# 窗口状态控制
function Set-WindowState {
    param(
        [Parameter(Mandatory)]
        [string]$ProcessName,
        [ValidateSet('Minimize', 'Maximize', 'Restore')]
        [string]$State
    )
    $proc = Get-Process -Name $ProcessName -ErrorAction SilentlyContinue |
        Where-Object { $_.MainWindowHandle -ne 0 } |
        Select-Object -First 1
    if (-not $proc) {
        Write-Warning "未找到进程: $ProcessName"
        return
    }
    $cmd = switch ($State) {
        'Minimize' { [Win32Api]::SW_MINIMIZE }
        'Maximize' { [Win32Api]::SW_MAXIMIZE }
        'Restore'  { [Win32Api]::SW_RESTORE }
    }
    [Win32Api]::ShowWindow($proc.MainWindowHandle, $cmd) | Out-Null
    Write-Host "已将 $ProcessName 窗口设置为 $State 状态"
}

# 按窗口标题搜索
$notepadWindows = $windows | Where-Object { $_.Title -match '记事本|Notepad' }
if ($notepadWindows) {
    Write-Host "`n找到记事本窗口:"
    $notepadWindows | Format-Table -AutoSize
}
```

执行结果示例：

```
当前可见窗口（共 8 个）:
进程                 标题                                          PID   内存(MB)
----------------------------------------------------------------------------------
code                 test-script.ps1 - Visual Studio Code         12345     312.45
explorer             PowerShell                                        67890     85.21
msedge               blog.vichamp.com - 个人技术博客 - Microsoft Edge 11223     425.67
notepad              未命名 - 记事本                                  33445      12.30
WindowsTerminal      Windows PowerShell                                55677     98.15

找到记事本窗口:
ProcessName Title          Handle        Id Memory
----------- -----          ------        -- ------
notepad     未命名 - 记事本 1234567    33445  12.3
```

## SendKeys 与 GUI 自动化

当目标应用没有提供命令行接口或 API 时，SendKeys 模拟键盘输入就成了最后的自动化手段。PowerShell 可以通过 `[System.Windows.Forms.SendKeys]` 类向当前活动窗口发送按键指令，实现自动填写表单、执行菜单操作等功能。结合前面的窗口管理能力，可以先激活目标窗口再发送按键，形成完整的自动化链路。

```powershell
# 加载必要的程序集
Add-Type -AssemblyName System.Windows.Forms

# 基础 SendKeys 操作
function Invoke-SendKeys {
    param(
        [Parameter(Mandatory)]
        [string]$Keys,
        [int]$DelayMs = 500
    )
    Start-Sleep -Milliseconds $DelayMs
    [System.Windows.Forms.SendKeys]::SendWait($Keys)
    Write-Host "已发送按键: $Keys"
}

# SendKeys 特殊键对照（常用）
function Show-SendKeysReference {
    $ref = @(
        [PSCustomObject]@{ Key = 'Enter';        SendKeys = '{ENTER}' }
        [PSCustomObject]@{ Key = 'Tab';           SendKeys = '{TAB}' }
        [PSCustomObject]@{ Key = 'Escape';        SendKeys = '{ESC}' }
        [PSCustomObject]@{ Key = 'Backspace';     SendKeys = '{BACKSPACE}' }
        [PSCustomObject]@{ Key = 'Delete';        SendKeys = '{DELETE}' }
        [PSCustomObject]@{ Key = 'Home';          SendKeys = '{HOME}' }
        [PSCustomObject]@{ Key = 'End';           SendKeys = '{END}' }
        [PSCustomObject]@{ Key = 'Page Up';       SendKeys = '{PGUP}' }
        [PSCustomObject]@{ Key = 'Page Down';     SendKeys = '{PGDN}' }
        [PSCustomObject]@{ Key = 'Ctrl+A';        SendKeys = '^a' }
        [PSCustomObject]@{ Key = 'Ctrl+C';        SendKeys = '^c' }
        [PSCustomObject]@{ Key = 'Ctrl+V';        SendKeys = '^v' }
        [PSCustomObject]@{ Key = 'Ctrl+S';        SendKeys = '^s' }
        [PSCustomObject]@{ Key = 'Alt+F4';        SendKeys = '%{F4}' }
        [PSCustomObject]@{ Key = 'F5 (刷新)';     SendKeys = '{F5}' }
    )
    $ref | Format-Table -AutoSize
}

Show-SendKeysReference

# 完整的 GUI 自动化脚本示例
function Invoke-NotepadAutomation {
    # 启动记事本
    Write-Host "启动记事本..."
    $notepad = Start-Process notepad -PassThru
    Start-Sleep -Seconds 1

    # 等待窗口出现
    $timeout = 10
    while ($timeout -gt 0) {
        $proc = Get-Process -Id $notepad.Id -ErrorAction SilentlyContinue
        if ($proc -and $proc.MainWindowHandle -ne 0) { break }
        Start-Sleep -Milliseconds 500
        $timeout--
    }

    # 输入内容
    Write-Host "输入文本内容..."
    Invoke-SendKeys -Keys "PowerShell GUI Automation Demo" -DelayMs 300
    Invoke-SendKeys -Keys "{ENTER}" -DelayMs 200
    Invoke-SendKeys -Keys "Generated at $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -DelayMs 200
    Invoke-SendKeys -Keys "{ENTER}" -DelayMs 200

    # 全选并复制
    Write-Host "全选并复制到剪贴板..."
    Invoke-SendKeys -Keys "^a" -DelayMs 300
    Invoke-SendKeys -Keys "^c" -DelayMs 300

    # 验证剪贴板
    Start-Sleep -Milliseconds 500
    $clipContent = Get-Clipboard -Raw
    if ($clipContent -match 'PowerShell GUI') {
        Write-Host "`n自动化成功！剪贴板内容已捕获:"
        Write-Host $clipContent
    }
    else {
        Write-Warning "剪贴板验证失败"
    }

    # 关闭记事本（不保存）
    Write-Host "`n关闭记事本..."
    Invoke-SendKeys -Keys "%{F4}" -DelayMs 500
    Invoke-SendKeys -Keys "%n" -DelayMs 500
}

# 剪贴板内容自动填入 Web 表单的辅助函数
function Send-ClipboardToField {
    param(
        [int]$PreDelayMs = 2000,
        [int]$FieldCount = 1
    )
    Write-Host "请在 $([Math]::Round($PreDelayMs/1000, 1)) 秒内切换到目标窗口并定位到第一个输入框..."
    Start-Sleep -Milliseconds $PreDelayMs

    $lines = (Get-Clipboard -Raw) -split "`r?`n" | Where-Object { $_ -ne '' }
    $count = [Math]::Min($FieldCount, $lines.Count)

    for ($i = 0; $i -lt $count; $i++) {
        Set-Clipboard -Value $lines[$i]
        Invoke-SendKeys -Keys "^v" -DelayMs 300
        if ($i -lt $count - 1) {
            Invoke-SendKeys -Keys "{TAB}" -DelayMs 300
        }
        Write-Host "已填入第 $($i + 1) 个字段: $($lines[$i].Substring(0, [Math]::Min(30, $lines[$i].Length)))"
    }
    Write-Host "`n共填入 $count 个字段"
}
```

执行结果示例：

```
Key             SendKeys
---             --------
Enter           {ENTER}
Tab             {TAB}
Escape          {ESC}
Backspace       {BACKSPACE}
Delete          {DELETE}
Home            {HOME}
End             {END}
Page Up         {PGUP}
Page Down       {PGDN}
Ctrl+A          ^a
Ctrl+C          ^c
Ctrl+V          ^v
Ctrl+S          ^s
Alt+F4          %{F4}
F5 (刷新)       {F5}

启动记事本...
输入文本内容...
已发送按键: PowerShell GUI Automation Demo
已发送按键: {ENTER}
已发送按键: Generated at 2026-03-23 10:30:00
已发送按键: {ENTER}
全选并复制到剪贴板...
已发送按键: ^a
已发送按键: ^c

自动化成功！剪贴板内容已捕获:
PowerShell GUI Automation Demo
Generated at 2026-03-23 10:30:00

关闭记事本...
已发送按键: %{F4}
已发送按键: %n
```

## 注意事项

1. **剪贴板是共享资源**：Windows 剪贴板是全局共享的，如果在脚本读写剪贴板的过程中用户手动进行了复制操作，会导致数据被覆盖。对于关键的自动化流程，建议先读取并保存到变量中再处理，避免中间过程依赖剪贴板状态。

2. **SendKeys 的时序问题**：`SendKeys` 发送的是按键事件而非直接输入，目标窗口必须在前台且已就绪。网络延迟、应用启动速度等因素都可能导致按键发送到错误的窗口。建议在每步操作之间加入适当的 `Start-Sleep` 延迟，并在发送前验证目标窗口确实获得了焦点。

3. **Win32 API 调用需要管理员权限**：部分窗口操作（如操控其他用户会话的窗口、系统进程的窗口）需要以管理员身份运行 PowerShell。普通用户权限只能操控同一会话下的窗口。

4. **跨平台限制**：`Get-Clipboard` 和 `Set-Clipboard` 在 PowerShell 7 中支持 Windows、macOS 和 Linux，但窗口管理和 SendKeys 功能仅限 Windows 平台。在 macOS 上可以考虑使用 `osascript` 配合 AppleScript 实现类似的 GUI 自动化。

5. **SendKeys 特殊字符需要转义**：`SendKeys` 中 `+`、`^`、`%`、`{`、`}` 等字符有特殊含义（分别代表 Shift、Ctrl、Alt 和特殊键定界符）。如果要发送这些字符本身，需要用 `{}` 包裹，例如发送加号应使用 `{+}` 而非 `+`。

6. **GUI 自动化的脆弱性**：基于窗口标题匹配和按键模拟的自动化方案非常脆弱——界面布局变化、分辨率调整、系统语言切换都可能导致脚本失效。对于有命令行接口或 API 的应用，应优先使用这些更稳定的方案；SendKeys 仅作为没有其他选择时的补充手段。
