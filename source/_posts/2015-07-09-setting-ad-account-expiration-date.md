layout: post
date: 2015-07-09 04:00:00
title: "PowerShell 技能连载 - 设置 AD 账号的过期时间"
description: PowerTip of the Day - Setting AD Account Expiration Date
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
要安全地使用临时的 AD 账号，例如给客户或是顾问使用，请记得设置一个失效日期。

以下示例代码演示了如何设置今天起 20 之后过期：

    #requires -Version 1 -Modules ActiveDirectory
    # SAMAccount name
    $user = 'user12'
    
    # days when to expire
    $Days = 20
    
    # expiration date is today plus the number of days
    $expirationDate = (Get-Date).AddDays($Days)
    
    Set-ADUser -Identity $user -AccountExpirationDate $expirationDate

请注意这段代码需要随 RSAT 免费工具发布的 Active Directory 模块。

如果您的计算机并没有连接到 AD，但是您拥有一个合法的 AD 账号，您可以用这种方法手动连接到 AD：

    #requires -Version 1 -Modules ActiveDirectory
    
    # Name or IP of DC
    $ServerName = '10.10.12.110'
    # Logon credentials
    $Credential = Get-Credential
    
    
    # SAMAccount name
    $user = 'user12'
    
    # days when to expire
    $Days = 20
    
    # expiration date is today plus the number of days
    $expirationDate = (Get-Date).AddDays($Days)
    
    Set-ADUser -Identity $user -AccountExpirationDate $expirationDate -Server $ServerName -Credential $Credential

<!--more-->
本文国际来源：[Setting AD Account Expiration Date](http://community.idera.com/powershell/powertips/b/tips/posts/setting-ad-account-expiration-date)
