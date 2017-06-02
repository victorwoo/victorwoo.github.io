---
layout: post
date: 2017-03-09 00:00:00
title: "PowerShell 技能连载 - 探索对象"
description: PowerTip of the Day - Explore Objects
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
在 PowerShell 中，一切都是用对象描述。以下是一个检查任意对象并将它的成员以文本的方式复制到剪贴板的单行代码：

```powershell
"Hello" | 
  Get-Member |
  Format-Table -AutoSize -Wrap |
  Out-String -Width 150 |
  clip.exe
```

只需要将 "Hello" 替换成任何变量或命令，然后看看复制了什么到剪贴板中。您可以将信息粘贴到文本编辑器或文字处理器中，并将它打印出来或转成 PDF 备用。

<!--more-->
本文国际来源：[Explore Objects](http://community.idera.com/powershell/powertips/b/tips/posts/explore-objects)
