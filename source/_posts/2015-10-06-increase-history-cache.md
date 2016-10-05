layout: post
date: 2015-10-06 11:00:00
title: "PowerShell 技能连载 - 增加历史缓存"
description: PowerTip of the Day - Increase History Cache
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
当您在 PowerShell 会话中工作一段时间以后，命令历史可能十分有用。每个会话存储了您输入的所有命令，您可以按上下键浏览已输入的命令。

您甚至可以这样搜索历史缓存：

    PS C:\> #obje

键入一个注释符（# 号），然后跟上您所能回忆起的命令关键字，然后按下 `TAB` 键，每按一次 `TAB` 将会显示命令历史中匹配的一条命令（如果没有匹配成功，将不会显示）。

要限制命令历史的大小，请使用 `$MaximumHistoryCount` 变量。缺省值是 4096。

    PS C:\> $MaximumHistoryCount
    4096
    
    PS C:\> $MaximumHistoryCount = 32KB-1
    
    PS C:\> $MaximumHistoryCount
    32767
    
    PS C:\>

历史缓存最大允许的容量是 32KB-1。

<!--more-->
本文国际来源：[Increase History Cache](http://community.idera.com/powershell/powertips/b/tips/posts/increase-history-cache)
