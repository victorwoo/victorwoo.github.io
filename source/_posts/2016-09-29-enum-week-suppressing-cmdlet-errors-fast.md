---
layout: post
date: 2016-09-29 00:00:00
title: "PowerShell 技能连载 - Enum 之周: 快速关闭 Cmdlet 错误提示"
description: 'PowerTip of the Day - Enum Week: Suppressing Cmdlet Errors - Fast'
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
这周我们将关注枚举类型：它们是什么，以及如何利用它们。

在前一个技能中，我们学习了枚举类型。这个技能教您如何使用最少的代码关闭 Cmdlet 产生的错误信息。

非管理员账户执行这行代码将产生错误信息，因为您无法存取其他用户的进程信息：


```shell
PS> Get-Process -FileVersionInfo
```
由于这个错误是良性的，并且不可避免，您可能会想将它们屏蔽：


```shell
PS> Get-Process -FileVersionInfo -ErrorAction SilentlyContinue
```
这对于脚本来说是完美的语法。当您交互式地运行代码时，您完全可以用难看的窍门来缩短关键字的输入，只需要写：


```shell
PS> Get-Process -FileVersionInfo -ea 0
```
"`-ea`" 是 `-ErrorAction` 参数的别名，而数字 0 相当于 `SilentlyContinue` 的枚举值。

要查看一个参数的别名，可以使用这样的代码：


```shell
PS> (Get-Command -Name Get-Process).Parameters["ErrorAction"].Aliases
ea
```

要查看枚举值对应的数字值，首先确定参数的数据类型：


```shell
PS> (Get-Command -Name Get-Process).Parameters["ErrorAction"].ParameterType.FullName
System.Management.Automation.ActionPreference
```

下一步，将参数转成一个整形：


```shell
PS> [int][System.Management.Automation.ActionPreference]::SilentlyContinue
0
```

So if you’d like to create a shortcut for the parameter value “Ignore” instead of “SilentlyContinue”, try this:

所以如果您想了解参数值 "`Ignore`" 而不是 "`SilentlyContinue`"，请试验以下代码：


```shell
PS> [int][System.Management.Automation.ActionPreference]::Ignore
4
```

"`SilientlyContinue`" 和 "`Ignore`" 都禁止了错误的输出，但是 "`SilentlyContinue`" 还会将禁止输出的错误信息写入 PowerShell 的 `$error` 变量中。

从现在开始，您在交互式操作 PowerShell 时可以用这种方式使用 "`Ignore`" 禁用错误信息：


```shell
PS> Get-Process -FileVersionInfo -ea 4
```
请注意：您也可以在脚本中使用这些快捷方式，但最好不要这么做。脚本中应当按照 PowerShell 的缺省写法，才能清晰易读。

<!--more-->
本文国际来源：[Enum Week: Suppressing Cmdlet Errors - Fast](http://community.idera.com/powershell/powertips/b/tips/posts/enum-week-suppressing-cmdlet-errors-fast)
