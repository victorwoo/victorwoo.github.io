layout: post
date: 2015-06-16 11:00:00
title: "PowerShell 技能连载 - 加载 PowerShell 模块"
description: PowerTip of the Day - Loading PowerShell Modules
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
所有的 cmdlet 都位于模块或是 snap-in 中。要查看当前加载了哪些模块，请使用 `Get-Module` 命令。

在 PowerShell 3.0 或更高版本中，当您运行多数模块中的 cmdlet 时，它们都将被隐式地导入。这种聪明的机制实现了“按需加载”的效果，所以在多数情况下不需要手动加载模块，或是显式地手动加载所有模块。

要关闭自动加载，请使用这行代码：

    $PSModuleAutoLoadingPreference = 'none'

请注意当您这么做的时候，您有责任加载所有需要的模块。

如果您希望加载所有可用的模块，请使用 `Import-Module` 命令。

这将读取您整个系统中所有可用的模块：

    Get-Module -ListAvailable | Import-Module -Verbose

<!--more-->
本文国际来源：[Loading PowerShell Modules](http://community.idera.com/powershell/powertips/b/tips/posts/loading-powershell-modules)
