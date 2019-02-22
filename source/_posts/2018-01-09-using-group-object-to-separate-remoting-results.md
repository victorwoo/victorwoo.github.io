---
layout: post
date: 2018-01-09 00:00:00
title: "PowerShell 技能连载 - 用 Group-Object 区分远程处理结果"
description: PowerTip of the Day - Using Group-Object to Separate Remoting Results
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
当您需要通过 PowerShell 远程处理来获取多台计算机的信息时，您可以单独查询每台机器。更快的方法是同时查询多台机器，这也产生一个问题，如何区分处理结果呢？

以下是一个例子（假设您的环境中启用了 PowerShell 远程操作）：

```powershell
$serverList = 'TRAIN11','TRAIN12'


$code = {
    Get-Service
}

# get results from all machines in parallel...
$results = Invoke-Command -ScriptBlock $code -ComputerName $serverList |
    # and separate results by PSComputerName
    Group-Object -Property PSComputerName -AsHashTable -AsString


$results['TRAIN11']

$results['TRAIN12']
```

如您所见，`Invoke-Command` 命令从两台机器返回了所请求的服务信息。接下来 `Group-Object` 命令将数据分离到两个组里，并且使用 `PSComputerName` 属性来标识它。`PSComputerName` 是一个自动属性，通过 PowerShell 远程处理接收到的数据总是带有这个属性。

这样，即便 PowerShell 远程处理在所有机器上并行执行代码，我们也可以区分每台机器的执行结果。

<!--本文国际来源：[Using Group-Object to Separate Remoting Results](http://community.idera.com/powershell/powertips/b/tips/posts/using-group-object-to-separate-remoting-results)-->
