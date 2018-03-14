---
layout: post
date: 2018-03-08 00:00:00
title: "PowerShell 技能连载 - 将 Windows 错误 ID 转换为友好的文字"
description: PowerTip of the Day - Converting a Windows Error ID into Friendly Text
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
当您在 PowerShell 中调用一个底层的函数时，您可能经常会得到一个数值型的返回值。如果这个返回值是来自一个 Windows API 函数，那么有一个非常简单的方法将它转换成有意义的文本：

例如，当一个 API 函数因为权限不足导致失败，它的返回值是 5。让我们将它翻译为一个有意义的文本：

```powershell
PS> New-Object -TypeName ComponentModel.Win32Exception(5)
Access is denied
```

在 PowerShell 5 中，您还可以使用这种语法：

```powershell
PS> [ComponentModel.Win32Exception]::new(5)
Access is denied
```

请试试这个例子：

```powershell
1..200 | ForEach-Object { '{0} = {1}' -f $_, (New-Object -TypeName ComponentModel.Win32Exception($_)) }
```

<!--more-->
本文国际来源：[Converting a Windows Error ID into Friendly Text](http://community.idera.com/powershell/powertips/b/tips/posts/converting-a-windows-error-id-into-friendly-text)
