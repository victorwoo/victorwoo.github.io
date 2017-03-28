layout: post
title: "PowerShell 技能连载 - 阻止非管理员权限运行脚本"
date: 2014-05-29 00:00:00
description: PowerTip of the Day - Blocking Administrator Scripts
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
如果您明确知道您的脚本需要管理员权限，那么您必须在脚本的头部加上这行代码：

    #requires -runasadministrator

这行代码确保脚本只能在调用者用后本地管理员权限的情况下运行。这行代码不仅会试图提升脚本权限，而且会确保脚本不会启动后运行一半失败。

<!--more-->
本文国际来源：[Blocking Administrator Scripts](http://community.idera.com/powershell/powertips/b/tips/posts/blocking-administrator-scripts)
