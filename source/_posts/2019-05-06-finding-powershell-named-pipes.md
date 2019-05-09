---
layout: post
date: 2019-05-06 00:00:00
title: "PowerShell 技能连载 - 查找 PowerShell 命名管道"
description: PowerTip of the Day - Finding PowerShell Named Pipes
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
每个运行 PowerShell 5 以及以上版本的 PowerShell 宿主都会打开一个能被检测到的“命名管道”。以下代码检测这些命名管道并返回暴露这些管道的进程：

```powershell
Get-ChildItem -Path "\\.\pipe\" -Filter '*pshost*' |
ForEach-Object {
    Get-Process -Id $_.Name.Split('.')[2]
}
```

结果看起来类似这样：

    Handles  NPM(K)    PM(K)      WS(K)     CPU(s)     Id  SI ProcessName
    -------  ------    -----      -----     ------     --  -- -----------
       1204      98   306220      66620      63,30  28644   1 powershell_ise
        525      29    72604      12708       5,64  12188   1 powershell
        741      41   125728     142656      11,52  27144   1 powershell
        835      61    40836      82624       1,44  22412   1 pwsh
        820      49   199680     230632       2,86  26500   1 powershell_ise

这里列出的每个进程都启动了一个 PowerShell 运行空间。您可以使用 `Enter-PSHostProcess -Id XXX` 来连接到 PowerShell 进程（假设您有本地管理员特权）。

<!--本文国际来源：[Finding PowerShell Named Pipes](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/finding-powershell-named-pipes)-->

