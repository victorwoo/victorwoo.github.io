---
layout: post
date: 2017-02-24 00:00:00
title: "PowerShell 技能连载 - 用 Pester Tests 做测试"
description: PowerTip of the Day - Using Pester Tests to Test Anything
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
Pester 是一个随 Windows 10 和 Windows Server 2016 发布的开源模块，可以通过 [PowerShell Gallery](http://www.powershellgallery.com) 免费下载（需要事先安装最新版本的 PowerShellGet）：

```powershell
    PS C:\> Install-Module -Name Pester -Force -SkipPublisherCheck
```

Pester 是一个主要用来测试 PowerShell 代码的测试框架。您不仅可以用它来测试代码，而且可以用它来测试任何东西。以下是一个测试 PowerShell 版本号和一些设置的小例子：

```powershell
Describe 'PowerShell Basic Check' {

  Context 'PS Versioning'   {
    It 'is current version' {
      $host.Version.Major -ge 5 -and $host.Version.Minor -ge 1 | Should Be $true
    }
  }
  Context 'PS Settings'   {
    It 'can execute scripts' {
      (Get-ExecutionPolicy) | Should Not Be 'Restricted'
    }
    It 'does not use AllSigned' {
      (Get-ExecutionPolicy) | Should Not Be 'AllSigned'
    }
    It 'does not have GPO restrictions' {
      (Get-ExecutionPolicy -Scope MachinePolicy) | Should Be 'Undefined'
      (Get-ExecutionPolicy -Scope UserPolicy) | Should Be 'Undefined'
    }
  }
}
```

当您运行它时（当然，前提是已经安装了 Pester 模块），这是得到的输出结果：

```powershell
Describing PowerShell Basic Check

  Context PS Versioning
    [+] is current version 76ms

  Context PS Settings
    [+] can execute scripts 47ms
    [+] does not use AllSigned 18ms
    [+] does not have GPO restrictions 21ms

PS>
```

当然，这只是一个例子。您可以把它做详细并且将测试扩展到更多的其它设置或依赖条件。

<!--more-->
本文国际来源：[Using Pester Tests to Test Anything](http://community.idera.com/powershell/powertips/b/tips/posts/using-pester-tests-to-test-anything)
