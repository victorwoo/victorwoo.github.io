---
layout: post
date: 2017-07-10 00:00:00
title: "PowerShell 技能连载 - 查找 PowerShell 缺省变量（第一部分）"
description: PowerTip of the Day - Finding PowerShell Default Variables (Part 1)
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
有些时候识别出 PowerShell 管理的缺省变量十分有用，这样能帮您区分内置的变量和自定义的变量。`Get-Variable` 总是输出所有的变量。

以下是一个简单的技巧，使用一个独立、全新的 PowerShell 运行空间来确定内置的 PowerShell 变量：

```powershell
# create a new PowerShell
$ps = [PowerShell]::Create()
# get all variables inside of it
$null = $ps.AddCommand('Get-Variable')
$result = $ps.Invoke()
# dispose new PowerShell
$ps.Runspace.Close()
$ps.Dispose()

# check results
$varCount = $result.Count
Write-Warning "Found $varCount variables."
$result | Out-GridView
```

当您运行这段代码时，该代码输出找到的变量数量，以及这些变量。

<!--本文国际来源：[Finding PowerShell Default Variables (Part 1)](http://community.idera.com/powershell/powertips/b/tips/posts/finding-powershell-default-variables-part-1)-->
