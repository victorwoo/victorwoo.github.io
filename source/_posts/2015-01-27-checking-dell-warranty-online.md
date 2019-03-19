---
layout: post
date: 2015-01-27 12:00:00
title: "PowerShell 技能连载 - 在线检测 DELL 保修"
description: PowerTip of the Day - Checking DELL Warranty Online
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
_适用于 PowerShell 2.0 及以上版本_

如果您拥有一台 DELL 电脑，您可以通过 Web Service 提交电脑的序列号得到授权信息：

    $serial = '36GPL41'

    $service = New-WebServiceProxy -Uri http://143.166.84.118/services/assetservice.asmx?WSDL
    $guid = [Guid]::NewGuid()

    $info = $service.GetAssetInformation($guid,'warrantycheck',$serial)
    $info.Entitlements

结果可能看起来如下：

    $info.Entitlements


    ServiceLevelCode        : TS
    ServiceLevelDescription : P, ProSupport
    Provider                : DELL
    StartDate               : 23.03.2004 00:00:00
    EndDate                 : 23.03.2007 00:00:00
    DaysLeft                : 0
    EntitlementType         : Expired

    ServiceLevelCode        : ND
    ServiceLevelDescription : C, NBD ONSITE
    Provider                : UNY
    StartDate               : 23.03.2005 00:00:00
    EndDate                 : 23.03.2007 00:00:00
    DaysLeft                : 0
    EntitlementType         : Expired

    ServiceLevelCode        : ND
    ServiceLevelDescription : C, NBD ONSITE
    Provider                : UNY
    StartDate               : 23.03.2004 00:00:00
    EndDate                 : 24.03.2005 00:00:00
    DaysLeft                : 0
    EntitlementType         : Expired

这些从 Web Service 返回的信息还包括了其它有用的信息，例如计算机的系统类型：

    PS> $info.AssetHeaderData


    ServiceTag     : 36GPL41
    SystemID       : PLX_PNT_CEL_GX270
    Buid           : 11
    Region         : Americas
    SystemType     : OptiPlex
    SystemModel    : GX270
    SystemShipDate : 23.03.2004 07:00:00

<!--本文国际来源：[Checking DELL Warranty Online](http://community.idera.com/powershell/powertips/b/tips/posts/checking-dell-warranty-online)-->
