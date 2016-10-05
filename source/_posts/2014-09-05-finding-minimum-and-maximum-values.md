layout: post
date: 2014-09-05 11:00:00
title: "PowerShell 技能连载 - 查找最大值和最小值"
description: PowerTip of the Day - Finding Minimum and Maximum Values
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
_适用于 PowerShell 所有版本_

要查找一系列数据中的最小值和最大值，请使用 `Measure-Object` 命令：

    $list = 1,4,3,1,3,12,990
    
    $result = $list | Measure-Object -Minimum -Maximum
    $result.Minimum
    $result.Maximum

它对输入的任何数据类型都有效。以下是稍作修改的代码，可以返回 Windows 文件夹中最旧和最新的文件：

    $list = Get-ChildItem -Path C:\windows 
    
    $result = $list | Measure-Object -Property LastWriteTime -Minimum -Maximum
    $result.Minimum
    $result.Maximum
    

如果您的输入数据有多个属性，只需要加上 `-Property` 参数，并选择您想检测的属性即可。

<!--more-->
本文国际来源：[Finding Minimum and Maximum Values](http://community.idera.com/powershell/powertips/b/tips/posts/finding-minimum-and-maximum-values)
