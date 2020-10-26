---
layout: post
date: 2020-10-13 00:00:00
title: "PowerShell 技能连载 - 识别 PowerShell 宿主和路径"
description: PowerTip of the Day - Identifying PowerShell Host and Path
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
这是一个快速的单行代码，用于标识当前 PowerShell 宿主的完整路径：

```powershell
PS> (Get-Process -Id $pid).Path
C:\Program Files\PowerShell\7\pwsh.exe
```

该路径会告诉您当前宿主的位置，并且您可以检查代码是否在 Windows PowerShell、PowerShell 7 或PowerShell ISE 中执行。

用类似的方法，您还可以按名称查找可执行文件的路径。例如，如果您想知道 PowerShell 7 在系统上的安装位置，请尝试以下操作：

```powershell
PS C:\> (Get-Command -Name pwsh).Source
C:\Program Files\PowerShell\7\pwsh.exe
```

当然，如果找不到可执行文件，此行将产生错误。它必须位于 `$env:path` 中列出的文件夹之一中。

<!--本文国际来源：[Identifying PowerShell Host and Path](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/identifying-powershell-host-and-path)-->

