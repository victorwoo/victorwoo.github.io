---
layout: post
date: 2019-06-05 00:00:00
title: "PowerShell 技能连载 - 异步使用 FileSystemWatcher"
description: PowerTip of the Day - Using FileSystemWatcher Asynchronously
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
在前一个技能中我们介绍了 `FileSystemWatcher` 对象以及如何用它监控文件夹的变化。不过，为了不错过所有变化，需要使用异步的方法，类似这样：

```powershell
$FileSystemWatcher = New-Object System.IO.FileSystemWatcher
$FileSystemWatcher.Path  = "$home\Desktop"
$FileSystemWatcher.IncludeSubdirectories = $true
$FileSystemWatcher.EnableRaisingEvents = $true
  Register-ObjectEvent -InputObject $FileSystemWatcher -SourceIdentifier Monitoring1  -EventName Created  -Action {

  $Object  = "{0} was  {1} at {2}" -f $Event.SourceEventArgs.FullPath,
  $Event.SourceEventArgs.ChangeType,
  $Event.TimeGenerated

  Write-Host $Object -ForegroundColor Green
}
```

在这个例子中，当检测到任何一个变化事件，就会触发一个事件，并且 `FileSystemWatcher` 继续监听。由 PowerShell 负责响应这个事件，并且它使用一个事件处理器来响应。事件处理器是在后台执行的。

如果不想使用后台事件管理器，请运行这行代码：

```powershell
Get-EventSubscriber -SourceIdentifier Monitoring1 | Unregister-Event
```

请注意每个支持的变更类型会发出不同的事件。在这个例子中，我们关注 "`Created`" 事件，当创建新文件或新文件夹的时候会发出这个事件。要响应其它变化类型，请添加更多的事件处理器。这将返回所有支持的事件名称：

```powershell
PS C:\> $FileSystemWatcher | Get-Member -MemberType *Event


   TypeName: System.IO.FileSystemWatcher

Name     MemberType Definition
----     ---------- ----------
Changed  Event      System.IO.FileSystemEventHandler Changed(System.Object, System.IO.FileSystemEventArgs)
Created  Event      System.IO.FileSystemEventHandler Created(System.Object, System.IO.FileSystemEventArgs)
Deleted  Event      System.IO.FileSystemEventHandler Deleted(System.Object, System.IO.FileSystemEventArgs)
Disposed Event      System.EventHandler Disposed(System.Object, System.EventArgs)
Error    Event      System.IO.ErrorEventHandler Error(System.Object, System.IO.ErrorEventArgs)
Renamed  Event      System.IO.RenamedEventHandler Renamed(System.Object, System.IO.RenamedEventArgs)
```

<!--本文国际来源：[Using FileSystemWatcher Asynchronously](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/using-filesystemwatcher-asynchronously)-->

