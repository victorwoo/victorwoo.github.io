layout: post
date: 2016-11-14 00:00:00
title: "PowerShell 技能连载 - 本地帐户的内置支持"
description: PowerTip of the Day - Built-In Support for Local Accounts
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
从 PowerShell 5.1 开始，终于内置支持了本地用户账户。PowerShell 5.1 现在支持 Windows 10 和 Windows Server 2016：

    PS C:\> Get-Command -Module *LocalAccounts | Select-Object -ExpandProperty Name

    Add-LocalGroupMember
    Disable-LocalUser
    Enable-LocalUser
    Get-LocalGroup
    Get-LocalGroupMember
    Get-LocalUser
    New-LocalGroup
    New-LocalUser
    Remove-LocalGroup
    Remove-LocalGroupMember
    Remove-LocalUser
    Rename-LocalGroup
    Rename-LocalUser
    Set-LocalGroup
    Set-LocalUser

<!--more-->
本文国际来源：[Built-In Support for Local Accounts](http://community.idera.com/powershell/powertips/b/tips/posts/built-in-support-for-local-accounts)
