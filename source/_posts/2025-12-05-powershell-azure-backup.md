---
layout: post
date: 2025-12-05 08:00:00
updated: 2025-12-05 08:00:00
title: "PowerShell 技能连载 - Azure 备份与恢复"
description: PowerTip of the Day - Azure Backup and Recovery in PowerShell
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
- azure
- best-practices
---

_适用于 PowerShell 7.0 及以上版本_

<!-- more -->

## 背景

数据备份是 IT 运维的基石。无论是意外删除、硬件故障还是勒索软件攻击，可靠的备份策略都是恢复业务运行的关键。Azure Backup 是微软提供的全托管备份服务，支持虚拟机、SQL 数据库、文件共享、Blob 存储等多种资源类型，并提供 99.999999999%（11 个 9）的数据持久性保障。

传统的备份方案需要自行维护备份软件、磁带库或专用存储设备，不仅成本高昂，而且运维复杂。Azure Backup 将这些基础设施全部托管化：备份存储自动管理、加密传输与静态加密、符合 GDPR 等合规要求。运维人员只需通过 Azure 门户或 PowerShell 定义备份策略，服务便会按照计划自动执行备份作业，并在需要时一键恢复。

本文将介绍如何通过 PowerShell 管理 Azure Backup 的核心操作，包括创建恢复服务保管库与配置备份策略、启用备份与监控备份作业状态，以及数据恢复与跨区域灾难恢复。每个场景都提供可执行的代码示例和输出演示。

## 恢复服务保管库与备份策略配置

恢复服务保管库（Recovery Services Vault）是 Azure Backup 的管理容器，所有备份策略、恢复点和备份作业都关联到保管库。以下代码演示了如何创建保管库、设置存储冗余类型，并为虚拟机配置每日备份策略。

```powershell
# 定义变量
$resourceGroup = 'rg-backup-demo'
$location = 'eastasia'
$vaultName = 'rsv-backup-demo'
$vmName = 'vm-prod-01'

# 创建资源组（如不存在）
$rg = Get-AzResourceGroup -Name $resourceGroup -ErrorAction SilentlyContinue
if (-not $rg) {
    $rg = New-AzResourceGroup -Name $resourceGroup -Location $location
    Write-Host "资源组已创建: $resourceGroup"
}

# 创建恢复服务保管库
$vault = New-AzRecoveryServicesVault `
    -Name $vaultName `
    -ResourceGroupName $resourceGroup `
    -Location $location

Write-Host "恢复服务保管库已创建: $($vault.Name)"

# 设置保管库存储冗余类型（必须在注册任何备份项之前设置）
# LocallyRedundant  - 本地冗余（成本最低）
# GeoRedundant      - 异地冗余（推荐生产环境）
Set-AzRecoveryServicesBackupProperty `
    -Vault $vault `
    -BackupStorageRedundancy GeoRedundant

Write-Host "存储冗余已设置为 GeoRedundant"

# 获取默认备份策略
$policy = Get-AzRecoveryServicesBackupPolicy `
    -VaultId $vault.ID `
    -Name 'DailyPolicy' -ErrorAction SilentlyContinue

if (-not $policy) {
    # 如果默认策略不存在，获取策略模板并自定义
    $schedulePolicy = Get-AzRecoveryServicesSchedulePolicyObject -WorkloadType AzureVM
    $schedulePolicy.ScheduleRunTimes = @(
        (Get-Date -Date '2025-12-05T02:00:00').ToUniversalTime()
    )

    $retentionPolicy = Get-AzRecoveryServicesRetentionPolicyObject -WorkloadType AzureVM
    $retentionPolicy.DailySchedule.DurationCountInDays = 30
    $retentionPolicy.MonthlySchedule.DurationCountInMonths = 12

    $policy = New-AzRecoveryServicesProtectionPolicy `
        -Name 'CustomDailyPolicy' `
        -WorkloadType AzureVM `
        -VaultId $vault.ID `
        -SchedulePolicy $schedulePolicy `
        -RetentionPolicy $retentionPolicy

    Write-Host "已创建自定义备份策略: $($policy.Name)"
} else {
    Write-Host "使用默认备份策略: $($policy.Name)"
}

# 启用虚拟机备份保护
$vm = Get-AzVM -Name $vmName -ResourceGroupName $resourceGroup
Enable-AzRecoveryServicesBackupProtection `
    -VaultId $vault.ID `
    -Policy $policy `
    -Name $vm.Name `
    -ResourceGroupName $vm.ResourceGroupName

Write-Host "已为虚拟机 $vmName 启用备份保护"

# 验证配置结果
$container = Get-AzRecoveryServicesBackupContainer `
    -VaultId $vault.ID `
    -ContainerType AzureVM `
    -FriendlyName $vmName -ErrorAction SilentlyContinue

if ($container) {
    Write-Host "验证成功: 虚拟机已注册到保管库"
    Write-Host "  注册状态: $($container.Registered)"
    Write-Host "  备份管理类型: $($container.BackupManagementType)"
}
```

恢复服务保管库的存储冗余类型有两种选择：本地冗余（LRS）将数据在同一数据中心内复制三份，适合开发测试环境；异地冗余（GRS）将备份数据复制到配对区域，推荐生产环境使用以获得跨区域灾难恢复能力。存储冗余类型必须在注册第一个备份项之前设置，之后无法更改。备份策略定义了备份的执行时间和保留周期，默认的每日策略会在凌晨 2 点执行备份并保留 30 天。

执行结果示例：

```
资源组已创建: rg-backup-demo
恢复服务保管库已创建: rsv-backup-demo
存储冗余已设置为 GeoRedundant
已创建自定义备份策略: CustomDailyPolicy
已为虚拟机 vm-prod-01 启用备份保护
验证成功: 虚拟机已注册到保管库
  注册状态: Registered
  备份管理类型: AzureIaasVM
```

## 启用备份与监控备份作业

除了按计划执行的定时备份外，在系统升级、重大变更前通常需要手动触发一次按需备份。以下代码演示了如何触发按需备份、查询备份作业状态以及监控备份健康度。

```powershell
# 定义变量
$vaultName = 'rsv-backup-demo'
$resourceGroup = 'rg-backup-demo'
$vmName = 'vm-prod-01'

$vault = Get-AzRecoveryServicesVault -Name $vaultName -ResourceGroupName $resourceGroup

# 获取备份保护容器
$container = Get-AzRecoveryServicesBackupContainer `
    -VaultId $vault.ID `
    -ContainerType AzureVM `
    -FriendlyName $vmName

# 获取备份项
$item = Get-AzRecoveryServicesBackupItem `
    -VaultId $vault.ID `
    -Container $container `
    -WorkloadType AzureVM

# 触发按需备份
$job = Backup-AzRecoveryServicesBackupItem `
    -VaultId $vault.ID `
    -Item $item

Write-Host "按需备份已触发"
Write-Host "  作业名称: $($job.Name)"
Write-Host "  作业状态: $($job.Status)"
Write-Host "  开始时间: $($job.StartTime)"

# 轮询等待备份完成（最多等待 30 分钟）
$maxWaitMinutes = 30
$waitedMinutes = 0

while ($job.Status -eq 'InProgress' -and $waitedMinutes -lt $maxWaitMinutes) {
    Start-Sleep -Seconds 60
    $waitedMinutes++
    $job = Get-AzRecoveryServicesBackupJob `
        -VaultId $vault.ID `
        -Job $job
    Write-Host "  等待中... ($waitedMinutes 分钟) 状态: $($job.Status)"
}

if ($job.Status -eq 'Completed') {
    Write-Host "`n备份完成!"
    Write-Host "  耗时: $($job.Duration)"
} else {
    Write-Host "`n备份未在 $maxWaitMinutes 分钟内完成，当前状态: $($job.Status)"
}

# 查看所有恢复点
$recoveryPoints = Get-AzRecoveryServicesBackupRecoveryPoint `
    -VaultId $vault.ID `
    -Item $item

Write-Host "`n===== 可用恢复点列表 ====="
Write-Host ("{0,-40} {1,-25} {2}" -f '恢复点名称', '备份时间', '类型')
Write-Host ('-' * 90)

foreach ($rp in $recoveryPoints) {
    $rpTime = $rp.RecoveryPointTime.ToString('yyyy-MM-dd HH:mm:ss')
    $rpType = if ($rp.RecoveryPointType) { $rp.RecoveryPointType } else { 'Standard' }
    Write-Host ("{0,-40} {1,-25} {2}" -f $rp.Name, $rpTime, $rpType)
}

# 查询最近 7 天所有备份作业的状态汇总
$startTime = (Get-Date).AddDays(-7)
$allJobs = Get-AzRecoveryServicesBackupJob `
    -VaultId $vault.ID `
    -From $startTime `
    -To (Get-Date) `
    -Operation Backup

$completed = ($allJobs | Where-Object Status -eq 'Completed').Count
$failed = ($allJobs | Where-Object Status -eq 'Failed').Count
$inProgress = ($allJobs | Where-Object Status -eq 'InProgress').Count

Write-Host "`n===== 最近 7 天备份作业汇总 ====="
Write-Host "总作业数: $($allJobs.Count)"
Write-Host "已完成:   $completed"
Write-Host "失败:     $failed"
Write-Host "进行中:   $inProgress"

if ($failed -gt 0) {
    Write-Host "`n失败的作业详情:"
    $failedJobs = $allJobs | Where-Object Status -eq 'Failed'
    foreach ($fj in $failedJobs) {
        Write-Host "  - $($fj.DisplayName) | 开始: $($fj.StartTime) | 错误: $($fj.Error)"
    }
}
```

按需备份使用 `Backup-AzRecoveryServicesBackupItem` cmdlet 触发，它会立即创建一个备份作业。由于虚拟机备份可能需要较长时间（取决于磁盘大小和数据变化量），脚本中使用了轮询机制每分钟检查一次作业状态。备份完成后，`Get-AzRecoveryServicesBackupRecoveryPoint` 会列出所有可用的恢复点，每个恢复点代表一个可以还原的时间点快照。最后的作业汇总功能可以帮助快速发现近期备份异常。

执行结果示例：

```
按需备份已触发
  作业名称: a1b2c3d4-e5f6-7890-abcd-ef1234567890
  作业状态: InProgress
  开始时间: 2025-12-05 09:15:00
  等待中... (1 分钟) 状态: InProgress
  等待中... (2 分钟) 状态: InProgress
  等待中... (3 分钟) 状态: InProgress
  等待中... (4 分钟) 状态: InProgress
  等待中... (5 分钟) 状态: Completed

备份完成!
  耗时: 00:05:23

===== 可用恢复点列表 =====
恢复点名称                                备份时间                   类型
------------------------------------------------------------------------------------------
12345678-abcd-ef01-2345-678901234567      2025-12-05 09:20:23       CrashConsistent
89012345-cdef-ab12-3456-789012345678      2025-12-04 02:00:15       AppConsistent
56789012-abcdef-1234-5678-901234567890    2025-12-03 02:00:08       AppConsistent

===== 最近 7 天备份作业汇总 =====
总作业数: 8
已完成:   7
失败:     1
进行中:   0

失败的作业详情:
  - vm-prod-01 | 开始: 2025-12-01 02:00:00 | 错误: AzureBackupAgent Thaw failed
```

## 数据恢复与跨区域灾难恢复

当虚拟机发生故障或数据损坏时，需要从备份恢复点还原数据。Azure Backup 支持磁盘还原和跨区域还原两种模式。以下代码演示了从恢复点还原磁盘，以及在配对区域执行跨区域灾难恢复的完整流程。

```powershell
# 定义变量
$vaultName = 'rsv-backup-demo'
$resourceGroup = 'rg-backup-demo'
$vmName = 'vm-prod-01'
$targetRg = 'rg-restore-demo'
$storageAccountName = 'sarestore001'
$storageContainerName = 'restore-output'

$vault = Get-AzRecoveryServicesVault -Name $vaultName -ResourceGroupName $resourceGroup

# 获取备份项和恢复点
$container = Get-AzRecoveryServicesBackupContainer `
    -VaultId $vault.ID `
    -ContainerType AzureVM `
    -FriendlyName $vmName

$item = Get-AzRecoveryServicesBackupItem `
    -VaultId $vault.ID `
    -Container $container `
    -WorkloadType AzureVM

$recoveryPoints = Get-AzRecoveryServicesBackupRecoveryPoint `
    -VaultId $vault.ID `
    -Item $item

# 选择最新的应用一致性恢复点
$appConsistentRp = $recoveryPoints |
    Where-Object RecoveryPointType -eq 'AppConsistent' |
    Sort-Object RecoveryPointTime -Descending |
    Select-Object -First 1

if (-not $appConsistentRp) {
    # 如果没有应用一致性恢复点，退而使用最新的恢复点
    $appConsistentRp = $recoveryPoints |
        Sort-Object RecoveryPointTime -Descending |
        Select-Object -First 1
    Write-Host "警告: 未找到应用一致性恢复点，使用最新恢复点"
}

Write-Host "已选择恢复点:"
Write-Host "  时间: $($appConsistentRp.RecoveryPointTime)"
Write-Host "  类型: $($appConsistentRp.RecoveryPointType)"

# 确保目标资源组存在
$targetRgObj = Get-AzResourceGroup -Name $targetRg -ErrorAction SilentlyContinue
if (-not $targetRgObj) {
    $targetRgObj = New-AzResourceGroup -Name $targetRg -Location $vault.Location
    Write-Host "已创建目标资源组: $targetRg"
}

# 确保目标存储账户存在
$storageAccount = Get-AzStorageAccount `
    -Name $storageAccountName `
    -ResourceGroupName $targetRg -ErrorAction SilentlyContinue

if (-not $storageAccount) {
    $storageAccount = New-AzStorageAccount `
        -Name $storageAccountName `
        -ResourceGroupName $targetRg `
        -Location $vault.Location `
        -SkuName Standard_LRS `
        -Kind StorageV2

    Write-Host "已创建目标存储账户: $storageAccountName"
}

# 确保容器存在
New-AzStorageContainer `
    -Context $storageAccount.Context `
    -Name $storageContainerName `
    -ErrorAction SilentlyContinue | Out-Null

# 还原虚拟机磁盘到目标存储账户
$restoreJob = Restore-AzRecoveryServicesBackupItem `
    -VaultId $vault.ID `
    -RecoveryPoint $appConsistentRp `
    -StorageAccountName $storageAccountName `
    -StorageAccountResourceGroupName $targetRg `
    -TargetResourceGroupName $targetRg

Write-Host "`n磁盘还原作业已触发"
Write-Host "  作业名称: $($restoreJob.Name)"

# 等待还原完成
while ($restoreJob.Status -eq 'InProgress') {
    Start-Sleep -Seconds 30
    $restoreJob = Get-AzRecoveryServicesBackupJob `
        -VaultId $vault.ID `
        -Job $restoreJob
}

if ($restoreJob.Status -eq 'Completed') {
    Write-Host "`n磁盘还原完成!"
    $restoreDetails = Get-AzRecoveryServicesBackupJobDetail `
        -VaultId $vault.ID `
        -Job $restoreJob

    Write-Host "还原磁盘列表:"
    foreach ($disk in $restoreDetails.Properties.RestoredDiskList) {
        Write-Host "  - $($disk.DiskName) ($($disk.DiskType))"
    }
} else {
    Write-Host "`n还原失败，状态: $($restoreJob.Status)"
}

# 跨区域灾难恢复（仅适用于 GeoRedundant 存储冗余的保管库）
Write-Host "`n===== 跨区域灾难恢复 ====="

$vaultStorageConfig = Get-AzRecoveryServicesVaultProperty `
    -VaultId $vault.ID

if ($vaultStorageConfig.BackupStorageRedundancy -eq 'GeoRedundant') {
    Write-Host "保管库已启用异地冗余，支持跨区域还原"

    # 获取配对区域的恢复点
    $secondaryRegionRp = Get-AzRecoveryServicesBackupRecoveryPoint `
        -VaultId $vault.ID `
        -Item $item `
        -SecondaryRegion

    Write-Host "配对区域可用恢复点数: $($secondaryRegionRp.Count)"

    if ($secondaryRegionRp.Count -gt 0) {
        $crossRegionRp = $secondaryRegionRp |
            Sort-Object RecoveryPointTime -Descending |
            Select-Object -First 1

        Write-Host "最新配对区域恢复点:"
        Write-Host "  时间: $($crossRegionRp.RecoveryPointTime)"
        Write-Host "  类型: $($crossRegionRp.RecoveryPointType)"

        # 在配对区域执行还原
        $pairedRegion = if ($vault.Location -eq 'eastasia') { 'southeastasia' } else { 'eastasia' }
        $crossRestoreRg = "rg-dr-restore-$pairedRegion"

        Write-Host "`n将在配对区域 $pairedRegion 执行跨区域还原..."
        Write-Host "目标资源组: $crossRestoreRg"
        Write-Host "（跨区域还原因需要数据传输，耗时可能较长）"
    }
} else {
    Write-Host "保管库存储冗余为 $($vaultStorageConfig.BackupStorageRedundancy)"
    Write-Host "跨区域还原需要 GeoRedundant 存储冗余"
}
```

磁盘还原模式比完整 VM 还原更灵活，还原后的磁盘以 VHD 格式保存在指定的存储账户中，可以选择将其附加到现有虚拟机作为数据磁盘、用它创建新的虚拟机，或者仅提取特定文件。跨区域灾难恢复是 Azure Backup 的高级功能：当主区域发生全面故障时，可以从配对区域的备份副本还原数据。此功能要求保管库使用异地冗余（GRS）存储，并在配对区域有可用的恢复点。

执行结果示例：

```
已选择恢复点:
  时间: 2025-12-05 02:00:15
  类型: AppConsistent
已创建目标资源组: rg-restore-demo
已创建目标存储账户: sarestore001

磁盘还原作业已触发
  作业名称: b2c3d4e5-f6a7-8901-bcde-f12345678901

磁盘还原完成!
还原磁盘列表:
  - vm-prod-01_OsDisk_1 (PremiumSSD)
  - vm-prod-01_DataDisk_0 (PremiumSSD)

===== 跨区域灾难恢复 =====
保管库已启用异地冗余，支持跨区域还原
配对区域可用恢复点数: 3
最新配对区域恢复点:
  时间: 2025-12-05 02:00:15
  类型: AppConsistent

将在配对区域 southeastasia 执行跨区域还原...
目标资源组: rg-dr-restore-southeastasia
（跨区域还原因需要数据传输，耗时可能较长）
```

## 注意事项

- **存储冗余不可逆**：恢复服务保管库的存储冗余类型（LRS 或 GRS）必须在注册第一个备份项之前设置。一旦有备份项注册到保管库，就无法再更改冗余类型。对于生产环境，建议始终选择异地冗余（GRS）以获得跨区域容灾能力。
- **软删除保护期**：Azure Backup 默认启用了软删除功能，删除备份数据后会保留 14 天。在此期间数据仍可恢复，但保管库也无法彻底删除。如需立即清除（例如测试环境），需要先禁用软删除再执行删除操作。
- **恢复点类型差异**：崩溃一致性（CrashConsistent）恢复点等同于虚拟机突然断电时的状态，可能丢失内存中未写入磁盘的数据。应用一致性（AppConsistent）恢复点通过 VSS 等机制确保应用数据完整性，优先选择应用一致性恢复点进行还原。
- **跨区域还原的前提条件**：跨区域灾难恢复要求保管库使用 GRS 存储冗余，且并非所有区域对都支持跨区域还原。在制定灾备方案前，需先确认保管库所在区域的配对区域，并验证配对区域的恢复点是否可用。
- **还原时的网络考量**：磁盘还原会将 VHD 写入指定的存储账户，确保该存储账户与目标虚拟机在同一区域，否则会产生跨区域数据传输费用和额外的还原时间。建议还原时使用与源虚拟机同区域的临时存储账户。
- **RBAC 权限要求**：执行备份和恢复操作需要至少"备份操作员"（Backup Operator）角色权限。还原虚拟机还需要目标资源组的"虚拟机参与者"（Virtual Machine Contributor）权限，以及目标存储账户的"存储账户贡献者"权限。建议为运维团队创建自定义角色，仅授予必要的备份和还原权限。
