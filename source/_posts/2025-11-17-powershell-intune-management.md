---
layout: post
date: 2025-11-17 08:00:00
title: "PowerShell 技能连载 - Intune 设备管理"
description: PowerTip of the Day - Intune Device Management in PowerShell
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
- intune
- device-management
- mdm
- endpoint
---

_适用于 PowerShell 5.1 及以上版本_

Microsoft Intune 是微软推出的云端移动设备管理（MDM）和移动应用管理（MAM）解决方案，已经成为企业终端设备管理的核心平台。随着混合办公模式的普及，IT 管理员需要一种高效的方式来批量查询、配置和管理通过 Intune 注册的设备，而不再局限于图形化控制台的手动操作。

PowerShell 配合 Microsoft Graph API，为 Intune 管理提供了强大的自动化能力。通过脚本化操作，管理员可以实现设备合规性巡检、批量策略下发、设备生命周期管理等日常任务，大幅减少重复劳动。尤其在管理成百上千台设备时，自动化脚本的价值更加显著。

本文将介绍如何使用 PowerShell 连接 Intune，查询设备信息、管理合规策略，以及批量执行设备操作，帮助你构建属于自己的 Intune 自动化管理工作流。

## 连接 Intune 环境

Intune 的管理接口已经统一到 Microsoft Graph API。首先需要安装 Microsoft Graph PowerShell SDK，然后使用具有 DeviceManagementManagedDevices.ReadWrite.All 权限的账户进行连接。

```powershell
# 安装 Microsoft Graph PowerShell SDK（仅需执行一次）
Install-Module -Name Microsoft.Graph -Scope CurrentUser -Force

# 连接到 Microsoft Graph，指定 Intune 所需的权限范围
$Scopes = @(
    'DeviceManagementManagedDevices.Read.All',
    'DeviceManagementConfiguration.Read.All',
    'DeviceManagementApps.Read.All'
)

Connect-MgGraph -Scopes $Scopes
```

连接成功后，PowerShell 会显示已认证的账户信息和授予的权限列表。

```text
Welcome To Microsoft Graph!
Account         : admin@contoso.onmicrosoft.com
Scopes          : DeviceManagementManagedDevices.Read.All DeviceManagementConfiguration.Read.All
```

## 查询设备清单

连接建立后，最常见的操作是查询 Intune 中注册的所有设备。使用 `Get-MgDeviceManagementManagedDevice` 可以获取完整的设备列表，并按需筛选关键字段。

```powershell
# 获取所有 Intune 托管设备，提取关键属性
$Devices = Get-MgDeviceManagementManagedDevice -All -Property (
    'id', 'deviceName', 'operatingSystem', 'osVersion',
    'complianceState', 'managementState', 'lastSyncDateTime',
    'emailAddress', 'model', 'manufacturer'
)

# 统计设备概况
$Total = $Devices.Count
$Compliant = ($Devices | Where-Object { $_.ComplianceState -eq 'compliant' }).Count
$NonCompliant = ($Devices | Where-Object { $_.ComplianceState -eq 'noncompliant' }).Count
$Inactive = ($Devices | Where-Object {
    $_.LastSyncDateTime -lt (Get-Date).AddDays(-30)
}).Count

Write-Host "设备总数: $Total"
Write-Host "合规设备: $Compliant"
Write-Host "不合规设备: $NonCompliant"
Write-Host "超过30天未同步: $Inactive"
```

执行后会输出当前 Intune 租户的设备统计摘要。

```text
设备总数: 128
合规设备: 112
不合规设备: 9
超过30天未同步: 7
```

## 生成设备合规性报告

在日常运维中，我们需要定期生成设备合规性报告，找出不合规的设备并分析原因。以下脚本将不合规设备导出为结构化 CSV 文件，便于后续分发和处理。

```powershell
# 筛选不合规设备并生成报告
$ReportDate = Get-Date -Format 'yyyy-MM-dd'
$OutputPath = "Intune_Compliance_Report_$ReportDate.csv"

$NonCompliantDevices = $Devices | Where-Object {
    $_.ComplianceState -eq 'noncompliant'
}

$Report = foreach ($Device in $NonCompliantDevices) {
    [PSCustomObject]@{
        设备名称     = $Device.DeviceName
        操作系统     = $Device.OperatingSystem
        系统版本     = $Device.OsVersion
        合规状态     = $Device.ComplianceState
        管理状态     = $Device.ManagementState
        最后同步时间 = $Device.LastSyncDateTime
        用户邮箱     = $Device.EmailAddress
        设备型号     = $Device.Model
        制造商       = $Device.Manufacturer
    }
}

$Report | Export-Csv -Path $OutputPath -NoTypeInformation -Encoding UTF8
Write-Host "合规性报告已导出: $OutputPath ($($Report.Count) 条记录)"
```

运行后会生成包含不合规设备详情的 CSV 文件。

```text
合规性报告已导出: Intune_Compliance_Report_2025-11-17.csv (9 条记录)
```

## 按操作系统分组统计

了解不同平台设备的分布情况，有助于制定针对性的管理策略。下面这段代码按操作系统分组统计，并以表格形式展示结果。

```powershell
# 按操作系统分组统计设备数量
$OsGroups = $Devices | Group-Object -Property OperatingSystem

$OsSummary = foreach ($Group in $OsGroups) {
    $GroupDevices = $Group.Group
    $CompliantCount = ($GroupDevices | Where-Object {
        $_.ComplianceState -eq 'compliant'
    }).Count

    [PSCustomObject]@{
        操作系统   = $Group.Name
        设备数量   = $Group.Count
        合规数量   = $CompliantCount
        合规率     = '{0:P1}' -f ($CompliantCount / $Group.Count)
        占总设备比 = '{0:P1}' -f ($Group.Count / $Total)
    }
}

$OsSummary | Format-Table -AutoSize
```

执行结果会以表格形式展示各操作系统的设备分布和合规率。

```text
操作系统    设备数量 合规数量 合规率 占总设备比
---------   -------- -------- ------ ----------
Windows     86       78       90.7% 67.2%
iOS         24       22       91.7% 18.8%
macOS       12       8        66.7% 9.4%
Android     6        4        66.7% 4.7%
```

## 批量设备操作

当需要对多台设备执行批量操作（如同步、重启、擦除）时，PowerShell 可以显著提高效率。以下示例展示如何对超过指定天数未同步的设备发送同步指令。

```powershell
# 查找并同步超过 7 天未联系的设备
$StaleDays = 7
$StaleDevices = $Devices | Where-Object {
    $null -ne $_.LastSyncDateTime -and
    $_.LastSyncDateTime -lt (Get-Date).AddDays(-$StaleDays)
}

$SyncResults = foreach ($Device in $StaleDevices) {
    try {
        # 发送设备同步请求
        Invoke-MgGraphRequest -Method POST `
            -Uri "https://graph.microsoft.com/v1.0/deviceManagement/managedDevices/$($Device.Id)/syncDevice" `
            -ErrorAction Stop

        [PSCustomObject]@{
            设备     = $Device.DeviceName
            状态     = '同步已触发'
            最后同步 = $Device.LastSyncDateTime
        }
    }
    catch {
        [PSCustomObject]@{
            设备     = $Device.DeviceName
            状态     = "失败: $($_.Exception.Message)"
            最后同步 = $Device.LastSyncDateTime
        }
    }
}

$SyncResults | Format-Table -AutoSize
Write-Host "共处理 $($StaleDevices.Count) 台设备"
```

运行后可以看到每台设备的同步触发结果。

```text
设备          状态         最后同步
----          ----         --------
DESKTOP-A01  同步已触发    2025-11-01T10:23:45Z
DESKTOP-B22  同步已触发    2025-11-03T14:12:00Z
LAPTOP-C07   失败: 403     2025-10-28T09:00:00Z
共处理 3 台设备
```

## 查询设备配置策略分配

Intune 的配置策略决定了设备的行为和安全基线。通过 Graph API 可以查看哪些策略已分配到哪些设备组，帮助排查策略未生效的问题。

```powershell
# 获取所有设备配置策略
$Policies = Get-MgDeviceManagementDeviceConfiguration -All -Property (
    'id', 'displayName', 'description', 'createdDateTime', 'lastModifiedDateTime'
)

Write-Host "已找到 $($Policies.Count) 条配置策略"
Write-Host ''

# 查看每条策略的分配目标
foreach ($Policy in $Policies) {
    $Assignments = Get-MgDeviceManagementDeviceConfigurationAssignment `
        -DeviceConfigurationId $Policy.Id -ErrorAction SilentlyContinue

    $TargetCount = if ($Assignments) { $Assignments.Count } else { 0 }

    [PSCustomObject]@{
        策略名称   = $Policy.DisplayName
        分配目标数 = $TargetCount
        创建时间   = $Policy.CreatedDateTime
        修改时间   = $Policy.LastModifiedDateTime
    }
} | Format-Table -AutoSize
```

执行后会列出所有配置策略及其分配情况。

```text
已找到 15 条配置策略

策略名称                       分配目标数 创建时间            修改时间
--------                       ---------- --------            --------
BitLocker 加密策略             3          2025-03-15T08:00:00 2025-10-20T14:30:00
Windows 更新策略               2          2025-04-01T10:00:00 2025-09-12T09:15:00
Endpoint Protection 基线       5          2025-02-20T07:00:00 2025-11-01T16:00:00
macOS 磁盘加密策略             1          2025-06-10T11:00:00 2025-08-05T10:00:00
```

## 注意事项

1. **权限要求**：Intune 管理操作需要通过 `Connect-MgGraph` 授予对应的 Graph API 权限。建议遵循最小权限原则，只申请实际需要的权限范围，避免使用过宽的权限。对于只读操作，使用 `.Read` 后缀的权限即可。

2. **API 限流**：Microsoft Graph API 有请求频率限制。批量操作大量设备时，建议在循环中加入适当延迟（如 `Start-Sleep -Milliseconds 200`），避免触发 HTTP 429 Too Many Requests 错误。如果遇到限流，响应头中的 `Retry-After` 值会告知等待时间。

3. **模块版本兼容**：Microsoft Graph PowerShell SDK 更新频繁，不同版本间 cmdlet 名称和参数可能有差异。生产环境中建议锁定模块版本（`RequiredVersion`），并在升级前在测试环境验证脚本兼容性。

4. **分页处理**：`Get-MgDeviceManagementManagedDevice` 使用 `-All` 参数会自动处理分页，一次性拉取所有数据。但设备量非常大（超过 10000 台）时，可能导致内存压力。可以考虑使用 `-PageSize` 参数分批获取。

5. **时间格式注意**：Graph API 返回的时间为 UTC 格式的 ISO 8601 字符串。在进行时间比较时，务必确保本机时间也转换为 UTC（使用 `.ToUniversalTime()`），否则可能导致时区偏差，影响过滤结果的准确性。

6. **断开连接**：脚本执行完毕后，务必调用 `Disconnect-MgGraph` 断开会话。长时间保持活跃的 Graph 会话不仅浪费资源，还可能在共享环境中带来安全隐患。建议在脚本的 `finally` 块中执行断开操作。
