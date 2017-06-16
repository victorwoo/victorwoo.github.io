---
layout: post
date: 2017-06-14 00:00:00
title: "PowerShell 技能连载 - 查找一个脚本块中的所有变量"
description: PowerTip of the Day - Finding All Variables in a Script Block
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
要分析一个脚本快中的内容，您可以简单地检查 AST，并且，例如创建一个包含代码中所有变量的清单：

```powershell
$code = {

    $a = "Test"
    $b = 12
    Get-Service
    Get-Process
    $berta = 100

}


$code.Ast.FindAll( { $true }, $true) |
    Where-Object { $_.GetType().Name -eq 'VariableExpressionAst' } |
    Select-Object -Property VariablePath -ExpandProperty Extent |
    Out-GridView
```

如果您想查看所有的命令，请试试以下代码：

```powershell
$code = {

    $a = "Test"
    $b = 12
    Get-Service
    Get-Process
    $berta = 100

}


$code.Ast.FindAll( { $true }, $true)  |
    Where-Object { $_.GetType().Name -eq 'CommandAst' } |
    Select-Object -ExpandProperty Extent  |
    Select-Object -Property * -ExcludeProperty *ScriptPosition |
    Out-GridView
```

这在根据脚本块自动生成文档的时候非常有用。

<!--more-->
本文国际来源：[Finding All Variables in a Script Block](http://community.idera.com/powershell/powertips/b/tips/posts/finding-all-variables-in-a-script-block)
