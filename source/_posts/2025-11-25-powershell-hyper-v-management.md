---
layout: post
date: 2025-11-25 08:00:00
updated: 2025-11-25 08:00:00
title: "PowerShell 技能连载 - Hyper-V 虚拟机管理"
description: PowerTip of the Day - Hyper-V Virtual Machine Management in PowerShell
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
- hyper-v
- virtual-machine
- vm
- windows-server
---

_适用于 PowerShell 5.1 及以上版本（Windows），需要 Hyper-V 角色_

Hyper-V 是微软提供的原生虚拟化平台，从 Windows Server 2008 开始内置，在 Windows 10/11 专业版和企业版中同样可用。对于系统管理员和 DevOps 工程师来说，能够通过脚本批量管理虚拟机是提高效率的关键。PowerShell 的 Hyper-V 模块提供了完整的 cmdlet 集，覆盖虚拟机的创建、配置、启动、快照、迁移等全生命周期操作。

在实际运维场景中，手动通过 Hyper-V 管理器操作几台虚拟机尚可应付，但当你需要管理数十甚至上百台虚拟机时，手动操作不仅耗时，还容易出错。通过 PowerShell 脚本，我们可以将日常的虚拟机管理任务自动化，比如批量创建开发环境、定期检查虚拟机状态、自动创建检查点等。

本文将通过几个实用的示例，展示如何使用 PowerShell 完成 Hyper-V 虚拟机的日常管理任务，包括查询状态、批量创建虚拟机、管理检查点以及资源监控。

## 查询虚拟机状态

最基础的操作是了解当前 Hyper-V 主机上有哪些虚拟机以及它们的运行状态。使用 `Get-VM` 可以快速获取这些信息。

```powershell
# 查询所有虚拟机的基本信息
Get-VM | Select-Object Name, State, CPUUsage, MemoryAssigned, Uptime,
    @{N = 'MemoryMB'; E = { [math]::Round($_.MemoryAssigned / 1MB, 0) } } |
    Format-Table -AutoSize
```

这段代码使用 `Get-VM` 获取所有虚拟机对象，然后通过 `Select-Object` 提取关键字段。其中 `MemoryAssigned` 原始值以字节为单位，我们用计算属性将其转换为兆字节（MB）以便阅读。

执行结果示例：

```
Name            State      CPUUsage MemoryAssigned     Uptime MemoryMB
----            -----      -------- --------------     ------ --------
Ubuntu-Dev      Running          12      2147483648  12:34:56     2048
Win2022-Test    Running           8      4294967296  06:12:30     4096
CentOS-Build    Off               0               0  00:00:00        0
Win11-Client    Saved             0               0  00:00:00        0
Docker-Host     Running          25      2147483648  03:45:12     2048
```

如果只想查看正在运行的虚拟机，可以加上过滤条件：

```powershell
# 仅查询正在运行的虚拟机
Get-VM | Where-Object { $_.State -eq 'Running' } |
    Select-Object Name, @{N = 'CPU(%)'; E = { $_.CPUUsage } },
    @{N = 'MemGB'; E = { [math]::Round($_.MemoryAssigned / 1GB, 2) } }
```

执行结果示例：

```
Name         CPU(%) MemGB
----         ------ -----
Ubuntu-Dev       12  2.00
Win2022-Test      8  4.00
Docker-Host      25  2.00
```

## 批量创建虚拟机

在搭建测试环境时，经常需要一次性创建多台虚拟机。手动一台台创建费时费力，下面的脚本可以批量完成这项工作。

```powershell
# 批量创建虚拟机的配置参数
$vmConfigs = @(
    @{
        Name   = 'Test-Web01'
        Memory = 2GB
        VHDSize = 60GB
        Switch = 'Default Switch'
    }
    @{
        Name   = 'Test-DB01'
        Memory = 4GB
        VHDSize = 120GB
        Switch = 'Default Switch'
    }
    @{
        Name   = 'Test-API01'
        Memory = 2GB
        VHDSize = 60GB
        Switch = 'Default Switch'
    }
)

# 获取 VHD 默认存储路径
$vhdPath = (Get-VMHost).VirtualHardDiskPath

foreach ($config in $vmConfigs) {
    $vhdFilePath = Join-Path $vhdPath "$($config.Name).vhdx"

    # 检查虚拟机是否已存在
    $existing = Get-VM -Name $config.Name -ErrorAction SilentlyContinue
    if ($existing) {
        Write-Host "跳过: 虚拟机 '$($config.Name)' 已存在" -ForegroundColor Yellow
        continue
    }

    Write-Host "正在创建虚拟机: $($config.Name)..." -ForegroundColor Cyan

    # 创建动态扩展的虚拟硬盘
    New-VHD -Path $vhdFilePath -SizeBytes $config.VHDSize -Dynamic |
        Out-Null

    # 创建虚拟机并挂载虚拟硬盘
    New-VM -Name $config.Name -MemoryStartupBytes $config.Memory `
        -VHDPath $vhdFilePath -SwitchName $config.Switch |
        Out-Null

    # 设置处理器数量
    Set-VM -Name $config.Name -ProcessorCount 2

    Write-Host "  完成: $($config.Name) (内存: $($config.Memory / 1GB)GB, " `
        "磁盘: $($config.VHDSize / 1GB)GB, 2 vCPU)" -ForegroundColor Green
}

Write-Host "`n批量创建完成!" -ForegroundColor Green
```

这个脚本首先定义了一个配置数组，包含每台虚拟机的名称、内存大小、磁盘大小和虚拟交换机名称。然后遍历配置数组，逐一创建虚拟硬盘和虚拟机。脚本还加入了重复检查逻辑，避免在已有同名虚拟机时报错。

执行结果示例：

```
正在创建虚拟机: Test-Web01...
  完成: Test-Web01 (内存: 2GB, 磁盘: 60GB, 2 vCPU)
正在创建虚拟机: Test-DB01...
  完成: Test-DB01 (内存: 4GB, 磁盘: 120GB, 2 vCPU)
正在创建虚拟机: Test-API01...
  完成: Test-API01 (内存: 2GB, 磁盘: 60GB, 2 vCPU)

批量创建完成!
```

## 管理检查点（快照）

检查点（Checkpoint，以前称为快照 Snapshot）是 Hyper-V 的重要功能，可以在虚拟机的特定时间点保存状态，方便后续回滚。下面的脚本展示了如何自动创建和还原检查点。

```powershell
# 为所有运行中的虚拟机创建带时间戳的检查点
$timestamp = Get-Date -Format 'yyyy-MM-dd_HHmm'
$runningVMs = Get-VM | Where-Object { $_.State -eq 'Running' }

foreach ($vm in $runningVMs) {
    $checkpointName = "AutoBackup_$timestamp"
    Write-Host "正在为 '$($vm.Name)' 创建检查点: $checkpointName"
    Checkpoint-VM -VM $vm -SnapshotName $checkpointName
}

Write-Host "`n所有检查点创建完成" -ForegroundColor Green
```

这段代码筛选出所有正在运行的虚拟机，为每台创建一个带有时间戳标记的检查点。这种做法特别适合在做系统更新或软件升级前保存一个回滚点。

执行结果示例：

```
正在为 'Ubuntu-Dev' 创建检查点: AutoBackup_2025-11-25_0800
正在为 'Win2022-Test' 创建检查点: AutoBackup_2025-11-25_0800
正在为 'Docker-Host' 创建检查点: AutoBackup_2025-11-25_0800

所有检查点创建完成
```

查询和还原检查点同样简单：

```powershell
# 查看指定虚拟机的检查点列表
$vmName = 'Win2022-Test'
Get-VMSnapshot -VMName $vmName |
    Select-Object Name, CreationTime, @{N = 'Type'; E = { $_.SnapshotType } } |
    Sort-Object CreationTime -Descending |
    Format-Table -AutoSize
```

执行结果示例：

```
Name                         CreationTime          Type
----                         ------------          ----
AutoBackup_2025-11-25_0800   2025/11/25 08:00:15 Standard
BeforePatch_2025-11-20       2025/11/20 14:30:22 Standard
CleanInstall                 2025/11/01 10:15:00 Standard
```

如果需要回滚到某个检查点：

```powershell
# 回滚虚拟机到指定检查点
$snapshot = Get-VMSnapshot -VMName 'Win2022-Test' |
    Where-Object { $_.Name -eq 'BeforePatch_2025-11-20' }

if ($snapshot) {
    Write-Host "正在将 'Win2022-Test' 回滚到 '$($snapshot.Name)'..."
    Restore-VMSnapshot -VMSnapshot $snapshot -Confirm:$false
    Write-Host "回滚完成" -ForegroundColor Green
} else {
    Write-Host "未找到指定的检查点" -ForegroundColor Red
}
```

执行结果示例：

```
正在将 'Win2022-Test' 回滚到 'BeforePatch_2025-11-20'...
回滚完成
```

## 批量启停虚拟机

在测试环境中，可能需要按特定顺序启动或关闭一组虚拟机。例如先启动数据库服务器，再启动应用服务器和 Web 服务器。PowerShell 可以精确控制这个流程。

```powershell
# 按顺序启动虚拟机组
$startOrder = @('Test-DB01', 'Test-API01', 'Test-Web01')

foreach ($vmName in $startOrder) {
    $vm = Get-VM -Name $vmName -ErrorAction SilentlyContinue

    if (-not $vm) {
        Write-Host "跳过: 虚拟机 '$vmName' 不存在" -ForegroundColor Yellow
        continue
    }

    if ($vm.State -eq 'Running') {
        Write-Host "跳过: '$vmName' 已在运行" -ForegroundColor Gray
        continue
    }

    Write-Host "正在启动: $vmName" -ForegroundColor Cyan
    Start-VM -Name $vmName

    # 等待虚拟机进入运行状态
    $timeout = 60
    $elapsed = 0
    while ((Get-VM -Name $vmName).State -ne 'Running' -and $elapsed -lt $timeout) {
        Start-Sleep -Seconds 2
        $elapsed += 2
    }

    if ((Get-VM -Name $vmName).State -eq 'Running') {
        Write-Host "  已启动: $vmName (等待 $($elapsed)s)" -ForegroundColor Green
    } else {
        Write-Host "  超时: $vmName 未能在 ${timeout}s 内启动" -ForegroundColor Red
    }
}
```

这段脚本按照指定的顺序逐台启动虚拟机，并在每台启动后等待确认其进入 Running 状态再继续下一台，确保服务依赖关系正确。同时加入了超时机制，避免某台虚拟机启动失败时脚本无限等待。

执行结果示例：

```
正在启动: Test-DB01
  已启动: Test-DB01 (等待 8s)
正在启动: Test-API01
  已启动: Test-API01 (等待 6s)
正在启动: Test-Web01
  已启动: Test-Web01 (等待 4s)
```

关闭虚拟机时，建议优先使用正常关机而非强制断电：

```powershell
# 优雅关闭所有运行中的虚拟机
$runningVMs = Get-VM | Where-Object { $_.State -eq 'Running' }

foreach ($vm in $runningVMs) {
    Write-Host "正在关闭: $($vm.Name)" -ForegroundColor Cyan
    Stop-VM -Name $vm.Name -Force

    # 等待虚拟机完全关闭
    $count = 0
    while ((Get-VM -Name $vm.Name).State -ne 'Off' -and $count -lt 30) {
        Start-Sleep -Seconds 2
        $count++
    }

    $finalState = (Get-VM -Name $vm.Name).State
    if ($finalState -eq 'Off') {
        Write-Host "  已关闭: $($vm.Name)" -ForegroundColor Green
    } else {
        Write-Host "  强制关闭: $($vm.Name)" -ForegroundColor Yellow
        Stop-VM -Name $vm.Name -TurnOff -Force
    }
}
```

`Stop-VM` 默认会向虚拟机发送关机信号（类似于按下电源按钮），操作系统正常处理后关闭。如果虚拟机在一定时间内没有响应关机信号，脚本会使用 `-TurnOff` 参数强制断电。

执行结果示例：

```
正在关闭: Ubuntu-Dev
  已关闭: Ubuntu-Dev
正在关闭: Win2022-Test
  已关闭: Win2022-Test
正在关闭: Docker-Host
  已关闭: Docker-Host
```

## 资源使用监控

监控虚拟机的资源使用情况是运维的重要环节。下面的脚本会收集所有虚拟机的 CPU、内存和磁盘使用信息，并生成一个汇总报告。

```powershell
# 虚拟机资源使用报告
$report = foreach ($vm in Get-VM) {
    $vhd = Get-VMHardDiskDrive -VMName $vm.Name |
        Select-Object -First 1

    $vhdInfo = $null
    if ($vhd -and (Test-Path $vhd.Path)) {
        $vhdItem = Get-VHD -Path $vhd.Path
        $vhdInfo = @{
            SizeGB   = [math]::Round($vhdItem.Size / 1GB, 1)
            UsedGB   = [math]::Round($vhdItem.FileSize / 1GB, 1)
            Fragment = [math]::Round($vhdItem.FragmentationPercentage, 1)
        }
    }

    [PSCustomObject]@{
        Name          = $vm.Name
        State         = $vm.State
        CPUUsage      = "$($vm.CPUUsage)%"
        MemoryGB      = [math]::Round($vm.MemoryAssigned / 1GB, 2)
        MemDemandGB   = [math]::Round($vm.MemoryDemand / 1GB, 2)
        DiskSizeGB    = if ($vhdInfo) { $vhdInfo.SizeGB } else { 'N/A' }
        DiskUsedGB    = if ($vhdInfo) { $vhdInfo.UsedGB } else { 'N/A' }
        Uptime        = $vm.Uptime.ToString('dd\天hh\时mm\分')
    }
}

$report | Format-Table -AutoSize

# 输出汇总统计
$totalRunning = ($report | Where-Object { $_.State -eq 'Running' }).Count
$totalMemGB = ($report | Where-Object { $_.State -eq 'Running' } |
    Measure-Object -Property MemoryGB -Sum).Sum

Write-Host "`n--- 汇总 ---" -ForegroundColor Cyan
Write-Host "虚拟机总数: $(($report).Count)"
Write-Host "运行中: $totalRunning"
Write-Host "总内存占用: $([math]::Round($totalMemGB, 1)) GB"
```

这个脚本通过 `Get-VM` 获取虚拟机基本信息，再结合 `Get-VMHardDiskDrive` 和 `Get-VHD` 获取磁盘使用详情。最终生成一个格式化的报告，包含每台虚拟机的 CPU 使用率、内存分配与需求、磁盘容量与实际使用量等关键指标。

执行结果示例：

```
Name          State   CPUUsage MemoryGB MemDemandGB DiskSizeGB DiskUsedGB Uptime
----          -----   -------- -------- ----------- ---------- ---------- ------
Ubuntu-Dev    Running 12%           2        1.85       60.0       18.3  12天06时34分
Win2022-Test  Running 8%            4        3.42      120.0       45.7  06天12时30分
CentOS-Build  Off      0%           0        0            80.0       32.1  00天00时00分
Win11-Client  Saved    0%           0        0            60.0       25.6  00天00时00分
Docker-Host   Running 25%           2        1.92       60.0       22.8  03天15时45分

--- 汇总 ---
虚拟机总数: 5
运行中: 3
总内存占用: 8.0 GB
```

## 注意事项

- **权限要求**：管理 Hyper-V 虚拟机需要管理员权限，并且当前用户必须是 Hyper-V Administrators 组的成员。如果 cmdlet 执行失败，请以管理员身份运行 PowerShell 并检查组成员身份。
- **Hyper-V 模块可用性**：Hyper-V 模块仅在 Windows 上可用，且需要安装 Hyper-V 角色。在 Windows 10/11 上可以通过"启用或关闭 Windows 功能"安装，在 Windows Server 上通过 `Install-WindowsFeature Hyper-V-PowerShell` 安装。
- **检查点不是备份**：检查点依赖于虚拟硬盘的差异链，不能替代完整的虚拟机备份。生产环境中务必配合 Windows Server Backup 或第三方备份方案使用，避免因宿主机故障导致数据丢失。
- **动态内存的影响**：使用动态内存时，`MemoryAssigned` 显示的是当前分配值，可能随负载变化。如果需要固定内存，创建虚拟机时应设置 `-MemoryMinimumBytes`、`-MemoryMaximumBytes` 和 `-MemoryStartupBytes` 为相同值。
- **虚拟硬盘类型选择**：`New-VHD` 支持 Fixed（固定大小）和 Dynamic（动态扩展）两种类型。动态扩展创建速度快、初始占用空间小，但 I/O 性能略低于固定大小。生产数据库等 I/O 密集型场景建议使用固定大小的虚拟硬盘。
- **网络适配器配置**：创建虚拟机时指定的虚拟交换机决定了网络连接方式。如果需要更灵活的网络配置，可以在创建后使用 `Add-VMNetworkAdapter` 添加额外的网络适配器，或用 `Set-VMNetworkAdapterVlan` 配置 VLAN 标签。
