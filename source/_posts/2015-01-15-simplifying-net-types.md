---
layout: post
date: 2015-01-15 12:00:00
title: "PowerShell 技能连载 - 简化 .NET 类型"
description: PowerTip of the Day - Simplifying .NET Types
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

PowerShell 为多数常见的 .NET 类型定义了一个短名字。要查看已有多少个 .NET 类型定义了短名称，请使用以下代码：

    PS> [System.Management.Automation.LanguagePrimitives]::ConvertTypeNameToPSTypeName("System.String")
    [string]

    PS> [System.Management.Automation.LanguagePrimitives]::ConvertTypeNameToPSTypeName("System.Int32")
    [int]

    PS> [System.Management.Automation.LanguagePrimitives]::ConvertTypeNameToPSTypeName("System.Management.ManagementObject")
    [wmi]

    PS> [System.Management.Automation.LanguagePrimitives]::ConvertTypeNameToPSTypeName("System.DirectoryServices.DirectoryEntry")
    [adsi]

    PS>

要查用另一种方法看真实的 .NET 名称，请使用以下方法：

    PS> [string].FullName
    System.String

    PS> [int].FullName
    System.Int32

    PS> [wmi].FullName
    System.Management.ManagementObject

    PS> [adsi].FullName
    System.DirectoryServices.DirectoryEntry

    PS>

通过这个技巧，您还可以更好地理解 PowerShell 转换数据类型的机制：

    PS> [System.Management.Automation.LanguagePrimitives]::ConvertTypeNameToPSTypeName("UInt8")
    [Byte]

    PS>

这表明了，当 PowerShell 遇到一个无符号 8 位整型数值，将自动把它转换为一个 Byte 数据。整个魔法是由 `ConvertTypeNameToPSTypeName()` 完成的。在内部，PowerShell 使用一个检索表来转换特定的数据类型：

    $field = [System.Management.Automation.LanguagePrimitives].GetField('nameMap', 'NonPublic,Static')
    $field.GetValue([System.Management.Automation.LanguagePrimitives])

该检索表看起来类似这样：

    Key                                                            Value
    ---                                                            -----
    SInt8                                                          SByte
    UInt8                                                          Byte
    SInt16                                                         Int16
    UInt16                                                         UInt16
    SInt32                                                         Int32
    UInt32                                                         UInt32
    SInt64                                                         Int64
    UInt64                                                         UInt64
    Real32                                                         Single
    Real64                                                         double
    Boolean                                                        bool
    String                                                         string
    DateTime                                                       DateTime
    Reference                                                      CimInstance
    Char16                                                         char
    Instance                                                       CimInstance
    BooleanArray                                                   bool[]
    UInt8Array                                                     byte[]
    SInt8Array                                                     Sbyte[]
    UInt16Array                                                    uint16[]
    SInt16Array                                                    int64[]
    UInt32Array                                                    UInt32[]
    SInt32Array                                                    Int32[]
    UInt64Array                                                    UInt64[]
    SInt64Array                                                    Int64[]
    Real32Array                                                    Single[]
    Real64Array                                                    double[]
    Char16Array                                                    char[]
    DateTimeArray                                                  DateTime[]
    StringArray                                                    string[]
    ReferenceArray                                                 CimInstance[]
    InstanceArray                                                  CimInstance[]
    Unknown                                                        UnknownType

<!--本文国际来源：[Simplifying .NET Types](http://community.idera.com/powershell/powertips/b/tips/posts/simplifying-net-types)-->
