---
layout: post
date: 2016-11-09 00:00:00
title: "PowerShell 技能连载 - 创建新对象的快速方法"
description: PowerTip of the Day - Fast Approach to Creating New Objects
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
要将一系列信息打包起来的最好方法就是将它们存储在自定义对象中。最简单最快捷的方法就是用 `PSCustomObject`：

```powershell
#requires -Version 3.0
$o = [PSCustomObject]@{
    Date     = Get-Date
    BIOS     = Get-WmiObject -Class Win32_BIOS
    Computer = $env:COMPUTERNAME
    OS       = [Environment]::OSVersion
    Remark   = 'Some remark'
}
```

在大括号内，将一系列信息（或命令执行结果）存储在键中。这将创建一个将包含一系列信息的对象：

    PS C:\> $o

​    
    Date     : 10/28/2016 3:47:27 PM
    BIOS     : \\DESKTOP-7AAMJLF\root\cimv2:Win32_BIOS.Name="1.4.4",SoftwareElementID="1.4.4",SoftwareElementState=3,TargetOpera
               tingSystem=0,Version="DELL   - 1072009"
    Computer : DESKTOP-7AAMJLF
    OS       : Microsoft Windows NT 10.0.14393.0
    Remark   : Some remark


​    
​    
    PS C:\> $o.Remark
    Some remark
    
    PS C:\> $o.OS 
    
    Platform ServicePack Version      VersionString                    
    -------- ----------- -------      -------------                    
     Win32NT             10.0.14393.0 Microsoft Windows NT 10.0.14393.0


​    
    PS C:\> $o.OS.VersionString
    Microsoft Windows NT 10.0.14393.0
    
    PS C:\>

<!--本文国际来源：[Fast Approach to Creating New Objects](http://community.idera.com/powershell/powertips/b/tips/posts/fast-approach-to-creating-new-objects)-->
