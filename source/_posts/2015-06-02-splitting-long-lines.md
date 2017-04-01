layout: post
date: 2015-06-02 11:00:00
title: "PowerShell 技能连载 - 分割超长代码行"
description: PowerTip of the Day - Splitting Long Lines
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
为了提高可读性，您可以将超长的 PowerShell 代码行拆分成多行。

    Get-Service | Where-Object { $_.Status -eq 'Running' }
    
    Get-Service |
      Where-Object { $_.Status -eq 'Running' }

在管道符之后，您可以加入一个换行。您也可以安全地在一个左大括号之后、右大括号之前加入一个换行：

    Get-Service |
      Where-Object {
        $_.Status -eq 'Running'
      }

如果您需要在其它地方换行，那么请在换行之前加入一个反引号：

    Get-Service |
    Where-Object `
    {
      $_.Status -eq 'Running'
    }

<!--more-->
本文国际来源：[Splitting Long Lines](http://community.idera.com/powershell/powertips/b/tips/posts/splitting-long-lines)
