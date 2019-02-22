---
layout: post
date: 2018-01-24 00:00:00
title: "PowerShell 技能连载 - 用网格视图窗口显示列表视图（第 2 部分）"
description: PowerTip of the Day - Using List View in a Grid View Window (Part 2)
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
`Out-GridView` 是一个有用的 cmdlet。但如果只是用它来显示一个单一对象的所有属性时不太理想，因为这样显示出来只有一行。在前一个技能中我们解释了将一个对象转换为一个哈希表能解决这个问题。它实际上是将一个网格视图工作在“列表视图”模式。

因为这个方法在许多场景中十分有用，以下是一个封装好的名为 `ConvertObject-ToHashTable` 的函数，以及一系列示例代码：

```powershell
function ConvertObject-ToHashTable
{
    param
    (
        [Parameter(Mandatory,ValueFromPipeline)]
        $object
    )

    process
    {
    $object |
        Get-Member -MemberType *Property |
        Select-Object -ExpandProperty Name |
        Sort-Object |
        ForEach-Object { [PSCustomObject]@{
            Item = $_
            Value = $object.$_}
        }
    }
}

systeminfo.exe /FO CSV | ConvertFrom-Csv | ConvertObject-ToHashTable | Out-GridView

Get-ComputerInfo | ConvertObject-ToHashTable | Out-GridView

Get-WmiObject -Class Win32_BIOS | ConvertObject-ToHashTable | Out-GridView
```

<!--本文国际来源：[Using List View in a Grid View Window (Part 2)](http://community.idera.com/powershell/powertips/b/tips/posts/using-list-view-in-a-grid-view-window-part-2)-->
