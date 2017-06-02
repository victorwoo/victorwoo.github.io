---
layout: post
title: "PowerShell 技能连载 - 将 Tick 转换为真实的日期"
date: 2014-04-10 00:00:00
description: PowerTip of the Day - Converting Ticks into Real Date
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
Active Directory 内部使用 tick （从 1601 年起的百纳秒数）来表示日期和时间。在以前，要将这个大数字转换为人类可读的日期和时间是很困难的。以下是一个很简单的办法：

    [DateTime]::FromFileTime(635312826377934727) 

类似地，要将一个日期转换为 tick 数，使用以下方法：

![](/img/2014-04-10-converting-ticks-into-real-date-001.png)

<!--more-->
本文国际来源：[Converting Ticks into Real Date](http://community.idera.com/powershell/powertips/b/tips/posts/converting-ticks-into-real-date)
