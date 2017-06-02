---
layout: post
date: 2015-05-13 11:00:00
title: "PowerShell 技能连载 - 互斥参数 (2)"
description: PowerTip of the Day - Mutually Exclusive Parameters (Part 2)
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
PowerShell 函数中的互斥参数使用“`ParameterSetName`”属性将参数指定到不同的参数集上（或是参数组上）。

很少人知道可以为一个参数指定多个参数集名。通过这种方法，某个参数可以在一个场景中为可选，但在另外一个场景中为必选。

    function Test-ParameterSet
    {
      [CmdletBinding(DefaultParameterSetName='NonCredential')]
      param
      (
        $id,
    
        [Parameter(ParameterSetName='LocalOnly', Mandatory=$false)]
        $LocalAction,
    
        [Parameter(ParameterSetName='Credential', Mandatory=$true)]
        [Parameter(ParameterSetName='NonCredential', Mandatory=$false)]
        $ComputerName,
    
        [Parameter(ParameterSetName='Credential', Mandatory=$false)]
        $Credential
      )
    
      $PSCmdlet.ParameterSetName
      $PSBoundParameters
    
      if ($PSBoundParameters.ContainsKey('ComputerName'))
      {
        Write-Warning 'Remote Call!'
      }
    }

`Test-ParameterSet` 函数显示了如何实现该功能：当“NonCredential”参数集有效时 `-ComputerName` 是可选的。如果用户使用了 `-Credential` 参数，那么 `-ComputerName` 变成了必选的。而如果用户使用了 `-LocalAction` 参数，那么 `-ComputerName` 和 `-Credential` 都变为不可用的了。

<!--more-->
本文国际来源：[Mutually Exclusive Parameters (Part 2)](http://community.idera.com/powershell/powertips/b/tips/posts/mutually-exclusive-parameters-part-2)
