---
layout: post
date: 2014-10-14 11:00:00
title: "PowerShell 技能连载 - 列出所有信息"
description: PowerTip of the Day - List All Information
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

大多数时候，PowerShell 不会显示从 cmdlet 中返回的所有信息。相反地，PowerShell 限制了只显示信息中最常见的部分。

    PS> Get-WmiObject -Class CIM_CacheMemory


    BlockSize      : 1024
    CacheSpeed     :
    CacheType      : 4
    DeviceID       : Cache Memory 0
    InstalledSize  : 32
    Level          : 3
    MaxCacheSize   : 32
    NumberOfBlocks : 32
    Status         : OK

    (...)


要看到完整的信息，请像这样加一句 `Select-Object` 语句：

    PS> Get-WmiObject -Class CIM_CacheMemory | Select-Object -Property *


    PSComputerName              : TOBI2
    DeviceID                    : Cache Memory 0
    ErrorCorrectType            : 5
    Availability                : 3
    Status                      : OK
    StatusInfo                  : 3
    BlockSize                   : 1024
    CacheSpeed                  :
    CacheType                   : 4
    InstalledSize               : 32
    Level                       : 3
    MaxCacheSize                : 32
    NumberOfBlocks              : 32
    WritePolicy                 : 3
    __GENUS                     : 2
    __CLASS                     : Win32_CacheMemory
    __SUPERCLASS                : CIM_CacheMemory
    __DYNASTY                   : CIM_ManagedSystemElement
    __RELPATH                   : Win32_CacheMemory.DeviceID="Cache Memory 0"
    __PROPERTY_COUNT            : 53
    __DERIVATION                : {CIM_CacheMemory, CIM_Memory, CIM_StorageExtent,
                                  CIM_LogicalDevice...}
    __SERVER                    : TOBI2
    __NAMESPACE                 : root\cimv2
    __PATH                      : \\TOBI2\root\cimv2:Win32_CacheMemory.DeviceID="Cache
                                   Memory 0"
    Access                      :
    AdditionalErrorData         :
    Associativity               : 7
    Caption                     : Cache Memory
    ConfigManagerErrorCode      :
    ConfigManagerUserConfig     :
    CorrectableError            :
    CreationClassName           : Win32_CacheMemory
    CurrentSRAM                 : {5}
    Description                 : Cache Memory
    EndingAddress               :
    ErrorAccess                 :
    ErrorAddress                :
    ErrorCleared                :
    ErrorData                   :
    ErrorDataOrder              :
    ErrorDescription            :
    ErrorInfo                   :
    ErrorMethodology            :
    ErrorResolution             :
    ErrorTime                   :
    ErrorTransferSize           :
    FlushTimer                  :
    InstallDate                 :
    LastErrorCode               :
    LineSize                    :
    Location                    : 0
    Name                        : Cache Memory
    OtherErrorDescription       :
    PNPDeviceID                 :
    PowerManagementCapabilities :
    PowerManagementSupported    :
    Purpose                     : L1 Cache
    ReadPolicy                  :
    ReplacementPolicy           :
    StartingAddress             :
    SupportedSRAM               : {5}
    SystemCreationClassName     : Win32_ComputerSystem
    SystemLevelAddress          :
    SystemName                  : TOBI2
    Scope                       : System.Management.ManagementScope
    Path                        : \\TOBI2\root\cimv2:Win32_CacheMemory.DeviceID="Cache
                                   Memory 0"
    Options                     : System.Management.ObjectGetOptions
    ClassPath                   : \\TOBI2\root\cimv2:Win32_CacheMemory
    Properties                  : {Access, AdditionalErrorData, Associativity,
                                  Availability...}
    SystemProperties            : {__GENUS, __CLASS, __SUPERCLASS, __DYNASTY...}
    Qualifiers                  : {dynamic, Locale, provider, UUID}
    Site                        :
    Container                   :

    (...)

<!--本文国际来源：[List All Information](http://community.idera.com/powershell/powertips/b/tips/posts/list-all-information)-->
