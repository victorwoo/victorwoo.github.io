layout: post
date: 2015-04-03 11:00:00
title: "PowerShell 技能连载 - 查找 Exchange 邮箱"
description: PowerTip of the Day - Finding Exchange Mailboxes
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
_适用于 Microsoft Exchange 2013_

要查看邮箱的个数，只需要使用 Exchange cmdlet 并且用 `Measure-Object` 来统计结果：

    Get-Mailbox –ResultSize Unlimited | 
      Measure-Object |
      Select-Object -ExpandProperty Count

类似地，要查看所有共享的邮箱，使用这段代码：

    Get-Mailbox –ResultSize Unlimited -RecipientTypeDetails SharedMailbox | 
      Measure-Object |
      Select-Object -ExpandProperty Count

若要只查看用户邮箱，需要稍微调整一下：

    Get-Mailbox –ResultSize Unlimited -RecipientTypeDetails UserMailbox | 
      Measure-Object |
      Select-Object -ExpandProperty Count

<!--more-->
本文国际来源：[Finding Exchange Mailboxes](http://community.idera.com/powershell/powertips/b/tips/posts/finding-exchange-mailboxes)
