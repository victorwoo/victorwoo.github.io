layout: post
title: "PowerShell 技能连载 - 使用 break、continue 和 return 语句"
date: 2014-06-26 00:00:00
description: PowerTip of the Day - Using break, continue, and return
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
在 PowerShell 的循环中，有两个特殊的关键字：`break` 和 `continue`。

使用 `continue`，循环继续执行，但是跳过剩下的代码。当您执行 `break` 时，循环提前结束并返回所有的结果。

另外，还有一个关键字 `return`。它将导致立即退出当前的作用域。所以当您在一个函数中执行 `return`，那么该函数将会退出；而如果您在一个脚本中执行 `return`，那么整个脚本将退出。

<!--more-->
本文国际来源：[Using break, continue, and return](http://community.idera.com/powershell/powertips/b/tips/posts/using-break-continue-and-return)
