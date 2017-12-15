---
layout: post
date: 2017-12-12 00:00:00
title: "PowerShell 技能连载 - 在 Grid View 窗口中垂直显示数据"
description: PowerTip of the Day - Displaying Data in a Grid View Window Vertically
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
- translation
---
`Out-GridView` 总是以每个对象一行的方式生成表格：

```powershell
Get-Process -Id $pid | Out-GridView
```

有些时候，在 grid view 窗口中垂直显示对象属性，每个属性一行，更有用。

要做到这个效果，请看看 `Flip-Object`：这个函数输入对象，并将它们按每个属性分割成独立的键-值对象。它们可以通过管道导到 `Out-GridView` 中。通过这种方式，对象属性可以以更详细的方式查看：

```powershell
Get-Process -Id $pid | Flip-Object | Out-GridView
```

以下是 `Flip-Object` 函数的实现：

```powershell
function Flip-Object
{
    param
    (
        [Object]
        [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
        $InputObject
    )
    process
    {
        
        $InputObject | 
        ForEach-Object {
            $instance = $_
            $instance | 
            Get-Member -MemberType *Property |
            Select-Object -ExpandProperty Name |
            ForEach-Object {
                [PSCustomObject]@{
                    Name = $_
                    Value = $instance.$_
                }
            }
        } 
            
    }
}
```

<!--more-->
本文国际来源：[Displaying Data in a Grid View Window Vertically](http://community.idera.com/powershell/powertips/b/tips/posts/displaying-data-in-a-grid-view-window-vertically)
