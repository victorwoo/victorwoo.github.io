---
layout: post
date: 2015-04-01 11:00:00
title: "PowerShell 技能连载 - 发现高影响级别 cmdlet"
description: PowerTip of the Day - Discovering High Impact Cmdlets
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
_适用于 PowerShell 所有版本_

cmdlet 可以定义它们的影响力有多大。通常，那些会对系统造成不可恢复影响的 cmdlet 的“影响级别”设置为“高”。

当您运行这样一个 cmdlet 时，PowerShell 将会弹出一个确认对话框，防止您不小心误操作。确认对话框也能防止您在无人值守的情况下运行这些 cmdlet。

要查看 cmdlet 的“影响级别”为多高，可以用这段代码输出该信息：

    Get-Command -CommandType Cmdlet |
      ForEach-Object {
        $type = $_.ImplementingType
        if ($type -ne $null)
        {
          $type.GetCustomAttributes($true) |
          Where-Object { $_.VerbName -ne $null } |
          Select-Object @{Name='Name';
          Expression={'{0}-{1}' -f $_.VerbName, $_.NounName}}, ConfirmImpact
        }
      } |
      Sort-Object ConfirmImpact -Descending

要只查看影响级别为“高”的 cmdlet，只需要加一个过滤器：

    Get-Command -CommandType Cmdlet |
      ForEach-Object {
        $type = $_.ImplementingType
        if ($type -ne $null)
        {
          $type.GetCustomAttributes($true) |
          Where-Object { $_.VerbName -ne $null } |
          Select-Object @{Name='Name';
          Expression={'{0}-{1}' -f $_.VerbName, $_.NounName}}, ConfirmImpact
        }
      } |
      Sort-Object ConfirmImpact -Descending |
      Where-Object { $_.ConfirmImpact -eq 'High' }

要以无人值守的方式运行这些 cmdlet 并且不让自动提示框出现，请加上 `-Confirm:$False` 参数。

<!--本文国际来源：[Discovering High Impact Cmdlets](http://community.idera.com/powershell/powertips/b/tips/posts/discovering-high-impact-cmdlets)-->
