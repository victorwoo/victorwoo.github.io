---
layout: post
date: 2018-08-31 00:00:00
title: "PowerShell 技能连载 - 探索 PowerShell 模块"
description: PowerTip of the Day - Exploring PowerShell Modules
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
大多数 cmdlet 和函数是 PowerShell 模块的一部分。如果您希望探索这些命令究竟是从哪儿来的，以下是一个简单的实践。

```powershell
# replace the command name with any PowerShell command name
# you'd like to explore
$Name = "Get-Printer"
$ModuleName = (Get-Command -Name $Name -CommandType Function, Cmdlet).Source

if ('' -eq $ModuleName)
{
    Write-Warning "$Name was defined in memory, no module available."
    return
} 

Write-Warning "$Name resides in $ModuleName module"

$module = Get-Module -Name $ModuleName -ListAvailable
explorer $module.ModuleBase
```

只需要将 `$name` 改为您希望探索的任何 PowerShell cmdlet 名称即可。如果该命令存在于一个 PowerShell 模块中，该模块将打开一个 Windows 资源管理器，您可以在其中检查它的内容。

<!--本文国际来源：[Exploring PowerShell Modules](http://community.idera.com/powershell/powertips/b/tips/posts/exploring-powershell-modules)-->
