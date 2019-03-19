---
layout: post
date: 2015-07-23 11:00:00
title: "PowerShell 技能连载 - 查找登录的用户"
description: PowerTip of the Day - Finding Logged On Users
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
在前一个技能里我们介绍了如何查找物理上登录的用户。在这个技能中您将学习到如何列出当前登录到本地系统的所有用户。这包括了通过 RDP 及其它方式连上的用户：

    #requires -Version 1
    function Get-LoggedOnUserSession
    {
        param
        (
            $ComputerName,
            $Credential
        )

        Get-WmiObject -Class Win32_LogonSession @PSBoundParameters |
        ForEach-Object {
            $_.GetRelated('Win32_UserAccount') |
            Select-Object -ExpandProperty Caption
        } |
        Sort-Object -Unique
    }

执行 `Get-LoggedOnUserSession` 命令将得到当前登录到机器上的所有用户。如指定了 `-Credential`（域名\\用户名）参数，可以访问远程机器。

<!--本文国际来源：[Finding Logged On Users](http://community.idera.com/powershell/powertips/b/tips/posts/finding-logged-on-users)-->
