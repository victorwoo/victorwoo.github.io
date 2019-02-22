---
layout: post
date: 2017-08-25 00:00:00
title: "PowerShell 技能连载 - 创建一个清单式的摘要对象"
description: PowerTip of the Day - Create Summary Objects for Inventory
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
从 PowerShell 3 开始，`PSCustomObject` 可以将从其他地方收集的有用信息方便地合并进来。以下例子从不同的 WMI 类获取各种信息，并且输出为一个清单。该清单可以传递给其它命令，也可以直接使用：

```powershell
# get information from this computer
$Computername = "."

# get basic information (i.e. from WMI)
$comp = Get-WmiObject -Class Win32_ComputerSystem -ComputerName $Computername
$bios = Get-WmiObject -Class Win32_bios -ComputerName $Computername
$os = Get-WmiObject -Class Win32_OperatingSystem -ComputerName $Computername


# combine everything important in one object
[PSCustomObject]@{
    ComputerName = $Computername
    Timestamp = (Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
    Model = $comp.Model
    Manufacturer = $comp.Manufacturer
    BIOSVersion = $bios.SMbiosbiosversion
    BIOSSerialNumber = $bios.serialnumber
    OSVersion = $os.Version
    InstallDate = $os.ConvertToDateTime( $os.InstallDate)
    LastBoot = $os.ConvertToDateTime($os.lastbootuptime)
    LoggedOnUser = $Comp.UserName
}
```

<!--本文国际来源：[Create Summary Objects for Inventory](http://community.idera.com/powershell/powertips/b/tips/posts/create-summary-objects-for-inventory)-->
