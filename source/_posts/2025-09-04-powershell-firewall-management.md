---
layout: post
date: 2025-09-04 08:00:00
updated: 2025-09-04 08:00:00
title: "PowerShell 技能连载 - Windows 防火墙规则管理"
description: PowerTip of the Day - Windows Firewall Rule Management in PowerShell
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
- firewall
- security
- windows-firewall
---

_适用于 PowerShell 5.1 及以上版本（Windows），需要管理员权限_

Windows 防火墙是保障系统安全的第一道防线。在企业运维中，管理员经常需要批量查看、创建、修改或删除防火墙规则，以应对不同的网络环境和安全策略。手动通过 `advfw.msc` 图形界面操作不仅效率低下，而且难以保证多台机器之间的配置一致性。

PowerShell 提供了 `NetSecurity` 模块，其中包含一系列以 `NetFirewall` 开头的 cmdlet，可以方便地对防火墙规则、配置文件和地址进行程序化管理。结合脚本化思维，运维人员可以快速完成规则的批量审计与部署。

本文将从实际场景出发，演示如何用 PowerShell 查询现有防火墙规则、批量创建入站规则，以及导出规则审计报告。

<!-- more -->

## 查询防火墙规则

使用 `Get-NetFirewallRule` 可以列出系统中所有防火墙规则。配合 `Get-NetFirewallAddressFilter`、`Get-NetFirewallPortFilter` 等关联 cmdlet，可以获取规则的详细信息。

```powershell
# 查询所有已启用的入站规则，显示名称、方向、操作和配置文件
$rules = Get-NetFirewallRule |
    Where-Object { $_.Enabled -eq $true -and $_.Direction -eq 'Inbound' } |
    Sort-Object -Property DisplayName

foreach ($rule in $rules) {
    $portFilter = $rule | Get-NetFirewallPortFilter -ErrorAction SilentlyContinue
    $addressFilter = $rule | Get-NetFirewallAddressFilter -ErrorAction SilentlyContinue

    [PSCustomObject]@{
        Name         = $rule.DisplayName
        Direction    = $rule.Direction
        Action       = $rule.Action
        Profile      = $rule.Profile
        Protocol     = if ($portFilter) { $portFilter.Protocol } else { 'N/A' }
        LocalPort    = if ($portFilter) { $portFilter.LocalPort -join ', ' } else { 'N/A' }
        RemoteAddr   = if ($addressFilter) { $addressFilter.RemoteAddress -join ', ' } else { 'N/A' }
    }
}
```

执行结果示例：

```text
Name                          Direction Action  Profile      Protocol LocalPort      RemoteAddr
----                          --------- ------  -------      -------- ---------      ----------
Core Networking - DHCP (In)   Inbound   Allow   Any          UDP      68, 546        LocalSubnet
Core Networking - IPv6 (In)   Inbound   Allow   Any          IPv6     N/A            N/A
远程桌面 - 用户模式(TCP-In)    Inbound   Allow   Private      TCP      3389           Any
Windows 管理规范(WMI-In)       Inbound   Allow   Domain       TCP      0-65535        LocalSubnet
```

## 批量创建入站规则

在部署新服务时，通常需要为多个端口同时开放防火墙入站规则。下面的脚本演示如何根据配置表批量创建规则，并为每条规则添加描述和远程地址限制。

```powershell
# 定义需要开放的端口规则列表
$firewallConfig = @(
    @{
        Name        = 'Web Server - HTTP'
        Port        = 80
        Protocol    = 'TCP'
        Profile     = 'Any'
        Description = '允许 HTTP 流量入站'
        RemoteAddr  = 'Any'
    }
    @{
        Name        = 'Web Server - HTTPS'
        Port        = 443
        Protocol    = 'TCP'
        Profile     = 'Any'
        Description = '允许 HTTPS 流量入站'
        RemoteAddr  = 'Any'
    }
    @{
        Name        = 'Admin API'
        Port        = 8080
        Protocol    = 'TCP'
        Profile     = 'Private'
        Description = '允许管理 API 访问，仅限内网'
        RemoteAddr  = '10.0.0.0/8'
    }
)

foreach ($config in $firewallConfig) {
    $existingRule = Get-NetFirewallRule -DisplayName $config.Name -ErrorAction SilentlyContinue

    if ($existingRule) {
        Write-Host "规则 '$($config.Name)' 已存在，跳过创建。" -ForegroundColor Yellow
        continue
    }

    New-NetFirewallRule `
        -DisplayName $config.Name `
        -Direction Inbound `
        -Action Allow `
        -Protocol $config.Protocol `
        -LocalPort $config.Port `
        -Profile $config.Profile `
        -RemoteAddress $config.RemoteAddr `
        -Description $config.Description

    Write-Host "已创建规则 '$($config.Name)' (端口 $($config.Port)/$($config.Protocol))" -ForegroundColor Green
}
```

执行结果示例：

```text
已创建规则 'Web Server - HTTP' (端口 80/TCP)
已创建规则 'Web Server - HTTPS' (端口 443/TCP)
已创建规则 'Admin API' (端口 8080/TCP)
```

## 导出防火墙审计报告

定期的防火墙规则审计是安全合规的重要环节。以下脚本将所有防火墙规则导出为 CSV 文件，便于后续分析和归档。

```powershell
# 导出防火墙规则审计报告
$timestamp = Get-Date -Format 'yyyyMMdd_HHmmss'
$exportPath = Join-Path -Path $env:USERPROFILE -ChildPath "FirewallAudit_$timestamp.csv"

$allRules = Get-NetFirewallRule | Sort-Object -Property DisplayName

$report = foreach ($rule in $allRules) {
    $portFilter = $rule | Get-NetFirewallPortFilter -ErrorAction SilentlyContinue
    $addressFilter = $rule | Get-NetFirewallAddressFilter -ErrorAction SilentlyContinue
    $appFilter = $rule | Get-NetFirewallApplicationFilter -ErrorAction SilentlyContinue

    [PSCustomObject]@{
        DisplayName   = $rule.DisplayName
        Group         = $rule.Group
        Enabled       = $rule.Enabled
        Direction     = $rule.Direction
        Action        = $rule.Action
        Profile       = $rule.Profile
        Protocol      = if ($portFilter) { $portFilter.Protocol } else { '' }
        LocalPort     = if ($portFilter) { $portFilter.LocalPort -join '; ' } else { '' }
        RemotePort    = if ($portFilter) { $portFilter.RemotePort -join '; ' } else { '' }
        LocalAddress  = if ($addressFilter) { $addressFilter.LocalAddress -join '; ' } else { '' }
        RemoteAddress = if ($addressFilter) { $addressFilter.RemoteAddress -join '; ' } else { '' }
        Program       = if ($appFilter) { $appFilter.Program } else { '' }
        Description   = $rule.Description
    }
}

$report | Export-Csv -Path $exportPath -NoTypeInformation -Encoding UTF8

$totalCount = $report.Count
$enabledCount = ($report | Where-Object { $_.Enabled -eq $true }).Count
$allowCount = ($report | Where-Object { $_.Action -eq 'Allow' -and $_.Enabled -eq $true }).Count

Write-Host "审计报告已导出: $exportPath" -ForegroundColor Green
Write-Host "总规则数: $totalCount | 已启用: $enabledCount | 允许规则(已启用): $allowCount"
```

执行结果示例：

```text
审计报告已导出: C:\Users\Admin\FirewallAudit_20250904_143022.csv
总规则数: 852 | 已启用: 356 | 允许规则(已启用): 214
```

## 禁用危险规则示例

在某些加固场景下，需要快速定位并禁用不符合安全策略的规则。例如，查找所有允许任意远程地址入站且已启用的 TCP 规则。

```powershell
# 查找并标记高风险入站规则
$highRiskRules = Get-NetFirewallRule |
    Where-Object {
        $_.Enabled -eq $true -and
        $_.Direction -eq 'Inbound' -and
        $_.Action -eq 'Allow'
    }

$flagged = foreach ($rule in $highRiskRules) {
    $addressFilter = $rule | Get-NetFirewallAddressFilter -ErrorAction SilentlyContinue
    $portFilter = $rule | Get-NetFirewallPortFilter -ErrorAction SilentlyContinue

    $remoteAddr = if ($addressFilter) { $addressFilter.RemoteAddress -join ', ' } else { '' }
    $localPort = if ($portFilter) { $portFilter.LocalPort -join ', ' } else { '' }

    # 标记远程地址为 Any 且端口开放的规则
    if ($remoteAddr -eq 'Any' -and $localPort -ne '') {
        [PSCustomObject]@{
            Name       = $rule.DisplayName
            Profile    = $rule.Profile
            Protocol   = $portFilter.Protocol
            LocalPort  = $localPort
            RemoteAddr = $remoteAddr
            Risk       = 'High'
        }
    }
}

$flagged | Format-Table -AutoSize

Write-Host "`n共发现 $($flagged.Count) 条高风险规则，请逐一审核。" -ForegroundColor Red
```

执行结果示例：

```text
Name                        Profile    Protocol LocalPort RemoteAddr Risk
----                        -------    -------- --------- ---------- ----
Web Server - HTTP           Any        TCP      80        Any        High
Web Server - HTTPS          Any        TCP      443       Any        High
文件和打印机共享(回显请求)   Private    ICMPv4   *         Any        High

共发现 3 条高风险规则，请逐一审核。
```

## 注意事项

1. **管理员权限**：所有 `NetFirewall` 相关的 cmdlet 创建、修改和删除操作都需要以管理员身份运行 PowerShell，查询操作也建议在提升权限后执行以获取完整信息。

2. **配置文件区分**：Windows 防火墙有 Domain、Private、Public 三种配置文件，创建规则时务必根据实际网络环境选择正确的 Profile，避免在公用网络中暴露不必要的服务端口。

3. **规则冲突检测**：新创建规则前应先检查是否存在同名或相同端口/协议的规则，重复规则可能导致意外行为或排查困难。

4. **远程地址最小化**：生产环境中应遵循最小权限原则，将 `RemoteAddress` 尽量限定为特定 IP 段或子网，而非使用 `Any`，降低被攻击面。

5. **CSV 导出编码**：导出包含中文规则名的 CSV 文件时，务必指定 `-Encoding UTF8` 参数，否则在 Excel 中打开可能出现乱码。

6. **测试环境验证**：批量修改防火墙规则前，建议先在测试环境或单台机器上验证效果，避免因规则配置不当导致服务不可达或远程管理中断。
