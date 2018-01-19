---
layout: post
date: 2018-01-18 00:00:00
title: "PowerShell 技能连载 - 用网格视图窗口作为选择对话框（第二部分）"
description: PowerTip of the Day - Using a Grid View Window as a Selection Dialog (Part 2)
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
在前一个技能中我们介绍了如何使用哈希表来显示简单的选择对话框，而当用户选择了一个对象时，返回完整的对象。

哈希表基本上可以使用任何数据作为键。在前一个例子中，我们使用字符串作为键。它也可以是其它对象。这可以让您做选择对话框的时候十分灵活。

只需要使用 `Select-Object` 来选择希望在网格视图窗口中显示的属性，并且用它来作为哈希表的键。

```powershell
# create a hash table where the key is the selected properties to display, 
# and the value is the original object
$hashTable = Get-WmiObject -Class Win32_NetworkAdapterConfiguration |
    # sort the objects by a property of your choice
    Sort-Object -Property Description |
    # use an ordered hash table to keep sort order
    # (requires PowerShell 3; for older PowerShell remove [Ordered])
    ForEach-Object { $ht = [Ordered]@{}}{
        # specify the properties that you would like to show in a grid view window
        $key = $_ | Select-Object -Property Description, IPAddress, MacAddress
        $ht.Add($key, $_)
    }{$ht}
    Group-Object -Property Description, Index -AsHashTable -AsString

# show the keys in the grid view window
$hashTable.Keys |
    Out-GridView -Title "Select Network Card" -OutputMode Single |
    ForEach-Object {
        # and retrieve the original (full) object by using
        # the selected item as key into your hash table
        $selectedObject = $hashTable[$_]
        $selectedObject | Select-Object -Property *
    }
```

当您运行这段代码时，网格视图窗口显示一个网络适配器的列表，并且只显示选择的属性 (Description、IPAddress 和 MacAddress)。

当用户选择了一个元素，这段代码返回原始的（完整）对象。这样即便网格视图窗口显示的是对象的一部分，整个对象任然可以用。

<!--more-->
本文国际来源：[Using a Grid View Window as a Selection Dialog (Part 2)](http://community.idera.com/powershell/powertips/b/tips/posts/using-a-grid-view-window-as-a-selection-dialog-part-2)
