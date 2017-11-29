---
layout: post
date: 2017-11-24 00:00:00
title: "PowerShell 技能连载 - 在 PowerShell 5+ 中读取 .PSD1 文件"
description: PowerTip of the Day - Reading Data from .PSD1 Files in PowerShell 5+
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
在前一个技能中我们介绍了通过 `Import-LocalizedData` 读取存储在 .psd1 文件中的数据。

从 PowerShell 5 开始，有一个新的cmdlet名为 `Import-PowerShellDataFile`。您可以用它安全地从 .psd1 文件中读取数据。类似 `Import-LocalizedData`，这个cmdlet只接受没有活动内容（没有命令和变量）的 .psd1 文件。

以下是您需要的脚本：

```powershell
$path = "$PSScriptRoot\data.psd1"
$infos = Import-PowerShellDataFile -Path $path
```

将数据文件存放在相同文件夹下，将它命名为 data.psd1，然后设为如下内容：

```powershell
@{
    Name = 'Tobias'
    ID = 12
    Path = 'c:\Windows'
}
```

当您运行这段脚本时，它将 .psd1 文件中的数据以哈希表的形式返回。

<!--more-->
本文国际来源：[Reading Data from .PSD1 Files in PowerShell 5+](http://community.idera.com/powershell/powertips/b/tips/posts/reading-data-from-psd1-files-in-powershell-5)
