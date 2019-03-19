---
layout: post
date: 2015-07-15 11:00:00
title: "PowerShell 技能连载 - 复制 Active Directory 安全设置"
description: PowerTip of the Day - Cloning Active Directory Security Settings
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
当您向一个 AD 对象增加委派权限（例如允许一个用户管理一个组织对象的成员）时，实际上是调用了该 AD 对象的改变安全设置方法。

AD 安全描述符有可能非常复杂。复制 AD 安全信息却非常简单。所以如果您希望将相同的安全设置复制到另一个 AD 对象，您可以从一个对象读取已有的安全设置，然后将它们复制到另一个对象上。

这段脚本演示了如何从一个 OU 读取安全设置，并且将它复制到另一个 OU。这需要随 ActiveDirectory 模块发布的 ActiveDirectory 提供器。这个模块是微软免费的 RSAT 工具的一部分，需事先安装。

    #requires -Version 2 -Modules ActiveDirectory
    Import-Module -Name ActiveDirectory

    # read AD security from NewOU1
    $sd = Get-Acl -Path 'AD:\OU=NewOU1,DC=powershell,DC=local'

    # assign security to NewOU2
    Set-Acl -Path 'AD:\OU=NewOU2,DC=powershell,DC=local' -AclObject $sd

<!--本文国际来源：[Cloning Active Directory Security Settings](http://community.idera.com/powershell/powertips/b/tips/posts/cloning-active-directory-security-settings)-->
