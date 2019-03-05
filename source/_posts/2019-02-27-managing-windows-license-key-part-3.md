---
layout: post
date: 2019-02-27 00:00:00
title: "PowerShell 技能连载 - 管理 Windows 授权密钥（第 3 部分）"
description: PowerTip of the Day - Managing Windows License Key (Part 3)
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
多数 Windows 许可证激活任务可以通过一个古老的名为 `slmgr.vbs` 的 VBScript 来实现自动化。不过，用这个工具来获取信息的意义不大。因为 `slmgr.vbs` 使用的事本地化的字符串，并且将所有数据转换为一个大字符串格式。

一个更好的方法是跳过 `slmgr.vbs`，而直接查询信息源。要搞清 `slmgr.vbs` 如何实现这些功能，您可以查看该脚本的源码。请在 PowerShell ISE 中运行这段代码：

```powershell
# get the path to the script file
$Path = Get-Command slmgr.vbs | Select-Object -ExpandProperty Source
# load the script file
$file = $psise.CurrentPowerShellTab.Files.Add($Path)
```

让我开始将这部分功能转换为 PowerShell。例如 `/dlv` 参数显示许可证信息：

```powershell
PS> slmgr.vbs /dlv
```

当您在 VBScript 源码中搜索 "dlv"，能快速找到所有相关的核心代码，有一个名为 `GetServiceObject()` 的函数，是关于简单 WMI 查询的：

```powershell
g_objWMIService.ExecQuery("SELECT " & strQuery & " FROM " & ServiceClass)
```

实际上，该脚本展现了关于许可证方面的 WMI 类。从 PowerShell 中您可以方便地查询所有跟它有关的服务信息：

```powershell
PS> Get-WmiObject -Class SoftwareLicensingService


__GENUS                                        : 2
__CLASS                                        : SoftwareLicensingService
__SUPERCLASS                                   : 
__DYNASTY                                      : SoftwareLicensingService
__RELPATH                                      : SoftwareLicensingService.Version="10.0.17134.471"
__PROPERTY_COUNT                               : 38
__DERIVATION                                   : {}
__SERVER                                       : DESKTOP-7AAMJLF
__NAMESPACE                                    : root\cimv2
__PATH                                         : \\DESKTOP-7AAMJLF\root\cimv2:SoftwareLicensingService.Version="10.0.17134.471"
ClientMachineID                                : 
DiscoveredKeyManagementServiceMachineIpAddress : 
DiscoveredKeyManagementServiceMachineName      : 
DiscoveredKeyManagementServiceMachinePort      : 0
IsKeyManagementServiceMachine                  : 0
KeyManagementServiceCurrentCount               : 4294967295
KeyManagementServiceDnsPublishing              : True
KeyManagementServiceFailedRequests             : 4294967295
KeyManagementServiceHostCaching                : True
KeyManagementServiceLicensedRequests           : 4294967295
KeyManagementServiceListeningPort              : 1688
KeyManagementServiceLookupDomain               : 
KeyManagementServiceLowPriority                : False
KeyManagementServiceMachine                    : 
KeyManagementServiceNonGenuineGraceRequests    : 4294967295
KeyManagementServiceNotificationRequests       : 4294967295
KeyManagementServiceOOBGraceRequests           : 4294967295
KeyManagementServiceOOTGraceRequests           : 4294967295
KeyManagementServicePort                       : 1688
KeyManagementServiceProductKeyID               : 
KeyManagementServiceTotalRequests              : 4294967295
KeyManagementServiceUnlicensedRequests         : 4294967295
OA2xBiosMarkerMinorVersion                     : 1
OA2xBiosMarkerStatus                           : 1
OA3xOriginalProductKey                         : XXXXXXXXXXXXXXXXXXXXXXXXX
OA3xOriginalProductKeyDescription              : [4.0] Professional OEM
OA3xOriginalProductKeyPkPn                     : [TH]XXXXXXX
PolicyCacheRefreshRequired                     : 0
RemainingWindowsReArmCount                     : 1001
RequiredClientCount                            : 4294967295
TokenActivationAdditionalInfo                  : 
TokenActivationCertificateThumbprint           : 
TokenActivationGrantNumber                     : 4294967295
TokenActivationILID                            : 
TokenActivationILVID                           : 4294967295
Version                                        : 10.0.17134.471
VLActivationInterval                           : 4294967295
VLRenewalInterval                              : 4294967295
PSComputerName                                 : DESKTOP-7AAMJLF
```

和 `slmgr.vbs` 不同，您可以以面向对象的格式获得该信息，所以访问具体的项十分容易：

```powershell
PS> $all = Get-WmiObject -Class SoftwareLicensingService

PS> $all.OA3xOriginalProductKeyDescription
[4.0] Professional OEM:DM
 

funcValue 1
}
```

还有更多内容可以发现。

今日知识点：

* `slmgr.vbs` 返回的所有 Windows 许可证信息都来自 WMI。相比于 `slmgr.vbs` 收到的是难以阅读的文本，您可以直接查询 WMI 并跳过 `slmgr.vbs`。
* 一个大数据源是 `SoftwareLicensingService` WMI 类。

<!--本文国际来源：[Managing Windows License Key (Part 3)](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/managing-windows-license-key-part-3)-->
