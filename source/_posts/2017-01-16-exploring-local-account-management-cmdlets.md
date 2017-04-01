layout: post
date: 2017-01-16 00:00:00
title: "PowerShell 技能连载 - 探索本地账户管理 cmdlet"
description: PowerTip of the Day - Exploring Local Account Management Cmdlets
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
PowerShell 5.1（随着 Windows 10 和 Server 2016 发布）现在原生支持管理本地账户。在前一个技能中您学习了如何使用 `Get-LocalUser` 命令。

要探索本地账户管理的其它 cmdlet，以下是如何识别暴露 `Get-LocalUser` 命令的模块的方法，然后列出该模块的其它 cmdlet：

```powershell
#requires -Modules Microsoft.PowerShell.LocalAccounts


# find module that defines this cmdlet
$module = Get-Command -Name Get-LocalUser | Select-Object -ExpandProperty Source

# list all cmdlets defined by this module
Get-Command -Module $module
```

最终，列出所有新的管理 cmdlet：


```powershell
CommandType Name                    Version Source                            
----------- ----                    ------- ------                            
Cmdlet      Add-LocalGroupMember    1.0.0.0 Microsoft.PowerShell.LocalAccounts
Cmdlet      Disable-LocalUser       1.0.0.0 Microsoft.PowerShell.LocalAccounts
Cmdlet      Enable-LocalUser        1.0.0.0 Microsoft.PowerShell.LocalAccounts
Cmdlet      Get-LocalGroup          1.0.0.0 Microsoft.PowerShell.LocalAccounts
Cmdlet      Get-LocalGroupMember    1.0.0.0 Microsoft.PowerShell.LocalAccounts
Cmdlet      Get-LocalUser           1.0.0.0 Microsoft.PowerShell.LocalAccounts
Cmdlet      New-LocalGroup          1.0.0.0 Microsoft.PowerShell.LocalAccounts
Cmdlet      New-LocalUser           1.0.0.0 Microsoft.PowerShell.LocalAccounts
Cmdlet      Remove-LocalGroup       1.0.0.0 Microsoft.PowerShell.LocalAccounts
Cmdlet      Remove-LocalGroupMember 1.0.0.0 Microsoft.PowerShell.LocalAccounts
Cmdlet      Remove-LocalUser        1.0.0.0 Microsoft.PowerShell.LocalAccounts
Cmdlet      Rename-LocalGroup       1.0.0.0 Microsoft.PowerShell.LocalAccounts
Cmdlet      Rename-LocalUser        1.0.0.0 Microsoft.PowerShell.LocalAccounts
Cmdlet      Set-LocalGroup          1.0.0.0 Microsoft.PowerShell.LocalAccounts
Cmdlet      Set-LocalUser           1.0.0.0 Microsoft.PowerShell.LocalAccounts
```

<!--more-->
本文国际来源：[Exploring Local Account Management Cmdlets](http://community.idera.com/powershell/powertips/b/tips/posts/exploring-local-account-management-cmdlets)
