layout: post
date: 2015-08-03 11:00:00
title: "PowerShell 技能连载 - 查找带动态参数的 cmdlet"
description: PowerTip of the Day - Finding Cmdlets with Dynamic Parameters
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
有些 cmdlet 暴露了动态参数。它们只在特定的环境下可用。例如 `Get-ChildItem` 只在当前的位置是文件系统路径（并且是 PowerShell 3.0 以上版本）时才暴露 `-File` 和 `-Directory` 参数。

要查找所有带动态参数的 cmdlet，请试试这段代码：

    #requires -Version 2
    
    $cmdlets = Get-Command -CommandType Cmdlet
    
    $cmdlets.Count
    
    $loaded = $cmdlets |
    Where-Object { $_.ImplementingType }
    
    $loaded.Count
    
    $dynamic = $loaded |
    Where-Object {
        $cmdlet = New-Object -TypeName $_.ImplementingType.FullName
        $cmdlet -is [System.Management.Automation.IDynamicParameters]
      }
      
    $dynamic.Count
    
    $dynamic | Out-GridView

您将只会获得已加载并且包含动态参数的 cmdlet。

<!--more-->
本文国际来源：[Finding Cmdlets with Dynamic Parameters](http://powershell.com/cs/blogs/tips/archive/2015/08/03/finding-cmdlets-with-dynamic-parameters.aspx)
