layout: post
date: 2015-02-03 12:00:00
title: "PowerShell 技能连载 - 管理终端服务设置"
description: PowerTip of the Day - Managing Terminal Service Settings
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
_需要 _ActiveDirectory 模块_

有些时候您也许希望在一个 AD 账户中直接存取终端服务相关的属性。以下是一些演示如何实现该功能的示例代码：

    $Identity = 'SomeUserName'
    
    $distinguishedName = (Get-ADUser -Identity $Identity -Properties distinguishedName).distinguishedName
    $ADUser = [ADSI]"LDAP://$distinguishedName"
    
    $TSProfilePath = $ADUser.psbase.InvokeGet('terminalservicesprofilepath')
    $TSHomeDir = $ADUser.psbase.InvokeGet('TerminalServicesHomeDirectory')
    $TSHomeDrive = $ADUser.psbase.InvokeGet('TerminalServicesHomeDrive')
    $TSAllowLogOn = $ADUser.psbase.InvokeGet('allowLogon')

<!--more-->
本文国际来源：[Managing Terminal Service Settings](http://community.idera.com/powershell/powertips/b/tips/posts/managing-terminal-service-settings)
