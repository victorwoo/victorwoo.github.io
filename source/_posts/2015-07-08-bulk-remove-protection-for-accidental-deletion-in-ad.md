layout: post
date: 2015-07-08 11:00:00
title: "PowerShell 技能连载 - 批量删除 AD 的防意外删除保护"
description: PowerTip of the Day - Bulk-Remove Protection for Accidental Deletion in AD
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
缺省情况下，AD 对象是受保护防止意外删除的。要移除一个指定的范围内所有对象（例如某个机构之下）的这种保护，请试试这段代码：

    #requires -Version 1 -Modules ActiveDirectory
    
    Get-ADObject -Filter * -SearchBase 'OU=TestOU,DC=Vision,DC=local"' |
    ForEach-Object -Process {
        Set-ADObject -ProtectedFromAccidentalDeletion $false -Identity $_
    }

注意：这段代码需要免费的 RSAT 工具所带的 ActiveDirectory 模块。

<!--more-->
本文国际来源：[Bulk-Remove Protection for Accidental Deletion in AD](http://community.idera.com/powershell/powertips/b/tips/posts/bulk-remove-protection-for-accidental-deletion-in-ad)
