---
layout: post
date: 2020-07-07 00:00:00
title: "PowerShell 技能连载 - 识别操作系统详细信息"
description: PowerTip of the Day - Identifying Operating System Details
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
当您查询操作系统详细信息时，WMI 会返回一个数字：

```powershell
PS> Get-CimInstance -ClassName Win32_OperatingSystem |
      Select-Object -ExpandProperty SuiteMask
272
```

SuiteMask 实际上是一个位掩码，其中每个位代表一个特定的细节。要将其转换为可读的文本，请使用标志枚举：

```powershell
$SuiteMask = @{
  Name = 'SuiteMaskText'
  Expression = {
    [Flags()] Enum EnumSuiteMask
    {
      SmallBusinessServer             = 1
      Server2008Enterprise            = 2
      BackOfficeComponents            = 4
      CommunicationsServer            = 8
      TerminalServices                = 16
      SmallBusinessServerRestricted   = 32
      WindowsEmbedded                 = 64
      DatacenterEdition               = 128
      TerminalServicesSingleSession   = 256
      HomeEdition                     = 512
      WebServerEdition                = 1024
      StorageServerEdition            = 8192
      ComputeClusterEdition           = 16384
    }

    [EnumSuiteMask][int]$_.SuiteMask
  }
}

Get-CimInstance -ClassName Win32_OperatingSystem | Select-Object -Property Caption, SuiteMask, $SuiteMask
```

这将添加一个计算得出的 `SuiteMaskText` 属性，该属性列出了已安装的操作系统扩展：


    Caption                  SuiteMask                                   SuiteMaskText
    -------                  ---------                                   -------------
    Microsoft Windows 10 Pro       272 TerminalServices, TerminalServicesSingleSession

<!--本文国际来源：[Identifying Operating System Details](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/identifying-operating-system-details)-->

