---
layout: post
title: "PowerShell 技能连载 - 在 ISE 中重设 PowerShell 宿主"
date: 2013-10-15 00:00:00
description: PowerTip of the Day - Resetting PowerShell Host in ISE
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
想象一下您在 ISE 编辑器中长时间地编写一个脚本。当您开发的时候，您也许定义了变量、创建了函数、加载了对象，等等。

要确保您的脚本能像所希望的那样运行，您最终需要一个干净的测试环境。

获得一个干净的 PowerShell 并且移除所有变量和函数的最简单办法如下：

在 ISE 编辑器中，选择 文件 > 新建 PowerShell 选项卡。这实际上将创建一个新的 PowerShell 选项卡，以及一个全新的 PowerShell 宿主。这将确保没有任何不希望存在的旧变量和函数存在。
<!--more-->

本文国际来源：[Resetting PowerShell Host in ISE](http://community.idera.com/powershell/powertips/b/tips/posts/resetting-powershell-host-in-ise)
