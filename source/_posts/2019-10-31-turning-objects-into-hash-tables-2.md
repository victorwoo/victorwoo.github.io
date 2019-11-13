---
layout: post
date: 2019-10-31 00:00:00
title: "PowerShell 技能连载 - 将对象转换为哈希表"
description: PowerTip of the Day - Turning Objects into Hash Tables
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
我们经常需要检视一个对象，例如一个进程或是一个 Active Directory 用户。当您在一个网格视图窗口，例如 `Out-GridView` 中显示一个对象时，整个对象显示为一个长行。

一个好得多的方法是将一个对象转换为哈希表。通过这种方式，每个属性都在独立的一行中显示，这样您就可以用网格视图窗口顶部的文本过滤器搜索每个属性。另外，您可以完全控制转换的过程，这样您可以对对象的属性排序，并且确保它们按字母顺序排序，甚至排除空属性。

以下是一个将对象转换为哈希表并且可以根据需要排除空属性的函数：

```powershell
function Convert-ObjectToHashtable
{
    param
    (
        [Parameter(Mandatory,ValueFromPipeline)]
        $object,

        [Switch]
        $ExcludeEmpty
    )

    process
    {
        $object.PSObject.Properties |
        # sort property names
        Sort-Object -Property Name |
        # exclude empty properties if requested
        Where-Object { $ExcludeEmpty.IsPresent -eq $false -or $_.Value -ne $null } |
        ForEach-Object {
            $hashtable = [Ordered]@{}} {
            $hashtable[$_.Name] = $_.Value
            } {
            $hashtable
            }
    }
}
```

让我们来看看一个对象，例如当前进程，缺省情况下在 `Out-GridView` 是如何显示的：

```powershell
$process = Get-Process -Id $pid | Out-GridView
```

和以下这个作对比：

```powershell
$process = Get-Process -Id $pid | Convert-ObjectToHashtable -ExcludeEmpty | Out-GridView
```

现在分析起来好多了。

<!--本文国际来源：[Turning Objects into Hash Tables](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/turning-objects-into-hash-tables-2)-->

