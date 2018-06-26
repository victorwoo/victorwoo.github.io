---
layout: post
date: 2018-06-18 00:00:00
title: "PowerShell 技能连载 - 快速读取文本文件"
description: PowerTip of the Day - Reading Text Files Fast
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
PowerShell 有许多读取文本文件的方法，它们的性能差异很大。请自己确认一下。以下例子演示了不同的实践，并测量执行的时间。请确保例子中的路径实际存在。如果文件不存在，请选择一个大文件来测试。

```powershell
# make sure this file exists, or else
# pick a different text file that is
# very large
$path = 'C:\Windows\Logs\DISM\dism.log'

# slow reading line-by-line
Measure-Command {
  $text = Get-Content -Path $Path 
}

# fast reading entire text as one large string
Measure-Command {
  $text = Get-Content -Path $Path -Raw
}

# fast reading text as string array with one
# array element per line
Measure-Command {
  $text = Get-Content -Path $Path -ReadCount 0
}

# reading entire text with .NET
# no advantage over -Raw
Measure-Command {
  $text = [System.IO.File]::ReadAllText($path)
}
```

<!--more-->
本文国际来源：[Reading Text Files Fast](http://community.idera.com/powershell/powertips/b/tips/posts/reading-text-files-fast-1152612330)
