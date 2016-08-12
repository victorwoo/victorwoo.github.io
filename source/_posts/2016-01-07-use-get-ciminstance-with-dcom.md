layout: post
date: 2016-01-07 12:00:00
title: "PowerShell 技能连载 - ___"
description: PowerTip of the Day - Use Get-CimInstance with DCOM
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
PowerShell 3.0 added an alternative to Get-WmiObject: Get-CimInstance seems to work very similar and can retrieve information from the internal WMI service:

     
    PS C:\> Get-WmiObject -Class Win32_BIOS
    
    SMBIOSBIOSVersion : A03
    Manufacturer      : Dell Inc.
    Name              : A03
    SerialNumber      : 5TQLM32
    Version           : DELL   - 1072009
    
    PS C:\> Get-CimInstance -Class Win32_BIOS
    
    SMBIOSBIOSVersion : A03
    Manufacturer      : Dell Inc.
    Name              : A03
    SerialNumber      : 5TQLM32
    Version           : DELL   - 1072009 
     

While Get-WmiObject still works, Get-CimInstance is definitely the way to go. This cmdlet supports IntelliSense completion for WMI classes (in PowerShell ISE), and the returned data has a more readable format: dates for example appear as human readible dates whereas Get-WmiObject displays the internal raw WMI date format.

The most important difference, though, is how they work across remote connections. Get-WmiObject always uses the old DCOM protocol whereas Get-CimInstance defaults to the new WSMan protocol, yet is flexible and can still fall back to DCOM when needed.

Here is a sample function that retrieves BIOS information remotely via Get-CimInstance. The function defaults to DCOM, and with the -Protocol parameter you can choose the protocol you'd like to use:

    #requires -Version 3
    function Get-BIOS
    {
        param
        (
            $ComputerName = $env:COMPUTERNAME,
            
            [Microsoft.Management.Infrastructure.CimCmdlets.ProtocolType]
            $Protocol = 'DCOM'
        )
        $option = New-CimSessionOption -Protocol $protocol
        $session = New-CimSession -ComputerName $ComputerName -SessionOption $option
        Get-CimInstance -CimSession $session -ClassName Win32_BIOS
    }

<!--more-->
本文国际来源：[Use Get-CimInstance with DCOM](http://powershell.com/cs/blogs/tips/archive/2016/01/07/use-get-ciminstance-with-dcom.aspx)
