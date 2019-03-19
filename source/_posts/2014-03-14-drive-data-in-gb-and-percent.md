---
layout: post
title: "PowerShell 技能连载 - 以 GB 和百分比的形式显示驱动器容量"
date: 2014-03-14 00:00:00
description: PowerTip of the Day - Drive Data in GB and Percent
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
当一个 cmdlet 返回原始数据时，您可能希望将数据转换为一个更好的格式。例如，WMI 可以汇报驱动器的剩余空间，但是是以字节为单位的。

您可以使用 `Select-Object` 并且传入一个哈希表来将原始数据转换为您希望的格式。这个例子演示了如何将剩余空间转换为以 GB 为单位，并且计算剩余空间的百分比：

    $Freespace =
    @{
      Expression = {[int]($_.Freespace/1GB)}
      Name = 'Free Space (GB)'
    }

    $PercentFree =
    @{
      Expression = {[int]($_.Freespace*100/$_.Size)}
      Name = 'Free (%)'
    }

    Get-WmiObject -Class Win32_LogicalDisk |
      Select-Object -Property DeviceID, VolumeName, $Freespace, $PercentFree



以下是不使用哈希表的结果：

![](/img/2014-03-14-drive-data-in-gb-and-percent-001.png)

这是使用了哈希表的结果：

![](/img/2014-03-14-drive-data-in-gb-and-percent-002.png)

<!--本文国际来源：[Drive Data in GB and Percent](http://community.idera.com/powershell/powertips/b/tips/posts/drive-data-in-gb-and-percent)-->
