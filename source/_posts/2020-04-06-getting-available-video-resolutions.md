---
layout: post
date: 2020-04-06 00:00:00
title: "PowerShell 技能连载 - 获取可用的显示分辨率"
description: PowerTip of the Day - Getting Available Video Resolutions
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
WMI 可以返回显示适配器可用的显示分辨率列表：

```powershell
PS> Get-CimInstance -ClassName CIM_VideoControllerResolution |
    Select-Object -Property SettingID

SettingID
---------
640 x 480 x 4294967296 colors @ 60 Hertz
640 x 480 x 4294967296 colors @ 67 Hertz
640 x 480 x 4294967296 colors @ 72 Hertz
640 x 480 x 4294967296 colors @ 75 Hertz
720 x 400 x 4294967296 colors @ 70 Hertz
720 x 480 x 4294967296 colors @ 60 Hertz
720 x 576 x 4294967296 colors @ 50 Hertz (Interlaced)
800 x 600 x 4294967296 colors @ 60 Hertz
800 x 600 x 4294967296 colors @ 72 Hertz
800 x 600 x 4294967296 colors @ 75 Hertz
832 x 624 x 4294967296 colors @ 75 Hertz
1024 x 768 x 4294967296 colors @ 60 Hertz
1024 x 768 x 4294967296 colors @ 70 Hertz
1024 x 768 x 4294967296 colors @ 75 Hertz
1152 x 864 x 4294967296 colors @ 75 Hertz
1152 x 870 x 4294967296 colors @ 75 Hertz
1280 x 720 x 4294967296 colors @ 50 Hertz (Interlaced)
1280 x 720 x 4294967296 colors @ 60 Hertz
1280 x 800 x 4294967296 colors @ 60 Hertz
1280 x 1024 x 4294967296 colors @ 60 Hertz
1280 x 1024 x 4294967296 colors @ 75 Hertz
1440 x 900 x 4294967296 colors @ 60 Hertz
1600 x 900 x 4294967296 colors @ 60 Hertz
1680 x 1050 x 4294967296 colors @ 60 Hertz
1920 x 1080 x 4294967296 colors @ 24 Hertz (Interlaced)
1920 x 1080 x 4294967296 colors @ 25 Hertz (Interlaced)
1920 x 1080 x 4294967296 colors @ 30 Hertz (Interlaced)
1920 x 1080 x 4294967296 colors @ 50 Hertz (Interlaced)
1920 x 1080 x 4294967296 colors @ 60 Hertz
1920 x 1440 x 4294967296 colors @ 60 Hertz
2048 x 1152 x 4294967296 colors @ 60 Hertz
3840 x 2160 x 4294967296 colors @ 24 Hertz (Interlaced)
3840 x 2160 x 4294967296 colors @ 25 Hertz (Interlaced)
3840 x 2160 x 4294967296 colors @ 30 Hertz (Interlaced)
4096 x 2160 x 4294967296 colors @ 24 Hertz (Interlaced)
4096 x 2160 x 4294967296 colors @ 25 Hertz (Interlaced)
4096 x 2160 x 4294967296 colors @ 30 Hertz (Interlaced)
```

WMI 是否可以返回视频模式取决于您的视频适配器和驱动程序。如果没有可用的视频模式，则不返回任何内容。

要检查您的视频适配器，请使用 `Win32_VideoController` WMI类：

```powershell
PS> Get-CimInstance -ClassName CIM_VideoController -Property *


Caption                      : Intel(R) Iris(R) Plus Graphics
Description                  : Intel(R) Iris(R) Plus Graphics
InstallDate                  :
Name                         : Intel(R) Iris(R) Plus Graphics
Status                       : OK
Availability                 : 3
ConfigManagerErrorCode       : 0
ConfigManagerUserConfig      : False
CreationClassName            : Win32_VideoController
DeviceID                     : VideoController3
ErrorCleared                 :
ErrorDescription             :
LastErrorCode                :
PNPDeviceID                  : PCI\VEN_8086&DEV_8A52&SUBSYS_08B01028&REV_07\3&11583659&0&10
PowerManagementCapabilities  :
PowerManagementSupported     :
StatusInfo                   :
SystemCreationClassName      : Win32_ComputerSystem
SystemName                   : DESKTOP-8DVNI43
MaxNumberControlled          :
ProtocolSupported            :
TimeOfLastReset              :
AcceleratorCapabilities      :
CapabilityDescriptions       :
CurrentBitsPerPixel          : 32
CurrentHorizontalResolution  : 3840
CurrentNumberOfColors        : 4294967296
CurrentNumberOfColumns       : 0
CurrentNumberOfRows          : 0
CurrentRefreshRate           : 59
CurrentScanMode              : 4
CurrentVerticalResolution    : 2400
MaxMemorySupported           :
MaxRefreshRate               : 0
MinRefreshRate               :
NumberOfVideoPages           :
VideoMemoryType              : 2
VideoProcessor               : Intel(R) Iris(R) Graphics Family
NumberOfColorPlanes          :
VideoArchitecture            : 5
VideoMode                    :
AdapterCompatibility         : Intel Corporation
AdapterDACType               : Internal
AdapterRAM                   : 1073741824
ColorTableEntries            :
DeviceSpecificPens           :
DitherType                   : 0
DriverDate                   : 06.11.2019 01:00:00
DriverVersion                : 26.20.100.7463
ICMIntent                    :
ICMMethod                    :
InfFilename                  : oem105.inf
InfSection                   : iICLD_w10_DS_N
InstalledDisplayDrivers      : C:\Windows\System32\DriverStore\FileRepository\iigd_dch.inf_amd64_fdbe15db86939fb5\igdumdim64.dll,C:\Windows\System32\DriverStore\FileRepository\iigd_dch.inf
                                _amd64_fdbe15db86939fb5\igd10iumd64.dll,C:\Windows\System32\DriverStore\FileRepository\iigd_dch.inf_amd64_fdbe15db86939fb5\igd10iumd64.dll,C:\Windows\System3
                                2\DriverStore\FileRepository\iigd_dch.inf_amd64_fdbe15db86939fb5\igd12umd64.dll
Monochrome                   : False
ReservedSystemPaletteEntries :
SpecificationVersion         :
SystemPaletteEntries         :
VideoModeDescription         : 3840 x 2400 x 4294967296 colors
PSComputerName               :
CimClass                     : root/cimv2:Win32_VideoController
CimInstanceProperties        : {Caption, Description, InstallDate, Name...}
CimSystemProperties          : Microsoft.Management.Infrastructure.CimSystemProperties
```

有关这两个类的文档，请访问 [http://powershell.one/wmi/root/cimv2/cim_videocontrollerresolution](http://powershell.one/wmi/root/cimv2/cim_videocontrollerresolution) 和 [http://powershell.one/wmi/root/cimv2/win32_videocontroller](http://powershell.one/wmi/root/cimv2/win32_videocontroller)。

<!--本文国际来源：[Getting Available Video Resolutions](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/getting-available-video-resolutions)-->

