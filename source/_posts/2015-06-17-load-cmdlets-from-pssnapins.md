layout: post
date: 2015-06-17 11:00:00
title: "PowerShell 技能连载 - 从 PSSnapin 中加载 cmdlet"
description: PowerTip of the Day - Load Cmdlets from PSSnapins
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
近期多数 cmdlet 都是包装在模块中。模块是从 PowerShell 2.0 开始引入的概念。它们的主要好处是可以复制粘贴部署（不需要安装）以及模块自动加载（当您需要时，PowerShell 将自动加载模块）。

有一些 cmdlet 还是用 PowerShell snap-in (PSSnapin) 的方式包装，而不是采用模块的方式包装。PSSnapin 是从 PowerShell 1.0 就开始引入的。PSSnapin 需要安装才能使用。而且由于它们是注册在 `HKEY_LOCAL_MACHINE` 中，所以它们安装时往往需要管理员权限。

要列出所有可用的 PSSnapin，请运行这行代码：

    Get-PSSnapin -Registered

与模块相对，PSSnapin 需要先手动加载，才能使用其中的 cmdlet。这行代码将会加载所有可用的 PSSnapin：

    Get-PSSnapin -Registered | Add-PSSnapin -Verbose

<!--more-->
本文国际来源：[Load Cmdlets from PSSnapins](http://community.idera.com/powershell/powertips/b/tips/posts/load-cmdlets-from-pssnapins)
