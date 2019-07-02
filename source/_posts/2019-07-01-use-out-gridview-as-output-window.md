---
layout: post
date: 2019-07-01 00:00:00
title: "PowerShell 技能连载 - 用 Out-GridView 做为输出窗口"
description: PowerTip of the Day - Use Out-GridView as Output Window
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
通常，`Out-GridView` 打开一个窗口并且显示所有通过管道传输到该 cmdlet 的内容：

```powershell
PS C:\> Get-Service | Out-GridView
```

然而，通过一点技巧，`Out-GridView` 就会变得更强大。您可以随时将信息通过管道传输到相同的输出窗口。

First, get yourself an instance of Out-GridView that thinks it is running in a pipeline:
首先，获取一个 `Out-GridView` 的实例，然后认为它在一个管道中运行：

```powershell
$pipeline = { Out-GridView }.GetSteppablePipeline()
$pipeline.Begin($true)
```

现在，您可以通过调用 "`Process`" 来输出任何信息。每次调用 `Process()` 都好比将一个元素通过管道传给 cmdlet：

```powershell
$pipeline.Process('Hello this is awesome!')
Start-Sleep -Seconds 4
$pipeline.Process('You can output any time...')
```

当操作完成时，调用 `End()` 结束管道：

```powershell
$pipeline.End()
```

通过这种方式，您可以将信息记录到网格视图中，或者将其用作向用户显示结果的通用输出窗口。

<!--本文国际来源：[Use Out-GridView as Output Window](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/use-out-gridview-as-output-window)-->

