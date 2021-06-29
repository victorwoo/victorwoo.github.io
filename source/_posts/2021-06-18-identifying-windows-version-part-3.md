---
layout: post
date: 2021-06-18 00:00:00
title: "PowerShell 技能连载 - 检测 Windows 版本（第 3 部分）"
description: PowerTip of the Day - Identifying Windows Version (Part 3)
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
在上一个技巧中，我们说明访问 WinRT 类 `AnalyticsInfo` 似乎是读取当前 Windows 10 版本的唯一受支持方式。与使用上一个示例中的异步方法不同，为了仅获取当前的 Windows 10 版本，这里有一个更简单的方法：

```powershell
# get raw Windows version
[int64]$rawVersion =
  [Windows.System.Profile.AnalyticsInfo,Windows.System.Profile,ContentType=WindowsRuntime].
  GetMember('get_VersionInfo').Invoke( $Null, $Null ).DeviceFamilyVersion

# decode bits to version bytes
$major = ( $rawVersion -band 0xFFFF000000000000l ) -shr 48
$minor = ( $rawVersion -band 0x0000FFFF00000000l ) -shr 32
$build = ( $rawVersion -band 0x00000000FFFF0000l ) -shr 16
$revision =   $rawVersion -band 0x000000000000FFFFl

# compose version
$winver = [System.Version]::new($major, $minor, $build, $revision)
$winver
```

请注意，PowerShell 7 (pwsh.exe) 无法访问此 API。该代码需要 Windows PowerShell (powershell.exe)。

<!--本文国际来源：[Identifying Windows Version (Part 3)](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/identifying-windows-version-part-3)-->
