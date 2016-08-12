layout: post
date: 2015-11-06 12:00:00
title: "PowerShell 技能连载 - 尽可能使用服务端过滤"
description: PowerTip of the Day - Use Server-Side Filtering When Possible
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
当您跨网络获取信息时，请注意只能在最后一步使用客户端技术，例如 `Where-Object`。服务端过滤技术更有效率。

例如，当您试图根据电子邮箱查找用户时，客户端的 `Where-Object` 语句将会将所有 AD 用户推到您的计算机上，并且通过本地的 `Where-Object` 来确认您需要的用户：

    #requires -Version 1 -Modules ActiveDirectory
    
    # inefficient client-side filter
    Get-ADUser -Filter * | Where-Object { $_.mail -ne $null }

如您猜想的那样，当一个 cmdlet 有一个名为 `-Filter` 的参数时，它可以在传送数据到您的机器之前，在服务端过滤需要的元素。然而，`Get-ADUser` 命令的 `-Filter` 参数有的时候工作起来很困难，需要将类似 PowerShell 的语法转换为 Active Directory 所需的 LDAP 查询。

所以更常见的是，在第一处使用 LDAP 查询字符串更自然。这两条语句将会快速地找出所有包含（和不包含）邮箱地址的用户账户：

    #requires -Version 1 -Modules ActiveDirectory
    
    # any user with a mail address
    Get-ADUser -LDAPFilter '(mail=*)'
    
    # any user with NO mail address
    Get-ADUser -LDAPFilter '(!mail=*)'

<!--more-->
本文国际来源：[Use Server-Side Filtering When Possible](http://powershell.com/cs/blogs/tips/archive/2015/11/06/use-server-side-filtering-when-possible.aspx)
