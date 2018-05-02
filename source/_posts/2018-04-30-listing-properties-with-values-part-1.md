---
layout: post
date: 2018-04-30 00:00:00
title: "PowerShell 技能连载 - 列出属性和值（第 1 部分）"
description: PowerTip of the Day - Listing Properties with Values (Part 1)
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
对象中有丰富的信息，但是对象也可能有空的属性。尤其是从 Active Directory 中获取的对象。

以下是一个名为 `Remove-EmptyProperty` 的有用的函数，能够接受任意的对象并移除所有空属性：

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
            Select-Object -ExpandProperty Name
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

以下是一个例子，演示如何使用该函数：

```powershell
PS> Get-Process -Id $pid

Handles  NPM(K)    PM(K)      WS(K)     CPU(s)     Id  SI ProcessName
-------  ------    -----      -----     ------     --  -- -----------
    1432      87   324452     346012     145,13  14340   1 powershell_ise



PS> Get-Process -Id $pid | Remove-EmptyProperty


Handles                    : 1256
Name                       : powershell_ise
NPM                        : 85320
PM                         : 332496896
SI                         : 1
VM                         : 1491988480
WS                         : 363655168
__NounName                 : Process
BasePriority               : 8
Handle                     : 5776
HandleCount                : 1256
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
NonpagedSystemMemorySize   : 85320
NonpagedSystemMemorySize64 : 85320
PagedMemorySize            : 332496896
PagedMemorySize64          : 332496896
PagedSystemMemorySize      : 1272400
PagedSystemMemorySize64    : 1272400
PeakPagedMemorySize        : 389857280
PeakPagedMemorySize64      : 389857280
PeakVirtualMemorySize      : 1601478656
PeakVirtualMemorySize64    : 1601478656
PeakWorkingSet             : 423972864
PeakWorkingSet64           : 423972864
PriorityBoostEnabled       : True
PriorityClass              : Normal
PrivateMemorySize          : 332496896
PrivateMemorySize64        : 332496896
PrivilegedProcessorTime    : 00:00:30.6250000
ProcessName                : powershell_ise
ProcessorAffinity          : 15
Responding                 : True
SafeHandle                 : Microsoft.Win32.SafeHandles.SafeProcessHandle
SessionId                  : 1
StartInfo                  : System.Diagnostics.ProcessStartInfo
StartTime                  : 04.04.2018 08:55:57
Threads                    : {16712, 12844, 15764, 1992...}
TotalProcessorTime         : 00:02:26.2656250
UserProcessorTime          : 00:01:55.6406250
VirtualMemorySize          : 1491988480
VirtualMemorySize64        : 1491988480
WorkingSet                 : 363655168
WorkingSet64               : 363655168
Company                    : Microsoft Corporation
CPU                        : 146,265625
Description                : Windows PowerShell ISE
FileVersion                : 10.0.16299.15 (WinBuild.160101.0800)
Path                       : C:\WINDOWS\system32\WindowsPowerShell\v1.0\PowerShell_ISE.exe
Product                    : Microsoft® Windows® Operating System
ProductVersion             : 10.0.16299.15




PS>
```

`Remove-EmptyProperty` 基本上是创建一个只包含实际值的属性。由于它总是创建一个新对象，所以它有副作用：您总是会看到缺省情况下隐藏的属性。

<!--more-->
本文国际来源：[Listing Properties with Values (Part 1)](http://community.idera.com/powershell/powertips/b/tips/posts/listing-properties-with-values-part-1)
