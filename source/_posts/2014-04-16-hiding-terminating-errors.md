---
layout: post
title: "PowerShell 技能连载 - 屏蔽终止性错误"
date: 2014-04-16 00:00:00
description: PowerTip of the Day - Hiding Terminating Errors
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
有时候，您会注意到虽然已经为 `-ErrorAction` 参数指定了 `"SilentlyContinue"` 值，cmdlet 还是会抛出错误。

`-ErrorAction` 参数只能隐藏**非终止性错误**（原本被 cmdlet 处理的错误）。不被 cmdlet 处理的错误称为“**终止性错误**”。这些错误通常是和安全相关的，并且不能被 `-ErrorAction` 屏蔽。

所以如果您是一个非管理员用户，虽然用 `-ErrorAction` 指定了屏蔽错误，以下调用将会抛出一个异常：

![](/img/2014-04-16-hiding-terminating-errors-001.png)

要屏蔽终止性错误，您必须使用异常处理器：

    try
    {
      Get-EventLog -LogName Security 
    }
    catch
    {} 

<!--本文国际来源：[Hiding Terminating Errors](http://community.idera.com/powershell/powertips/b/tips/posts/hiding-terminating-errors)-->
