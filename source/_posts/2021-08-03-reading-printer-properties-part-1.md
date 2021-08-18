---
layout: post
date: 2021-08-03 00:00:00
title: "PowerShell 技能连载 - 读取打印机属性（第 1 部分）"
description: PowerTip of the Day - Reading Printer Properties (Part 1)
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
您可能知道 `Get-Printer`，它返回系统上所有已安装打印机的名称。但是，您无法通过这种方式获得特定的打印机功能或设置。

`Get-PrinterProperty` 可以提供帮助。只需提交打印机名称（使用 `Get-Printer` 找出可用的打印机名称），然后运行以下命令（确保将打印机名称更改为存在的名称）：

```powershell
PS> Get-PrinterProperty -PrinterName 'S/W Laser HP'

ComputerName         PrinterName          PropertyName         Type       Value
------------         -----------          ------------         ----       -----
                        S/W Laser HP         Config:AccessoryO... String     500Stapler
                        S/W Laser HP         Config:ActualCust... String     431800_914400
                        S/W Laser HP         Config:AutoConfig... String     NotInstalled
                        S/W Laser HP         Config:Auto_install  String     INSTALLED
                        S/W Laser HP         Config:BookletMak... String     NOTINSTALLED
                        S/W Laser HP         Config:CombineMed... String     Installed
                        S/W Laser HP         Config:DeviceIsMo... String     Installed
                        S/W Laser HP         Config:DuplexUnit    String     Installed
                        S/W Laser HP         Config:DynamicRender String     AUTODEVICE
                        S/W Laser HP         Config:EMFSpooling   String     Automatic
                        S/W Laser HP         Config:EdgeToEdge... String     Enabled
                        S/W Laser HP         Config:EmbeddedJo... String     NotInstalled
                        S/W Laser HP         Config:EnvFeed_in... String     NOTINSTALLED
                        S/W Laser HP         Config:HPDisplayD... String     True
                        S/W Laser HP         Config:HPFontInst... String     TRUE
                        S/W Laser HP         Config:HPInstalla... String     HP2HolePunch-Q3689
                        S/W Laser HP         Config:HPInstalla... String     500Stapler-Q2443
                        S/W Laser HP         Config:HPInstalla... String     Auto_install
                        S/W Laser HP         Config:HPJobSepar... String     NotInstalled
                        S/W Laser HP         Config:HPMOutputB... String     500Stapler-Q2443
                        S/W Laser HP         Config:HPMOutputB... String     None
                        S/W Laser HP         Config:HPOutputBi... String     0-0
                        S/W Laser HP         Config:HPPCL6Version String     PDL_VERSION_2-1_OR_GREATER
                        S/W Laser HP         Config:HPPinToPri... String     NotInstalled
                        S/W Laser HP         Config:HPPrnPropR... String     hpchl230.cab
                        S/W Laser HP         Config:HPPunchUni... String     NotInstalled
                        S/W Laser HP         Config:InsLwH1_in... String     NOTINSTALLED
                        S/W Laser HP         Config:InsUpH1_in... String     NOTINSTALLED
                        S/W Laser HP         Config:JobRetention  String     Installed
                        S/W Laser HP         Config:LineWidthC... String     Disabled
                        S/W Laser HP         Config:ManualFeed... String     INSTALLED
                        S/W Laser HP         Config:Memory        String     128MB
                        S/W Laser HP         Config:PCCFoldUnit   String     NOTINSTALLED
                        S/W Laser HP         Config:PCOptional... String     None
                        S/W Laser HP         Config:PCVFoldUnit   String     NOTINSTALLED
                        S/W Laser HP         Config:PrinterHar... String     Installed
                        S/W Laser HP         Config:ProductClass  String     HP
                        S/W Laser HP         Config:SHAccessor... String     None
                        S/W Laser HP         Config:SHByPassTray  String     None
                        S/W Laser HP         Config:SHDocInser... String     None
                        S/W Laser HP         Config:SHInstalla... String     MXFN19
                        S/W Laser HP         Config:SHLargeCap... String     None
                        S/W Laser HP         Config:SHMOutputB... String     None
                        S/W Laser HP         Config:SHPaperFol... String     None
                        S/W Laser HP         Config:SHPuncherUnit String     None
                        S/W Laser HP         Config:SPSOptiona... String     None
                        S/W Laser HP         Config:SecurePrin... String     Installed
                        S/W Laser HP         Config:StaplingUn... String     NOTINSTALLED
                        S/W Laser HP         Config:Tray10_ins... String     NOTINSTALLED
                        S/W Laser HP         Config:Tray1_install String     INSTALLED
                        S/W Laser HP         Config:Tray2_install String     INSTALLED
                        S/W Laser HP         Config:Tray3_install String     INSTALLED
                        S/W Laser HP         Config:Tray4_install String     NOTINSTALLED
                        S/W Laser HP         Config:Tray5_install String     NOTINSTALLED
                        S/W Laser HP         Config:Tray6_install String     NOTINSTALLED
                        S/W Laser HP         Config:Tray7_install String     NOTINSTALLED
                        S/W Laser HP         Config:Tray8_install String     NOTINSTALLED
                        S/W Laser HP         Config:Tray9_install String     NOTINSTALLED
                        S/W Laser HP         Config:TrayExt1_i... String     NOTINSTALLED
                        S/W Laser HP         Config:TrayExt2_i... String     NOTINSTALLED
                        S/W Laser HP         Config:TrayExt3_i... String     NOTINSTALLED
                        S/W Laser HP         Config:TrayExt4_i... String     NOTINSTALLED
                        S/W Laser HP         Config:TrayExt5_i... String     NOTINSTALLED
                        S/W Laser HP         Config:TrayExt6_i... String     NOTINSTALLED
```

注意：`Get-PrinterProperty` 是 Windows 操作系统（客户端和服务器）附带的 `PrintManagement` 模块的一部分。如果您使用非常旧的 Windows 操作系统或其他操作系统，则 cmdlet 可能不可用。

返回的属性列表取决于打印机型号。运行此命令以仅获取可用属性名的列表：

```powershell
    PS> Get-PrinterProperty -PrinterName 'S/W Laser HP' | Select-Object -ExpandProperty PropertyName | Sort-Object -Unique
    Config:AccessoryOutputBins
    Config:ActualCustomRange
    Config:Auto_install
    Config:AutoConfiguration
    Config:BookletMakerUnit_PC
    Config:CombineMediaTypesAndInputBins
    Config:DeviceIsMopier
    Config:DuplexUnit
    Config:DynamicRender
    Config:EdgeToEdgeSupport_PC
    Config:EmbeddedJobAccounting
    Config:EMFSpooling
    Config:EnvFeed_install
    Config:HPDisplayDocUITab
    Config:HPFontInstaller
    Config:HPInstallableFinisher
    Config:HPInstallableHCO
    Config:HPInstallableTrayFeatureName
    Config:HPJobSeparatorPage
    Config:HPMOutputBinHCOMap
    Config:HPMOutputBinHCOPMLMap
    Config:HPOutputBinPMLRange
    Config:HPPCL6Version
    Config:HPPinToPrintOnly
    Config:HPPrnPropResourceData
    Config:HPPunchUnitType
    Config:InsLwH1_install
    Config:InsUpH1_install
    Config:JobRetention
    Config:LineWidthCorrection
    Config:ManualFeed_install
    Config:Memory
    Config:PCCFoldUnit
    Config:PCOptionalOutputBin
    Config:PCVFoldUnit
    Config:PrinterHardDisk
    Config:ProductClass
    Config:SecurePrinting
    Config:SHAccessoryOutputBins
    Config:SHByPassTray
    Config:SHDocInsertionUnit
    Config:SHInstallableHCO
    Config:SHLargeCapacityTray
    Config:SHMOutputBinHCOMap
    Config:SHPaperFoldUnit
    Config:SHPuncherUnit
    Config:SPSOptionalOutputBin
    Config:StaplingUnit_PC
    Config:Tray1_install
    Config:Tray10_install
    Config:Tray2_install
    Config:Tray3_install
    Config:Tray4_install
    Config:Tray5_install
    Config:Tray6_install
    Config:Tray7_install
    Config:Tray8_install
    Config:Tray9_install
    Config:TrayExt1_install
    Config:TrayExt2_install
    Config:TrayExt3_install
    Config:TrayExt4_install
    Config:TrayExt5_install
    Config:TrayExt6_install
```

一旦您知道您所希望了解的属性名，您就可以将结果限制为以下属性：

```powershell
PS> Get-PrinterProperty -PrinterName 'S/W Laser HP' -PropertyName Config:AccessoryOutputBins, Config:BookletMakerUnit_PC

ComputerName         PrinterName          PropertyName         Type       Value
------------         -----------          ------------         ----       -----
                        S/W Laser HP         Config:AccessoryO... String     500Stapler
                        S/W Laser HP         Config:BookletMak... String     NOTINSTALLED
```

<!--本文国际来源：[Reading Printer Properties (Part 1)](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/reading-printer-properties-part-1)-->

