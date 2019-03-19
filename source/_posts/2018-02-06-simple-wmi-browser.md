---
layout: post
date: 2018-02-06 00:00:00
title: "PowerShell 技能连载 - 简易的 WMI 浏览器"
description: PowerTip of the Day - Simple WMI Browser
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
WMI 是一个丰富的信息库——如果您知道 WMI 的类名：

```powershell
Get-CimInstance -ClassName Win32_BIOS
Get-CimInstance -ClassName Win32_Share
Get-CimInstance -ClassName Win32_OperatingSystem
```

如果您想探索 WMI 的内容，那么以下代码会十分便利。`Find-WmiClass` 接受一个简单的关键字，例如 "video"、"network"、"ipaddress"。接下来它可以获取所有类名、某个属性名或方法名包含该关键字的 WMI 类。

```powershell
function Find-WmiClass
{
    param([Parameter(Mandatory)]$Keyword)

    Write-Progress -Activity "Finding WMI Classes" -Status "Searching"

    # find all WMI classes...
    Get-WmiObject -Class * -List |
    # that contain the search keyword
    Where-Object {
        # is there a property or method with the keyword?
        $containsMember = ((@($_.Properties.Name) -like "*$Keyword*").Count -gt 0) -or ((@($_.Methods.Name) -like "*$Keyword*").Count -gt 0)
        # is the keyword in the class name, and is it an interesting type of class?
        $containsClassName = $_.Name -like "*$Keyword*" -and $_.Properties.Count -gt 2 -and $_.Name -notlike 'Win32_Perf*'
        $containsMember -or $containsClassName
    }
    Write-Progress -Activity "Find WMI Classes" -Completed
}

$classes = Find-WmiClass

$classes |
    # let the user select one of the found classes
    Out-GridView -Title "Select WMI Class" -OutputMode Single |
    ForEach-Object {
        # get all instances of the selected class
        Get-CimInstance -Class $_.Name |
            # show all properties
            Select-Object -Property * |
            Out-GridView -Title "Instances"
    }
```

接下来用户可以选择某个找到的类，该代码将显示这个类的实际实例。

声明：有部分类有几千个实例，例如 CIM_File。当选择了一个有这么多实例的 WMI 类时，该脚本将执行很长时间才能完成。

<!--本文国际来源：[Simple WMI Browser](http://community.idera.com/powershell/powertips/b/tips/posts/simple-wmi-browser)-->
