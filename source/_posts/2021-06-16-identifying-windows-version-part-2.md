---
layout: post
date: 2021-06-16 00:00:00
title: "PowerShell 技能连载 - 检测 Windows 版本（第 2 部分）"
description: PowerTip of the Day - Identifying Windows Version (Part 2)
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
在之前的技能中，我们报告了 `ReleaseId` 已弃用，无法再用于正确识别当前的 Windows 10 版本。相反，应该使用 `DisplayVersion`：

```powershell
PS> (Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion').DisplayVersion
20H2
```

但是，`DisplayVersion` 也不是确定当前 Windows 10 版本的可靠方法，因为其最初的目的是使外壳能够向用户报告当前版本。它也可能在未来发生变化。

识别当前 Windows 10 版本的唯一受支持的安全方法是使用名为 `AnalyticsInfo` 的操作系统类。不过用起来比较复杂，因为该类在 WinRT 中异步运行。PowerShell 7 (pwsh.exe) 无法访问此类。但是，内置的 Windows PowerShell (powershell.exe) 可以创建包装器并返回信息：

```powershell
# load WinRT and runtime types
[System.Void][Windows.System.Profile.AnalyticsInfo,Windows.System.Profile,ContentType=WindowsRuntime]
Add-Type -AssemblyName 'System.Runtime.WindowsRuntime'

# define call and information to query
[Collections.Generic.List[System.String]]$names = 'DeviceFamily',
                                                    'OSVersionFull',
                                                    'FlightRing',
                                                    'App',
                                                    'AppVer'

$task = [Windows.System.Profile.AnalyticsInfo]::GetSystemPropertiesAsync($names)

# use reflection to find method definition
$definition = [System.WindowsRuntimeSystemExtensions].GetMethods().Where{
    $_.Name -eq 'AsTask' -and
    $_.GetParameters().Count -eq 1 -and
    $_.GetParameters()[0].ParameterType.Name -eq 'IAsyncOperation`1'
}

# create generic method
$Method = $definition.MakeGenericMethod( [System.Collections.Generic.IReadOnlyDictionary[System.String,System.String]] )

# call async method and wait for completion
$task = $Method.Invoke.Invoke($null, $task)
$null = $task.Wait(-1)

# emit output
$task.Result
```

结果类似于：

    Key           Value
    ---           -----
    OSVersionFull 10.0.19042.985.amd64fre.vb_release.191206-1406
    FlightRing    Retail
    App           powershell_ise.exe
    AppVer        10.0.19041.1
    DeviceFamily  Windows.Desktop

`OSVersionFull` 返回有关当前 Windows 版本的完整详细信息。

请注意，上面示例中调用的方法可以检索更多详细信息。`$names` 列出要查询的属性名称。不幸的是，没有办法发现可用的属性名称，因为第三方方可能会添加无穷无尽的附加信息。本示例中使用的五个属性是唯一保证的属性。

<!--本文国际来源：[Identifying Windows Version (Part 2)](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/identifying-windows-version-part-2)-->

