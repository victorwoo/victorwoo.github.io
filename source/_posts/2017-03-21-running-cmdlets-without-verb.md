---
layout: post
date: 2017-03-21 00:00:00
title: "PowerShell 技能连载 - 不带动词运行 Cmdlet"
description: PowerTip of the Day - Running Cmdlets without Verb
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
这是从 PowerShell 1.0 开始就具有的一个特性：调用动词为 "get" 的 cmdlet 可以省略动词。所以调用 "`Get-Service`" 时您可以仅执行 "`Service`"调用 "`Get-Date`" 时可以仅执行 "`Date`"。

以下不是别名，甚至 PowerShell 引擎并不知道为什么它能工作。请试试这些代码：

```powershell
    PS> Date
    PS> Get-Command Date
```

使用这个快捷方式的前提是没有冲突的命令或语法元素。这也是为什么您可以运行 "`Get-Process`"，但不能运行 "`Process`" 的原因："`Process`" 是 PowerShell 语言中的一个保留关键字。

<!--本文国际来源：[Running Cmdlets without Verb](http://community.idera.com/powershell/powertips/b/tips/posts/running-cmdlets-without-verb)-->
