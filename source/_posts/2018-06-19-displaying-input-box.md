---
layout: post
date: 2018-06-19 00:00:00
title: "PowerShell 技能连载 - 显示输入框"
description: PowerTip of the Day - Displaying Input Box
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
如果您想弹出一个快速而粗糙的输入框，提示用户输入数据，您可以通过 Microsoft Visual Basic 并且“借用”它的 InputBox 控件：

```powershell
Add-Type -AssemblyName Microsoft.VisualBasic
$result = [Microsoft.VisualBasic.Interaction]::InputBox("Enter your Name", "Name", $env:username)
$result
```

但是请注意，这种方法有一些局限性：该输入框可能在您的 PowerShell 窗口之下打开，而且在高分辨率屏中，它的缩放可能不正确。

<!--more-->
本文国际来源：[Displaying Input Box](http://community.idera.com/powershell/powertips/b/tips/posts/displaying-input-box)
