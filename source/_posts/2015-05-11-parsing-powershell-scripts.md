layout: post
date: 2015-05-11 11:00:00
title: "PowerShell 技能连载 - 解析 PowerShell 脚本"
description: PowerTip of the Day - Parsing PowerShell Scripts
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
如果您希望为 PowerShell 脚本语法着色，例如用 HTML 将它们格式化，以下是一个起步示例：

这个例子将读取当前 ISE 编辑器中显示的脚本，然后调用 PowerShell 解析器返回所有 token 的信息。

    $content = $psise.CurrentFile.Editor.Text
    $token = $null
    $errors = $null
    
    $token = [System.Management.Automation.PSParser]::Tokenize($content, [ref]$errors)
    
    $token | Out-GridView

您可以简单地使用 `Get-Content` 来读取任何脚本中的内容。读取到的结果是一个由 token 对象组成的数组。它们包含了语法元素类型，以及起止位置。

该信息是格式化 PowerShell 代码所需要的。您可以为 token 类型指定颜色，并为 PowerShell 代码创建自己的文档。

<!--more-->
本文国际来源：[Parsing PowerShell Scripts](http://powershell.com/cs/blogs/tips/archive/2015/05/11/parsing-powershell-scripts.aspx)
