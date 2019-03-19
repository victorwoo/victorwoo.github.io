---
layout: post
date: 2019-02-25 00:00:00
title: "PowerShell 技能连载 - 管理 Windows 许可证密钥（第 1 部分）"
description: PowerTip of the Day - Managing Windows License Key
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
我们来看看这个单行的解析 Windows 许可证密钥的迷你系列：

```powershell
PS> $key = (Get-WmiObject -Class SoftwareLicensingService).OA3xOriginalProductKey

PS> $key
KJU8F-XXUZH-UU776-IUZGT-HHGR5
```

今日知识点：

* WMI 可以获取许多关于 Windows 许可证和 Windows 许可证状态的信息。
* Windows 用于许可证管理的一个 WMI 名为 "SoftwareLicensingService"。它可以提供 Windows 许可证号码。
* 同一个类叶包含了许多额外的信息。请看：

```powershell
PS> Get-WmiObject -Class SoftwareLicensingService


...
KeyManagementServiceUnlicensedRequests         : 4294967295
OA2xBiosMarkerMinorVersion                     : 1
OA2xBiosMarkerStatus                           : 1
OA3xOriginalProductKey                         : XXXXXXXXX
OA3xOriginalProductKeyDescription              : [4.0] Professional OEM:DM
OA3xOriginalProductKeyPkPn                     : [TH]X19-99481
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

<!--本文国际来源：[Managing Windows License Key](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/managing-windows-license-key)-->
title: "PowerShell 技能连载 - 管理 Windows 许可证密钥"
description: PowerTip of the Day - Managing Windows License Key
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
我们来看看这个单行的解析 Windows 许可证密钥的迷你系列：

```powershell
PS> $key = (Get-WmiObject -Class SoftwareLicensingService).OA3xOriginalProductKey

PS> $key
KJU8F-XXUZH-UU776-IUZGT-HHGR5
```

今日知识点：

* WMI 可以获取许多关于 Windows 许可证和 Windows 许可证状态的信息。
* Windows 用于许可证管理的一个 WMI 名为 "SoftwareLicensingService"。它可以提供 Windows 许可证号码。
* 同一个类叶包含了许多额外的信息。请看：

```powershell
PS> Get-WmiObject -Class SoftwareLicensingService


...
KeyManagementServiceUnlicensedRequests         : 4294967295
OA2xBiosMarkerMinorVersion                     : 1
OA2xBiosMarkerStatus                           : 1
OA3xOriginalProductKey                         : XXXXXXXXX
OA3xOriginalProductKeyDescription              : [4.0] Professional OEM:DM
OA3xOriginalProductKeyPkPn                     : [TH]X19-99481
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

<!--本文国际来源：[Managing Windows License Key](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/managing-windows-license-key)-->
