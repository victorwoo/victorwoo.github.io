---
layout: post
date: 2018-05-01 00:00:00
title: "PowerShell 技能连载 - 列出属性和值（第 2 部分）"
description: PowerTip of the Day - Listing Properties with Values (Part 2)
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
在前一个技能中我们介绍了一个名为 `Remove-EmptyProperty` 的新函数，它能够移除所有没有值的属性。现在让我们将它扩展一点，使它的对象属性按字母顺序排序：

```powershell
# Only list output fields with content

function Remove-EmptyProperty  {
    param (
        [Parameter(Mandatory,ValueFromPipeline)]
            $InputObject,

            [Switch]
            $AsHashTable
    )


    begin
    {
        $props = @()

    }

    process {
        if ($props.COunt -eq 0)
        {
            $props = $InputObject |
            Get-Member -MemberType *Property |
            Select-Object -ExpandProperty Name |
            Sort-Object
        }

        $notEmpty = $props | Where-Object {
            !($InputObject.$_ -eq $null -or
                $InputObject.$_ -eq '' -or
                $InputObject.$_.Count -eq 0) |
            Sort-Object

        }

        if ($AsHashTable)
        {
            $notEmpty |
            ForEach-Object {
                $h = [Ordered]@{}} {
                    $h.$_ = $InputObject.$_
                    } {
                    $h
                    }
        }
        else
        {
            $InputObject |
            Select-Object -Property $notEmpty
        }
    }
}
```

当运行它以后，所有属性将会按字母顺序排序，这样要查找一个特定的属性变得十分容易：

```powershell
PS> Get-Process -Id $pid | Remove-EmptyProperty


__NounName                 : Process
BasePriority               : 8
Company                    : Microsoft Corporation
CPU                        : 162,953125
Description                : Windows PowerShell ISE
FileVersion                : 10.0.16299.15 (WinBuild.160101.0800)
Handle                     : 5708
HandleCount                : 1345
Handles                    : 1345
Id                         : 14340
MachineName                : .
MainModule                 : System.Diagnostics.ProcessModule (PowerShell_ISE.exe)
MainWindowHandle           : 10033714
MainWindowTitle            : C:\Users\tobwe
MaxWorkingSet              : 1413120
MinWorkingSet              : 204800
Modules                    : {System.Diagnostics.ProcessModule (PowerShell_ISE.exe), System.Diagnostics.ProcessModule
                                (ntdll.dll), System.Diagnostics.ProcessModule (MSCOREE.DLL), System.Diagnostics.ProcessModule
                                (KERNEL32.dll)...}
Name                       : powershell_ise
NonpagedSystemMemorySize   : 86544
NonpagedSystemMemorySize64 : 86544
NPM                        : 86544
PagedMemorySize            : 335093760
PagedMemorySize64          : 335093760
PagedSystemMemorySize      : 1277432
PagedSystemMemorySize64    : 1277432
Path                       : C:\WINDOWS\system32\WindowsPowerShell\v1.0\PowerShell_ISE.exe
PeakPagedMemorySize        : 389857280
PeakPagedMemorySize64      : 389857280
PeakVirtualMemorySize      : 1601478656
PeakVirtualMemorySize64    : 1601478656
PeakWorkingSet             : 423972864
PeakWorkingSet64           : 423972864
PM                         : 335093760
PriorityBoostEnabled       : True
PriorityClass              : Normal
PrivateMemorySize          : 335093760
PrivateMemorySize64        : 335093760
PrivilegedProcessorTime    : 00:00:34.2187500
ProcessName                : powershell_ise
ProcessorAffinity          : 15
Product                    : Microsoft® Windows® Operating System
ProductVersion             : 10.0.16299.15
Responding                 : True
SafeHandle                 : Microsoft.Win32.SafeHandles.SafeProcessHandle
SessionId                  : 1
SI                         : 1
StartInfo                  : System.Diagnostics.ProcessStartInfo
StartTime                  : 04.04.2018 08:55:57
Threads                    : {16712, 12844, 15764, 1992...}
TotalProcessorTime         : 00:02:42.9531250
UserProcessorTime          : 00:02:08.7343750
VirtualMemorySize          : 1485922304
VirtualMemorySize64        : 1485922304
VM                         : 1485922304
WorkingSet                 : 354381824
WorkingSet64               : 354381824
WS                         : 354381824
```

<!--more-->
本文国际来源：[Listing Properties with Values (Part 2)](http://community.idera.com/powershell/powertips/b/tips/posts/listing-properties-with-values-part-2)
