---
layout: post
date: 2019-04-19 00:00:00
title: "PowerShell 技能连载 - 隐藏返回结果的属性"
description: PowerTip of the Day - Hiding Properties in Return Results
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
默认情况下，PowerShell 会精简对象并且只显示最重要的属性：

```powershell
PS C:\> Get-WmiObject -Class Win32_BIOS


SMBIOSBIOSVersion : 1.9.0
Manufacturer      : Dell Inc.
Name              : 1.9.0
SerialNumber      : DLGQD72
Version           : DELL   - 1072009
```

要查看真实的信息，需要使用 `Select-Object` 并显示要求显示所有信息：

```powershell
PS C:\> Get-WmiObject -Class Win32_BIOS | Select-Object -Property *


PSComputerName                 : DESKTOP-7AAMJLF
Status                         : OK
Name                           : 1.9.0
Caption                        : 1.9.0
SMBIOSPresent                  : True
__GENUS                        : 2
__CLASS                        : Win32_BIOS
__SUPERCLASS                   : CIM_BIOSElement
__DYNASTY                      : CIM_ManagedSystemElement
__RELPATH                      : Win32_BIOS.Name="1.9.0",SoftwareElementID="1.9.0",SoftwareElementState=3,TargetOperatingSystem=0,Version="DELL   - 1072009"
__PROPERTY_COUNT               : 31
__DERIVATION                   : {CIM_BIOSElement, CIM_SoftwareElement, CIM_LogicalElement, CIM_ManagedSystemElement}
__SERVER                       : DESKTOP-7AAMJLF
__NAMESPACE                    : root\cimv2
__PATH                         : \\DESKTOP-7AAMJLF\root\cimv2:Win32_BIOS.Name="1.9.0",SoftwareElementID="1.9.0",SoftwareElementState=3,TargetOperatingSystem=0,Version="D
                                 ELL   - 1072009"
BiosCharacteristics            : {7, 9, 11, 12...}
BIOSVersion                    : {DELL   - 1072009, 1.9.0, American Megatrends - 5000B}
BuildNumber                    :
CodeSet                        :
…
ClassPath                      : \\DESKTOP-7AAMJLF\root\cimv2:Win32_BIOS
Properties                     : {BiosCharacteristics, BIOSVersion, BuildNumber, Caption...}
SystemProperties               : {__GENUS, __CLASS, __SUPERCLASS, __DYNASTY...}
Qualifiers                     : {dynamic, Locale, provider, UUID}
Site                           :
Container                      :
```

如何在自己的 PowerShell 函数中实现相同的内容并且返回自己的对象？

只需要告诉 PowerShell 缺省情况下需要可见的最重要的属性。以下是一个示例。`Get-Info` 函数创建一个有五个属性的自定义对象。在函数返回这个对象之前，它使用一些 PowerShell 的魔法对这个对象进行标记并且列出缺省的属性：

```powershell
function Get-Info
{

  # prepare the object returned by the function
  $result = [PSCustomObject]@{
    Name = $env:username
    Date = Get-Date
    BIOS = Get-WmiObject -Class Win32_BIOS | Select-Object -ExpandProperty SMBIOSBIOSVersion
    Computername = $env:COMPUTERNAME
    Random = Get-Date
  }

  #region Define the VISIBLE properties
  # this is the list of properties visible by default
  [string[]]$visible = 'Name','BIOS','Random'
  $typ = 'DefaultDisplayPropertySet'
  [Management.Automation.PSMemberInfo[]]$info =
  New-Object System.Management.Automation.PSPropertySet($typ,$visible)

  # add the information about the visible properties to the return value
  Add-Member -MemberType MemberSet -Name PSStandardMembers -Value $info -InputObject $result
  #endregion


  # return the result object
  return $result
}
```

以下是执行结果：

```powershell
PS C:\> Get-Info

Name  BIOS  Random
----  ----  ------
tobwe 1.9.0 01.04.2019 19:32:44



PS C:\> Get-Info | Select-Object -Property *


Name         : tobwe
Date         : 01.04.2019 19:32:50
BIOS         : 1.9.0
Computername : DESKTOP-7AAMJLF
Random       : 01.04.2019 19:32:50
```

<!--本文国际来源：[Hiding Properties in Return Results](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/hiding-properties-in-return-results)-->

