---
layout: post
date: 2015-12-23 12:00:00
title: "PowerShell 技能连载 - 获取操作系统清单"
description: PowerTip of the Day - Get List of Operating Systems
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
如果您的老板需要一份您 AD 中所有计算机的操作系统清单，这也许是个好办法：

    #requires -Version 1 -Modules ActiveDirectory
    
    $max = 100
    
    $os = Get-ADComputer -Filter * -Properties OperatingSystem -ResultPageSize $max |
    Group-Object -Property OperatingSystem -NoElement |
    Select-object -ExpandProperty Name |
    ForEach-Object { '"{0}"' -f $_ }
    
    $list = $os -join ','
    $list
    # copy list to clipboard
    $list | clip

该脚本将从您的 AD 中获取计算机账户并将它们根据操作系统分组，然后将它整理成一个清单。请注意使用 `PageSize` 因为在一个大型的组织中获取所有计算机信息可能会花费很长时间。

<!--more-->
本文国际来源：[Get List of Operating Systems](http://community.idera.com/powershell/powertips/b/tips/posts/get-list-of-operating-systems)
