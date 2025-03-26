---
layout: post
date: 2023-01-23 06:00:14
title: "PowerShell 技能连载 - 通过 SNMP 查询高级的打印机"
description: PowerTip of the Day - Querying Advanced Printer Info via SNMP
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
许多网络打印机支持使用 SNMP 查询设备信息，例如序列号、状态和纸仓中纸张的大小，以及错误信息。

在 Windows 系统中，操作系统通过 PowerShell 已经提供所有 SNMP 查询所需的组件。您所需要知道的只是打印机的 IP 地址。当然，请确保它已开机并支持 SNMP。

以下是测试脚本：

```powershell
# define your printer network IP here:
$Printer_IP = '192.168.2.200'

# connect to printer:
$SNMP = New-Object -ComObject olePrn.OleSNMP
$SNMP.Open($Printer_IP,'public')

# get device description
$SNMP.Get(".1.3.6.1.2.1.25.3.2.1.3.1")
# get device serial number
$SNMP.Get(".1.3.6.1.2.1.43.5.1.1.17.1")
$SNMP.Close()
```

这段代码非常短小。

更有挑战性的是：除了设备描述和序列号之外您能找到哪些信息？如何知道您可以查询的剩余信息片段的 ID 号。下面是一个最常用的 ID 列表。不过，并非所有打印机都支持所有的 ID：

```powershell
#region list of IDs that you can ask your printer:
# (not all IDs will work with all printers)
$OID_RAW_DATA = ".1.3.6.1.2.1.43.18.1.1"
$OID_CONSOLE_DATA = ".1.3.6.1.2.1.43.16"
$OID_CONTACT = ".1.3.6.1.2.1.1.4.0"
$OID_LOCATION = ".1.3.6.1.2.1.1.6.0"
$OID_SERIAL_NUMBER = ".1.3.6.1.2.1.43.5.1.1.17.1"
$OID_SYSTEM_DESCRIPTION = ".1.3.6.1.2.1.1.1.0"
$OID_DEVICE_DESCRIPTION = ".1.3.6.1.2.1.25.3.2.1.3.1"
$OID_DEVICE_STATE = ".1.3.6.1.2.1.25.3.2.1.5.1"
$OID_DEVICE_ERRORS = ".1.3.6.1.2.1.25.3.2.1.6.1"
$OID_UPTIME = ".1.3.6.1.2.1.1.3.0"
$OID_MEMORY_SIZE = ".1.3.6.1.2.1.25.2.2.0"
$OID_PAGE_COUNT = ".1.3.6.1.2.1.43.10.2.1.4.1.1"
$OID_HARDWARE_ADDRESS = ".1.3.6.1.2.1.2.2.1.6.1"
$OID_TRAY_1_NAME = ".1.3.6.1.2.1.43.8.2.1.13.1.1"
$OID_TRAY_1_CAPACITY = ".1.3.6.1.2.1.43.8.2.1.9.1.1"
$OID_TRAY_1_LEVEL = ".1.3.6.1.2.1.43.8.2.1.10.1.1"
$OID_TRAY_2_NAME = ".1.3.6.1.2.1.43.8.2.1.13.1.2"
$OID_TRAY_2_CAPACITY = ".1.3.6.1.2.1.43.8.2.1.9.1.2"
$OID_TRAY_2_LEVEL = ".1.3.6.1.2.1.43.8.2.1.10.1.2"
$OID_TRAY_3_NAME = ".1.3.6.1.2.1.43.8.2.1.13.1.3"
$OID_TRAY_3_CAPACITY = ".1.3.6.1.2.1.43.8.2.1.9.1.3"
$OID_TRAY_3_LEVEL = ".1.3.6.1.2.1.43.8.2.1.10.1.3"
$OID_TRAY_4_NAME = ".1.3.6.1.2.1.43.8.2.1.13.1.4"
$OID_TRAY_4_CAPACITY = ".1.3.6.1.2.1.43.8.2.1.9.1.4"
$OID_TRAY_4_LEVEL = ".1.3.6.1.2.1.43.8.2.1.10.1.4"
$OID_BLACK_TONER_CARTRIDGE_NAME = ".1.3.6.1.2.1.43.11.1.1.6.1.1"
$OID_BLACK_TONER_CARTRIDGE_CAPACITY = ".1.3.6.1.2.1.43.11.1.1.8.1.1"
$OID_BLACK_TONER_CARTRIDGE_LEVEL = ".1.3.6.1.2.1.43.11.1.1.9.1.1"
$OID_CYAN_TONER_CARTRIDGE_NAME = ".1.3.6.1.2.1.43.11.1.1.6.1.2"
$OID_CYAN_TONER_CARTRIDGE_CAPACITY = ".1.3.6.1.2.1.43.11.1.1.8.1.2"
$OID_CYAN_TONER_CARTRIDGE_LEVEL = ".1.3.6.1.2.1.43.11.1.1.9.1.2"
$OID_MAGENTA_TONER_CARTRIDGE_NAME = ".1.3.6.1.2.1.43.11.1.1.6.1.3"
$OID_MAGENTA_TONER_CARTRIDGE_CAPACITY = ".1.3.6.1.2.1.43.11.1.1.8.1.3"
$OID_MAGENTA_TONER_CARTRIDGE_LEVEL = ".1.3.6.1.2.1.43.11.1.1.9.1.3"
$OID_YELLOW_TONER_CARTRIDGE_NAME = ".1.3.6.1.2.1.43.11.1.1.6.1.4"
$OID_YELLOW_TONER_CARTRIDGE_CAPACITY = ".1.3.6.1.2.1.43.11.1.1.8.1.4"
$OID_YELLOW_TONER_CARTRIDGE_LEVEL = ".1.3.6.1.2.1.43.11.1.1.9.1.4"
$OID_WASTE_TONER_BOX_NAME = ".1.3.6.1.2.1.43.11.1.1.6.1.5"
$OID_WASTE_TONER_BOX_CAPACITY = ".1.3.6.1.2.1.43.11.1.1.8.1.5"
$OID_WASTE_TONER_BOX_LEVEL = ".1.3.6.1.2.1.43.11.1.1.9.1.5"
$OID_BELT_UNIT_NAME = ".1.3.6.1.2.1.43.11.1.1.6.1.6"
$OID_BELT_UNIT_CAPACITY = ".1.3.6.1.2.1.43.11.1.1.8.1.6"
$OID_BELT_UNIT_LEVEL = ".1.3.6.1.2.1.43.11.1.1.9.1.6"
$OID_BLACK_DRUM_UNIT_NAME = ".1.3.6.1.2.1.43.11.1.1.6.1.7"
$OID_BLACK_DRUM_UNIT_CAPACITY = ".1.3.6.1.2.1.43.11.1.1.8.1.7"
$OID_BLACK_DRUM_UNIT_LEVEL = ".1.3.6.1.2.1.43.11.1.1.9.1.7"
$OID_CYAN_DRUM_UNIT_NAME = ".1.3.6.1.2.1.43.11.1.1.6.1.8"
$OID_CYAN_DRUM_UNIT_CAPACITY = ".1.3.6.1.2.1.43.11.1.1.8.1.8"
$OID_CYAN_DRUM_UNIT_LEVEL = ".1.3.6.1.2.1.43.11.1.1.9.1.8"
$OID_MAGENTA_DRUM_UNIT_NAME = ".1.3.6.1.2.1.43.11.1.1.6.1.9"
$OID_MAGENTA_DRUM_UNIT_CAPACITY = ".1.3.6.1.2.1.43.11.1.1.8.1.9"
$OID_MAGENTA_DRUM_UNIT_LEVEL = ".1.3.6.1.2.1.43.11.1.1.9.1.9"
$OID_YELLOW_DRUM_UNIT_NAME = ".1.3.6.1.2.1.43.11.1.1.6.1.10"
$OID_YELLOW_DRUM_UNIT_CAPACITY = ".1.3.6.1.2.1.43.11.1.1.8.1.10"
$OID_YELLOW_DRUM_UNIT_LEVEL = ".1.3.6.1.2.1.43.11.1.1.9.1.10"
#endregion
```
<!--本文国际来源：[Querying Advanced Printer Info via SNMP](https://blog.idera.com/database-tools/powershell/powertips/querying-advanced-printer-info-via-snmp/)-->

