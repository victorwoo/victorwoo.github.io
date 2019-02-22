---
layout: post
date: 2016-11-15 00:00:00
title: "PowerShell 技能连载 - systeminfo.exe 的最新替代"
description: PowerTip of the Day - Modern Replacement for systeminfo.exe
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
曾几何时，systeminfo.exe 返回一台电脑所有的分析信息，并且有一些能够在 PowerShell 中变成面向对象的：

    PS C:\> $info = systeminfo.exe /FO CSV | ConvertFrom-Csv

    PS C:\> $info.Domain
    WORKGROUP
    
    PS C:\> $info.'Logon Server'
    \\DESKTOP-7AAMJLF

在 PowerShell 5.1 （Windows 10 和 Server 2016 ）中，有一个现代的替代品：

    PS C:\> Get-ComputerInfo
    
    
    WindowsBuildLabEx                                       : 14393.321.amd64fre.rs1_release_inmarket.161004-2338
    WindowsCurrentVersion                                   : 6.3
    WindowsEditionId                                        : Professional
    WindowsInstallationType                                 : Client
    WindowsInstallDateFromRegistry                          : 8/17/2016 1:40:27 PM
    WindowsProductId                                        : 00350-50721-50845-ACOEM
    WindowsProductName                                      : Windows 10 Pro
    WindowsRegisteredOrganization                           : 
    WindowsRegisteredOwner                                  : topoftheworld
    WindowsSystemRoot                                       : C:\WINDOWS
    BiosCharacteristics                                     : {7, 9, 11, 12...}
    BiosBIOSVersion                                         : {DELL   - 1072009, 1.4.4, American Megatrends - 5000B}
    BiosBuildNumber                                         : 
    BiosCaption                                             : 1.4.4
    BiosCodeSet                                             : 
    BiosCurrentLanguage                                     : en|US|iso8859-1
    BiosDescription                                         : 1.4.4
    BiosEmbeddedControllerMajorVersion                      : 255
    BiosEmbeddedControllerMinorVersion                      : 255
    BiosFirmwareType                                        : Uefi
    BiosIdentificationCode                                  : 
    BiosInstallableLanguages                                : 2
    BiosInstallDate                                         : 
    BiosLanguageEdition                                     : 
    BiosListOfLanguages                                     : {en|US|iso8859-1, }
    BiosManufacturer                                        : Dell Inc.
    BiosName                                                : 1.4.4
    BiosOtherTargetOS                                       : 
    BiosPrimaryBIOS                                         : True
    BiosReleaseDate                                         : 6/14/2016 2:00:00 AM
    BiosSeralNumber                                         : DLGQD72
    BiosSMBIOSBIOSVersion                                   : 1.4.4
    BiosSMBIOSMajorVersion                                  : 2
    BiosSMBIOSMinorVersion                                  : 8
    BiosSMBIOSPresent                                       : True
    BiosSoftwareElementState                                : Running
    BiosStatus                                              : OK
    BiosSystemBiosMajorVersion                              : 1
    BiosSystemBiosMinorVersion                              : 4
    BiosTargetOperatingSystem                               : 0
    BiosVersion                                             : DELL   - 1072009
    CsAdminPasswordStatus                                   : Unknown
    CsAutomaticManagedPagefile                              : True
    CsAutomaticResetBootOption                              : True
    CsAutomaticResetCapability                              : True
    CsBootOptionOnLimit                                     : 
    CsBootOptionOnWatchDog                                  : 
    CsBootROMSupported                                      : True
    CsBootStatus                                            : {0, 0, 0, 0...}
    CsBootupState                                           : Normal boot
    CsCaption                                               : CLIENT
    CsChassisBootupState                                    : Safe
    CsChassisSKUNumber                                      : Laptop
    CsCurrentTimeZone                                       : 120
    CsDaylightInEffect                                      : True
    CsDescription                                           : AT/AT COMPATIBLE
    CsDNSHostName                                           : DESKTOP-7AAMJLF
    CsDomain                                                : WORKGROUP
    CsDomainRole                                            : StandaloneWorkstation
    CsEnableDaylightSavingsTime                             : True
    CsFrontPanelResetStatus                                 : Unknown
    CsHypervisorPresent                                     : False
    CsInfraredSupported                                     : False
    CsInitialLoadInfo                                       : 
    CsInstallDate                                           : 
    CsKeyboardPasswordStatus                                : Unknown
    CsLastLoadInfo                                          : 
    CsManufacturer                                          : Dell Inc.
    CsModel                                                 : XPS 13 9350
    CsName                                                  : CLIENT
    CsNetworkAdapters                                       : {WiFi, Bluetooth-Netzwerkverbindung}
    CsNetworkServerModeEnabled                              : True
    CsNumberOfLogicalProcessors                             : 4
    CsNumberOfProcessors                                    : 1
    CsProcessors                                            : {Intel(R) Core(TM) i7-6500U CPU @ 2.50GHz}
    CsOEMStringArray                                        : {Dell System, 1[0704], 3[1.0], 12[www.dell.com]...}
    CsPartOfDomain                                          : False
    CsPauseAfterReset                                       : -1
    CsPCSystemType                                          : Mobile
    CsPCSystemTypeEx                                        : Mobile
    CsPowerManagementCapabilities                           : 
    CsPowerManagementSupported                              : 
    CsPowerOnPasswordStatus                                 : Unknown
    CsPowerState                                            : Unknown
    CsPowerSupplyState                                      : Safe
    CsPrimaryOwnerContact                                   : 
    CsPrimaryOwnerName                                      : user@company.de
    CsResetCapability                                       : Other
    CsResetCount                                            : -1
    CsResetLimit                                            : -1
    CsRoles                                                 : {LM_Workstation, LM_Server, NT, Potential_Browser...}
    CsStatus                                                : OK
    CsSupportContactDescription                             : 
    CsSystemFamily                                          : 
    CsSystemSKUNumber                                       : 0704
    CsSystemType                                            : x64-based PC
    CsThermalState                                          : Safe
    CsTotalPhysicalMemory                                   : 17045016576
    CsPhyicallyInstalledMemory                              : 16777216
    CsUserName                                              : CLIENT12\TEST
    CsWakeUpType                                            : PowerSwitch
    CsWorkgroup                                             : WORKGROUP
    OsName                                                  : Microsoft Windows 10 Pro
    OsType                                                  : WINNT
    OsOperatingSystemSKU                                    : 48
    OsVersion                                               : 10.0.14393
    OsCSDVersion                                            : 
    OsBuildNumber                                           : 14393
    OsHotFixes                                              : {KB3176936, KB3194343, KB3199209, KB3199986...}
    OsBootDevice                                            : \Device\HarddiskVolume1
    OsSystemDevice                                          : \Device\HarddiskVolume3
    OsSystemDirectory                                       : C:\WINDOWS\system32
    OsSystemDrive                                           : C:
    OsWindowsDirectory                                      : C:\WINDOWS
    OsCountryCode                                           : 1
    OsCurrentTimeZone                                       : 120
    OsLocaleID                                              : 0409
    OsLocale                                                : en-US
    OsLocalDateTime                                         : 10/28/2016 4:11:51 PM
    OsLastBootUpTime                                        : 10/19/2016 7:48:03 AM
    OsUptime                                                : 9.08:23:47.7627676
    OsBuildType                                             : Multiprocessor Free
    OsCodeSet                                               : 1252
    OsDataExecutionPreventionAvailable                      : True
    OsDataExecutionPrevention32BitApplications              : True
    OsDataExecutionPreventionDrivers                        : True
    OsDataExecutionPreventionSupportPolicy                  : OptIn
    OsDebug                                                 : False
    OsDistributed                                           : False
    OsEncryptionLevel                                       : 256
    OsForegroundApplicationBoost                            : Maximum
    OsTotalVisibleMemorySize                                : 16645524
    OsFreePhysicalMemory                                    : 9128212
    OsTotalVirtualMemorySize                                : 19135892
    OsFreeVirtualMemory                                     : 8607696
    OsInUseVirtualMemory                                    : 10528196
    OsTotalSwapSpaceSize                                    : 
    OsSizeStoredInPagingFiles                               : 2490368
    OsFreeSpaceInPagingFiles                                : 2442596
    OsPagingFiles                                           : {C:\pagefile.sys}
    OsHardwareAbstractionLayer                              : 10.0.14393.206
    OsInstallDate                                           : 8/17/2016 3:40:27 PM
    OsManufacturer                                          : Microsoft Corporation
    OsMaxNumberOfProcesses                                  : 4294967295
    OsMaxProcessMemorySize                                  : 137438953344
    OsMuiLanguages                                          : {de-DE, en-US}
    OsNumberOfLicensedUsers                                 : 
    OsNumberOfProcesses                                     : 157
    OsNumberOfUsers                                         : 2
    OsOrganization                                          : 
    OsArchitecture                                          : 64-bit
    OsLanguage                                              : de-DE
    OsProductSuites                                         : {TerminalServicesSingleSession}
    OsOtherTypeDescription                                  : 
    OsPAEEnabled                                            : 
    OsPortableOperatingSystem                               : False
    OsPrimary                                               : True
    OsProductType                                           : WorkStation
    OsRegisteredUser                                        : test@company.com
    OsSerialNumber                                          : 00330-50021-50665-AAOEM
    OsServicePackMajorVersion                               : 0
    OsServicePackMinorVersion                               : 0
    OsStatus                                                : OK
    OsSuites                                                : {TerminalServices, TerminalServicesSingleSession}
    OsServerLevel                                           : 
    KeyboardLayout                                          : de-DE
    TimeZone                                                : (UTC+01:00) Amsterdam, Berlin, Bern, Rome, Stockholm, Vienna
    LogonServer                                             : \\CLIENT
    PowerPlatformRole                                       : Mobile
    HyperVisorPresent                                       : False
    HyperVRequirementDataExecutionPreventionAvailable       : True
    HyperVRequirementSecondLevelAddressTranslation          : True
    HyperVRequirementVirtualizationFirmwareEnabled          : True
    HyperVRequirementVMMonitorModeExtensions                : True
    DeviceGuardSmartStatus                                  : Off
    DeviceGuardRequiredSecurityProperties                   : 
    DeviceGuardAvailableSecurityProperties                  : 
    DeviceGuardSecurityServicesConfigured                   : 
    DeviceGuardSecurityServicesRunning                      : 
    DeviceGuardCodeIntegrityPolicyEnforcementStatus         : 
    DeviceGuardUserModeCodeIntegrityPolicyEnforcementStatus :


<!--本文国际来源：[Modern Replacement for systeminfo.exe](http://community.idera.com/powershell/powertips/b/tips/posts/modern-replacement-for-systeminfo-exe)-->
