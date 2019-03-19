---
layout: post
date: 2019-03-12 00:00:00
title: "PowerShell 技能连载 - 检查 Cmdlet 可用性和脚本兼容性（第 1 部分）"
description: PowerTip of the Day - Checking Cmdlet Availability and Script Compatibility (Part 1)
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

要查看您的脚本的兼容性，在第一部分中我们先看看如何查找一个脚本实际使用哪些命令。以下是一个帮助函数，能够利用 PowerShell 内部的抽象语法树 (AST) 来检测命令：

```powershell
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
```

`Get-ContainedCommand` 可以解析一个脚本中定义的函数，或是一个脚本中使用的命令。以下是获取某个脚本中所有定义的函数的代码：

```powershell
$Path = "C:\scriptToPS1File\WithFunctionDefinitionsInIt.ps1"

$functionNames = Get-ContainedCommand $Path -ItemType FunctionDefinition |
  Select-Object -ExpandProperty Name

$functionNames
```

以下是脚本内部使用的命令列表：

```powershell
$commands = Get-ContainedCommand $Path -ItemType Command
$commands.Foreach{$_.CommandElements[0].Extent.Text}
```

要找出使用外部命令的地方，只需要从命令列表中减掉所有内部定义的函数，然后移除重复。以下将获取某个脚本用到的所有外部命令：

```powershell
$Path = "C:\scriptToPS1File\WithFunctionDefinitionsInIt.ps1"

$functionNames = Get-ContainedCommand $Path -ItemType FunctionDefinition |
  Select-Object -ExpandProperty Name

$commands = Get-ContainedCommand $Path -ItemType Command

$externalCommands = $commands | Where-Object {
      $commandName = $_.CommandElements[0].Extent.Text
      $commandName -notin $functionNames
  } |
  Sort-Object -Property { $_.GetCommandName() } -Unique
```

<!--本文国际来源：[Checking Cmdlet Availability and Script Compatibility (Part 1)](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/checking-cmdlet-availability-and-script-compatibility-part-1)-->

