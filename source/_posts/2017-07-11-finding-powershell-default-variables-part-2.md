---
layout: post
date: 2017-07-11 00:00:00
title: "PowerShell 技能连载 - 查找 PowerShell 缺省变量（第二部分）"
description: PowerTip of the Day - Finding PowerShell Default Variables (Part 2)
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
在前一个技能里我们解释了如何使用独立全新的 PowerShell 实例来获取所有缺省变量。当您仔细查看这些变量，会发现还是丢失了某些变量。

以下是一个稍微修改过的版本，名为 `Get-BuiltInPSVariable`，能返回所有保留的 PowerShell 变量：

```powershell
function Get-BuiltInPSVariable($Name='*')
{
  # create a new PowerShell
  $ps = [PowerShell]::Create()
  # get all variables inside of it
  $null = $ps.AddScript('$null=$host;Get-Variable') 
  $ps.Invoke() |
    Where-Object Name -like $Name
  # dispose new PowerShell
  $ps.Runspace.Close()
  $ps.Dispose()
}
```

为了不遗漏任何一个内置的 PowerShell 变量，这个做法使用了 `AddScript()` 方法来代替 `AddCommand()`，来执行多于一条命令。有一些 PowerShell 变量要等待至少一条命令执行之后才创建。

您现在可以获取所有的 PowerShell 内置变量，或搜索指定的变量：

```powershell     
PS> Get-BuiltInPSVariable -Name *pref*

Name                           Value                                                                         
----                           -----                                                                         
ConfirmPreference              High                                                                          
DebugPreference                SilentlyContinue                                                              
ErrorActionPreference          Continue                                                                      
InformationPreference          SilentlyContinue                                                              
ProgressPreference             Continue                                                                      
VerbosePreference              SilentlyContinue                                                              
WarningPreference              Continue                                                                      
WhatIfPreference               False
```

<!--more-->
本文国际来源：[Finding PowerShell Default Variables (Part 2)](http://community.idera.com/powershell/powertips/b/tips/posts/finding-powershell-default-variables-part-2)
