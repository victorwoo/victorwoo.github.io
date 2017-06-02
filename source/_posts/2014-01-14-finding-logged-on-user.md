---
layout: post
title: "PowerShell 技能连载 - 查询已登录的用户"
date: 2014-01-14 00:00:00
description: PowerTip of the Day - Finding Logged-On User
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
有一个十分有用的控制台程序叫做 quser.exe 可以告诉您哪些用户登录到了一台机器上。该可执行程序返回的是纯文本，但通过一点点正则表达式，该文本可以转换成 CSV 并导入 PowerShell。

以下代码以对象的形式返回所有当前登录到您机器上的用户信息：

	(quser) -replace 's{2,}', ',' | ConvertFrom-Csv

![](/img/2014-01-14-finding-logged-on-user-001.png)

<!--more-->
本文国际来源：[Finding Logged-On User](http://community.idera.com/powershell/powertips/b/tips/posts/finding-logged-on-user)
