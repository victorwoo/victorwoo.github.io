---
layout: post
date: 2018-09-04 00:00:00
title: "PowerShell 技能连载 - 管理 Lenovo BIOS 设置（第 2 部分）"
description: PowerTip of the Day - Managing Lenovo BIOS Settings (Part 2)
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
在前一个技能中，我们解释了如何转储 Lenovo 计算机的 BIOS 设置。要调整设置，您需要了解某个设置支持的各种选项。以下是一段转储某个（Lenovo 电脑的）BIOS 设置的所有可选项的代码：

```powershell
#requires -RunAsAdministrator

# this is case-sensitive
$Setting = "WakeOnLAN"

$selections = Get-WmiObject -Class Lenovo_GetBiosSelections -Namespace root\wmi
$selections.GetBiosSelections($Setting).Selections.Split(',')
```

请注意这段代码需要管理员特权。并且该设置名称是大小写敏感的。结果类似这样：

    Disable
    ACOnly
    ACandBattery
    Enable

这可能是一个显示如何获取当前 BIOS 设置，以及合法设置的列表的复杂示例：

```powershell
#requires -RunAsAdministrator

$selections = Get-WmiObject -Class Lenovo_GetBiosSelections -Namespace root\wmi

Get-WmiObject -Class Lenovo_BiosSetting -Namespace root\wmi |
Where-Object CurrentSetting |
ForEach-Object {
    $parts = $_.CurrentSetting.Split(',')
    [PSCustomObject]@{
        CurrentSetting = $parts[0]
        Status = $parts[1]
        Active = $_.Active
        AvailableSettings = $selections.GetBiosSelections($parts[0]).Selections.Split(',')
    }
} | Out-GridView
```

结果类似如下：

    CurrentSetting                      Status                                Active AvailableSettings
    --------------                      ------                                ------ -----------------
    WakeOnLAN                           ACOnly                                  True {Disable, ACOnly, ACandBattery,...
    WakeOnLANDock                       Enable                                  True {Disable, Enable}
    EthernetLANOptionROM                Enable                                  True {Disable, Enable}
    IPv4NetworkStack                    Enable                                  True {Disable, Enable}
    IPv6NetworkStack                    Enable                                  True {Disable, Enable}
    UefiPxeBootPriority                 IPv4First                               True {IPv6First, IPv4First}
    WiGigWake                           Disable                                 True {Disable, Enable}
    WirelessAutoDisconnection           Disable                                 True {Disable, Enable}
    MACAddressPassThrough               Disable                                 True {Disable, Enable}
    USBBIOSSupport                      Disable                                 True {Disable, Enable}
    AlwaysOnUSB                         Enable                                  True {Disable, Enable}
    TrackPoint                          Automatic                               True {Disable, Automatic}
    TouchPad                            Automatic                               True {Disable, Automatic}
    FnCtrlKeySwap                       Disable                                 True {Disable, Enable}
    FnSticky                            Disable                                 True {Disable, Enable}
    FnKeyAsPrimary                      Disable                                 True {Disable, Enable}
    BootDisplayDevice                   LCD                                     True {LCD, USBTypeC, HDMI, DockDisplay}
    SharedDisplayPriority               DockDisplay                             True {HDMI, DockDisplay}
    TotalGraphicsMemory                 256MB                                   True {256MB, 512MB}
    BootTimeExtension                   Disable                                 True {Disable, 1, 2, 3...}
    SpeedStep                           Enable                                  True {Disable, Enable}
    AdaptiveThermalManagementAC         MaximizePerformance                     True {MaximizePerformance, Balanced}
    AdaptiveThermalManagementBattery    Balanced                                True {MaximizePerformance, Balanced}
    CPUPowerManagement                  Automatic                               True {Disable, Automatic}
    OnByAcAttach                        Disable                                 True {Disable, Enable}
    PasswordBeep                        Disable                                 True {Disable, Enable}
    KeyboardBeep                        Enable                                  True {Disable, Enable}
    AMTControl                          Enable                                  True {Disable, Enable, Disable}
    USBKeyProvisioning                  Disable                                 True {Disable, Enable}
    WakeByThunderbolt                   Enable                                  True {Disable, Enable}
    ThunderboltSecurityLevel            UserAuthorization                       True {NoSecurity, UserAuthorization,...
    PreBootForThunderboltDevice         Disable                                 True {Disable, Enable, Pre-BootACL}
    PreBootForThunderboltUSBDevice      Disable                                 True {Disable, Enable}
    LockBIOSSetting                     Disable                                 True {Disable, Enable}
    MinimumPasswordLength               Disable                                 True {Disable, 4, 5, 6...}
    BIOSPasswordAtUnattendedBoot        Enable                                  True {Disable, Enable}
    BIOSPasswordAtReboot                Disable                                 True {Disable, Enable}
    BIOSPasswordAtBootDeviceList        Disable                                 True {Disable, Enable}
    PasswordCountExceededError          Enable                                  True {Disable, Enable}
    FingerprintPredesktopAuthentication Enable                                  True {Disable, Enable}
    FingerprintReaderPriority           External                                True {External, InternalOnly}
    FingerprintSecurityMode             Normal                                  True {Normal, High}
    FingerprintPasswordAuthentication   Enable                                  True {Disable, Enable}
    SecurityChip                        Enable                                  True {Active, Inactive, Disable, Ena...
    TXTFeature                          Disable                                 True {Disable, Enable}
    PhysicalPresenceForTpmProvision     Disable                                 True {Disable, Enable}
    PhysicalPresenceForTpmClear         Enable                                  True {Disable, Enable}
    BIOSUpdateByEndUsers                Enable                                  True {Disable, Enable}
    SecureRollBackPrevention            Enable                                  True {Disable, Enable}
    WindowsUEFIFirmwareUpdate           Enable                                  True {Disable, Enable}
    DataExecutionPrevention             Enable                                  True {Disable, Enable}
    VirtualizationTechnology            Enable                                  True {Disable, Enable}
    VTdFeature                          Enable                                  True {Disable, Enable}
    EthernetLANAccess                   Enable                                  True {Disable, Enable}
    WirelessLANAccess                   Enable                                  True {Disable, Enable}
    WirelessWANAccess                   Enable                                  True {Disable, Enable}
    BluetoothAccess                     Enable                                  True {Disable, Enable}
    USBPortAccess                       Enable                                  True {Disable, Enable}
    MemoryCardSlotAccess                Enable                                  True {Disable, Enable}
    SmartCardSlotAccess                 Enable                                  True {Disable, Enable}
    IntegratedCameraAccess              Enable                                  True {Disable, Enable}
    MicrophoneAccess                    Enable                                  True {Disable, Enable}
    FingerprintReaderAccess             Enable                                  True {Disable, Enable}
    ThunderboltAccess                   Enable                                  True {Disable, Enable}
    NfcAccess                           Enable                                  True {Disable, Enable}
    WiGig                               Enable                                  True {Disable, Enable}
    BottomCoverTamperDetected           Disable                                 True {Disable, Enable}
    InternalStorageTamper               Disable                                 True {Disable, Enable}
    ComputraceModuleActivation          Enable                                  True {Disable, Enable, Disable}
    SecureBoot                          Disable                                 True {Disable, Enable}
    SGXControl                          SoftwareControl                         True {Disable, Enable, SoftwareControl}
    DeviceGuard                         Disable                                 True {Disable, Enable}
    BootMode                            Quick                                   True {Quick, Diagnostics}
    StartupOptionKeys                   Enable                                  True {Disable, Enable}
    BootDeviceListF12Option             Enable                                  True {Disable, Enable}
    BootOrder                           USBCD:USBFDD:NVMe0:HDD0:USBHDD:PCILAN   True {HDD0, HDD1, HDD2, HDD3...}
    NetworkBoot                         USBFDD                                  True {HDD0, HDD1, HDD2, HDD3...}
    BootOrderLock                       Disable                                 True {Disable, Enable}

<!--more-->
本文国际来源：[Managing Lenovo BIOS Settings (Part 2)](http://community.idera.com/powershell/powertips/b/tips/posts/managing-lenovo-bios-settings-part-2)
