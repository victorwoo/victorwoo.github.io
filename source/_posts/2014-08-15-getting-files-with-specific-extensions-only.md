layout: post
date: 2014-08-15 11:00:00
title: "PowerShell 技能连载 - 获取指定扩展名的文件"
description: PowerTip of the Day - Getting Files with Specific Extensions Only
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
_适用于 PowerShell 所有版本_

当您使用 `Get-ChildItem` 来获取一个文件列表时，您可能会注意到 `-Filter` 参数有时候会导致返回比你预期的更多的文件。

以下是一个例子。这段代码并不只是返回“.ps1”扩展名的文件，而也会返回“.ps1xml”扩展名的文件：

    Get-ChildItem -Path C:\windows -Recurse -ErrorAction SilentlyContinue -Filter *.ps1

要限制只返回您需要的扩展名的文件，请用一个 cmdlet 来过滤结果：

    Get-ChildItem -Path C:\windows -Recurse -ErrorAction SilentlyContinue -Filter *.ps1 |
      Where-Object { $_.Extension -eq '.ps1' }

这将只返回您指定的扩展名的文件。

<!--more-->
本文国际来源：[Getting Files with Specific Extensions Only](http://community.idera.com/powershell/powertips/b/tips/posts/getting-files-with-specific-extensions-only)
