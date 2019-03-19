---
layout: post
date: 2019-03-13 00:00:00
title: "PowerShell 技能连载 - 检查 Cmdlet 可用性和脚本兼容性（第 2 部分）"
description: PowerTip of the Day - Checking Cmdlet Availability and Script Compatibility (Part 2)
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

在前一部分中我们处理了一个脚本并且读出这个脚本所使用的所有外部命令。我们用这个函数合并了找到的所有外部命令：

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
      Sort-Object -Unique
}
```

您可以向这个函数传入任何 PowerShell 脚本路径并且得到这个脚本使用的所有外部命令（只需要确保在 `$path` 中传入了一个脚本的合法路径）：

```powershell
PS C:\> Get-ExternalCommand -Path $Path
ConvertFrom-StringData
Get-Acl
Get-ItemProperty
Get-Service
Get-WmiObject
New-Object
out-default
Test-Path
Where-Object
write-host
```

<!--本文国际来源：[Checking Cmdlet Availability and Script Compatibility (Part 2)](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/checking-cmdlet-availability-and-script-compatibility-part-2)-->

