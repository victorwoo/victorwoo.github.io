---
layout: post
date: 2017-11-20 00:00:00
title: "PowerShell 技能连载 - 临时禁用 PSReadLine 模块"
description: PowerTip of the Day - Temporarily Disabling PSReadLine Module
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
从 PowerShell 5 开始，PowerShell 控制台支持彩色文本特性，以及一系列由 PSReadLine 模块提供的新特性。

如果您从更早的 PowerShell 版本升级到 PowerShell 5，而丢失了彩色文本功能，那么您可以从 PSGallery 下载和安装 PSReadLine 模块：

```powershell
PS C:\> Install-Module -Name PSReadLine -Scope CurrentUser
```

类似地，如果您的 PS5+ 控制台和以前的行为不一致，例如不会执行粘贴入的代码块，那么您可以临时禁止该模块：

```powershell
# disable PS5+ console handler temporarily
Remove-Module psreadline

# re-enable PS5+ console handler again
Import-Module psreadline
```

<!--more-->
本文国际来源：[Temporarily Disabling PSReadLine Module](http://community.idera.com/powershell/powertips/b/tips/posts/temporarily-disabling-psreadline-module)
