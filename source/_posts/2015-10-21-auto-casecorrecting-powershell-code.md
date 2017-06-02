---
layout: post
date: 2015-10-21 11:00:00
title: "PowerShell 技能连载 - 自动修正 PowerShell 代码的大小写"
description: PowerTip of the Day - Auto-CaseCorrecting PowerShell Code
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
当您编写 PowerShell 脚本时，可能常常没有使用正确的大小写，或只使用部分参数名，或使用别名而不是 cmdlet 名称。这些技术上都是可行的，因为 PowerShell 命令是大小写不敏感的，参数名可以省略，并且别名也是一种合法的命令类型。

然而，当使用正确的的大小写、完整的参数名称，以及 cmdlet 名字而不是别名时，脚本的可读性会更好。

在 PowerShell ISE 中，要纠正这些东西，只需要将光标放置在命令名或参数名处，然后按下 `TAB` 键。Tab 展开功能将会读取原有的代码并将它替换成大小写正确的、名字完整的版本。

<!--more-->
本文国际来源：[Auto-CaseCorrecting PowerShell Code](http://community.idera.com/powershell/powertips/b/tips/posts/auto-casecorrecting-powershell-code)
