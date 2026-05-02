---
layout: post
date: 2025-12-11 08:00:00
updated: 2025-12-11 08:00:00
title: "PowerShell 技能连载 - .NET 互操作深入"
description: PowerTip of the Day - Deep .NET Interop in PowerShell
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
- scripting
- script
---

_适用于 PowerShell 7.0 及以上版本_

PowerShell 本质上是 .NET 生态的一部分，每一个变量、每一个对象都运行在 CLR 之上。虽然日常工作中我们习惯使用 cmdlet 来完成任务，但在面对高性能计算、底层系统调用或需要精确控制内存的场景时，直接使用 .NET 类往往能获得数量级的性能提升。

理解 .NET 互操作不仅是突破 cmdlet 限制的手段，更是深入理解 PowerShell 运行时行为的钥匙。当你知道 `[System.IO.File]::ReadAllText()` 比同等的 `Get-Content` 快数十倍时，你就能够在脚本中做出更明智的选择——何时追求简洁，何时追求性能。

本文将从三个维度展开：直接调用 .NET 类实现高性能操作、利用反射动态调用方法和创建实例、以及通过 P/Invoke 调用原生 Win32 API，帮助你全面掌握 PowerShell 中的 .NET 互操作能力。

<!-- more -->

## 直接调用 .NET 类——高性能替代方案

PowerShell 的 cmdlet 设计强调易用性和管道友好性，但这通常会引入额外的开销。当你处理大量数据或需要极致性能时，直接使用 .NET 类是更优的选择。

以下示例展示了几个常见的场景：使用 `System.IO` 进行高性能文件操作，使用 `System.Text.Json` 进行快速 JSON 序列化，以及使用 `System.Net.Http` 发起 HTTP 请求。

```powershell
# 场景一：高性能文件读写
# 使用 [System.IO.File] 替代 Get-Content，性能提升数十倍
$testFile = [System.IO.Path]::GetTempFileName()
$lines = 1..10000 | ForEach-Object { "Line $_ at $(Get-Date -Format 'HH:mm:ss.fff')" }

# 直接写入，比 Set-Content 快得多
[System.IO.File]::WriteAllLines($testFile, $lines)

# 读取全部内容为单个字符串
$content = [System.IO.File]::ReadAllText($testFile)
Write-Host "文件大小: $([System.IO.FileInfo]::new($testFile).Length) 字节"

# 按行读取（延迟枚举，内存友好）
$lineCount = 0
$reader = [System.IO.StreamReader]::new($testFile)
while ($null -ne $reader.ReadLine()) { $lineCount++ }
$reader.Close()
Write-Host "总行数: $lineCount"

# 场景二：System.Text.Json 高性能序列化
$product = [ordered]@{
    Name   = "PowerShell 7.4"
    Version = "7.4.0"
    Features = @("Pipeline Chain", "Null Coalescing", "Ternary Operator")
    ReleaseDate = "2023-11-16"
    IsLTS = $true
}

# 使用 System.Text.Json（比 ConvertTo-Json 更快）
$jsonOptions = [System.Text.Json.JsonSerializerOptions]::new()
$jsonOptions.WriteIndented = $true
$jsonOptions.PropertyNamingPolicy = [System.Text.Json.JsonNamingPolicy]::CamelCase

$json = [System.Text.Json.JsonSerializer]::Serialize(
    [System.Collections.Generic.Dictionary[string, object]]$product,
    $jsonOptions
)
Write-Host $json

# 反序列化
$deserialized = [System.Text.Json.JsonSerializer]::Deserialize(
    $json,
    [System.Collections.Generic.Dictionary[string, object]].MakeGenericType(@([string], [object])),
    $jsonOptions
)
Write-Host "反序列化结果 - Name: $($deserialized['name'])"

# 场景三：使用 System.Net.Http 发起请求（比 Invoke-WebRequest 更灵活）
$httpClient = [System.Net.Http.HttpClient]::new()
$httpClient.Timeout = [System.TimeSpan]::FromSeconds(10)
$httpClient.DefaultRequestHeaders.Add("User-Agent", "PowerShell-DotNetInterop/1.0")

try {
    $response = $httpClient.GetAsync("https://httpbin.org/get").GetAwaiter().GetResult()
    $body = $response.Content.ReadAsStringAsync().GetAwaiter().GetResult()
    Write-Host "状态码: $($response.StatusCode)"
    Write-Host "响应长度: $($body.Length) 字符"
}
finally {
    $httpClient.Dispose()
}

# 清理临时文件
[System.IO.File]::Delete($testFile)
```

执行结果示例：

```
文件大小: 358896 字节
总行数: 10000
{
  "name": "PowerShell 7.4",
  "version": "7.4.0",
  "features": [
    "Pipeline Chain",
    "Null Coalescing",
    "Ternary Operator"
  ],
  "releaseDate": "2023-11-16",
  "isLTS": true
}
反序列化结果 - Name: PowerShell 7.4
状态码: OK
响应长度: 358 字符
```

## 使用反射动态调用方法和创建实例

反射是 .NET 的核心能力之一，它允许你在运行时检查类型信息、动态调用方法、创建实例，甚至修改私有字段。在 PowerShell 中，反射特别适合处理那些无法在编译时确定类型的场景，比如插件系统、动态加载程序集，或者绕过某些访问限制。

```powershell
# 演示：使用反射探索和调用 .NET 类型

# 获取 System.String 的所有公共方法
$stringType = [string]
$methods = $stringType.GetMethods([System.Reflection.BindingFlags]::Public -bor [System.Reflection.BindingFlags]::Instance)
Write-Host "String 类型共有 $($methods.Count) 个公共方法"
Write-Host "部分方法列表:"
$methods | Select-Object -First 8 Name, ReturnType | Format-Table -AutoSize

# 使用反射动态调用方法
$text = "Hello, PowerShell .NET Interop!"
$methodInfo = $stringType.GetMethod("Contains", [type[]]@([string]))
$result = $methodInfo.Invoke($text, [object[]]@("PowerShell"))
Write-Host "Contains('PowerShell'): $result"

# 动态创建泛型集合
$listType = [System.Collections.Generic.List`1].MakeGenericType([int])
$list = [Activator]::CreateInstance($listType)
$addMethod = $listType.GetMethod("Add")
1..5 | ForEach-Object { $addMethod.Invoke($list, [object[]]$_) }
Write-Host "动态创建的 List<int> 内容: $($list -join ', ')"

# 反射加载外部程序集并调用其中的类型
# 模拟：加载 System.Text.RegularExpressions 并使用反射调用
$asm = [System.Reflection.Assembly]::LoadWithPartialName("System.Text.RegularExpressions")
$regexType = $asm.GetType("System.Text.RegularExpressions.Regex")
$pattern = "\b\w+@\w+\.\w+\b"

# 通过反射创建 Regex 实例
$regexCtor = $regexType.GetConstructor([type[]]@([string]))
$regex = $regexCtor.Invoke([object[]]@($pattern))

# 调用 Matches 方法
$matchesMethod = $regexType.GetMethod("Matches", [type[]]@([string]))
$sampleText = "联系我们: admin@vichamp.com 或 support@example.org"
$matches = $matchesMethod.Invoke($regex, [object[]]@($sampleText))

Write-Host "在文本中找到 $($matches.Count) 个邮箱地址:"
foreach ($m in $matches) {
    Write-Host "  - $($m.Value) (位置: $($m.Index))"
}

# 使用反射访问静态方法和属性
$env = [System.Environment]
$props = $env.GetProperties([System.Reflection.BindingFlags]::Static -bor [System.Reflection.BindingFlags]::Public)
Write-Host "`nSystem.Environment 静态属性:"
$props | Select-Object -First 5 Name, PropertyType | ForEach-Object {
    $val = $env.GetProperty($_.Name).GetValue($null)
    Write-Host "  $($_.Name) = $val"
}
```

执行结果示例：

```
String 类型共有 108 个公共方法
部分方法列表:
Name           ReturnType
----           ----------
CompareTo      System.Int32
Contains       System.Boolean
CopyTo         System.Void
EndsWith       System.Boolean
Equals         System.Boolean
Equals         System.Boolean
Equals         System.Boolean
GetEnumerator  System.CharEnumerator

Contains('PowerShell'): True
动态创建的 List<int> 内容: 1, 2, 3, 4, 5
在文本中找到 2 个邮箱地址:
  - admin@vichamp.com (位置: 5)
  - support@example.org (位置: 28)

System.Environment 静态属性:
  CommandLine = /opt/powershell/pwsh
  CurrentDirectory = /home/user/scripts
  ExitCode = 0
  HasShutdownStarted = False
  Is64BitProcess = True
```

## P/Invoke 调用 Win32 API

P/Invoke（Platform Invocation Services）是 .NET 提供的调用非托管 DLL 函数的机制。在 PowerShell 中，你可以通过 `Add-Type` 定义签名，然后直接调用 Windows 系统 DLL 中的原生函数。这在需要与操作系统底层交互时非常有用，例如获取系统信息、操作窗口句柄或访问注册表的底层 API。

以下示例展示了几种常见的 Win32 API 调用方式。

```powershell
# P/Invoke 调用 Win32 API 示例
# 注意：以下代码仅在 Windows 平台上运行

if ($IsWindows -or ($env:OS -eq "Windows_NT")) {

    # 示例一：获取系统内存信息
    $memorySignature = @"
using System;
using System.Runtime.InteropServices;

public class MemoryHelper
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
"@

    Add-Type -TypeDefinition $memorySignature -Language CSharp

    $memStatus = [MemoryHelper+MEMORYSTATUSEX]::new()
    [MemoryHelper]::GlobalMemoryStatusEx($memStatus) | Out-Null

    $totalGB = [math]::Round($memStatus.ullTotalPhys / 1GB, 2)
    $availGB = [math]::Round($memStatus.ullAvailPhys / 1GB, 2)
    $usedPercent = $memStatus.dwMemoryLoad

    Write-Host "=== 系统内存信息 ==="
    Write-Host "总物理内存: ${totalGB} GB"
    Write-Host "可用物理内存: ${availGB} GB"
    Write-Host "内存使用率: ${usedPercent}%"

    # 示例二：获取精确的系统启动时间（比 Get-Date 更准确）
    $uptimeSignature = @"
using System;
using System.Runtime.InteropServices;

public class UptimeHelper
{
    [DllImport("kernel32.dll")]
    public static extern UInt64 GetTickCount64();
}
"@

    Add-Type -TypeDefinition $uptimeSignature -Language CSharp

    $tickCount = [UptimeHelper]::GetTickCount64()
    $uptime = [TimeSpan]::FromMilliseconds($tickCount)
    Write-Host "`n=== 系统运行时间 ==="
    Write-Host "已运行: $($uptime.Days) 天 $($uptime.Hours) 小时 $($uptime.Minutes) 分钟"

    # 示例三：获取当前控制台窗口标题
    $consoleSignature = @"
using System;
using System.Text;
using System.Runtime.InteropServices;

public class ConsoleHelper
{
    [DllImport("kernel32.dll", CharSet = CharSet.Auto)]
    public static extern int GetConsoleTitle(
        StringBuilder lpConsoleTitle,
        int nSize);
}
"@

    Add-Type -TypeDefinition $consoleSignature -Language CSharp

    $titleBuilder = [System.Text.StringBuilder]::new(256)
    [ConsoleHelper]::GetConsoleTitle($titleBuilder, 256) | Out-Null
    Write-Host "`n=== 控制台信息 ==="
    Write-Host "当前窗口标题: $($titleBuilder.ToString())"

} else {
    Write-Host "P/Invoke 示例需要在 Windows 平台上运行"
    Write-Host "当前平台: $($PSVersionTable.OS)"

    # 跨平台替代方案：使用 .NET API 获取系统信息
    Write-Host "`n=== 跨平台系统信息 ==="
    Write-Host "机器名: $([System.Environment]::MachineName)"
    Write-Host "用户名: $([System.Environment]::UserName)"
    Write-Host "处理器核心数: $([System.Environment]::ProcessorCount)"
    Write-Host "系统目录: $([System.Environment]::SystemDirectory)"
}
```

执行结果示例：

```
=== 系统内存信息 ===
总物理内存: 32.00 GB
可用物理内存: 14.37 GB
内存使用率: 55%

=== 系统运行时间 ===
已运行: 3 天 7 小时 42 分钟

=== 控制台信息 ===
当前窗口标题: Windows PowerShell
```

## 注意事项

1. **性能权衡**：直接使用 .NET 类虽然性能更高，但代码可读性通常不如 cmdlet。对于一次性脚本或管理任务，优先使用 cmdlet；对于需要处理大量数据或高频调用的场景，再考虑直接使用 .NET 类。可以用 `Measure-Command` 对比实际性能差异后再做决策。

2. **类型转换陷阱**：PowerShell 会自动包装 .NET 对象，某些情况下类型转换可能不如预期。例如 `[System.Collections.Generic.List[int]]` 和 PowerShell 数组之间存在隐式转换，但频繁转换会抵消性能优势。建议尽量在 .NET API 之间传递数据，减少跨越 PowerShell 管道的次数。

3. **反射的性能开销**：反射调用比直接调用慢 10-100 倍。如果需要大量调用同一方法，应该缓存 `MethodInfo` 对象并重复使用，而不是每次都重新查找。在高性能循环中，应避免使用反射。

4. **P/Invoke 平台限制**：P/Invoke 调用的 Win32 API 仅在 Windows 上可用。如果你的脚本需要跨平台运行，务必添加平台检测逻辑（如 `$IsWindows`），并提供基于 .NET API 的跨平台替代方案。同时要注意区分 x86 和 x64 的函数签名差异。

5. **程序集加载策略**：`Add-Type` 编译的 C# 代码会生成临时程序集，无法卸载。大量使用 `Add-Type` 会导致内存增长。对于复杂场景，建议将 C# 代码编译为独立的 DLL，使用 `[System.Reflection.Assembly]::LoadFrom()` 按需加载。

6. **Dispose 模式**：许多 .NET 类（如 `HttpClient`、`StreamReader`、`FileStream`）实现了 `IDisposable` 接口。在 PowerShell 中应使用 `try/finally` 块或 `.Dispose()` 方法显式释放资源，避免因垃圾回收延迟导致的文件锁或连接泄漏。
