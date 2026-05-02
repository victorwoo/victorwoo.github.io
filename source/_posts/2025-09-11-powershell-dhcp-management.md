---
layout: post
date: 2025-09-11 08:00:00
updated: 2025-09-11 08:00:00
title: "PowerShell 技能连载 - DHCP 管理自动化"
description: PowerTip of the Day - DHCP Management Automation in PowerShell
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
- dhcp
- ip-address
- network-management
---

_适用于 PowerShell 5.1（Windows），需要 DhcpServer 模块及管理员权限_

在企业网络运维中，DHCP 服务是基础架构的核心组件之一。随着组织规模的增长，手动管理 DHCP 作用域、地址租约和保留记录不仅耗时，还容易出错。PowerShell 提供了 `DhcpServer` 模块，让运维人员可以通过脚本实现 DHCP 配置的批量管理和自动化巡检。

本文将介绍如何利用 PowerShell 进行 DHCP 服务器的日常管理操作，包括查询作用域信息、统计地址使用率、批量创建保留地址，以及导出配置报告。这些技巧可以帮助网络管理员减少重复劳动，提升管理效率和准确性。

所有示例都基于 Windows Server 内置的 `DhcpServer` 模块，需要在已加入域的环境中以管理员权限运行。如果你的管理工作站没有安装该模块，可以通过 `Install-WindowsFeature RSAT-DHCP` 来添加。

<!-- more -->

## 查询 DHCP 服务器基本信息

首先，我们需要连接到 DHCP 服务器并获取基本的状态信息。以下代码展示了如何查询服务器级别的作用域概览，并以表格形式输出各作用域的地址池范围、已使用地址数和使用率。

```powershell
# 指定 DHCP 服务器名称
$DhcpServer = "dc01.contoso.com"

# 获取所有作用域的统计信息
$Scopes = Get-DhcpServerv4Scope -ComputerName $DhcpServer

$results = @()
foreach ($scope in $Scopes) {
    $stats = Get-DhcpServerv4ScopeStatistics -ComputerName $DhcpServer -ScopeId $scope.ScopeId
    $results += [PSCustomObject]@{
        ScopeId      = $scope.ScopeId
        SubnetMask   = $scope.SubnetMask
        Name         = $scope.Name
        AddressPool  = "$($scope.StartRange) - $($scope.EndRange)"
        FreeAddresses = $stats.Free
        InUseAddresses = $stats.InUse
        PercentageInUse = [math]::Round($stats.PercentageInUse, 1)
    }
}

$results | Format-Table -AutoSize
```

```text
ScopeId       SubnetMask      Name            AddressPool                        FreeAddresses InUseAddresses PercentageInUse
-------       ----------      ----            -----------                        ------------- -------------- ---------------
192.168.1.0   255.255.255.0   办公网-VLAN10   192.168.1.100 - 192.168.1.250              45            106            70.7
192.168.2.0   255.255.255.0   研发网-VLAN20   192.168.2.100 - 192.168.2.200              12             89            88.1
10.0.0.0      255.255.0.0     数据中心-VLAN30 10.0.0.50 - 10.0.255.250                2100           200              8.7
```

从输出可以看到，研发网的使用率已经接近 88%，需要关注地址空间是否充足。

## 统计并导出地址使用率报告

当管理多台 DHCP 服务器时，手动逐个查看作用域状态效率很低。下面的脚本可以批量获取所有作用域的使用率数据，筛选出使用率超过阈值的告警作用域，并生成 CSV 报告供后续分析。

```powershell
$DhcpServer = "dc01.contoso.com"
$Threshold = 80
$ExportPath = "C:\Reports\DhcpScopeReport_$(Get-Date -Format 'yyyyMMdd').csv"

# 确保输出目录存在
$dir = Split-Path $ExportPath
if (-not (Test-Path $dir)) {
    New-Item -Path $dir -ItemType Directory -Force | Out-Null
}

$scopes = Get-DhcpServerv4Scope -ComputerName $DhcpServer

$report = @()
foreach ($scope in $scopes) {
    $stats = Get-DhcpServerv4ScopeStatistics -ComputerName $DhcpServer -ScopeId $scope.ScopeId
    $leaseCount = (Get-DhcpServerv4Lease -ComputerName $DhcpServer -ScopeId $scope.ScopeId).Count

    $report += [PSCustomObject]@{
        Date             = Get-Date -Format 'yyyy-MM-dd'
        ScopeId          = $scope.ScopeId.ToString()
        ScopeName        = $scope.Name
        TotalAddresses   = $stats.Free + $stats.InUse
        FreeAddresses    = $stats.Free
        InUseAddresses   = $stats.InUse
        UsagePercent     = [math]::Round($stats.PercentageInUse, 1)
        ActiveLeases    = $leaseCount
        State            = $scope.State
        IsOverThreshold  = $stats.PercentageInUse -ge $Threshold
    }
}

# 导出到 CSV
$report | Export-Csv -Path $ExportPath -NoTypeInformation -Encoding UTF8

# 筛选告警作用域
$alerts = $report | Where-Object { $_.IsOverThreshold }
if ($alerts) {
    Write-Warning "以下作用域使用率已超过 ${Threshold}%："
    $alerts | Format-Table ScopeId, ScopeName, UsagePercent, FreeAddresses -AutoSize
} else {
    Write-Host "所有作用域使用率均在 ${Threshold}% 以下。" -ForegroundColor Green
}
```

```text
WARNING: 以下作用域使用率已超过 80%：
ScopeId      ScopeName       UsagePercent FreeAddresses
-------      ---------       ------------ -------------
192.168.2.0  研发网-VLAN20   88.1         12
192.168.3.0  访客网-VLAN40   83.5         28
```

脚本执行后会在 `C:\Reports\` 目录生成包含所有作用域详细数据的 CSV 文件，方便在 Excel 中做进一步分析和可视化。

## 批量创建 DHCP 保留地址

在网络管理中，经常需要为打印机、IP 电话、监控摄像头等设备配置固定 IP。通过 DHCP 保留（Reservation）可以在不手动配置设备 IP 的前提下确保设备始终获取相同的地址。以下脚本演示了如何从 CSV 文件批量导入保留记录。

首先准备一个 CSV 文件 `C:\Data\Reservations.csv`，内容格式如下：

```text
ScopeId,IPAddress,ClientId,Description
192.168.1.0,192.168.1.150,00-1A-2B-3C-4D-5E,三楼会议室打印机
192.168.1.0,192.168.1.151,00-1A-2B-3C-4D-6F,前台接待区打印机
192.168.2.0,192.168.2.180,AA-BB-CC-DD-EE-01,研发部网络摄像头
192.168.2.0,192.168.2.181,AA-BB-CC-DD-EE-02,机房温湿度传感器
```

然后运行以下脚本完成批量导入：

```powershell
$DhcpServer = "dc01.contoso.com"
$CsvPath = "C:\Data\Reservations.csv"

# 读取 CSV 数据
$reservations = Import-Csv -Path $CsvPath

$successCount = 0
$failCount = 0
foreach ($item in $reservations) {
    try {
        Add-DhcpServerv4Reservation `
            -ComputerName $DhcpServer `
            -ScopeId $item.ScopeId `
            -IPAddress $item.IPAddress `
            -ClientId $item.ClientId `
            -Description $item.Description `
            -ErrorAction Stop

        Write-Host "已添加保留：$($item.IPAddress) -> $($item.ClientId) ($($item.Description))" -ForegroundColor Green
        $successCount++
    } catch {
        Write-Host "添加失败：$($item.IPAddress) - $($_.Exception.Message)" -ForegroundColor Red
        $failCount++
    }
}

Write-Host "`n导入完成：成功 $successCount 条，失败 $failCount 条。" -ForegroundColor Cyan
```

```text
已添加保留：192.168.1.150 -> 00-1A-2B-3C-4D-5E (三楼会议室打印机)
已添加保留：192.168.1.151 -> 00-1A-2B-3C-4D-6F (前台接待区打印机)
已添加保留：192.168.2.180 -> AA-BB-CC-DD-EE-01 (研发部网络摄像头)
已添加保留：192.168.2.181 -> AA-BB-CC-DD-EE-02 (机房温湿度传感器)

导入完成：成功 4 条，失败 0 条。
```

## 查询租约记录并筛选特定设备

有时需要快速查找某个 IP 地址的租约信息，或者找出某个 MAC 地址对应的设备。以下代码展示了如何查询租约并按条件筛选。

```powershell
$DhcpServer = "dc01.contoso.com"
$ScopeId = "192.168.2.0"

# 获取指定作用域的所有租约
$leases = Get-DhcpServerv4Lease -ComputerName $DhcpServer -ScopeId $ScopeId

Write-Host "作用域 $ScopeId 共有 $($leases.Count) 条租约记录" -ForegroundColor Cyan
Write-Host ""

# 按地址状态分组统计
$grouped = $leases | Group-Object AddressState
foreach ($g in $grouped) {
    Write-Host "  状态: $($g.Name) - 数量: $($g.Count)"
}

Write-Host ""

# 筛选租约即将到期的设备（假设租期为 8 天，查询剩余不足 1 天的）
$expiringLeases = $leases | Where-Object {
    $_.LeaseExpiryTime -and ($_.LeaseExpiryTime - (Get-Date)).TotalHours -lt 24 -and ($_.LeaseExpiryTime - (Get-Date)).TotalHours -gt 0
}

if ($expiringLeases) {
    Write-Host "以下设备租约将在 24 小时内到期：" -ForegroundColor Yellow
    $expiringLeases | Select-Object IPAddress, ClientId, HostName, LeaseExpiryTime | Format-Table -AutoSize
}
```

```text
作用域 192.168.2.0 共有 89 条租约记录

  状态: Active - 数量: 85
  状态: Inactive - 数量: 4

以下设备租约将在 24 小时内到期：
IPAddress      ClientId           HostName              LeaseExpiryTime
---------      --------           --------              ---------------
192.168.2.105  00-15-5D-01-A2-B3  LAPTOP-DEV03          2025/9/12 6:30:00
192.168.2.137  00-15-5D-04-C7-D8  WS-TEST-BUILD01       2025/9/12 3:15:00
```

## 注意事项

1. **权限要求**：所有 `DhcpServer` 模块的命令都需要在具有 DHCP 管理权限的账户下运行，建议使用域管理员或 DHCP Administrators 组成员身份。本地执行时需要以管理员身份启动 PowerShell。

2. **防火墙配置**：远程管理 DHCP 服务器时，确保目标服务器已启用 RPC 和 WMI 的防火墙规则。如果连接失败，可先检查 `Get-Service DhcpServer -ComputerName <ServerName>` 确认服务是否运行。

3. **ClientId 格式**：创建保留地址时，`ClientId`（即 MAC 地址）的格式必须使用连字符分隔（如 `00-1A-2B-3C-4D-5E`）。如果从其他系统导入的是冒号格式（`00:1A:2B:3C:4D:5E`），需要先做格式转换。

4. **作用域状态**：如果作用域处于 Inactive 状态，租约将不会被续期。在排查 IP 分配问题前，先用 `Get-DhcpServerv4Scope` 确认作用域状态是否为 `Active`。

5. **导出备份**：在对 DHCP 配置做大规模变更前，务必使用 `Export-DhcpServer` 导出完整配置备份。一旦操作失误，可以通过 `Import-DhcpServer` 快速恢复，避免影响网络连通性。

6. **性能考量**：在包含大量作用域（超过 100 个）或大量租约（超过 10000 条）的环境中，避免在循环中逐条查询统计数据。建议先用 `Get-DhcpServerv4ScopeStatistics` 一次性获取所有作用域的统计，再做内存筛选，这样可以显著减少对 DHCP 服务器的请求次数。
