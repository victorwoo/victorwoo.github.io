---
layout: post
date: 2019-08-02 00:00:00
title: "PowerShell 技能连载 - 查找隐藏的 PowerShell 应用"
description: PowerTip of the Day - Finding Hidden PowerShell Applications
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
最广为人知的 PowerShell 宿主当然是 PowerShell.exe 和 powershell_ise.exe，因为它们是开箱即用的。但是，运行 PowerShell 的宿主可能更多（而且是隐藏的）。任何实例化 PowerShell 引擎的软件都是一个 PowerShell 宿主。这可以是 Visual Studio Code（安装了 PowerShell扩展）、Visual Studio 或任何其它类似的软件。

要找出所有当前运行 PowerShell 的宿主，请运行以下命令：

```powershell
Get-ChildItem -Path "\\.\pipe\" -Filter '*pshost*' |
    ForEach-Object {
        $id = $_.Name.Split('.')[2]
        if ($id -ne $pid)
        {
            Get-Process -ID $id
        }
    }
```

结果看起来类似这样：

    Handles  NPM(K)    PM(K)      WS(K)     CPU(s)     Id  SI ProcessName
    -------  ------    -----      -----     ------     --  -- -----------
       1131     101   628520      42440             11216   0 SupportAssistAgent
       1011      82   269920     299208      85,30  17420   1 powershell_ise
        520      29    68012      75880       1,23  33532   1 powershell
        590      31    69508      77712       2,02  36636   1 powershell
        545      27    67952      76668       1,14  37584   1 powershell
       4114     654   801136     965032     129,69  28968   1 devenv

"SupportAssistAgent" 是由 Visual Studio Code 打开的，而 "devenv" 代表由 Visual Studio 启动的内部 PowerShell 宿主。

<!--本文国际来源：[Finding Hidden PowerShell Applications](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/finding-hidden-powershell-applications)-->

