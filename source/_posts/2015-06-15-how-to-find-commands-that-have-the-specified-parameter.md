layout: post
date: 2015-06-15 11:00:00
title: "PowerShell 技能连载 - 如何查找包含指定参数的命令"
description: PowerTip of the Day - How to find Commands that have the Specified Parameter
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
`Get-Command` 是当您需要查找某个命令来完成一件事情时的主要工具。

您可以这样搜索动词和/或名词：

    # find all cmdlets/functions that stop things
    Get-Command -Verb Stop
    # find all cmdlets/functions that affect services
    Get-Command -Noun Service

从 PowerShell 3.0 开始，`Get-Command` 还可以根据一个给定的参数查找 cmdlet 或函数：

    # new in PS3 and better
    # find all cmdlets/functions with a -ComputerName parameter
    Get-Command -ParameterName ComputerName

请注意 `Get-Command` 是在已加载的 cmdlet/函数中搜索。请确保在搜索前已导入了所需的模块。

<!--more-->
本文国际来源：[How to find Commands that have the Specified Parameter](http://community.idera.com/powershell/powertips/b/tips/posts/how-to-find-commands-that-have-the-specified-parameter)
