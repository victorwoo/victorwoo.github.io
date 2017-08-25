---
layout: post
date: 2017-08-21 00:00:00
title: "PowerShell 技能连载 - 获取 MAC 制造商列表"
description: PowerTip of the Day - Getting MAC Vendor List
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
Prateek Singh 贡献了一个干净的，CSV 格式的的 MAC 厂商列表。这个列表可以在他的博客 [Get-MACVendor using Powershell – Geekeefy](https://geekeefy.wordpress.com/2017/07/06/get-mac-vendor-using-powershell/) 找到。在通过 MAC 地址确定网络设备的厂商时，这个列表十分有用。

您可以用 PowerShell 方便地将它下载到计算机中：

```powershell
#requires -Version 3.0

$url = 'http://goo.gl/VG9XdU'
$target = "$home\Documents\macvendor.csv"
Invoke-WebRequest -Uri $url -UseBasicParsing -OutFile $target

$content = Import-Csv -Path $target
$content | Out-GridView


With this awesome list, you can now take the first three numbers of any MAC address and find its manufacturer. Here is a simple sample implementation taking the information from Get-NetAdapter, and adding Manufacturer info:

#requires -Modules NetAdapter
#requires -Version 4.0

$url = 'https://raw.githubusercontent.com/PrateekKumarSingh/PowershellScrapy/master/MACManufacturers/MAC_Manufacturer_Reference.csv'
$target = "$home\Documents\macvendor.csv"
$exists = Test-Path -Path $target
if (!$exists)
{
    Invoke-WebRequest -Uri $url -UseBasicParsing -OutFile $target
}

$content = Import-Csv -Path $target

Get-NetAdapter |
    ForEach-Object {
        $macString = $_.MacAddress.SubString(0, 8).Replace('-','')
        $manufacturer = $content.
        Where{$_.Assignment -like "*$macString*"}.
        Foreach{$_.ManufacturerName}

        $_ | 
            Add-Member -MemberType NoteProperty -Name Manufacturer -Value $manufacturer[0] -PassThru |
            Select-Object -Property Name, Mac*, Manufacturer  
    }
```

<!--more-->
本文国际来源：[Getting MAC Vendor List](http://community.idera.com/powershell/powertips/b/tips/posts/getting-mac-vendor-list)
