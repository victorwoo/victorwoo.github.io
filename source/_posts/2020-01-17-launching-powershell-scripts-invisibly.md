---
layout: post
date: 2020-01-17 00:00:00
title: "PowerShell 技能连载 - 隐藏启动 PowerShell 脚本"
description: PowerTip of the Day - Launching PowerShell Scripts Invisibly
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
没有内置的方法可以隐藏启动 PowerShell 脚本：即使您运行 powershell.exe 并指定 `-WindowStyle Hidden`，PowerShell 控制台仍将一闪而过。

要隐藏启动 PowerShell 脚本，可以使用 VBScript：

```VBScript
Set objShell = CreateObject("WScript.Shell")
path = WScript.Arguments(0)

command = "powershell -noprofile -windowstyle hidden -executionpolicy bypass -file """ & path & """"

objShell.Run command,0
```

将 test.vbs 保存，然后确保以 ANSI 编码保存（用记事本并在另存为对话框的地步下拉列表中选择编码）。VBS 无法处理 UTF8 编码的脚本。当您试图运行这样的脚本时，会得到一个非法字符的异常。

要隐藏启动一个 PowerShell 脚本，可以运行这行命令：

请注意，虽然 wscript.exe 隐藏了 PowerShell 的控制台窗口，但您打开任何 WPF窗口（例如使用 `Out-GridView`）时，将继续工作并且正常显示。

```powershell
Wscript.exe c:\pathtovbs.vbs c:\pathtoPS1file.ps1
```

<!--本文国际来源：[Launching PowerShell Scripts Invisibly](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/launching-powershell-scripts-invisibly)-->

