---
layout: post
date: 2014-07-23 11:00:00
title: "PowerShell 技能连载 - 别名有可能带来风险"
description: PowerTip of the Day - Aliases Can Be Dangerous
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
_适用于所有 PowerShell 版本_

在 PowerShell 中执行命令时，别名享有最高的优先权，所以如果遇到了有歧义的命令，PowerShell 将会优先执行别名命令。

这样可能很危险：如果您允许别人更改您的 PowerShell 环境，并且私下添加了您不知道的别名，那么您的脚本执行起来的效果可能完全不同。

Here is a simple call that adds the alias Get-ChildItem and lets it point to ping.exe:
以下是一个简单的例子，创建了一个名为 `Get-ChildItem` 的别名，并指向 `ping.exe`：

    Set-Alias -Name Get-ChildItem -Value ping

这将导致一切都改变了：`Get-ChildItem` 不再列出文件夹内容了，而是变为 `ping` 的行为。甚至，所有的别名（例如 `dir` 和 `ls`）现在都指向 `ping`。我们假想一下如果别名指向了 `format.exe`，那么您的脚本会做什么？

<!--本文国际来源：[Aliases Can Be Dangerous](http://community.idera.com/powershell/powertips/b/tips/posts/aliases-can-be-dangerous)-->
