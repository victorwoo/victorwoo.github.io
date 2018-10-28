---
layout: post
date: 2018-10-24 00:00:00
title: "PowerShell 技能连载 - 编程列出所有 Cmdlet 或函数参数的列表"
description: PowerTip of the Day - Programmatically listing any Cmdlet or Function Parameters
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
是否曾好奇如何列出一个函数或 cmdlet 暴露出的所有属性？以下是实现方法：

```powershell
Get-Help Get-Service -Parameter * | Select-Object -ExpandProperty name
```

`Get-Help` 提供了一系列关于参数的有用的信息和元数据。如果您只希望转储支持管道输入的参数，以下是实现方法：

```powershell
Get-Help Get-Service -Parameter * |
Where-Object { $_.pipelineInput.Length -gt 10 } |
Select-Object -Property name, pipelineinput, parameterValue
```

"`pipelineInput`" 属性暴露了通过管道接收到的一个属性的类型。不幸的是，它包含了一个本地化的字符串，所以一个区分的好方法是取字符串的长度。

输出的结果类似这样，并且可以从管道上游的命令中接受管道的输入，以及接受数据类型：

```powershell
name         pipelineInput                  parameterValue
----         -------------                  --------------
ComputerName True (ByPropertyName)          String[]
InputObject  True (ByValue)                 ServiceController[]
Name         True (ByPropertyName, ByValue) String[]
```

<!--more-->
本文国际来源：[Programmatically listing any Cmdlet or Function Parameters](http://community.idera.com/powershell/powertips/b/tips/posts/programmatically-listing-any-cmdlet-or-function-parameters)
