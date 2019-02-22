---
layout: post
date: 2018-01-25 00:00:00
title: "PowerShell 技能连载 - 用网格视图窗口显示列表视图（第 3 部分）"
description: PowerTip of the Day - Using List View in a Grid View Window (Part 3)
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
在前一个技能中我们介绍了 `ConvertObject-ToHashTable` 函数，它能方便地将对象显示在一个网格视图窗口中。

以下代码是一个改进的版本，能够根据字母顺序排列属性，并且可以由您决定每一列的名称。缺省情况下，`Out-GridView` 的列名为 "Property" 和 "Value"，但您将它们改为任意名称：

```powershell
function ConvertObject-ToHashTable
{
    param
    (
        [Parameter(Mandatory,ValueFromPipeline)]
        $object,

        [string]
        $PropertyName = "Property",

        [string]
        $ValueName = "Value"
    )

    process
    {
    $object |
        Get-Member -MemberType *Property |
        Select-Object -ExpandProperty Name |
        Sort-Object |
        ForEach-Object { [PSCustomObject]@{
            $PropertyName = $_
            $ValueName = $object.$_}
        }
    }
}

Get-ComputerInfo |
    # by default, columns are named "Property" and "Value"
    ConvertObject-ToHashTable |
    Out-GridView


Get-WmiObject -Class Win32_BIOS |
    # specify how you'd like to call the columns displayed in a grid view window
    ConvertObject-ToHashTable -PropertyName Information -ValueName Data |
    Out-GridView
```

<!--本文国际来源：[Using List View in a Grid View Window (Part 3)](http://community.idera.com/powershell/powertips/b/tips/posts/using-list-view-in-a-grid-view-window-part-3)-->
