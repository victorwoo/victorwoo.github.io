layout: post
date: 2015-01-19 12:00:00
title: "PowerShell 技能连载 - 远程更新组策略"
description: PowerTip of the Day - Remotely Updating Group Policy
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
_适用于 Windows 8.1 或 Server 2012 R2_

要更新远程计算机上的组策略设置，请使用 `Invoke-GPUpdate`，并且传入希望更新设置的计算机名。

`Invoke-GPUpdate` 在远程计算机上创建“`gpupdate`”计划任务。您可以使用 `–RandomDelayInMinutes` 指定一个 0 至 44640 分钟（31 天）之间的值。该 cmdlet 将使用一个随机的时间因子来避免网络阻塞。

<!--more-->
本文国际来源：[Remotely Updating Group Policy](http://community.idera.com/powershell/powertips/b/tips/posts/remotely-updating-group-policy)
