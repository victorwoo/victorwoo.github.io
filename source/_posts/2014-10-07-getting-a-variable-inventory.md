---
layout: post
date: 2014-10-07 11:00:00
title: "PowerShell 技能连载 - 获取变量详细清单"
description: PowerTip of the Day - Getting a Variable Inventory
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
_适用于 PowerShell ISE 3 或更高版本_

出于写文档等目的，您可能需要获得一份 PowerShell 脚本用到的所有变量的清单。

以下是一个名为 `Get-Variable` 的函数：

    function Get-Variable
    {
      
      $token = $null
      $errors = $null
      
      $ast = [System.Management.Automation.Language.Parser]::ParseInput($psise.CurrentFile.Editor.Text, [ref] $token, [ref] $errors)
      
      # not complete, add variables you want to exclude from the list:
      $systemVariables = '_', 'null', 'psitem', 'true', 'false', 'args', 'host'
      
      $null = $ast.FindAll({ $args[0] -is [System.Management.Automation.Language.CommandAst] }, $true)
      $token | 
        Where-Object { $_.Kind -eq 'Variable'} |
        Select-Object -ExpandProperty Name |
        Where-Object { $systemVariables -notcontains $_ } |
        Sort-Object -Unique
    } 

只需要用系统自带的 ISE 编辑器打开这个脚本，然后在交互式控制台中运行 `Get-Variable`。

您将会得到一个排序过的列表，内容是当前打开的脚本用到的所有变量。

如果您将“$`psise.CurrentFile.Editor.Text`”替换成一个包含脚本代码的变量，那么您可以在 ISE 编辑器之外运行这个函数。只需要用 `Get-Content` 将任意脚本的内容读取进一个变量，然后就可以在上述代码中使用这个变量。

<!--more-->
本文国际来源：[Getting a Variable Inventory](http://community.idera.com/powershell/powertips/b/tips/posts/getting-a-variable-inventory)
