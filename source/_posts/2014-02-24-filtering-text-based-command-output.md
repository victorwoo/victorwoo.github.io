layout: post
title: "PowerShell 技能连载 - 过滤命令输出的文本"
date: 2014-02-24 00:00:00
description: PowerTip of the Day - Filtering Text-Based Command Output
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
比较操作符作用于数组时，它们的作用和过滤器相似。所以许多输出多行文本的控制台命令可以使用比较操作符。

以下例子将使用 `netstat.exe` 来获取已连接上的网络连接，然后过滤出连到名字包含“stor”的服务器的连接，最后用 `ipconfig` 来获取当前的 IPv4 地址：

![](/img/2014-02-24-filtering-text-based-command-output-001.png)

这个技巧是将控制台命令用 `@()` 括起来，确保结果为一个数组。

<!--more-->
本文国际来源：[Filtering Text-Based Command Output](http://community.idera.com/powershell/powertips/b/tips/posts/filtering-text-based-command-output)
