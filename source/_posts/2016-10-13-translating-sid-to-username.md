layout: post
date: 2016-10-13 00:00:00
title: "PowerShell 技能连载 - 将 SID 翻译为用户名"
description: PowerTip of the Day - Translating SID to Username
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
- translation
---
是否希望将安全标识符（SID）翻译为一个真实的名称？这个函数将能够帮助您：

```powershell
#requires -Version 3.0

function ConvertFrom-SID
{
  param
  (
    [Parameter(Mandatory,ValueFromPipeline,ValueFromPipelineByPropertyName)]
    [Alias('Value')]
    $Sid 
  )

  process
  {
    $objSID = New-Object System.Security.Principal.SecurityIdentifier($sid)
    $objUser = $objSID.Translate( [System.Security.Principal.NTAccount])
    $objUser.Value
  }
}
```

您可以通过参数传入 SID，或通过管道传入一个或多个 SID 给这个函数。

<!--more-->
本文国际来源：[Translating SID to Username](http://community.idera.com/powershell/powertips/b/tips/posts/translating-sid-to-username)
