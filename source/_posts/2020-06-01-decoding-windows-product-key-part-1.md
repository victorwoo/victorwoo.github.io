---
layout: post
date: 2020-06-01 00:00:00
title: "PowerShell 技能连载 - 解析 Windows 产品密钥（第 1 部分）"
description: PowerTip of the Day - Decoding Windows Product Key (Part 1)
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
有很多脚本示例，甚至还有密钥恢复工具，它们都承诺会返回完整的产品密钥，但是在许多情况下，返回的密钥不是 Windows 产品密钥。

当您使用密钥恢复工具时，通常会丢失产品密钥，因此没有简单的方法来检查密钥恢复脚本或工具返回的承诺密钥是否正确。

幸运的是，WMI 至少可以返回“部分”产品密钥。这样，您可以验证恢复的密钥是否是有效的。

`SoftwareLicensingProduct` WMI 类返回有关大多数 Microsoft 产品的许可状态的详细信息。下面的此行获取所有以 "Windows" 开头且许可证状态为非 0 的 Microsoft 产品的所有许可信息：

```powershell
PS> Get-CimInstance -ClassName SoftwareLicensingProduct -Filter 'Name LIKE "Windows%" AND LicenseStatus>0'


ADActivationCsvlkPid                           :
ADActivationCsvlkSkuId                         :
ADActivationObjectDN                           :
ADActivationObjectName                         :
ApplicationID                                  : 55c92734-d682-4d71-983e-d6ec3f16059f
AutomaticVMActivationHostDigitalPid2           :
AutomaticVMActivationHostMachineName           :
AutomaticVMActivationLastActivationTime        : 01.01.1601 01:00:00
Description                                    : Windows(R) Operating System, OEM_DM channel
DiscoveredKeyManagementServiceMachineIpAddress :
DiscoveredKeyManagementServiceMachineName      :
DiscoveredKeyManagementServiceMachinePort      : 0
EvaluationEndDate                              : 01.01.1601 01:00:00
ExtendedGrace                                  : 4294967295
GenuineStatus                                  : 0
GracePeriodRemaining                           : 0
IAID                                           :
ID                                             : bd3762d7-270d-4760-8fb3-d829ca45278a
IsKeyManagementServiceMachine                  : 0
KeyManagementServiceCurrentCount               : 4294967295
KeyManagementServiceFailedRequests             : 4294967295
KeyManagementServiceLicensedRequests           : 4294967295
KeyManagementServiceLookupDomain               :
KeyManagementServiceMachine                    :
KeyManagementServiceNonGenuineGraceRequests    : 4294967295
KeyManagementServiceNotificationRequests       : 4294967295
KeyManagementServiceOOBGraceRequests           : 4294967295
KeyManagementServiceOOTGraceRequests           : 4294967295
KeyManagementServicePort                       : 0
KeyManagementServiceProductKeyID               :
KeyManagementServiceTotalRequests              : 4294967295
KeyManagementServiceUnlicensedRequests         : 4294967295
LicenseDependsOn                               :
LicenseFamily                                  : Professional
LicenseIsAddon                                 : False
LicenseStatus                                  : 1
LicenseStatusReason                            : 1074066433
MachineURL                                     :
Name                                           : Windows(R), Professional edition
OfflineInstallationId                          : 563276155667058052465840741114524545879016766601431504369777043
PartialProductKey                              : WFG6P
...
```

不幸的是，此调用需要很长时间才能完成。为了加快速度，请告诉 WMI 您要做什么，以便该调用不会计算您不需要的大量信息。下面的调用仅从所需实例中读取 PartialProductKey 属性，并且速度更快：

```powershell
PS> Get-CimInstance -Query 'Select PartialProductKey From SoftwareLicensingProduct Where Name LIKE "Windows%" AND LicenseStatus>0' | Select-Object -ExpandProperty PartialProductKey

WFG6P
```

<!--本文国际来源：[Decoding Windows Product Key (Part 1)](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/decoding-windows-product-key-part-1)-->

