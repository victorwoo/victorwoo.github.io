---
layout: post
date: 2020-10-09 00:00:00
title: "PowerShell 技能连载 - 使用在线帮助（第 2 部分）"
description: PowerTip of the Day - Using Online Help (Part 2)
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
在上一个技能中，我们提到许多 PowerShell 用户更喜欢在线帮助，而不是本地下载的帮助。要默认使用联机帮助文档，请在新的 PowerShell 控制台中尝试以下操作：

```powershell
# by default, -? opens LOCAL help
PS> dir -?

NAME
    Get-ChildItem

SYNOPSIS
    Gets the items and child items in one or more specified locations.


SYNTAX
...


# with this line you tell PowerShell to use the ONLINE help by default
PS> $PSDefaultParameterValues.Add("Get-Help:Online",$true)

# now, whenever you use -?, the ONLINE help opens in a nicely formatted browser window
PS> dir -?
```

使用 `$PSDefaultParameterValues.Add("Get-Help:Online",$true)` 命令告诉 PowerShell，`Get-Help` 命令应始终自动使用 `-Online` 参数，因此现在您始终可以获得基于浏览器的帮助。

尽管在大多数情况下这很好，但是联机帮助无法自动显示主题。如果需要显示有关主题的信息，只需使用 `Get-Help` 或带有 `-ShowWindow` 参数的帮助以显示本地帮助：

```powershell
# this fails when help defaults to show ONLINE help
PS> help about_for
Get-Help : The online version of this Help topic cannot be displayed because the Internet address (URI) of the Help topic is not specified in the command code or in the help file for the command.

# the -ShowWindow parameter always shows local help in an extra window
PS C:\> help about_for -ShowWindow
```

<!--本文国际来源：[Using Online Help (Part 2)](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/using-online-help-part-2)-->

