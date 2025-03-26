---
layout: post
date: 2023-07-07 12:00:33
title: "PowerShell 技能连载 - 选择最佳的文件格式（第 4 部分）"
description: PowerTip of the Day - Choosing Best File Format (Part 4)
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
在之前的部分中，我们回顾了不同的文件类型以持久化数据，并了解了用于读写这些文件的 cmdlets。

今天，让我们将这些知识应用到一个真实的数据文件中，你可以自己创建它（前提是你拥有一台带有 Windows 系统的笔记本电脑，并带有电池供电）。

```powershell
$Path = "$env:temp\battery.xml"
powercfg.exe /batteryreport /duration 1 /output $path /xml
```

运行这行代码后，它会生成一个包含所有电池信息的XML文件，包括设计容量和实际容量，这样你就可以查看电池的状态是否良好。从前面的代码示例中选择适当的代码，读取XML文件的内容：

```powershell
# path to XML file:
$Path = "$env:temp\battery.xml"

# read file and convert to XML:
[xml]$xml = Get-Content -Path $Path -Raw -Encoding UTF8
```

接下来，在您喜爱的编辑器中，通过在$xml中添加“.”来探索XML的对象结构，并查看 IntelliSense 或通过简单地输出变量来查看，这样 PowerShell 会打印下一个级别的属性名称。

通过这种方式，我找到了电池容量信息：

```powershell
PS> $xml

xml                            xml-stylesheet                                   BatteryReport
---                            --------------                                   -------------
version="1.0" encoding="utf-8" type='text/xsl' href='C:\battery-stylesheet.xsl' BatteryReport

PS> $xml.BatteryReport

xmlns             : http://schemas.microsoft.com/battery/2012
ReportInformation : ReportInformation
SystemInformation : SystemInformation
Batteries         : Batteries
RuntimeEstimates  : RuntimeEstimates
RecentUsage       : RecentUsage
History           : History
EnergyDrains      :

PS> $xml.BatteryReport.Batteries
Battery
-------
Battery

PS> $xml.BatteryReport.Batteries.Battery

Id                 : DELL XX3T797
Manufacturer       : BYD
SerialNumber       : 291
ManufactureDate    :
Chemistry          : LiP
LongTerm           : 1
RelativeCapacity   : 0
DesignCapacity     : 49985
FullChargeCapacity : 32346
CycleCount         : 0
```

现在我们可以将所有部分组合成一个脚本，返回面向对象的电池磨损信息（确保您的系统有电池，否则会出现红色异常）：

```powershell
# temp path to XML file:
$Path = "$env:temp\battery$(Get-Date -Format yyyyMMddHHmmssffff).xml"
# generate XML file
powercfg.exe /batteryreport /duration 1 /output $path /xml
# read file and convert to XML:
[xml]$xml = Get-Content -Path $Path -Raw -Encoding UTF8
# remove temporary file:
Remove-Item -Path $Path
# show battery infos:
$xml.BatteryReport.Batteries.Battery
```

只需非常少的努力，相同的内容可以成为一个有用的新命令。

```powershell
function Get-BatteryCapacity
{
    # temp path to XML file:
    $Path = "$env:temp\battery$(Get-Date -Format yyyyMMddHHmmssffff).xml"
    # generate XML file
    powercfg.exe /batteryreport /duration 1 /output $path /xml
    # read file and convert to XML:
    [xml]$xml = Get-Content -Path $Path -Raw -Encoding UTF8
    # remove temporary file:
    Remove-Item -Path $Path
    # show battery infos:
    $xml.BatteryReport.Batteries.Battery
}
```

现在轻松检查电池磨损：

```powershell
PS> Get-BatteryCapacity | Select-Object Id, Manufacturer, FullChargeCapacity, DesignCapacity

Id           Manufacturer FullChargeCapacity DesignCapacity

--           ------------ ------------------ --------------

DELL XX3T797 BYD          32346              49985
```

使用哈希表，`Select-Object` 现在甚至可以计算剩余电池容量的百分比（但这是我们今天不会深入探讨的另一个话题）：

```powershell
PS> Get-BatteryCapacity | Select-Object Id, Manufacturer, FullChargeCapacity, @{N='Remain';E={'{0:P}' -f ($_.FullChargeCapacity/$_.DesignCapacity)}}
Id           Manufacturer FullChargeCapacity Remain
--           ------------ ------------------ ------

DELL XX3T797 BYD          32346              64,71 %
```
<!--本文国际来源：[Choosing Best File Format (Part 4)](https://blog.idera.com/database-tools/choosing-best-file-format-part-4/)-->

