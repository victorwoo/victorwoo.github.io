---
layout: post
date: 2022-04-18 00:00:00
title: "PowerShell 技能连载 - 利用 WMI（第 2 部分）"
description: PowerTip of the Day - Leveraging WMI (Part 2)
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
查询 WMI 类时，一开始可能无法取回所有信息：

```powershell
PS> Get-CimInstance -ClassName Win32_LogicalDisk

DeviceID DriveType ProviderName   VolumeName Size          FreeSpace   
-------- --------- ------------   ---------- ----          ---------   
C:       3                        OS         1007210721280 227106992128
Z:       4         \\127.0.0.1\c$ OS         1007210721280 227106988032
```

确保加上 `Select-Object` 以获得完整的信息集：

```powershell
PS> Get-CimInstance -ClassName Win32_LogicalDisk | Select-Object -Property *


Status                       : 
Availability                 : 
DeviceID                     : C:
StatusInfo                   : 
Caption                      : C:
Description                  : Local Fixed Disk
InstallDate                  : 
Name                         : C:
ConfigManagerErrorCode       : 
ConfigManagerUserConfig      : 
CreationClassName            : Win32_LogicalDisk
ErrorCleared                 : 
ErrorDescription             : 
LastErrorCode                : 
PNPDeviceID                  : 
PowerManagementCapabilities  : 
PowerManagementSupported     : 
SystemCreationClassName      : Win32_ComputerSystem
SystemName                   : DELL7390
Access                       : 0
BlockSize                    : 
ErrorMethodology             : 
NumberOfBlocks               : 
Purpose                      : 
FreeSpace                    : 227111596032
Size                         : 1007210721280
Compressed                   : False
DriveType                    : 3
FileSystem                   : NTFS
MaximumComponentLength       : 255
MediaType                    : 12
ProviderName                 : 
QuotasDisabled               : 
QuotasIncomplete             : 
QuotasRebuilding             : 
SupportsDiskQuotas           : False
SupportsFileBasedCompression : True
VolumeDirty                  : 
VolumeName                   : OS
VolumeSerialNumber           : DAD43A43
PSComputerName               : 
CimClass                     : root/cimv2:Win32_LogicalDisk
CimInstanceProperties        : {Caption, Description, InstallDate, Name...}
CimSystemProperties          : Microsoft.Management.Infrastructure.CimSystemProperties

Status                       : 
Availability                 : 
DeviceID                     : Z:
StatusInfo                   : 
Caption                      : Z:
Description                  : Network Connection
InstallDate                  : 
Name                         : Z:
ConfigManagerErrorCode       : 
ConfigManagerUserConfig      : 
CreationClassName            : Win32_LogicalDisk
ErrorCleared                 : 
ErrorDescription             : 
LastErrorCode                : 
PNPDeviceID                  : 
PowerManagementCapabilities  : 
PowerManagementSupported     : 
SystemCreationClassName      : Win32_ComputerSystem
SystemName                   : DELL7390
Access                       : 0
BlockSize                    : 
ErrorMethodology             : 
NumberOfBlocks               : 
Purpose                      : 
FreeSpace                    : 227111596032
Size                         : 1007210721280
Compressed                   : False
DriveType                    : 4
FileSystem                   : NTFS
MaximumComponentLength       : 255
MediaType                    : 0
ProviderName                 : \\127.0.0.1\c$
QuotasDisabled               : 
QuotasIncomplete             : 
QuotasRebuilding             : 
SupportsDiskQuotas           : False
SupportsFileBasedCompression : True
VolumeDirty                  : 
VolumeName                   : OS
VolumeSerialNumber           : DAD43A43
PSComputerName               : 
CimClass                     : root/cimv2:Win32_LogicalDisk
CimInstanceProperties        : {Caption, Description, InstallDate, Name...}
CimSystemProperties          : Microsoft.Management.Infrastructure.CimSystemProperties
```

现在您看到了所有属性，并且可以选择真正需要的项目：

```powershell     
PS> Get-CimInstance -ClassName Win32_LogicalDisk | Select-Object -Property DeviceId, Description, FreeSpace, FileSystem

DeviceId Description           FreeSpace FileSystem
-------- -----------           --------- ----------
C:       Local Fixed Disk   227110989824 NTFS      
Z:       Network Connection 227110989824 NTFS  
```

<!--本文国际来源：[Leveraging WMI (Part 2)](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/leveraging-wmi-part-2)-->

