---
layout: post
date: 2019-03-14 00:00:00
title: "PowerShell 技能连载 - 检查 Cmdlet 可用性和脚本兼容性（第 3 部分）"
description: PowerTip of the Day - Checking Cmdlet Availability and Script Compatibility (Part 3)
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
并不是所有的 PowerShell cmdlet 都随着 PowerShell 发行。许多 cmdlet 是随着第三方模块发布。当安装某些软件时会同时安装这些模块，或者需要使用特定的 Windows 版本。

在之前的部分中我们创建了一个函数，它能够获取某个脚本中的所有外部命令。只需要再做一些额外努力，这就可以变成一个有用的兼容性报告：来自某个模块的所有 cmdlet，或者随着 PowerShell 发行的所有以 "Microsoft.PowerShell" 开头的模块。任何其它模块都属于具体的 Windows 版本或第三方扩展。

检查这个函数：

```powershell
function Get-ExternalCommand
{
    param
    (
        [Parameter(Mandatory)][string]
        $Path
    )
    function Get-ContainedCommand
    {
        param
        (
            [Parameter(Mandatory)][string]
            $Path,

            [string][ValidateSet('FunctionDefinition','Command')]
            $ItemType
        )

        $Token = $Err = $null
        $ast = [Management.Automation.Language.Parser]::ParseFile($Path, [ref] $Token, [ref] $Err)

        $ast.FindAll({ $args[0].GetType().Name -eq "${ItemType}Ast" }, $true)

    }


$functionNames = Get-ContainedCommand $Path -ItemType FunctionDefinition |
  Select-Object -ExpandProperty Name

    $commands = Get-ContainedCommand $Path -ItemType Command
    $commands | Where-Object {
      $commandName = $_.CommandElements[0].Extent.Text
      $commandName -notin $functionNames
      } |
      ForEach-Object { $_.GetCommandName() } |
      Sort-Object -Unique |
      ForEach-Object {
    $module = (Get-Command -name $_).Source
    $builtIn = $module -like &#39;Microsoft.PowerShell.*&#39;

    [PSCustomObject]@{
        Command = $_
        BuiltIn = $builtIn
        Module = $module
    }
    }
}
```

以下是根据一个 PowerShell 脚本生成的一个示例报告，它列出了所有外部的 cmdlet，以及它们是否是 PowerShell 的一部分或来自外部模块：

```powershell
PS> Get-ExternalCommand -Path $Path


Command                BuiltIn Module
-------                ------- ------
ConvertFrom-StringData    True Microsoft.PowerShell.Utility
Get-Acl                   True Microsoft.PowerShell.Security
Get-ItemProperty          True Microsoft.PowerShell.Management
Get-Service               True Microsoft.PowerShell.Management
Get-WmiObject             True Microsoft.PowerShell.Management
New-Object                True Microsoft.PowerShell.Utility
out-default               True Microsoft.PowerShell.Core
Test-Path                 True Microsoft.PowerShell.Management
Where-Object              True Microsoft.PowerShell.Core
write-host                True Microsoft.PowerShell.Utility

PS>
```

<!--本文国际来源：[Checking Cmdlet Availability and Script Compatibility (Part 3)](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/checking-cmdlet-availability-and-script-compatibility-part-3)-->

