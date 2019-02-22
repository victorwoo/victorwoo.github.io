---
layout: post
date: 2017-12-25 00:00:00
title: "PowerShell 技能连载 - 在多台计算机中并行运行命令"
description: PowerTip of the Day - Running Commands on Multiple Computers in Parallel
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
假设您已经启用了 PowerShell 远程处理（请看我们之前的技能），那么您可以同时在多台计算机上运行命令。

以下例子演示了这个操作，并且在列表中所有计算机中所有用户的桌面上放置一个文件。警告：这是个很强大的脚本。它将在列表中的所有机器上运行 `$code` 中的任何代码，假设启用了远程处理，并且您有相应的权限：

```powershell
# list of computers to connect to
$listOfComputers = 'PC10','TRAIN1','TRAIN2','AD001'
# exclude your own computer
$listOfComputers = $listOfComputers -ne $env:COMPUTERNAME
# code to execute remotely
$code = {
"Hello" | Out-File -FilePath "c:\users\Public\Desktop\result.txt"
}
# invoke code on all machines
Invoke-Command -ScriptBlock $code -ComputerName $listOfComputers -Throttle 1000
```

例如，如果您将 `$code` 中的代码替换为 `Stop-Computer -Force`，所有机器将会被关闭。

<!--本文国际来源：[Running Commands on Multiple Computers in Parallel](http://community.idera.com/powershell/powertips/b/tips/posts/running-commands-on-multiple-computers-in-parallel)-->
