---
layout: post
date: 2017-05-05 00:00:00
title: "PowerShell 技能连载 - 批量打印 Word 文档"
description: PowerTip of the Day - Bulk Printing Word Documents
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
这行代码将在您的配置文件中查找所有 Word 文档：

```powershell
Get-ChildItem -Path $home -Filter *.doc* -Recurse 
```

If you’d like, you can easily print them all. Here is how:
如果需要，可以将它们全部打印出来。以下是具体方法：

```powershell
Get-ChildItem -Path $home -Filter *.doc* -Recurse |
  ForEach-Object {
    Start-Process -FilePath $_.FullName -Verb Print -Wait
  }
```

它最重要的部分是 `-Wait` 参数：如果缺少了它，PowerShell 将会同时启动多个 Word 的实例，并行打印所有文档。这将耗尽您系统的资源。使用 `-Wait` 参数以后，PowerShell 将等待前一个 Word 打印完之后再启动下一个实例。

<!--more-->
本文国际来源：[Bulk Printing Word Documents](http://community.idera.com/powershell/powertips/b/tips/posts/bulk-printing-word-documents)
