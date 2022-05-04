---
layout: post
date: 2022-05-02 00:00:00
title: "PowerShell 技能连载 - 管理蓝牙设备（第 1 部分）"
description: PowerTip of the Day - Managing Bluetooth Devices (Part 1)
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
列出计算机已连接的蓝牙设备只需要一行代码：

```powershell
PS> Get-PnpDevice -Class Bluetooth 

Status Class     FriendlyName                           InstanceId             
------ -----     ------------                           ----------             
OK     Bluetooth Bose QC35 II Avrcp Transport           BTHENUM\{0000110C-00...
OK     Bluetooth Generic Attribute Profile              BTHLEDEVICE\{0000180...
OK     Bluetooth Generic Access Profile                 BTHLEDEVICE\{0000180...
OK     Bluetooth Generic Attribute Profile              BTHLEDEVICE\{0000180...
OK     Bluetooth Bamboo Ink Plus                        BTHLE\DEV_006FF2E608...
OK     Bluetooth Bose QC35 II Avrcp Transport           BTHENUM\{0000110E-00...
OK     Bluetooth Generic Attribute Profile              BTHLEDEVICE\{0000180...
OK     Bluetooth SMA001d SN: 2110109033 SN2110109033    BTHENUM\DEV_0080251B...
OK     Bluetooth MX Master 3                            BTHLE\DEV_D304DEE615...
OK     Bluetooth Bluetooth LE Generic Attribute Service BTHLEDEVICE\{0000FE5...
OK     Bluetooth Microsoft Bluetooth LE Enumerator      BTH\MS_BTHLE\6&1B2C8...
OK     Bluetooth Device Information Service             BTHLEDEVICE\{0000180...
OK     Bluetooth Bluetooth LE Generic Attribute Service BTHLEDEVICE\{0000180...
OK     Bluetooth Device Information Service             BTHLEDEVICE\{0000180...
OK     Bluetooth Generic Access Profile                 BTHLEDEVICE\{0000180...
OK     Bluetooth Bluetooth LE Generic Attribute Service BTHLEDEVICE\{0001000...
OK     Bluetooth Bluetooth LE Generic Attribute Service BTHLEDEVICE\{0000180...
OK     Bluetooth MX Keys                                BTHLE\DEV_D9FDB81EAB...
OK     Bluetooth Device Information Service             BTHLEDEVICE\{0000180...
OK     Bluetooth Microsoft Bluetooth Enumerator         BTH\MS_BTHBRB\6&1B2C...
OK     Bluetooth Generic Access Profile                 BTHLEDEVICE\{0000180...
OK     Bluetooth Bluetooth LE Generic Attribute Service BTHLEDEVICE\{0001000...
OK     Bluetooth Intel(R) Wireless Bluetooth(R)         USB\VID_8087&PID_002...
OK     Bluetooth Bluetooth Device (RFCOMM Protocol TDI) BTH\MS_RFCOMM\6&1B2C...
OK     Bluetooth Bluetooth LE Generic Attribute Service BTHLEDEVICE\{0000180...
OK     Bluetooth Bose QC35 II                           BTHENUM\DEV_2811A579... 
```

要根据名称搜索特定的蓝牙设备，请尝试下面一行代码。它会查找名称中带有 "Bose" 的所有设备：

```powershell
PS> Get-PnpDevice -Class Bluetooth -FriendlyName *Bose*

Status     Class           FriendlyName
------     -----           ------------
OK         Bluetooth       Bose QC35 II Avrcp Transport
OK         Bluetooth       Bose QC35 II Avrcp Transport
OK         Bluetooth       Bose QC35 II
```

通过添加 `Select-Object`，您还可以显示蓝牙设备的其他详细信息：

```powershell
PS> Get-PnpDevice -Class Bluetooth  | 
    Select-Object -Property Caption, Manufacturer, Service

Caption                                Manufacturer      Service
-------                                ------------      -------
Bose QC35 II Avrcp Transport           Microsoft         Microsoft_Bluetooth_AvrcpTransport
Generic Attribute Profile              Microsoft         UmPass
Generic Access Profile                 Microsoft         UmPass
Generic Attribute Profile              Microsoft         UmPass
Bamboo Ink Plus                        Microsoft         BthLEEnum
Bose QC35 II Avrcp Transport           Microsoft         Microsoft_Bluetooth_AvrcpTransport
Generic Attribute Profile              Microsoft         UmPass
SMA001d SN: 2110109033 SN2110109033    Microsoft                                           
MX Master 3                            Microsoft         BthLEEnum
Bluetooth LE Generic Attribute Service Microsoft         UmPass
Microsoft Bluetooth LE Enumerator      Microsoft         BthLEEnum
Device Information Service             Microsoft         UmPass                            
Bluetooth LE Generic Attribute Service Microsoft         UmPass                            
Device Information Service             Microsoft         UmPass
Generic Access Profile                 Microsoft         UmPass
Bluetooth LE Generic Attribute Service Microsoft         UmPass
Bluetooth LE Generic Attribute Service Microsoft         UmPass
MX Keys                                Microsoft         BthLEEnum
Device Information Service             Microsoft         UmPass
Microsoft Bluetooth Enumerator         Microsoft         BthEnum
Generic Access Profile                 Microsoft         UmPass
Bluetooth LE Generic Attribute Service Microsoft         UmPass
Intel(R) Wireless Bluetooth(R)         Intel Corporation BTHUSB
Bluetooth Device (RFCOMM Protocol TDI) Microsoft         RFCOMM
Bluetooth LE Generic Attribute Service Microsoft         UmPass
Bose QC35 II                           Microsoft   
```

当您使用名词 "PnPDevice" 搜索其他 cmdlet 时，还可以发现启用或禁用的命令：

```powershell
PS> Get-Command -Noun PnPDevice

CommandType Name              Version Source
----------- ----              ------- ------
Function    Disable-PnpDevice 1.0.0.0 PnpDevice
Function    Enable-PnpDevice  1.0.0.0 PnpDevice
Function    Get-PnpDevice     1.0.0.0 PnpDevice
```

要了解如何确定当前连接状态并完全删除蓝牙设备，请参阅我们的下一个提示。

<!--本文国际来源：[Managing Bluetooth Devices (Part 1)](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/managing-bluetooth-devices-part-1)-->

