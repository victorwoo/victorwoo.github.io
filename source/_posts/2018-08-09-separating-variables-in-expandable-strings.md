---
layout: post
date: 2018-08-09 00:00:00
title: "PowerShell 技能连载 - 在可扩展字符串中分隔变量"
description: PowerTip of the Day - Separating Variables in Expandable Strings
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
当使用双引号字符串时，您可以扩展它们当中的变量，类似这样：

```powershell
PS C:\> "Windir: $env:windir"
Windir: C:\Windows
```

然而，没有明显的方法来标记变量的起止位置，所以以下操作将会失败：

```powershell
PS C:\> "$env:windir: this is my Windows folder"
    this is my Windows folder
```

解决方案是使用大括号来标识字符串内变量的起止位置：

```powershell
PS C:\> "${env:windir}: this is my Windows folder"
C:\Windows: this is my Windows folder
```

<!--more-->
本文国际来源：[Separating Variables in Expandable Strings](http://community.idera.com/powershell/powertips/b/tips/posts/separating-variables-in-expandable-strings)
