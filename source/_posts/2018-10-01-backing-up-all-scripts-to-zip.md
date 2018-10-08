---
layout: post
date: 2018-10-01 00:00:00
title: "PowerShell 技能连载 - 将所有脚本备份到 ZIP 中"
description: PowerTip of the Day - Backing Up All Scripts to ZIP
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
PowerShell 5 终于支持 ZIP 文件了，所以如果您希望备份所有 PowerShell 脚本到一个 ZIP 文件中，以下是一个单行代码：

```powershell
Get-ChildItem -Path $Home -Filter *.ps1 -Recurse -ErrorAction SilentlyContinue |
  Compress-Archive -DestinationPath "$home\desktop\backupAllScripts.zip" -CompressionLevel Optimal
```

请注意在 Windows 10 上，所有文件写入 ZIP 之前都需要通过反病毒引擎。如果您的反病毒引擎检测到一段可疑的代码，可能会产生异常，并且不会生成 ZIP 文件。

<!--more-->
本文国际来源：[Backing Up All Scripts to ZIP](http://community.idera.com/powershell/powertips/b/tips/posts/backing-up-all-scripts-to-zip)
