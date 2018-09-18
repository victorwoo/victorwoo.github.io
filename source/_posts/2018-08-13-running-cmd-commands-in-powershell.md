---
layout: post
date: 2018-08-13 00:00:00
title: "PowerShell 技能连载 - 在 PowerShell 中运行 CMD 命令"
description: PowerTip of the Day - Running CMD commands in PowerShell
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
PowerShell 默认情况下不支持原生的 cmd.exe 命令，例如 "`dir`"。替代的是，它使用历史别名 "`dir`" 指向最接近的 PowerShell cmdlet：

```powershell
PS C:\> Get-Command -Name dir | ft -AutoSize

CommandType Name                 Version Source
----------- ----                 ------- ------
Alias       dir -> Get-ChildItem
```

这解释了为什么 PowerShell 中的 "`dir`" 不支持 cmd.exe 以及批处理文件中的开关和参数，例如 "`cmd.exe/w`"。

如果您必须使用 cmd 形式的命令，请用 `/c` 参数（代表 "command"）启动一个原生的 cmd.exe，执行这条命令，并在 PowerShell 内处理执行结果。这个例子运行 `cmd.exe /c`，然后以参数 `/w` 运行旧的 "`dir`" 命令：

```powershell
PS C:\> cmd.exe /c dir /w
```

一个更安全的方法是使用 "`--%`" 操作符：

```powershell
PS C:\> cmd.exe --% /c dir /w
```

当在参数之前添加了它之后，PowerShell 解释器将不会对参数进行处理，这样您甚至可以像在 cmd.exe 中一样使用环境变量注解。副作用是：您在参数中不再能使用 PowerShell 技术，比如变量：

```powershell
PS C:\> cmd.exe --% /c dir %WINDIR% /w
```

<!--more-->
本文国际来源：[Running CMD commands in PowerShell](http://community.idera.com/powershell/powertips/b/tips/posts/running-cmd-commands-in-powershell)
