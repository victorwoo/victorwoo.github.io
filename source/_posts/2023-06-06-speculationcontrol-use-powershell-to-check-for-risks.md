---
layout: post
date: 2023-06-06 00:00:07
title: "PowerShell 技能连载 - SpeculationControl：使用 PowerShell 检查风险"
description: 'PowerTip of the Day - SpeculationControl: Use PowerShell to Check for Risks'
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
微软几年前发布了一个模块（最近 3 周更新），您可以使用该模块来检测您的硬件是否容易受到 Spectre 和 Meltdown 威胁的攻击。要尝试这个功能，请从 PowerShell Gallery 安装该模块：

```powershell
Install-Module -Name SpeculationControl -Scope CurrentUser
```

要运行测试套件并查看结果，请输入以下命令：

```powershell
PS> Get-SpeculationControlSettings
```

这将显示您的计算机的测试结果，可能类似于以下内容：

    For more information about the output below, please refer to https://support.microsoft.com/help/4074629

    Speculation control settings for CVE-2017-5715 [branch target injection]

    Hardware support for branch target injection mitigation is present: True
    Windows OS support for branch target injection mitigation is present: True
    Windows OS support for branch target injection mitigation is enabled: True

    Speculation control settings for CVE-2017-5754 [rogue data cache load]

    Hardware is vulnerable to rogue data cache load: False

    Hardware requires kernel VA shadowing: False

    Speculation control settings for CVE-2018-3639 [speculative store bypass]

    Hardware is vulnerable to speculative store bypass: True
    Hardware support for speculative store bypass disable is present: True
    Windows OS support for speculative store bypass disable is present: True
    Windows OS support for speculative store bypass disable is enabled system-wide: False

    Speculation control settings for CVE-2018-3620 [L1 terminal fault]

    Hardware is vulnerable to L1 terminal fault: False

    Speculation control settings for MDS [microarchitectural data sampling]

    Windows OS support for MDS mitigation is present: True
    Hardware is vulnerable to MDS: False

    Speculation control settings for SBDR [shared buffers data read]

    Windows OS support for SBDR mitigation is present: True
    Hardware is vulnerable to SBDR: True
    Windows OS support for SBDR mitigation is enabled: False

    Speculation control settings for FBSDP [fill buffer stale data propagator]

    Windows OS support for FBSDP mitigation is present: True
    Hardware is vulnerable to FBSDP: True
    Windows OS support for FBSDP mitigation is enabled: False

    Speculation control settings for PSDP [primary stale data propagator]

    Windows OS support for PSDP mitigation is present: True
    Hardware is vulnerable to PSDP: True
    Windows OS support for PSDP mitigation is enabled: False

    Suggested actions

    * Follow the guidance for enabling Windows Client support for speculation control
    mitigations described in https://support.microsoft.com/help/4073119


    BTIHardwarePresent                  : True
    BTIWindowsSupportPresent            : True
    BTIWindowsSupportEnabled            : True
    BTIDisabledBySystemPolicy           : False
    BTIDisabledByNoHardwareSupport      : False
    BTIKernelRetpolineEnabled           : False
    BTIKernelImportOptimizationEnabled  : True
    RdclHardwareProtectedReported       : True
    RdclHardwareProtected               : True
    KVAShadowRequired                   : False
    KVAShadowWindowsSupportPresent      : True
    KVAShadowWindowsSupportEnabled      : False
    KVAShadowPcidEnabled                : False
    SSBDWindowsSupportPresent           : True
    SSBDHardwareVulnerable              : True
    SSBDHardwarePresent                 : True
    SSBDWindowsSupportEnabledSystemWide : False
    L1TFHardwareVulnerable              : False
    L1TFWindowsSupportPresent           : True
    L1TFWindowsSupportEnabled           : False
    L1TFInvalidPteBit                   : 0
    L1DFlushSupported                   : True
    HvL1tfStatusAvailable               : True
    HvL1tfProcessorNotAffected          : True
    MDSWindowsSupportPresent            : True
    MDSHardwareVulnerable               : False
    MDSWindowsSupportEnabled            : False
    FBClearWindowsSupportPresent        : True
    SBDRSSDPHardwareVulnerable          : True
    FBSDPHardwareVulnerable             : True
    PSDPHardwareVulnerable              : True
    FBClearWindowsSupportEnabled        : False


    PS>

<!--本文国际来源：[SpeculationControl: Use PowerShell to Check for Risks](https://blog.idera.com/database-tools/powershell/powertips/speculationcontrol-use-powershell-to-check-for-risks/)-->

