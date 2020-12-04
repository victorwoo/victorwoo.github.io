---
layout: post
date: 2020-11-24 00:00:00
title: "PowerShell 技能连载 - 查找 PowerShell 宿主参数和可执行文件"
description: PowerTip of the Day - Finding PowerShell Host Arguments and Executable
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
PowerShell 宿主可以使用参数启动，即您可以使用 `–NoProfile` 之类的参数运行 `powershell.exe` 或 `pwsh.exe`，或提交要执行的脚本的路径。

在外壳中，您始终可以查看启动此外壳程序的命令，包括其他参数：

```powershell
$exe, $parameters = [System.Environment]::GetCommandLineArgs()
"EXE: $exe"
"Args: $parameters"
```

当您使用 `-NoProfile` 启动 `powershell.exe` 时，结果如下所示：

    EXE: C:\WINDOWS\system32\WindowsPowerShell\v1.0\PowerShell.exe Args: -noprofile

当您传入多个参数时，`$parameters` 是一个数组。

<!--本文国际来源：[Finding PowerShell Host Arguments and Executable](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/finding-powershell-host-arguments-and-executable)-->

