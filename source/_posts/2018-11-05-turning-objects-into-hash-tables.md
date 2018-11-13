---
layout: post
date: 2018-11-05 00:00:00
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
- translation
---
在之前的一个技能中我们介绍了如何用 `Get-Member` 获取对象的属性。以下是另一个可以传入任何对象，将它转为一个包含排序属性的哈希表，然后排除所有空白属性的用例。

```powershell
# take an object...
$process = Get-Process -id $pid

# ...and turn it into a hash table
$hashtable = $process | ForEach-Object {

  $object = $_

  # determine the property names in this object and create a
  # sorted list
  $columns = $_ |
    Get-Member -MemberType *Property |
    Select-Object -ExpandProperty Name |
    Sort-Object

  # create an empty hash table
  $hashtable = @{}

  # take all properties, and add keys to the hash table for each property
  $columns | ForEach-Object {
    # exclude empty properties
    if (![String]::IsNullOrEmpty($object.$_))
    {
      # add a key (property) to the hash table with the
      # property value
      $hashtable.$_ = $object.$_
    }
  }
  $hashtable
}


$hashtable | Out-GridView
```

<!--more-->
本文国际来源：[Turning Objects into Hash Tables](http://community.idera.com/database-tools/powershell/powertips/b/tips/posts/turning-objects-into-hash-tables)
