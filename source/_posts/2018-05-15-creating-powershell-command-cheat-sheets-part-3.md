---
layout: post
date: 2018-05-15 00:00:00
title: "PowerShell 技能连载 - 创建 PowerShell 命令速查表（第 3 部分）"
description: PowerTip of the Day - Creating PowerShell Command Cheat Sheets (Part 3)
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
在前一个技能中，我们创建了 PowerShell 命令的速查表并且将他们转换为可被浏览器打开和打印的 HTML 报告。它可以正常工作，但是输出页面不是非常精致。只要加上一些 HTML 延时，您的命令列表就可以上黄金档啦，而且您还可以用这个例子中的技术来“美化”任何通过 PowerShell 的 `ConvertTo-Html` 创建的 HTML 表格：

```powershell
# adjust the name of the module
# code will list all commands shipped by that module
# list of all modules: Get-Module -ListAvailable
$ModuleName = "PrintManagement"
$Title = "PowerShell Print Management Commands"
$OutFile = "$env:temp\commands.html"
$StyleSheet = @"
<title>$Title</title>
<style>
h1, th { text-align: center; font-family: Segoe UI; color:#0046c3;}
table { margin: auto; font-family: Segoe UI; box-shadow: 10px 10px 5px #888; border: thin ridge grey; }
th { background: #0046c3; color: #fff; max-width: 400px; padding: 5px 10px; }
td { font-size: 11px; padding: 5px 20px; color: #000; }
tr { background: #b8d1f3; }
tr:nth-child(even) { background: #dae5f4; }
tr:nth-child(odd) { background: #b8d1f3; }
</style>
"@
$Header = "<h1 align='center'>$title</h1>"
Get-Command -Module $moduleName | 
  Get-Help | 
  Select-Object -Property Name, Synopsis |
  ConvertTo-Html -Title $Title -Head $StyleSheet -PreContent $Header |
  Set-Content -Path $OutFile


Invoke-Item -Path $OutFile
```

<!--more-->
本文国际来源：[Creating PowerShell Command Cheat Sheets (Part 3)](http://community.idera.com/powershell/powertips/b/tips/posts/creating-powershell-command-cheat-sheets-part-3)
