---
layout: post
date: 2017-06-15 00:00:00
title: "PowerShell 技能连载 - 查找一个脚本中的所有变量"
description: PowerTip of the Day - Finding All Variables in a Script
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
在前一个技能中我们掩饰了如何分析一段脚本块的内容并且搜索变量或命令。这种技术也适用于基于文本的脚本。以下脚本将会检查自己并且提取出变量和命令：

```powershell
$filepath = $PSCommandPath
$tokens = $errors = $null

$ast = [System.Management.Automation.Language.Parser]::ParseFile($filepath, [ref]$tokens, [ref]$errors )

# find variables
$ast.FindAll( { $true }, $true) | 
  Where-Object { $_.GetType().Name -eq 'VariableExpressionAst' } |
  Select-Object -Property VariablePath -ExpandProperty Extent |
  Select-Object -Property * -ExcludeProperty *ScriptPosition |
  Out-GridView -Title 'Variables'


# find commands
$ast.FindAll( { $true }, $true)  | 
  Where-Object { $_.GetType().Name -eq 'CommandAst' } |
  Select-Object -ExpandProperty Extent  |
  Select-Object -Property * -ExcludeProperty *ScriptPosition |
  Out-GridView -Title 'Commands'
```

请确保将脚本保存到硬盘，或为 `$filepath` 指定一个不同的实际存在的脚本路径。

<!--more-->
本文国际来源：[Finding All Variables in a Script](http://community.idera.com/powershell/powertips/b/tips/posts/finding-all-variables-in-a-script)
