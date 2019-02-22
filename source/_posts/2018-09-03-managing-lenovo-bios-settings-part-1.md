---
layout: post
date: 2018-09-03 00:00:00
title: "PowerShell 技能连载 - 管理 Lenovo BIOS 设置（第 1 部分）"
description: PowerTip of the Day - Managing Lenovo BIOS Settings (Part 1)
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
不幸的是，没有一个标准的方法来管理计算机厂商的 BIOS 设置。每个厂商使用专有的方法。对于 Lenovo 电脑，您可以使用 WMI 来存取和转储 BIOS 设置：

```powershell
Get-WmiObject -Class Lenovo_BiosSetting -Namespace root\wmi | 
Where-Object CurrentSetting |
ForEach-Object {
    $parts = $_.CurrentSetting.Split(',')
    [PSCustomObject]@{
        Setting = $parts[0]
        Status = $parts[1]
        Active = $_.Active
    }
}
```

结果看起来类似这样：

    Setting                             Status                                Active
    -------                             ------                                ------
    WakeOnLAN                           ACOnly                                  True
    WakeOnLANDock                       Enable                                  True
    EthernetLANOptionROM                Enable                                  True
    IPv4NetworkStack                    Enable                                  True
    IPv6NetworkStack                    Enable                                  True
    UefiPxeBootPriority                 IPv4First                               True
    WiGigWake                           Disable                                 True
    WirelessAutoDisconnection           Disable                                 True
    MACAddressPassThrough               Disable                                 True
    USBBIOSSupport                      Disable                                 True
    AlwaysOnUSB                         Enable                                  True
    TrackPoint                          Automatic                               True
    TouchPad                            Automatic                               True
    FnCtrlKeySwap                       Disable                                 True
    FnSticky                            Disable                                 True
    FnKeyAsPrimary                      Disable                                 True
    BootDisplayDevice                   LCD                                     True
    SharedDisplayPriority               DockDisplay                             True
    TotalGraphicsMemory                 256MB                                   True
    BootTimeExtension                   Disable                                 True
    SpeedStep                           Enable                                  True
    AdaptiveThermalManagementAC         MaximizePerformance                     True
    AdaptiveThermalManagementBattery    Balanced                                True
    CPUPowerManagement                  Automatic                               True
    OnByAcAttach                        Disable                                 True
    PasswordBeep                        Disable                                 True
    KeyboardBeep                        Enable                                  True
    AMTControl                          Enable                                  True
    USBKeyProvisioning                  Disable                                 True
    WakeByThunderbolt                   Enable                                  True
    ThunderboltSecurityLevel            UserAuthorization                       True
    PreBootForThunderboltDevice         Disable                                 True
    PreBootForThunderboltUSBDevice      Disable                                 True
    LockBIOSSetting                     Disable                                 True
    MinimumPasswordLength               Disable                                 True
    BIOSPasswordAtUnattendedBoot        Enable                                  True
    BIOSPasswordAtReboot                Disable                                 True
    BIOSPasswordAtBootDeviceList        Disable                                 True
    PasswordCountExceededError          Enable                                  True
    FingerprintPredesktopAuthentication Enable                                  True
    FingerprintReaderPriority           External                                True
    FingerprintSecurityMode             Normal                                  True
    FingerprintPasswordAuthentication   Enable                                  True
    SecurityChip                        Enable                                  True
    TXTFeature                          Disable                                 True
    PhysicalPresenceForTpmProvision     Disable                                 True
    PhysicalPresenceForTpmClear         Enable                                  True
    BIOSUpdateByEndUsers                Enable                                  True
    SecureRollBackPrevention            Enable                                  True
    WindowsUEFIFirmwareUpdate           Enable                                  True
    DataExecutionPrevention             Enable                                  True
    VirtualizationTechnology            Enable                                  True
    VTdFeature                          Enable                                  True
    EthernetLANAccess                   Enable                                  True
    WirelessLANAccess                   Enable                                  True
    WirelessWANAccess                   Enable                                  True
    BluetoothAccess                     Enable                                  True
    USBPortAccess                       Enable                                  True
    MemoryCardSlotAccess                Enable                                  True
    SmartCardSlotAccess                 Enable                                  True
    IntegratedCameraAccess              Enable                                  True
    MicrophoneAccess                    Enable                                  True
    FingerprintReaderAccess             Enable                                  True
    ThunderboltAccess                   Enable                                  True
    NfcAccess                           Enable                                  True
    WiGig                               Enable                                  True
    BottomCoverTamperDetected           Disable                                 True
    InternalStorageTamper               Disable                                 True
    ComputraceModuleActivation          Enable                                  True
    SecureBoot                          Disable                                 True
    SGXControl                          SoftwareControl                         True
    DeviceGuard                         Disable                                 True
    BootMode                            Quick                                   True
    StartupOptionKeys                   Enable                                  True
    BootDeviceListF12Option             Enable                                  True
    BootOrder                           USBCD:USBFDD:NVMe0:HDD0:USBHDD:PCILAN   True
    NetworkBoot                         USBFDD                                  True
    BootOrderLock                       Disable                                 True

<!--本文国际来源：[Managing Lenovo BIOS Settings (Part 1)](http://community.idera.com/powershell/powertips/b/tips/posts/managing-lenovo-bios-settings-part-1)-->
