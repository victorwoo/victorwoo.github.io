---
layout: post
date: 2018-12-17 00:00:00
title: "PowerShell 技能连载 - 正确使用 FileSystemWatcher（第 1 部分）"
description: PowerTip of the Day - Using FileSystemWatcher Correctly (Part 1)
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
- translation
---
`FileSystemWatcher` 可以监控一个文件或文件夹的改变。当有新文件复制到文件夹，或有文件删除或改变，您的 PowerShell 代码会立刻收到通知。

时常会见到这样的同步监控示例代码：

```powershell
    # make sure you adjust this
    $PathToMonitor = "c:\test"
    
    
    $FileSystemWatcher = New-Object System.IO.FileSystemWatcher
    $FileSystemWatcher.Path  = $PathToMonitor
    $FileSystemWatcher.IncludeSubdirectories = $true
    
    Write-Host "Monitoring content of $PathToMonitor"
    explorer $PathToMonitor
    while ($true) {
      $Change = $FileSystemWatcher.WaitForChanged('All', 1000)
      if ($Change.TimedOut -eq $false)
      {
          # get information about the changes detected
          Write-Host "Change detected:"
          $Change | Out-Default
    
          # uncomment this to see the issue
          #Start-Sleep -Seconds 5
      }
      else
      {
          Write-Host "." -NoNewline
      }
    }
```

这个示例可以正常工作。当您向监控的文件夹增加文件，或者作出改变时，将会监测到改变的类型。您可以容易地得到该信息并采取操作。例如，对于 IT 部门，人们可以向一个投放文件夹投放文件和说明，您的脚本可以自动处理这些文件。

然而，这种方式又一个副作用：当监测到一个变更时，控制权返回到您的脚本，这样它可以处理这些变更。如果这时候另一个文件发生改变，而您的脚本并不是正在等待事件，那么将错过这个事件。您可以很容易地自我检查：

向变更发生时的执行代码中添加一些耗时的语句，例如 "`Start-Sleep -Seconds 5`"，然后对文件夹做多个改变。如您所见，检测到了第一个变更，但是 PowerShell 会持续五分钟忙碌，而其它改变事件都丢失了。

就在明天的技能中我们将确保您的 `FileSystemWatcher` 不会跳过任何变更！

<!--more-->
本文国际来源：[Using FileSystemWatcher Correctly (Part 1)](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/using-filesystemwatcher-correctly-part-1)
