---
layout: post
date: 2018-01-17 00:00:00
title: "PowerShell 技能连载 - 用网格视图窗口作为选择对话框（第一部分）"
description: PowerTip of the Day - Using a Grid View Window as a Selection Dialog (Part 1)
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
如何使用网格视图窗口作为一个简单的选择对话框呢？

当您将对象用管道输出到网格视图窗口中，所有属性都会显示出来。通常情况下这可以工作得很好，只需要这样一行代码：

```powershell
Get-Service | Out-GridView -Title "Select Service" -OutputMode Single
```

有些时候，特别是一个对象有诸多属性时，可能会让用户看不过来：

```powershell
Get-WmiObject -Class Win32_NetworkAdapterConfiguration |
    Out-GridView -Title "Select Network Card" -OutputMode Single
```

要简化这个对话框，您可以使用我们之前在用户配置文件管理中的方法，使用一个哈希表。只需要选择一个属性作为键。这个属性必须是唯一的。接下来，试试这段代码：

```powershell
Get-WmiObject -Class Win32_NetworkAdapterConfiguration |
    Out-GridView -Title "Select Network Card" -OutputMode Single

$hashTable = Get-WmiObject -Class Win32_NetworkAdapterConfiguration |
    Group-Object -Property Description -AsHashTable -AsString

$hashTable.Keys |
    Sort-Object |
    Out-GridView -Title "Select Network Card" -OutputMode Single |
    ForEach-Object {
        $hashTable[$_]
    }
```

如您所见，只有选择中的属性会在网格视图窗口中显示，当用户选择了一个元素，将获取到完整的对象。这和服务列表的工作方式很像：

```powershell
$hashTable = Get-Service |
    Group-Object -Property DisplayName -AsHashTable -AsString

$hashTable.Keys |
    Sort-Object |
    Out-GridView -Title "Select Service" -OutputMode Single |
    ForEach-Object {
        $hashTable[$_]
    }
```

<!--more-->
本文国际来源：[Using a Grid View Window as a Selection Dialog (Part 1)](http://community.idera.com/powershell/powertips/b/tips/posts/using-a-grid-view-window-as-a-selection-dialog-part-1)
