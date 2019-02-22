---
layout: post
date: 2016-12-13 00:00:00
title: "PowerShell 技能连载 - 按属性值分割结果"
description: PowerTip of the Day - Separating Results by Property Value
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
如果您使用 PowerShell 远程操作来接收远程机器的信息，您可以指定多个计算机名（扇出）。PowerShell 会自动逐台访问所有的机器，这样可以节省很多时间（当然，这些操作的前提是设置并启用了 PowerShell，这里不再赘述）。

返回的结果顺序是随机的，因为所有被访问的机器都会在它们准备好数据的时候返回各自的信息。

要将结果数据按每台机器分割，请使用 `Group-Object` 命令：

```powershell
$pc1 = $env:computername
$pc2 = '192.168.2.112'

$code = 
{
  Get-Service | Where-Object Status -eq Running
}

# get all results
$result = Invoke-Command -ScriptBlock $code -ComputerName $pc1, $pc2 

# separate per computer
$groups = $result | Group-Object -Property PSComputerName -AsHashTable 
$groups

# access per computer results separately
$groups.$pc1
$groups.$pc2
```

当您指定了 `-AsHashTable` 参数时，`Groutp-Object` 创建了一个以计算机名为键的哈希表。通过这种方法，您可以并发执行操作以节约时间，并仍然按每台机器来区分数据。

<!--本文国际来源：[Separating Results by Property Value](http://community.idera.com/powershell/powertips/b/tips/posts/separating-results-by-property-value)-->
