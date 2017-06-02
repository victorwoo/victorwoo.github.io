---
layout: post
title: "PowerShell 技能连载 - 显示 Path 环境变量"
date: 2013-12-17 00:00:00
description: PowerTip of the Day - Displaying Path Environment Variables
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
当您启动一个程序时，`$env:Path` 环境变量列出了 Windows 搜索路径中的所有目录。类似地，`$env:PSModulePath` 列出了 PowerShell 搜索 PowerShell 模块（包括它的自动加载模块）的所有目录。

这些变量包含了以分号分隔的信息。所以使用 `-split` 操作符分隔并显示它们：

![](/img/2013-12-17-displaying-path-environment-variables-001.png)

顺便说一下，第三行（在 Program Files 中的）是在 PowerShell 4.0 中才加入的。

<!--more-->
本文国际来源：[Displaying Path Environment Variables](http://community.idera.com/powershell/powertips/b/tips/posts/displaying-path-environment-variables)
