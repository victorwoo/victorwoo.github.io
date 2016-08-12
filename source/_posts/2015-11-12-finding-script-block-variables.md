layout: post
date: 2015-11-12 12:00:00
title: "PowerShell 技能连载 - 查找脚本块变量"
description: PowerTip of the Day - Finding Script Block Variables
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
脚本块定义了一段 PowerShell 代码而并不执行它。最简单的定义脚本块的方法是将代码放入花括号中。

脚本块有一系列高级功能，能够检测花括号内部的代码。其中的一个功能是直接访问抽象语法树 (AST)。AST 可以分分析代码内容。以下是一个读出脚本块中所有变量名的例子：

    #requires -Version 3
    
    
    $scriptblock = {
    
       $test = 1
       $abc = 2
    
    }
    
    $scriptblock.Ast.FindAll( { $args[0] -is [System.Management.Automation.Language.VariableExpressionAst] }, $true ) |
      Select-Object -ExpandProperty VariablePath | Select-Object -ExpandProperty UserPath

<!--more-->
本文国际来源：[Finding Script Block Variables](http://powershell.com/cs/blogs/tips/archive/2015/11/12/finding-script-block-variables.aspx)
