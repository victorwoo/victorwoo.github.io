---
layout: post
date: 2023-03-14 00:00:30
title: "PowerShell 技能连载 - 自动化操作 Defender 杀毒软件（第 2 部分）"
description: PowerTip of the Day - Automating Defender Antivirus (Part 2)
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
在 Windows 上，PowerShell 带有用于自动化内置防病毒引擎 "Defender" 的 cmdlet。在第二部分中，让我们看看如何找出在您的计算机上活动的防病毒设置：

```powershell
PS C:\> Get-MpPreference


AllowDatagramProcessingOnWinServer            : False
AllowNetworkProtectionDownLevel               : False
AllowNetworkProtectionOnWinServer             : False
AllowSwitchToAsyncInspection                  : False
AttackSurfaceReductionOnlyExclusions          : {N/A: Must be and administrator to view exclusions}
AttackSurfaceReductionRules_Actions           :
AttackSurfaceReductionRules_Ids               :
CheckForSignaturesBeforeRunningScan           : False
CloudBlockLevel                               : 1
CloudExtendedTimeout                          : 1
ComputerID                                    : 7AB83555-0B97-47C7-A67C-8778E4757F65
ControlledFolderAccessAllowedApplications     : {N/A: Must be and administrator to view exclusions}
ControlledFolderAccessProtectedFolders        :
DefinitionUpdatesChannel                      : 0
DisableArchiveScanning                        : False
DisableAutoExclusions                         : False
DisableBehaviorMonitoring                     : False
DisableBlockAtFirstSeen                       : False
DisableCatchupFullScan                        : True
DisableCatchupQuickScan                       : True
DisableCpuThrottleOnIdleScans                 : True
DisableDatagramProcessing                     : False
DisableDnsOverTcpParsing                      : False
DisableDnsParsing                             : False
DisableEmailScanning                          : True
DisableFtpParsing                             : False
DisableGradualRelease                         : False
DisableHttpParsing                            : False
DisableInboundConnectionFiltering             : False
DisableIOAVProtection                         : False
DisableNetworkProtectionPerfTelemetry         : False
DisablePrivacyMode                            : False
DisableRdpParsing                             : False
DisableRealtimeMonitoring                     : False
DisableRemovableDriveScanning                 : True
DisableRestorePoint                           : True
DisableScanningMappedNetworkDrivesForFullScan : True
DisableScanningNetworkFiles                   : False
DisableScriptScanning                         : False
DisableSmtpParsing                            : False
DisableSshParsing                             : False
DisableTlsParsing                             : False
EnableControlledFolderAccess                  : 0
EnableDnsSinkhole                             : True
EnableFileHashComputation                     : False
EnableFullScanOnBatteryPower                  : False
EnableLowCpuPriority                          : False
EnableNetworkProtection                       : 0
EngineUpdatesChannel                          : 0
ExclusionExtension                            : {N/A: Must be and administrator to view exclusions}
ExclusionIpAddress                            : {N/A: Must be and administrator to view exclusions}
ExclusionPath                                 : {N/A: Must be and administrator to view exclusions}
ExclusionProcess                              : {N/A: Must be and administrator to view exclusions}
ForceUseProxyOnly                             : False
HighThreatDefaultAction                       : 0
IntelTDTEnabled                               : True
LowThreatDefaultAction                        : 0
MAPSReporting                                 : 2
MeteredConnectionUpdates                      : False
ModerateThreatDefaultAction                   : 0
PlatformUpdatesChannel                        : 0
ProxyBypass                                   :
ProxyPacUrl                                   :
ProxyServer                                   :
PUAProtection                                 : 1
QuarantinePurgeItemsAfterDelay                : 90
RandomizeScheduleTaskTimes                    : True
RealTimeScanDirection                         : 0
RemediationScheduleDay                        : 0
RemediationScheduleTime                       : 02:00:00
ReportDynamicSignatureDroppedEvent            : False
ReportingAdditionalActionTimeOut              : 10080
ReportingCriticalFailureTimeOut               : 10080
ReportingNonCriticalTimeOut                   : 1440
ScanAvgCPULoadFactor                          : 50
ScanOnlyIfIdleEnabled                         : True
ScanParameters                                : 1
ScanPurgeItemsAfterDelay                      : 10
ScanScheduleDay                               : 0
ScanScheduleOffset                            : 120
ScanScheduleQuickScanTime                     : 00:00:00
ScanScheduleTime                              : 02:00:00
SchedulerRandomizationTime                    : 4
ServiceHealthReportInterval                   : 60
SevereThreatDefaultAction                     : 0
SharedSignaturesPath                          :
SignatureAuGracePeriod                        : 0
SignatureBlobFileSharesSources                :
SignatureBlobUpdateInterval                   : 60
SignatureDefinitionUpdateFileSharesSources    :
SignatureDisableUpdateOnStartupWithoutEngine  : False
SignatureFallbackOrder                        : MicrosoftUpdateServer|MMPC
SignatureFirstAuGracePeriod                   : 120
SignatureScheduleDay                          : 8
SignatureScheduleTime                         : 01:45:00
SignatureUpdateCatchupInterval                : 1
SignatureUpdateInterval                       : 0
SubmitSamplesConsent                          : 1
ThreatIDDefaultAction_Actions                 : {6}
ThreatIDDefaultAction_Ids                     : {311978}
ThrottleForScheduledScanOnly                  : True
TrustLabelProtectionStatus                    : 0
UILockdown                                    : False
UnknownThreatDefaultAction                    : 0
PSComputerName                                :
```

从结果中可以看到，一些设置是受保护的，需要管理员权限才能查询。

如果您想更改防病毒软件设置，只需使用 `Set-MpPreference` 命令。

当然，您可以使用 `Select-Object` 命令过滤返回的信息以回答特定问题，但如果您想根据值过滤信息怎么办？比如说，您需要一份当前关闭的所有功能的列表？

以下是一种聪明的方法，使用底层的 PSObject 列出所有属性的名称，然后根据它们的值进行过滤：

```powershell
$preference = Get-MpPreference
[PSObject]$psObject = $preference.PSObject
$psObject.Properties | Where-Object {
    $_.Value -is [bool] -and $_.Value -eq $true
    } | Select-Object -ExpandProperty Name
```

同样，下面的代码列出了所有当前已禁用的属性（值为 `$false`）：

```powershell
$preference = Get-MpPreference
[PSObject]$psObject = $preference.PSObject
$psObject.Properties | Where-Object {
    $_.Value -is [bool] -and $_.Value -eq $false
    } | Select-Object -ExpandProperty Name
```

由于上述方法可以根据任何属性值进行过滤，因此您可以轻松地调整它，例如只转储包含小于 500 的 `[byte]` 属性：

```powershell
$preference = Get-MpPreference
[PSObject]$psObject = $preference.PSObject
$psObject.Properties | Where-Object {
    $_.Value -is [byte] -and $_.Value -lt 500
    } | Select-Object -Property Name, Value
```

以下是执行结果：

    Name                         Value
    ----                         -----
    CloudBlockLevel                  1
    DefinitionUpdatesChannel         0
    EnableControlledFolderAccess     0
    EnableNetworkProtection          0
    EngineUpdatesChannel             0
    HighThreatDefaultAction          0
    LowThreatDefaultAction           0
    MAPSReporting                    2
    ModerateThreatDefaultAction      0
    PlatformUpdatesChannel           0
    PUAProtection                    1
    RealTimeScanDirection            0
    RemediationScheduleDay           0
    ScanAvgCPULoadFactor            50
    ScanParameters                   1
    ScanScheduleDay                  0
    SevereThreatDefaultAction        0
    SignatureScheduleDay             8
    SubmitSamplesConsent             1
    UnknownThreatDefaultAction       0

现在，我们总结一下：通过将代码封装在函数中，您使代码可以重复使用，自动添加可扩展性（在上面的示例中，我们现在可以在同一个调用中转换一个或数千个字符串），并且您的生产脚本代码变得更短，可以集中精力完成真正想要实现的任务。

```powershell
PS C:\> Get-Command -Module ConfigDefender

CommandType     Name                                   Version    Source
-----------     ----                                   -------    ------
Function        Add-MpPreference                       1.0        ConfigDefender
Function        Get-MpComputerStatus                   1.0        ConfigDefender
Function        Get-MpPreference                       1.0        ConfigDefender
Function        Get-MpThreat                           1.0        ConfigDefender
Function        Get-MpThreatCatalog                    1.0        ConfigDefender
Function        Get-MpThreatDetection                  1.0        ConfigDefender
Function        Remove-MpPreference                    1.0        ConfigDefender
Function        Remove-MpThreat                        1.0        ConfigDefender
Function        Set-MpPreference                       1.0        ConfigDefender
Function        Start-MpRollback                       1.0        ConfigDefender
Function        Start-MpScan                           1.0        ConfigDefender
Function        Start-MpWDOScan                        1.0        ConfigDefender
Function        Update-MpSignature                     1.0        ConfigDefender
```
<!--本文国际来源：[Automating Defender Antivirus (Part 2)](https://blog.idera.com/database-tools/powershell/powertips/automating-defender-antivirus-part-2/)-->

