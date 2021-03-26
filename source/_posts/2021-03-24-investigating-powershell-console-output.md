---
layout: post
date: 2021-03-24 00:00:00
title: "PowerShell 技能连载 - 研究 PowerShell 控制台输出"
description: PowerTip of the Day - Investigating PowerShell Console Output
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---

当您在 PowerShell 控制台中看到命令的结果时，通常仅显示部分信息。要查看完整的信息，您需要将其发送到 `Select-Object` 并使用 "`*`" 通配符显式选择所有属性：

```powershell
PS> Get-CimInstance -ClassName Win32_BIOS


SMBIOSBIOSVersion : 1.7.1
Manufacturer      : Dell Inc.
Name              : 1.7.1
SerialNumber      : 4ZKM0Z2
Version           : DELL   - 20170001




PS> Get-CimInstance -ClassName Win32_BIOS | Select-Object -Property *


Status                         : OK
Name                           : 1.7.1
Caption                        : 1.7.1
SMBIOSPresent                  : True
Description                    : 1.7.1
InstallDate                    :
BuildNumber                    :
CodeSet                        :
IdentificationCode             :
LanguageEdition                :
Manufacturer                   : Dell Inc.
OtherTargetOS                  :
SerialNumber                   : 4ZKM0Z2
SoftwareElementID              : 1.7.1
SoftwareElementState           : 3
TargetOperatingSystem          : 0
Version                        : DELL   - 20170001
PrimaryBIOS                    : True
BiosCharacteristics            : {7, 9, 11, 12...}
BIOSVersion                    : {DELL   - 20170001, 1.7.1, Dell - 10000}
CurrentLanguage                : enUS
EmbeddedControllerMajorVersion : 255
EmbeddedControllerMinorVersion : 255
InstallableLanguages           : 1
ListOfLanguages                : {enUS}
ReleaseDate                    : 28.12.2020 01:00:00
SMBIOSBIOSVersion              : 1.7.1
SMBIOSMajorVersion             : 3
SMBIOSMinorVersion             : 1
SystemBiosMajorVersion         : 1
SystemBiosMinorVersion         : 7
PSComputerName                 :
CimClass                       : root/cimv2:Win32_BIOS
CimInstanceProperties          : {Caption, Description, InstallDate, Name...}
CimSystemProperties            : Microsoft.Management.Infrastructure.CimSystemProperties
```

这是因为 PowerShell 包含的逻辑会自动仅选择对象的最重要属性，以使您专注于重要的事情。为了更好地理解它是如何工作的，这里有一些示例代码来探索 `Get-Process` 返回的数据。要研究其他 cmdlet，请将代码中的 "`Get-Process`" 替换为另一个 cmdlet 的名称：

```powershell
Install-Module -Name PSCommandDiscovery -Scope CurrentUser -Verbose
```

该代码确定 cmdlet 发出的数据类型，然后找到定义该数据类型视图的 *.format.ps1xml 文件，并返回该定义的前 20 行：

```xml
        </ViewSelectedBy>
    <TableControl>
        <TableHeaders>
            <TableColumnHeader>
                <Label>Handles</Label>
                <Width>7</Width>
                <Alignment>right</Alignment>
            </TableColumnHeader>
            <TableColumnHeader>
                <Label>NPM(K)</Label>
                <Width>7</Width>
                <Alignment>right</Alignment>
            </TableColumnHeader>
            <TableColumnHeader>
                <Label>PM(K)</Label>
                <Width>8</Width>
                <Alignment>right</Alignment>
            </TableColumnHeader>
            <TableColumnHeader>
                <Label>WS(K)</Label>
    </ViewSelectedBy>
    <GroupBy>
        <PropertyName>PriorityClass</PropertyName>
        <Label>PriorityClass</Label>
    </GroupBy>
    <TableControl>
        <TableHeaders>
            <TableColumnHeader>
                <Width>20</Width>
            </TableColumnHeader>
            <TableColumnHeader>
                <Width>10</Width>
                <Alignment>right</Alignment>
            </TableColumnHeader>
            <TableColumnHeader>
                <Width>13</Width>
                <Alignment>right</Alignment>
            </TableColumnHeader>
            <TableColumnHeader>
                <Width>12</Width>
    </ViewSelectedBy>
    <GroupBy>
        <ScriptBlock>$_.StartTime.ToShortDateString()</ScriptBlock>
        <Label>StartTime.ToShortDateString()</Label>
    </GroupBy>
    <TableControl>
        <TableHeaders>
            <TableColumnHeader>
                <Width>20</Width>
            </TableColumnHeader>
            <TableColumnHeader>
                <Width>10</Width>
                <Alignment>right</Alignment>
            </TableColumnHeader>
            <TableColumnHeader>
                <Width>13</Width>
                <Alignment>right</Alignment>
            </TableColumnHeader>
            <TableColumnHeader>
                <Width>12</Width>
    </ViewSelectedBy>
    <WideControl>
        <WideEntries>
            <WideEntry>
                <WideItem>
                    <PropertyName>ProcessName</PropertyName>
                </WideItem>
            </WideEntry>
        </WideEntries>
    </WideControl>
</View>
<View>
    <Name>DateTime</Name>
    <ViewSelectedBy>
        <TypeName>System.DateTime</TypeName>
    </ViewSelectedBy>
    <CustomControl>
        <CustomEntries>
            <CustomEntry>
                <CustomItem> <ExpressionBinding> <PropertyName>DateTime</PropertyName> </ExpressionBinding> </CustomItem>
```

尽管示例代码为了简单起见不会给出完整的定义，但它使您可以更好地了解幕后发生的事情：每当 cmdlet 返回类型为 `System.Diagnostics.Process` 的对象时，PowerShell 默认都会根据到公开的 XML 定义。

在上面的示例中更改 cmdlet 名称时，您也可以看到其他类型的定义。但是，为简单起见，示例代码仅搜索在 PowerShell 主目录中找到的 *.format.ps1xml 文件，而不在可能存在其他格式定义的所有模块位置中搜索。

注意：本技能仅适用于 Windows PowerShell。

<!--本文国际来源：[Investigating PowerShell Console Output](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/investigating-powershell-console-output)-->

