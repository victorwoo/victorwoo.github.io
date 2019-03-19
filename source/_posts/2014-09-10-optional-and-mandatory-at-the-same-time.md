---
layout: post
date: 2014-09-10 11:00:00
title: "PowerShell 技能连载 - 同时支持可选参数和必选参数"
description: PowerTip of the Day - Optional and Mandatory at the Same Time
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
_适用于 PowerShell 所有版本_

一个函数的参数是否能既为可选的，又为必选的呢？这是可以的，基于不同的上下文即可。

一个参数可以在当其它参数存在的时候为必选的，否则为可选的。

    function Connect-Somewhere
    {
     [CmdletBinding(DefaultParameterSetName='A')]
     param
     (
     [Parameter(ParameterSetName='A',Mandatory=$false)]
     [Parameter(ParameterSetName='B',Mandatory=$true)]
     $ComputerName,
     [Parameter(ParameterSetName='B',Mandatory=$false)]
     $Credential
     )
     $chosen = $PSCmdlet.ParameterSetName
     "You have chosen $chosen parameter set."
    }

    # -Computername is optional
    Connect-Somewhere
    # here, -Computername is mandatory
    Connect-Somewhere -Credential test

<!--本文国际来源：[Optional and Mandatory at the Same Time](http://community.idera.com/powershell/powertips/b/tips/posts/optional-and-mandatory-at-the-same-time)-->
