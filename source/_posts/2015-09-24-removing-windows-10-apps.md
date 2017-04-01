layout: post
date: 2015-09-24 11:00:00
title: "PowerShell 技能连载 - 移除 Windows 10 应用"
description: PowerTip of the Day - Removing Windows 10 Apps
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
Windows 10 预装了一系列应用程序。幸运的是，您可以用 PowerShell 来移除您不想要的程序。当然，需要管理员权限。

要查看安装了哪些应用程序，请运行这段代码：

    Get-AppxPackage -User $env:USERNAME

这将列出所有用您自己的用户账户安装的应用程序。要移除应用程序，请使用 `PackageFullName`，并且将它传给 `Remove-AppxPackage` 命令。请在更改之前备份您的系统，而且风险自负。多数应用程序并不是必须的。

<!--more-->
本文国际来源：[Removing Windows 10 Apps](http://community.idera.com/powershell/powertips/b/tips/posts/removing-windows-10-apps)
