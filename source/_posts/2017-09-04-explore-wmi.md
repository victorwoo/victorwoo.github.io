---
layout: post
date: 2017-09-04 00:00:00
title: "PowerShell 技能连载 - 探索 WMI"
description: PowerTip of the Day - Explore WMI
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---

如果您知道 WMI 类查询的名字，`Get-WmiObject` 和 `Get-CimInstance` 两个命令都可以提供丰富的信息。

以下是一个名为 `Explore-WMI` 的快速的 PowerShell 函数，它可以帮您查找有用的 WMI 类名：

```powershell
function Explore-WMI
{
  # find all WMI classes that start with "Win32_"...
  $class = Get-WmiObject -Class Win32_* -List |
  # exclude performance counter classes...
  Where-Object { $_.Name -notlike 'Win32_Perf*' } |
  # exclude classes with less than 6 properties...
  Where-Object { $_.Properties.Count -gt 5 } |
  # let the user select one of the found classes
  Out-GridView -Title 'Select one' -OutputMode Single

  # display selected class name
  Write-Warning "Klassenname: $($class.Name)"

  # query class...
  Get-WmiObject -Class $class.Name |
  # and show all of its properties
  Select-Object -Property *


  # output code
  $name = $class.name
  " Get-WmiObject -Class $name | Select-Object -property *" | clip.exe

  Write-Warning 'Code copied to clipboard. Paste code to try'
}
```

当运行完这段代码后，调用 `Explore-WMI` 命令，它将会打开一个 grid view 窗口，显示所有以 "Win32_" 开头的 WMI 类，并且不包括性能计数器类，并且暴露至少 6 个属性。您接下来可以选择其中一个。PowerShell 将会显示这个类的实例和它的所有数据，然后将生成这些结果的命令复制到剪贴板。

通过这种方式可以方便有趣地在 WMI 中搜索有用的信息，并且获取得到这些信息的代码。

<!--本文国际来源：[Explore WMI](http://community.idera.com/powershell/powertips/b/tips/posts/explore-wmi)-->
