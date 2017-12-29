---
layout: post
date: 2017-12-28 00:00:00
title: "PowerShell 技能连载 - 在剪贴板中附加内容"
description: PowerTip of the Day - Appending the Clipboard
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
PowerShell 5 带来了新的将文本复制到剪贴板，以及取出剪贴板文本的 cmdlet：`Set-Clipboard` 和 `Get-Clipboard`。

`Set-Clipboard` 也支持 `-Append` 参数，它可以向剪贴板尾部附加文本。这可以成为一种新奇且有用的记录脚本行为的方法：

```powershell
Set-ClipBoard "Starting at $(Get-Date)"
1..30 |
  ForEach-Object {
    Set-ClipBoard -Append "Iteration $_"
    $wait = Get-Random -Minimum 1 -Maximum 5
    Set-ClipBoard -Append "Waiting $wait seconds"
    Start-Sleep -Seconds $wait
    "Processing $_"

  }
```

这个脚本片段使用 `Set-Clipboard` 将信息粘贴至剪贴板中。脚本运行后，您可以将剪贴板内容粘贴至剪贴板来查看脚本输出的日志。

<!--more-->
本文国际来源：[Appending the Clipboard](http://community.idera.com/powershell/powertips/b/tips/posts/appending-the-clipboard)
