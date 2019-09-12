---
layout: post
date: 2019-09-11 00:00:00
title: "PowerShell 技能连载 - 检测存储问题"
description: PowerTip of the Day - Detecting Storage Issues
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
在 Windows 10 和 Windows Server 2016 中，PowerShell 可以访问存储可靠性数据，这样您就可以发现其中一个附加的存储驱动器是否有问题。这需要管理员特权来执行：

```powershell
PS> Get-PhysicalDisk | Get-StorageReliabilityCounter

DeviceId Temperature ReadErrorsUncorrected Wear PowerOnHours
-------- ----------- --------------------- ---- ------------
0                                          0
1                                          0
```

要查看所有可用信息，请使用 `Select-Object`：

```powershell
PS> Get-PhysicalDisk | Get-StorageReliabilityCounter | Select-Object -Property *


(...)
DeviceId                : 0
FlushLatencyMax         : 104
LoadUnloadCycleCount    :
LoadUnloadCycleCountMax :
ManufactureDate         :
PowerOnHours            :
ReadErrorsCorrected     :
ReadErrorsTotal         :
ReadErrorsUncorrected   :
ReadLatencyMax          : 1078
StartStopCycleCount     :
StartStopCycleCountMax  :
Temperature             : 1
TemperatureMax          : 1
Wear                    : 0
WriteErrorsCorrected    :
WriteErrorsTotal        :
WriteErrorsUncorrected  :
WriteLatencyMax         : 1128
(...)
FlushLatencyMax         :
LoadUnloadCycleCount    :
LoadUnloadCycleCountMax :
ManufactureDate         :
PowerOnHours            :
ReadErrorsCorrected     :
ReadErrorsTotal         :
ReadErrorsUncorrected   :
ReadLatencyMax          : 46
StartStopCycleCount     :
StartStopCycleCountMax  :
Temperature             : 0
TemperatureMax          : 0
Wear                    : 0
WriteErrorsCorrected    :
WriteErrorsTotal        :
WriteErrorsUncorrected  :
WriteLatencyMax         :
PSComputerName          :
(...)
```

详情和返回数据的数量取决于您的存储制造商和您的驱动器。

<!--本文国际来源：[Detecting Storage Issues](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/detecting-storage-issues)-->

