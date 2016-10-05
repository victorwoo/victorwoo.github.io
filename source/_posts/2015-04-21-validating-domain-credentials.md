layout: post
date: 2015-04-21 11:00:00
title: "PowerShell 技能连载 - 验证域凭据"
description: PowerTip of the Day - Validating Domain Credentials
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
要通过当前的域验证凭据（用户名和密码），您可以使用这段代码：

    #requires -Version 1
    
    $username = 'test\user'
    $password = 'topSecret'
    
    $root = "LDAP://" + ([ADSI]"").distinguishedName
    $Domain = New-Object System.DirectoryServices.DirectoryEntry($root, $username, $password)
    
    if ($Domain.Name -eq $null)
    {
      Write-Warning 'Credentials incorrect, or computer is not a domain member.'
    }
    else
    {
      Write-Host 'Credentials accepted.'
    }
    

总的来说，该脚本首先确认当前域名，然后用提供的凭据来获取根元素。

如果该操作成功完成，说明凭据时合法的。如果失败，说明凭据是无效的，或者该计算机根本没有加入域。

<!--more-->
本文国际来源：[Validating Domain Credentials](http://community.idera.com/powershell/powertips/b/tips/posts/validating-domain-credentials)
