layout: post
date: 2015-05-08 11:00:00
title: "PowerShell 技能连载 - 跳出管道"
description: PowerTip of the Day - Aborting the Pipeline
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
如果您事先知道期望从管道中得到多少个对象，您可以用 `Select-Object` 命令来停止上游的 cmdlet 执行。这样可以节约很多时间。

这个例子试着在 Windows 文件夹中查找 explorer.exe 的第一个实例。由于 `Select-Object` 语句的作用，一旦找到第一个实例，管道就结束了。如果没有这个语句，即便已经查找到所需的数据，`Get-ChildItem` 也会不断地递归扫描 Windows 文件夹。

    #requires -Version 3
    
    
    Get-ChildItem -Path c:\Windows -Recurse -Filter explorer.exe -ErrorAction SilentlyContinue |
    Select-Object -First 1

请注意只有在 PowerShell 3.0 以上版本中，`Select-Object` 才具有中断上游 cmdlet 的能力。在早期的版本中，您仍然会获得前 x 个元素，但是上游的 cmdlet 会得不到“已经获得足够的数据”通知而一直持续执行。

<!--more-->
本文国际来源：[Aborting the Pipeline](http://community.idera.com/powershell/powertips/b/tips/posts/aborting-the-pipeline)
