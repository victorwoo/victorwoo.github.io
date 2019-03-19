---
layout: post
date: 2019-02-28 00:00:00
title: "PowerShell 技能连载 - 管理 Windows 授权密钥（第 4 部分）"
description: PowerTip of the Day - Managing Windows License Key (Part 4)
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
`Slmgr.vbs` 是一个用于自动化 Windows 许可证管理的古老的 VBScript。在前一个技能中我们开始直接读取 WMI，跳过 `slmgr.vbs`。除了已经介绍过的 `SoftwareLicensingService` 类，还有一个 `SoftwareLicensingProduct` 拥有许多实例并且获取需要一些时间：

```powershell
Get-WmiObject -Class SoftwareLicensingProduct | Out-GridView
```

描述列展示了这个类描述了 Windows 中许多不同的可用的许可证类型，只有其中的一部分有获得授权。要获得有用的信息，您需要过滤出正在使用的许可证信息。

用 `-Filter` 参数来使用服务端过滤器可以大大加速查询速度。请确保 WMI 只返回 `ProductKeyId` 非空的实例：

```powershell
Get-WmiObject -Class SoftwareLicensingProduct -Filter 'ProductKeyId != NULL' | Select-Object -Property Name, Description, LicenseStatus, EvaluationEndDate, PartialProductKey, ProductKeyChannel, RemainingAppRearmCount, trustedTime, UseLicenseUrl, ValidationUrl | Out-GridView
```

结果显示在一个网格视图窗口中，看起来类似这样：

    Name                   : Office 16, Office16ProPlusR_Grace edition
    Description            : Office 16, RETAIL(Grace) channel
    LicenseStatus          : 5
    EvaluationEndDate      : 16010101000000.000000-000
    PartialProductKey      : XXXXX
    ProductKeyChannel      : Retail
    RemainingAppRearmCount : 1
    trustedTime            : 20190203111404.180000-000
    UseLicenseUrl          : https://activation.sls.microsoft.com/SLActivateProduct/SLActivateProduct.asmx?c
                             onfigextension=o14
    ValidationUrl          : https://go.microsoft.com/fwlink/?LinkID=187557

    Name                   : Office 16, Office16ProPlusMSDNR_Retail edition
    Description            : Office 16, RETAIL channel
    LicenseStatus          : 1
    EvaluationEndDate      : 16010101000000.000000-000
    PartialProductKey      : XXXXX
    ProductKeyChannel      : Retail
    RemainingAppRearmCount : 1
    trustedTime            : 20190203111404.622000-000
    UseLicenseUrl          : https://activation.sls.microsoft.com/SLActivateProduct/SLActivateProduct.asmx?c
                             onfigextension=o14
    ValidationUrl          : https://go.microsoft.com/fwlink/?LinkID=187557

    Name                   : Windows(R), Professional edition
    Description            : Windows(R) Operating System, OEM_DM channel
    LicenseStatus          : 1
    EvaluationEndDate      : 16010101000000.000000-000
    PartialProductKey      : XXXXX
    ProductKeyChannel      : OEM:DM
    RemainingAppRearmCount : 1001
    trustedTime            : 20190203111405.221000-000
    UseLicenseUrl          : https://activation-v2.sls.microsoft.com/SLActivateProduct/SLActivateProduct.asm
                             x?configextension=DM
    ValidationUrl          : https://validation-v2.sls.microsoft.com/SLWGA/slwga.asmx

如您所见，日期是以 WMI 格式返回的。用 `Get-CimInstance` 代替 `Get-WmiObject` 来获取“真实的”日期对象：

```powershell
PS> Get-CimInstance -Class SoftwareLicensingProduct -Filter 'ProductKeyId != NULL' | Select-Object -Property Name, Description, LicenseStatus, EvaluationEndDate, PartialProductKey, ProductKeyChannel, RemainingAppRearmCount, trustedTime, UseLicenseUrl, ValidationUrl
```

今日知识点：

* 通过 `SoftwareLicensingProduct` WMI 类可以获取到独立的微软产品（包括 Office）许可证信息。
* 如果您希望 PowerShell 返回可阅读的 DateTime 对象，而不是难阅读的 WMI 日期格式，请使用 `Get-CimInstance` 来代替 `Get-WmiObject`。

<!--本文国际来源：[Managing Windows License Key (Part 4)](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/managing-windows-license-key-part-4)-->
