---
layout: post
date: 2022-04-26 00:00:00
title: "PowerShell 技能连载 - 利用 WMI（第 5 部分）"
description: PowerTip of the Day - Leveraging WMI (Part 5)
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
WMI 类被组织在所谓的命名空间中，这些命名空间从“根”开始并像目录结构一样工作。默认命名空间是 root\cimv2，当不指定命名空间时，你只能看到位于默认命名空间中的 WMI 类。这是我们在本系列的过去部分中一直使用的。

还有更多带有许多附加 WMI 类的命名空间，其中一些非常有用。在我们探索 WMI 的这一部分之前，请注意，您将进入 Windows 的文档稀少的区域，这些区域不一定适用于一般受众。您可能需要 google，此处找到的类可能仅适用于特定的 Windows 操作系统和/或许可证类型。

要获取计算机上可用的 WMI 命名空间列表，请运行以下代码：

```powershell
# create a new queue
$namespaces = [System.Collections.Queue]::new()

# add an initial namespace to the queue
# any namespace in the queue will later be processed
$namespaces.Enqueue('root')

# process all elements on the queue until all are taken
While ($namespaces.Count -gt 0 -and ($current = $namespaces.Dequeue()))
{
    # find child namespaces
    Get-CimInstance -Namespace $current -ClassName __Namespace -ErrorAction Ignore |
    # ignore localization namespaces
    Where-Object Name -NotMatch '^ms_\d{2}' |
    ForEach-Object {
        # construct the full namespace name
        $childnamespace = '{0}\{1}' -f $current, $_.Name
        # add namespace to queue
        $namespaces.Enqueue($childnamespace)
    }

    # output current namespace
    $current
}
```

代码可能会运行一段时间，所以请喝杯咖啡。结果是您机器上可用的命名空间列表，可能类似于以下内容：

    root
    root\subscription
    root\DEFAULT
    root\CIMV2
    root\msdtc
    root\Cli
    root\Intel_ME
    root\SECURITY
    root\HyperVCluster
    root\SecurityCenter2
    root\RSOP
    root\PEH
    root\StandardCimv2
    root\WMI
    root\MSPS
    root\directory
    root\Policy
    root\virtualization
    root\Interop
    root\Hardware
    root\ServiceModel
    root\SecurityCenter
    root\Microsoft
    root\Appv
    root\dcim
    root\CIMV2\mdm
    root\CIMV2\Security
    root\CIMV2\power
    root\CIMV2\TerminalServices
    root\HyperVCluster\v2
    root\RSOP\User
    root\RSOP\Computer
    root\StandardCimv2\embedded
    root\directory\LDAP
    root\virtualization\v2
    root\Microsoft\HomeNet
    root\Microsoft\protectionManagement
    root\Microsoft\Windows
    root\Microsoft\SecurityClient
    root\Microsoft\Uev
    root\dcim\sysman
    root\CIMV2\mdm\dmmap
    root\CIMV2\Security\MicrosoftTpm
    root\CIMV2\Security\MicrosoftVolumeEncryption
    root\Microsoft\Windows\RemoteAccess
    root\Microsoft\Windows\Dns
    root\Microsoft\Windows\Powershellv3
    root\Microsoft\Windows\Hgs
    root\Microsoft\Windows\WindowsUpdate
    root\Microsoft\Windows\DeviceGuard
    root\Microsoft\Windows\TaskScheduler
    root\Microsoft\Windows\DesiredStateConfigurationProxy
    root\Microsoft\Windows\SmbWitness
    root\Microsoft\Windows\Wdac
    root\Microsoft\Windows\StorageReplica
    root\Microsoft\Windows\winrm
    root\Microsoft\Windows\AppBackgroundTask
    root\Microsoft\Windows\DHCP
    root\Microsoft\Windows\PS_MMAgent
    root\Microsoft\Windows\Storage
    root\Microsoft\Windows\HardwareManagement
    root\Microsoft\Windows\SMB
    root\Microsoft\Windows\EventTracingManagement
    root\Microsoft\Windows\DesiredStateConfiguration
    root\Microsoft\Windows\Attestation
    root\Microsoft\Windows\CI
    root\Microsoft\Windows\dfsn
    root\Microsoft\Windows\DeliveryOptimization
    root\Microsoft\Windows\Defender
    root\dcim\sysman\biosattributes
    root\dcim\sysman\wmisecurity
    root\Microsoft\Windows\RemoteAccess\Client
    root\Microsoft\Windows\Storage\PT
    root\Microsoft\Windows\Storage\Providers_v2
    root\Microsoft\Windows\Storage\PT\Alt

一旦您知道了命名空间的名称，就可以使用这个迷你系列的前面部分来查询位于给定命名空间中的 WMI 类名。例如，下面的代码列出了命名空间 "root\Microsoft\Windows\WindowsUpdate" 中的所有 WMI 类：

```powershell
$ns = 'root\Microsoft\Windows\WindowsUpdate'
Get-CimClass -Namespace $ns |
    Select-Object -ExpandProperty CimClassName |
    Sort-Object
```

以双下划线开头的类名用于内部用途：

    __AbsoluteTimerInstruction
    __ACE
    __AggregateEvent
    __ClassCreationEvent
    __ClassDeletionEvent
    __ClassModificationEvent
    __ClassOperationEvent
    __ClassProviderRegistration
    __ConsumerFailureEvent
    __Event
    __EventConsumer
    __EventConsumerProviderRegistration
    __EventDroppedEvent
    __EventFilter
    __EventGenerator
    __EventProviderRegistration
    __EventQueueOverflowEvent
    __ExtendedStatus
    __ExtrinsicEvent
    __FilterToConsumerBinding
    __IndicationRelated
    __InstanceCreationEvent
    __InstanceDeletionEvent
    __InstanceModificationEvent
    __InstanceOperationEvent
    __InstanceProviderRegistration
    __IntervalTimerInstruction
    __MethodInvocationEvent
    __MethodProviderRegistration
    __NAMESPACE
    __NamespaceCreationEvent
    __NamespaceDeletionEvent
    __NamespaceModificationEvent
    __NamespaceOperationEvent
    __NotifyStatus
    __NTLMUser9X
    __ObjectProviderRegistration
    __PARAMETERS
    __PropertyProviderRegistration
    __Provider
    __ProviderRegistration
    __QOSFailureEvent
    __SecurityDescriptor
    __SecurityRelatedClass
    __SystemClass
    __SystemEvent
    __SystemSecurity
    __thisNAMESPACE
    __TimerEvent
    __TimerInstruction
    __TimerNextFiring
    __Trustee
    __Win32Provider
    CIM_ClassCreation
    CIM_ClassDeletion
    CIM_ClassIndication
    CIM_ClassModification
    CIM_Error
    CIM_Indication
    CIM_InstCreation
    CIM_InstDeletion
    CIM_InstIndication
    CIM_InstModification
    MSFT_ExtendedStatus
    MSFT_WmiError
    MSFT_WUOperations
    MSFT_WUSettings
    MSFT_WUUpdate

要查询此命名空间中的 `MSFT_WUSettings` 类（如果存在于您的机器上），请运行以下命令：

```powershell
$ns = 'root\Microsoft\Windows\WindowsUpdate'
Get-CimInstance -ClassName MSFT_WUSettings -Namespace $ns
```

结果是一个异常，表明您在探索新的且文档稀少的内部 WMI 类时可能会感到意外。根据您的操作系统和许可证类型，可能支持也可能不支持操作。如果它们不受支持，您最终可能会遇到 "provider failure" 异常。

此外，某些 WMI 类（如此命名空间中的类）并非旨在包含属性和返回信息。相反，它们包含方法（命令），这个例子用于管理 Windows 更新：

```powershell
$ns = 'root\Microsoft\Windows\WindowsUpdate'
Get-CimClass -Namespace $ns -ClassName 'MSFT_WUOperations' |
    Select-Object -ExpandProperty CimClassMethods
```

结果显示了它的方法：

    Name           ReturnType Parameters                              Qualifiers
    ----           ---------- ----------                              ----------
    ScanForUpdates     UInt32 {SearchCriteria, Updates}               {implemented, static}
    InstallUpdates     UInt32 {DownloadOnly, Updates, RebootRequired} {implemented, static}

这是 Windows Server 2019 机器的实际示例。该脚本远程访问服务器（并行）并使用本地 WMI 检查安全更新，然后安装它们：

```powershell
# list of names of Windows Server 2019 machines to update:
$servers="Server2019-IIS","Server2019-AD"

$ns = "root/Microsoft/Windows/WindowsUpdate"
$class = "MSFT_WUOperations"

Invoke-Command -ComputerName $servers -ScriptBlock {
    # find missing updates:
    $arg = @{SearchCriteria="IsInstalled=0 AND AutoSelectOnWebSites=1"}
    $r = Invoke-CimMethod -Namespace $ns -ClassName $class -MethodName ScanForUpdates -Arguments $arg

    # install missing updates:
    if ($r.Updates)
    {
        $arg = @{Updates=$r.Updates}
        Invoke-CimMethod -Namespace $ns -ClassName $class -MethodName InstallUpdates -Arguments $arg
    }
}
```

请注意，上面的代码在 Windows Server 2019 上有效，但在 Windows Server 2016 上失败（因为 WMI 类名略有变化）。如果你还想深入挖掘，我们强烈推荐 [https://github.com/microsoft/MSLab/blob/master/Scenarios/Windows%20Update/readme.md](https://github.com/microsoft/MSLab/blob/master/Scenarios/Windows%20Update/readme.md) 这是一组关于如何使用 WMI 管理 Windows 服务器上的 Windows 更新的丰富示例。

如果您对 WMI 感兴趣，请前往 [https://powershell.one/wmi/commands](https://powershell.one/wmi/commands) 了解更多信息。

<!--本文国际来源：[Leveraging WMI (Part 5)](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/leveraging-wmi-part-5)-->

