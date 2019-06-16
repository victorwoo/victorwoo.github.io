---
layout: post
date: 2019-06-04 00:00:00
title: "PowerShell 技能连载 - 同步使用 FileSystemWatcher "
description: PowerTip of the Day - Using FileSystemWatcher Synchronously
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
以下是一段演示 PowerShell 如何用 `FileSystemWatcher` 同步地监控一个包含字文件夹的文件夹变化：

```powershell
$folder = $home
$filter = '*'


try
{
    $fsw = New-Object System.IO.FileSystemWatcher $folder, $filter -ErrorAction Stop
}
catch [System.ArgumentException]
{
    Write-Warning "Oops: $_"
    return
}

$fsw.IncludeSubdirectories = $true
$fsw.NotifyFilter = [IO.NotifyFilters]'FileName, LastWrite'

do
{
    $result = $fsw.WaitForChanged([System.IO.WatcherChangeTypes]::All, 1000)
    if ($result.TimedOut) { continue }

    $result
    Write-Host "Change in $($result.Name) - $($result.ChangeType)"

} while ($true)
```

这段代码将会监测用户配置文件中 `FileName` 和 `LastWrite` 属性的变化。

一个同步的监听器会导致 PowerShell 处于忙碌状态，所以要退出监听，需要设置一个 1000ms 的超时值，PowerShell 将会将控制权返回给你，而如果您没有按下 `CTRL`+`C`，则循环会继续。

请注意同步的 `FileSystemWatcher` 可能会错过改变：正好当 `WaitForChange()` 返回时一个文件发生改变，那么在下一次调用 `WaitForChange()` 之前的文件变化都会丢失。

如果不想错过任何变化，请使用异步的方法（请见下一个技能）。

<!--本文国际来源：[Using FileSystemWatcher Synchronously](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/using-filesystemwatcher-synchronously)-->

