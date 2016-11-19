layout: post
date: 2016-11-09 16:00:00
title: "PowerShell 技能连载 - PSCustomObject 到底如何工作"
description: PowerTip of the Day - How PSCustomObject Really Works
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
在前一个技能中我们介绍了如何快速用 `PSCustomObject` 创建一个新对象：

    $o = [PSCustomObject]@{
        Date     = Get-Date
        BIOS     = Get-WmiObject -Class Win32_BIOS
        Computer = $env:COMPUTERNAME
        OS       = [Environment]::OSVersion
        Remark   = 'Some remark'
    }

实际中，`[PSCustomObject]` 并不是一个类型，并且也不是在转型一个哈希表。这个场景背后实际发生的是两个步骤的组合，您也可以分别执行这两个步骤：

```powershell
#requires -Version 3.0

# create an ordered hash table
$hash = [Ordered]@{
    Date     = Get-Date
    BIOS     = Get-WmiObject -Class Win32_BIOS
    Computer = $env:COMPUTERNAME
    OS       = [Environment]::OSVersion
    Remark   = 'Some remark'
}

# turn hash table in object
$o = New-Object -TypeName PSObject -Property $hash
```

由于这段代码用到了 PowerShell 3.0 引入的排序的哈希表，所以无法在 PowerShell 2.0 中使用相同的做法。要支持 PowerShell 2.0 ，请用无序的（传统的）哈希表代替：

```powershell
#requires -Version 2.0

# create a hash table
$hash = @{
    Date     = Get-Date
    BIOS     = Get-WmiObject -Class Win32_BIOS
    Computer = $env:COMPUTERNAME
    OS       = [Environment]::OSVersion
    Remark   = 'Some remark'
}

# turn hash table in object
$o = New-Object -TypeName PSObject -Property $hash

$o
```

<!--more-->
本文国际来源：[How PSCustomObject Really Works](http://community.idera.com/powershell/powertips/b/tips/posts/how-pscustomobject-really-works)
