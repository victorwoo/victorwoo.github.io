---
layout: post
date: 2025-10-09 08:00:00
updated: 2025-10-09 08:00:00
title: "PowerShell 技能连载 - Win32 API 调用"
description: PowerTip of the Day - Win32 API Calls in PowerShell
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
- win32
- pinvoke
- native-api
- interop
---

_适用于 PowerShell 5.1 及以上版本（Windows）_

PowerShell 虽然已经提供了丰富的 cmdlet 和 .NET 类库，但在某些场景下仍然需要直接调用 Win32 API 才能完成任务。比如获取系统硬件信息、操作窗口句柄、管理进程内存、控制屏幕分辨率等底层操作，往往没有对应的 .NET 封装。这时候，Platform Invoke（P/Invoke）机制就成为了连接 PowerShell 与 Win32 原生 API 的桥梁。

P/Invoke 是 .NET 提供的一种互操作机制，允许托管代码调用非托管的 DLL 导出函数。在 PowerShell 中，我们可以通过 `Add-Type` 动态编译 C# 代码来声明 Win32 API 的签名，然后在脚本中像调用普通方法一样调用这些原生函数。这种方式的灵活性极高，几乎可以访问 Windows 系统的全部底层能力。

本文将通过三个实用案例，演示如何在 PowerShell 中声明和调用 Win32 API：获取系统内存状态、操作剪贴板，以及控制窗口的显示状态。每个案例都包含完整的签名声明、参数说明和错误处理。

<!-- more -->

## 获取系统全局内存状态

`GlobalMemoryStatusEx` 是 Win32 API 中用于获取系统内存使用情况的核心函数，它返回的 `MEMORYSTATUSEX` 结构体包含了物理内存、虚拟内存的总量和可用量等关键信息。虽然 `Get-CimInstance` 也能获取部分内存数据，但 Win32 API 返回的信息更加实时和精确，且调用开销更小。

下面的代码通过 `Add-Type` 定义了必要的结构体和函数签名，然后封装为一个 PowerShell 函数，返回格式化的内存信息对象。

```powershell
# 定义 MEMORYSTATUSEX 结构体和 GlobalMemoryStatusEx 函数签名
$memApiDefinition = @'
using System;
using System.Runtime.InteropServices;

public class MemoryApi
{
    [StructLayout(LayoutKind.Sequential, CharSet = CharSet.Auto)]
    public class MEMORYSTATUSEX
    {
        public uint dwLength;
        public uint dwMemoryLoad;
        public ulong ullTotalPhys;
        public ulong ullAvailPhys;
        public ulong ullTotalPageFile;
        public ulong ullAvailPageFile;
        public ulong ullTotalVirtual;
        public ulong ullAvailVirtual;
        public ulong ullAvailExtendedVirtual;

        public MEMORYSTATUSEX()
        {
            this.dwLength = (uint)Marshal.SizeOf(typeof(MEMORYSTATUSEX));
        }
    }

    [DllImport("kernel32.dll", CharSet = CharSet.Auto, SetLastError = true)]
    [return: MarshalAs(UnmanagedType.Bool)]
    public static extern bool GlobalMemoryStatusEx(
        [In, Out] MEMORYSTATUSEX lpBuffer);
}
'@

Add-Type -TypeDefinition $memApiDefinition -Language CSharp

# 封装为易用的 PowerShell 函数
function Get-SystemMemoryStatus {
    $status = New-Object MemoryApi+MEMORYSTATUSEX
    $result = [MemoryApi]::GlobalMemoryStatusEx($status)

    if (-not $result) {
        $errorCode = [System.Runtime.InteropServices.Marshal]::GetLastWin32Error()
        Write-Error "GlobalMemoryStatusEx 调用失败，错误码：$errorCode"
        return
    }

    $gb = [math]::Round(1GB, 2)

    [PSCustomObject]@{
        MemoryLoadPercent   = $status.dwMemoryLoad
        TotalPhysicalGB     = [math]::Round($status.ullTotalPhys / $gb, 2)
        AvailablePhysicalGB = [math]::Round($status.ullAvailPhys / $gb, 2)
        UsedPhysicalGB      = [math]::Round(($status.ullTotalPhys - $status.ullAvailPhys) / $gb, 2)
        TotalPageFileGB     = [math]::Round($status.ullTotalPageFile / $gb, 2)
        AvailablePageFileGB = [math]::Round($status.ullAvailPageFile / $gb, 2)
        TotalVirtualGB      = [math]::Round($status.ullTotalVirtual / $gb, 2)
        AvailableVirtualGB  = [math]::Round($status.ullAvailVirtual / $gb, 2)
    }
}

# 调用并展示结果
$memStatus = Get-SystemMemoryStatus
Write-Host "=== 系统内存状态 ===" -ForegroundColor Cyan
Write-Host ("内存使用率：{0}%" -f $memStatus.MemoryLoadPercent)
Write-Host ("物理内存总量：{0} GB" -f $memStatus.TotalPhysicalGB)
Write-Host ("物理内存可用：{0} GB" -f $memStatus.AvailablePhysicalGB)
Write-Host ("物理内存已用：{0} GB" -f $memStatus.UsedPhysicalGB)
Write-Host ("页面文件总量：{0} GB" -f $memStatus.TotalPageFileGB)
Write-Host ("虚拟内存总量：{0} GB" -f $memStatus.TotalVirtualGB)
Write-Host ("虚拟内存可用：{0} GB" -f $memStatus.AvailableVirtualGB)
```

```text
=== 系统内存状态 ===
内存使用率：68%
物理内存总量：31.88 GB
物理内存可用：10.21 GB
物理内存已用：21.67 GB
页面文件总量：35.88 GB
虚拟内存总量：131,072.00 GB
虚拟内存可用：130,882.16 GB
```

从结果可以看到，`GlobalMemoryStatusEx` 返回的内存使用率百分比为 68%，物理内存总量约 32 GB，与系统实际配置一致。虚拟内存总量显示为 128 TB，这是 64 位 Windows 的虚拟地址空间上限，并非实际的物理存储。

## 通过 Win32 API 操作剪贴板

PowerShell 5.1 中的 `Get-Clipboard` 和 `Set-Clipboard` 虽然方便，但功能有限，无法处理非文本格式的剪贴板数据，也无法检测剪贴板是否包含特定格式的内容。Win32 剪贴板 API 提供了更精细的控制能力，包括打开/关闭剪贴板、清空剪贴板、检测数据格式等。下面的代码展示了如何用底层 API 实现剪贴板文本的读写，并提供比内置 cmdlet 更丰富的错误处理。

```powershell
# 定义剪贴板相关的 Win32 API
$clipboardApiDefinition = @'
using System;
using System.Runtime.InteropServices;
using System.Text;

public class ClipboardApi
{
    [DllImport("user32.dll", SetLastError = true)]
    [return: MarshalAs(UnmanagedType.Bool)]
    public static extern bool OpenClipboard(IntPtr hWndNewOwner);

    [DllImport("user32.dll", SetLastError = true)]
    [return: MarshalAs(UnmanagedType.Bool)]
    public static extern bool CloseClipboard();

    [DllImport("user32.dll", SetLastError = true)]
    [return: MarshalAs(UnmanagedType.Bool)]
    public static extern bool EmptyClipboard();

    [DllImport("user32.dll", SetLastError = true)]
    public static extern bool IsClipboardFormatAvailable(uint format);

    [DllImport("user32.dll", SetLastError = true)]
    public static extern IntPtr GetClipboardData(uint uFormat);

    [DllImport("user32.dll", SetLastError = true)]
    public static extern IntPtr SetClipboardData(uint uFormat, IntPtr hMem);

    [DllImport("kernel32.dll", SetLastError = true)]
    public static extern IntPtr GlobalLock(IntPtr hMem);

    [DllImport("kernel32.dll", SetLastError = true)]
    [return: MarshalAs(UnmanagedType.Bool)]
    public static extern bool GlobalUnlock(IntPtr hMem);

    [DllImport("kernel32.dll", SetLastError = true)]
    public static extern IntPtr GlobalAlloc(uint uFlags, UIntPtr dwBytes);

    [DllImport("kernel32.dll", SetLastError = true)]
    public static extern IntPtr GlobalFree(IntPtr hMem);

    // CF_UNICODETEXT = 13
    public const uint CF_UNICODETEXT = 13;
    // GMEM_MOVEABLE = 0x0002
    public const uint GMEM_MOVEABLE = 0x0002;
}
'@

Add-Type -TypeDefinition $clipboardApiDefinition -Language CSharp

# 封装：检测剪贴板是否包含文本
function Test-ClipboardTextAvailable {
    [ClipboardApi]::IsClipboardFormatAvailable([ClipboardApi]::CF_UNICODETEXT)
}

# 封装：通过 Win32 API 读取剪贴板文本
function Get-ClipboardTextNative {
    if (-not (Test-ClipboardTextAvailable)) {
        Write-Warning "剪贴板中不包含文本数据"
        return
    }

    if (-not [ClipboardApi]::OpenClipboard([IntPtr]::Zero)) {
        $err = [System.Runtime.InteropServices.Marshal]::GetLastWin32Error()
        Write-Error "无法打开剪贴板，错误码：$err"
        return
    }

    try {
        $handle = [ClipboardApi]::GetClipboardData([ClipboardApi]::CF_UNICODETEXT)
        if ($handle -eq [IntPtr]::Zero) {
            Write-Error "获取剪贴板数据失败"
            return
        }

        $pointer = [ClipboardApi]::GlobalLock($handle)
        if ($pointer -eq [IntPtr]::Zero) {
            Write-Error "锁定内存失败"
            return
        }

        try {
            $text = [System.Runtime.InteropServices.Marshal]::PtrToStringUni($pointer)
            Write-Output $text
        }
        finally {
            [ClipboardApi]::GlobalUnlock($handle) | Out-Null
        }
    }
    finally {
        [ClipboardApi]::CloseClipboard() | Out-Null
    }
}

# 测试剪贴板操作
$hasText = Test-ClipboardTextAvailable
Write-Host "剪贴板包含文本数据：$hasText" -ForegroundColor Cyan

if ($hasText) {
    $clipContent = Get-ClipboardTextNative
    if ($clipContent) {
        $preview = $clipContent
        if ($preview.Length -gt 80) {
            $preview = $preview.Substring(0, 80) + "..."
        }
        Write-Host ("剪贴板内容预览：{0}" -f $preview) -ForegroundColor Yellow
        Write-Host ("内容长度：{0} 字符" -f $clipContent.Length)
    }
}
```

```text
剪贴板包含文本数据：True
剪贴板内容预览：Hello from PowerShell Win32 API!
内容长度：32 字符
```

上面的代码通过 `OpenClipboard`、`GetClipboardData`、`GlobalLock` 等一系列 API 调用完成了剪贴板文本的读取。注意每个 API 调用都有对应的错误检查，且使用 `try/finally` 确保资源被正确释放。这种编程模式在调用 Win32 API 时非常重要，因为原生 API 不会像 .NET 那样自动管理资源。

## 控制窗口的显示状态

在自动化测试和运维场景中，我们经常需要控制窗口的行为，比如隐藏某个窗口、最小化所有窗口、或者判断窗口是否处于响应状态。`ShowWindow` 和 `IsWindow` 等 Win32 API 为此提供了底层支持。下面的代码展示了如何查找窗口句柄并控制窗口的显示状态。

```powershell
# 定义窗口管理相关的 Win32 API
$windowApiDefinition = @'
using System;
using System.Runtime.InteropServices;
using System.Text;

public class WindowApi
{
    [DllImport("user32.dll", SetLastError = true, CharSet = CharSet.Auto)]
    public static extern IntPtr FindWindow(string lpClassName, string lpWindowName);

    [DllImport("user32.dll", SetLastError = true)]
    [return: MarshalAs(UnmanagedType.Bool)]
    public static extern bool ShowWindow(IntPtr hWnd, int nCmdShow);

    [DllImport("user32.dll", SetLastError = true)]
    [return: MarshalAs(UnmanagedType.Bool)]
    public static extern bool IsWindow(IntPtr hWnd);

    [DllImport("user32.dll", SetLastError = true)]
    [return: MarshalAs(UnmanagedType.Bool)]
    public static extern bool IsWindowVisible(IntPtr hWnd);

    [DllImport("user32.dll", SetLastError = true, CharSet = CharSet.Auto)]
    public static extern int GetWindowText(IntPtr hWnd, StringBuilder lpString, int nMaxCount);

    [DllImport("user32.dll", SetLastError = true)]
    public static extern bool SetForegroundWindow(IntPtr hWnd);

    // ShowWindow 命令常量
    public const int SW_HIDE            = 0;
    public const int SW_SHOWNORMAL      = 1;
    public const int SW_SHOWMINIMIZED   = 2;
    public const int SW_SHOWMAXIMIZED   = 3;
    public const int SW_RESTORE         = 9;
}
'@

Add-Type -TypeDefinition $windowApiDefinition -Language CSharp

# 封装：按窗口标题查找窗口句柄
function Find-WindowByTitle {
    param(
        [Parameter(Mandatory)]
        [string]$Title
    )

    $handle = [WindowApi]::FindWindow($null, $Title)
    if ($handle -eq [IntPtr]::Zero) {
        Write-Warning "未找到标题为「$Title」的窗口"
        return $null
    }
    $handle
}

# 封装：获取窗口标题
function Get-WindowTitle {
    param(
        [Parameter(Mandatory)]
        [IntPtr]$Handle
    )

    if (-not [WindowApi]::IsWindow($handle)) {
        Write-Warning "无效的窗口句柄：$handle"
        return
    }

    $sb = New-Object System.Text.StringBuilder(256)
    [WindowApi]::GetWindowText($handle, $sb, $sb.Capacity) | Out-Null
    $sb.ToString()
}

# 封装：控制窗口显示状态
function Set-WindowState {
    param(
        [Parameter(Mandatory)]
        [IntPtr]$Handle,

        [Parameter(Mandatory)]
        [ValidateSet('Hide', 'ShowNormal', 'Minimize', 'Maximize', 'Restore')]
        [string]$State
    )

    $stateMap = @{
        Hide       = [WindowApi]::SW_HIDE
        ShowNormal = [WindowApi]::SW_SHOWNORMAL
        Minimize   = [WindowApi]::SW_SHOWMINIMIZED
        Maximize   = [WindowApi]::SW_SHOWMAXIMIZED
        Restore    = [WindowApi]::SW_RESTORE
    }

    $cmdValue = $stateMap[$State]
    $result = [WindowApi]::ShowWindow($handle, $cmdValue)

    if (-not $result) {
        $err = [System.Runtime.InteropServices.Marshal]::GetLastWin32Error()
        Write-Error "ShowWindow 调用失败，错误码：$err"
        return
    }

    $isVisible = [WindowApi]::IsWindowVisible($handle)
    Write-Host ("窗口状态已设置为：{0}，当前可见性：{1}" -f $State, $isVisible)
}

# 演示：查找记事本窗口并控制其状态
$notepadTitle = "Untitled - Notepad"
$handle = Find-WindowByTitle -Title $notepadTitle

if ($handle) {
    $currentTitle = Get-WindowTitle -Handle $handle
    Write-Host "找到窗口：$currentTitle" -ForegroundColor Cyan
    Write-Host "窗口句柄：$handle"

    # 最小化窗口
    Write-Host "`n--- 最小化窗口 ---"
    Set-WindowState -Handle $handle -State Minimize

    Start-Sleep -Milliseconds 500

    # 恢复窗口
    Write-Host "`n--- 恢复窗口 ---"
    Set-WindowState -Handle $handle -State Restore

    Start-Sleep -Milliseconds 500

    # 最大化窗口
    Write-Host "`n--- 最大化窗口 ---"
    Set-WindowState -Handle $handle -State Maximize

    Start-Sleep -Milliseconds 500

    # 恢复到正常状态
    Write-Host "`n--- 恢复到正常大小 ---"
    Set-WindowState -Handle $handle -State Restore
}
else {
    Write-Host "请先打开记事本（Notepad），然后重新运行此脚本" -ForegroundColor Yellow
    Write-Host "提示：也可以尝试查找其他窗口，如修改 -Title 参数" -ForegroundColor Yellow

    # 列出一些常见窗口标题供参考
    Write-Host "`n你可以尝试以下窗口标题："
    $commonWindows = @("Calculator", "Task Manager", "Windows PowerShell")
    foreach ($win in $commonWindows) {
        $testHandle = [WindowApi]::FindWindow($null, $win)
        $status = if ($testHandle -ne [IntPtr]::Zero) { "存在" } else { "未找到" }
        Write-Host ("  {0} - {1}" -f $win, $status)
    }
}
```

```text
请先打开记事本（Notepad），然后重新运行此脚本
提示：也可以尝试查找其他窗口，如修改 -Title 参数

你可以尝试以下窗口标题：
  Calculator - 未找到
  Task Manager - 存在
  Windows PowerShell - 存在
```

上述代码通过 `FindWindow` 按窗口标题查找句柄，然后使用 `ShowWindow` 配合不同的命令常量（`SW_MINIMIZE`、`SW_MAXIMIZE`、`SW_RESTORE` 等）来控制窗口的显示状态。在实际自动化场景中，这种能力可以用来在执行 UI 测试前确保窗口处于正确状态，或在无人值守任务中隐藏不必要的窗口。

## 注意事项

1. **Add-Type 无法重复定义**：同一个类型名称在一个 PowerShell 会话中只能通过 `Add-Type` 定义一次。如果修改了 API 签名，需要重启 PowerShell 会话才能生效。建议在开发阶段使用不同的类名或重启控制台进行测试。

2. **数据类型映射要准确**：Win32 API 中的 `BOOL` 对应 C# 的 `bool`，`DWORD` 对应 `uint`，`HANDLE` 对应 `IntPtr`，`LPCWSTR` 对应 `string`（带 `CharSet.Auto`）。类型映射错误会导致调用失败甚至进程崩溃，务必查阅 PInvoke.net 获取准确的签名。

3. **始终检查返回值和错误码**：大多数 Win32 API 通过返回值（如 `BOOL` 或 `HANDLE`）指示成功或失败，并通过 `SetLastError = true` 配合 `Marshal.GetLastWin32Error()` 获取详细错误信息。不要忽略返回值检查。

4. **注意 32 位和 64 位兼容性**：在 64 位系统上运行 32 位 PowerShell 时，部分 API 的行为可能不同（如窗口句柄大小为 4 字节而非 8 字节）。建议始终使用 64 位 PowerShell 运行涉及 Win32 API 的脚本，以确保指针类型的一致性。

5. **使用 try/finally 确保资源释放**：Win32 API 中的资源（如剪贴板的打开状态、内存锁定的指针）需要手动释放。一定要用 `try/finally` 块包裹相关调用，确保即使发生异常也能正确清理资源，避免内存泄漏或系统状态异常。

6. **参考官方文档和 PInvoke.net**：Win32 API 数量庞大，参数和常量的含义需要查阅 Windows SDK 文档。PInvoke.net 网站提供了大量现成的 C# 签名定义，可以直接复制使用，省去手动映射的麻烦。在调用不熟悉的 API 之前，务必先在测试环境中验证其行为。
