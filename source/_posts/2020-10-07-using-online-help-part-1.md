---
layout: post
date: 2020-10-07 00:00:00
title: "PowerShell 技能连载 - 使用在线帮助（第 1 部分）"
description: PowerTip of the Day - Using Online Help (Part 1)
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
PowerShell 支持本地帮助文件和联机资源。请看区别：

```powershell
# outputs help in same console window
# level of detail depends on whether local help was
# downloaded using Update-Help
PS C:\> help -Name Get-Process

NAME
    Get-Process

SYNOPSIS
    Gets the processes that are running on the local computer or a remote computer.


SYNTAX
    Get-Process [[-Name] <String[]>] [-ComputerName <String[]>] [-FileVersionInfo] [-Module] []
    ...

# opens help in separate browser window
PS> help -Name Get-Process -Online
```

默认情况下，"`help`"（`Get-Help` 的别名）将帮助信息输出到 PowerShell 的输出窗口中。指定 `-Online` 开关参数时，浏览器会在单独的窗口中显示帮助文件。在线帮助文​​档采用了较好的格式，并且可以通过“复制”按钮轻松地复制和粘贴示例代码。并且由于联机文档是直接从 Microsoft 加载的，因此它们始终是最新的，因此无需通过 `Update-Help` 下载帮助。

这就是为什么许多用户喜欢在线帮助资源而不是本地帮助的原因。

线上还有许多有用的“关于”主题。关于主题涵盖了 PowerShell 语言和引擎的各个方面。您会在此处找到所有有关主题的很好的分类：https://docs.microsoft.com/zh-cn/powershell/module/microsoft.powershell.core/about/about

<!--本文国际来源：[Using Online Help (Part 1)](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/using-online-help-part-1)-->

