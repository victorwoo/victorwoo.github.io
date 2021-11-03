---
layout: post
date: 2021-10-20 00:00:00
title: "PowerShell 技能连载 - 调整脚本性能"
description: PowerTip of the Day - Tuning Script Performance
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
如果脚本运行速度速度慢，找出导致延迟的地方并优化并不是一件很简单的事。使用名为 "psprofiler" 的 PowerShell 模块，可以测试脚本中的每行所需的时间。它在 Windows PowerShell 和 PowerShell 7 中都能运行。

首先安装模块：

```powershell
PS> Install-Module -Name PSProfiler -Scope CurrentUser
```

下一步，用 `Measure-Script` 执行脚本：

```powershell
PS> Measure-Script -Path 'C:\Users\tobias\test123.ps1'
```

Once your script completes, you get a sophisticated report telling you exactly how often each line of your script was executed, and how long it took:
脚本完成后，就会获得一份复杂的报告，告诉您脚本每行执行的次数，以及消耗的时间：

      Count  Line       Time Taken Statement
      -----  ----       ---------- ---------
          1     1    00:00.0033734 $Path = "$env:temp\tv.json"
          0     2    00:00.0000000
          1     3    00:28.1602885 $data = Get-Content -Path $Path -Raw |
          0     4    00:00.0000000 ConvertFrom-Json |
          1     5    00:26.6558438 ForEach-Object { $_ } |
          0     6    00:00.0000000 ForEach-Object {
          0     7    00:00.0000000
     101000     8    00:01.4408993   $title = '{0,5} [{2}] "{1}" ({3})' -f ([Object[]]$_)
     101000     9    00:13.6815132   $title | Add-Member -MemberType NoteProperty -Name Data -Value $_ -PassThru
          0    10    00:00.0000000 }
          0    11    00:00.0000000
    ...

<!--本文国际来源：[Tuning Script Performance](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/tuning-script-performance)-->

