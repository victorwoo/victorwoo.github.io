---
layout: post
date: 2022-05-16 00:00:00
title: "PowerShell 技能连载 - 专业地处理错误"
description: PowerTip of the Day - Professional Error Handling
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
通常，PowerShell 脚本使用这样简单的错误报告形式，该报告的结构是这样的：

```powershell
# clearing global error list:
$error.Clear()
# hiding errors:
$ErrorActionPreference = 'SilentlyContinue'

# do stuff:
Stop-Service -Name Spooler
dir c:\gibtsnichtabc


# check errors at end:
$error.Count 
$error | Out-GridView
```

尽管这没有错，但您应该了解 $error 是一个全局变量，因此，如果您在脚本中使用外部代码（即其他人写的功能或模块），这些作者可能已经使用了相同的技术，并且如果他们产生了错误并清除了全局错误列表，那么您将失去以前记录的错误。

一种更好，更健壮的方式是使用私有变量进行记录。 实际上并没有重写太多的代码：

```powershell
# hiding errors:
$ErrorActionPreference = 'SilentlyContinue'
# telling all cmdlets to use a private variable for error logging:
$PSDefaultParameterValues.Add('*:ErrorVariable', '+myErrors')
# initializing the variable:
$myErrors = $null

# do stuff:
Stop-Service -Name Spooler
dir c:\gibtsnichtabc


# check errors at end USING PRIVATE VARIABLE:
$myErrors.Count
$myErrors | Out-GridView
```

基本技巧是定义 `-ErrorVariable` 的默认参数值，并为其分配私有变量的名称。确保在名称之前添加一个 "+"，以便附加新错误，而不是覆盖现有错误。

<!--本文国际来源：[Professional Error Handling](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/professional-error-handling)-->

