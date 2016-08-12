layout: post
date: 2015-10-20 11:00:00
title: "PowerShell 技能连载 - 查找已加载的程序集"
description: 'PowerTip of the Day - Finding Loaded Assemblies '
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
要列出一个 PowerShell 会话中加载的所有 .NET 程序集，请试试这段代码：

    [System.AppDomain]::CurrentDomain.GetAssemblies() |
      Where-Object Location |
      Sort-Object -Property FullName |
      Select-Object -Property Name, Location, Version |
      Out-GridView

列出和对比已加载的程序集可以有助于对比 PowerShell 会话，并且检查区别。多数时间，区别在于已加载的模块，所以如果缺少了程序集，您可能需要先加载一个 PowerShell 模块来使用它们。

或者，您可以使用 `Add-Type` 命令根据名字或文件地址手动加载程序集。

<!--more-->
本文国际来源：[Finding Loaded Assemblies ](http://powershell.com/cs/blogs/tips/archive/2015/10/20/finding-loaded-assemblies.aspx)
