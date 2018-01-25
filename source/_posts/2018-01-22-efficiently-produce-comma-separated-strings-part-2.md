---
layout: post
date: 2018-01-22 00:00:00
title: "PowerShell 技能连载 - 快速创建逗号分隔的字符串（第 2 部分）"
description: PowerTip of the Day - Efficiently Produce Comma-Separated Strings (Part 2)
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
在前一个技能中我们演示了如何用 PowerShell 命令模式方便地创建引号包围的字符串列表。这可以很方便地创建代码，节省很多打字工作。

以下是一个在日常 PowerShell 编码工作中有用的函数：

```powershell
function s+ { "'$($args -join "','")'" | Set-ClipBoard }
```

下一次您在代码中需要一个引号包围的字符串列表时，只需要键入：

```powershell
    PS> s+ start stop pause end whatever

    PS> 'start','stop','pause','end','whatever'
    start
    stop
    pause
    end
    whatever

    PS>
```

执行完之后，引号包围的字符串就会存在您的剪贴板中，接下来您可以将它们粘贴到任何需要的地方。

<!--more-->
本文国际来源：[Efficiently Produce Comma-Separated Strings (Part 2)](http://community.idera.com/powershell/powertips/b/tips/posts/efficiently-produce-comma-separated-strings-part-2)
