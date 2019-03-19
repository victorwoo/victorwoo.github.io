---
layout: post
date: 2015-04-20 11:00:00
title: "PowerShell 技能连载 - 安全使用 UNC 路径"
description: PowerTip of the Day - Safely Use UNC Paths
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
当您在 PowerShell 中使用 UNC 路径时，您的脚本可能会中断。由于 UNC 路径没有驱动器号，所以 PowerShell 将会在当前目录下查找，并且使用当前路径对应的 PSProvider。

所以如果您的当前目录不是一个文件路径（例如是一个注册表驱动器），那么您的 UNC 路径将会被解释成一个注册表路径。

要安全地使用路径，请一定在 UNC 路径前面加上正确的提供器名称：

    # UNC-Paths have no drive letter
    # so PowerShell uses the current directory instead to find the PSProvider
    # for UNC paths, to be safe, always add the provider name manually
    $exists = Test-Path -Path 'FileSystem::\\server12\fileshare'

    $exists

<!--本文国际来源：[Safely Use UNC Paths](http://community.idera.com/powershell/powertips/b/tips/posts/safely-use-unc-paths)-->
