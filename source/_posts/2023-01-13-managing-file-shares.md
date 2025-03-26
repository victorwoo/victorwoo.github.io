---
layout: post
date: 2023-01-13 21:43:12
title: "PowerShell 技能连载 - 管理文件共享"
description: PowerTip of the Day - Managing File Shares
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
Windows 操作系统自带了 "Storage" PowerShell 模块，它可以同时用于 Windows PowerShell 和 PowerShell 7。


这个模块可以管理许多东西，其中之一是文件共享，不过需要管理员特权来运行以下命令。

要获取文件共享的清单（可以通过网络访问的本地文件夹），请试着执行以下代码：

```powershell
PS C:\> Get-FileShare

Name   HealthStatus OperationalStatus
----   ------------ -----------------
ADMIN$ Healthy      Online
C$     Healthy      Online
print$ Healthy      Online



PS C:\> Get-FileShare -Name c$

Name HealthStatus OperationalStatus
---- ------------ -----------------
C$   Healthy      Online


PS C:\> Get-FileShare -Name c$ | Select-Object -Property *


HealthStatus          : Healthy
OperationalStatus     : Online
ShareState            : Online
FileSharingProtocol   : SMB
ObjectId              : {1}\\DELL7390\root/Microsoft/Windows/Storage/Providers_v2\WSP_FileShare.ObjectId="{c0c2f698-c81d-11e9-9f6f-80
                        6e6f6e6963}:FX:SMB||*||C$"
PassThroughClass      :
PassThroughIds        :
PassThroughNamespace  :
PassThroughServer     :
UniqueId              : smb|DELL7390/C$
ContinuouslyAvailable : False
Description           : Standardfreigabe
EncryptData           : False
Name                  : C$
VolumeRelativePath    : \
PSComputerName        :
CimClass              : ROOT/Microsoft/Windows/Storage:MSFT_FileShare
CimInstanceProperties : {ObjectId, PassThroughClass, PassThroughIds, PassThroughNamespace...}
CimSystemProperties   : Microsoft.Management.Infrastructure.CimSystemProperties
```

类似地，其它动词可以执行相关的任务，例如改变一个已有的共享 (`Set`) 或者创建一个新的共享 (`New`)：

```powershell
PS C:\> Get-Command -Noun FileShare

CommandType     Name                                               Version    Source
-----------     ----                                               -------    ------
Function        Debug-FileShare                                    2.0.0.0    Storage
Function        Get-FileShare                                      2.0.0.0    Storage
Function        New-FileShare                                      2.0.0.0    Storage
Function        Remove-FileShare                                   2.0.0.0    Storage
Function        Set-FileShare                                      2.0.0.0    Storage
```
<!--本文国际来源：[Managing File Shares](https://blog.idera.com/database-tools/powershell/powertips/managing-file-shares/)-->

