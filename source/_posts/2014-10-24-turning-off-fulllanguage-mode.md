layout: post
date: 2014-10-24 11:00:00
title: "PowerShell 技能连载 - 关闭“完整语言”模式"
description: "PowerTip of the Day - Turning Off “FullLanguage” Mode"
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
_适用于 PowerShell 所有版本_

PowerShell 可以有多种方法作出限制。一种是将语言模式从 `FullLanguage` 改为 `RestrictedLanguage`。这是一种无法撤销的方法，最坏可以关闭并重开 PowerShell：

    $host.Runspace.SessionStateProxy.LanguageMode = 'RestrictedLanguage'

一旦设置成 `RestrictedLanguage`，PowerShell 将只能执行指令。它将再也无法执行对象的方法或存取对象的属性，并且您也无法定义新的函数。

所以 `RestrictedLanguage` 基本上是一个安全的锁，锁定以后 PowerShell 只能执行指令但无法深入到底层的 .NET 或用新创建的函数覆盖现有的命令。

<!--more-->
本文国际来源：[Turning Off “FullLanguage” Mode](http://community.idera.com/powershell/powertips/b/tips/posts/turning-off-fulllanguage-mode)
