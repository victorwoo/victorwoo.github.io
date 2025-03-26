---
layout: post
date: 2025-02-25 08:00:00
title: "PowerShell 技能连载 - 资产管理"
description: PowerTip of the Day - PowerShell Asset Management
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
在系统管理中，资产管理对于确保资源的有效利用和成本控制至关重要。本文将介绍如何使用PowerShell构建一个资产管理系统，包括资产发现、跟踪和优化等功能。

## 资产发现

首先，让我们创建一个用于管理资产发现的函数：

```powershell
function Discover-SystemAssets {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$DiscoveryID,
        
        [Parameter()]
        [string[]]$AssetTypes,
        
        [Parameter()]
        [ValidateSet("Full", "Quick", "Custom")]
        [string]$DiscoveryMode = "Full",
        
        [Parameter()]
        [hashtable]$DiscoveryConfig,
        
        [Parameter()]
        [string]$LogPath
    )
    
    try {
        $discoverer = [PSCustomObject]@{
            DiscoveryID = $DiscoveryID
            StartTime = Get-Date
            DiscoveryStatus = @{}
            Assets = @{}
            Issues = @()
        }
        
        # 获取发现配置
        $config = Get-DiscoveryConfig -DiscoveryID $DiscoveryID
        
        # 管理发现
        foreach ($type in $AssetTypes) {
            $status = [PSCustomObject]@{
                Type = $type
                Status = "Unknown"
                Config = @{}
                Assets = @{}
                Issues = @()
            }
            
            # 应用发现配置
            $typeConfig = Apply-DiscoveryConfig `
                -Config $config `
                -Type $type `
                -Mode $DiscoveryMode `
                -Settings $DiscoveryConfig
            
            $status.Config = $typeConfig
            
            # 发现系统资产
            $assets = Discover-AssetInventory `
                -Type $type `
                -Config $typeConfig
            
            $status.Assets = $assets
            $discoverer.Assets[$type] = $assets
            
            # 检查资产问题
            $issues = Check-AssetIssues `
                -Assets $assets `
                -Config $typeConfig
            
            $status.Issues = $issues
            $discoverer.Issues += $issues
            
            # 更新发现状态
            if ($issues.Count -gt 0) {
                $status.Status = "Warning"
            }
            else {
                $status.Status = "Success"
            }
            
            $discoverer.DiscoveryStatus[$type] = $status
        }
        
        # 记录发现日志
        if ($LogPath) {
            $discoverer | ConvertTo-Json -Depth 10 | Out-File -FilePath $LogPath
        }
        
        # 更新发现器状态
        $discoverer.EndTime = Get-Date
        
        return $discoverer
    }
    catch {
        Write-Error "资产发现失败：$_"
        return $null
    }
}
```

## 资产跟踪

接下来，创建一个用于管理资产跟踪的函数：

```powershell
function Track-SystemAssets {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$TrackingID,
        
        [Parameter()]
        [string[]]$TrackingTypes,
        
        [Parameter()]
        [ValidateSet("Usage", "Cost", "Lifecycle")]
        [string]$TrackingMode = "Usage",
        
        [Parameter()]
        [hashtable]$TrackingConfig,
        
        [Parameter()]
        [string]$ReportPath
    )
    
    try {
        $tracker = [PSCustomObject]@{
            TrackingID = $TrackingID
            StartTime = Get-Date
            TrackingStatus = @{}
            Tracking = @{}
            Metrics = @()
        }
        
        # 获取跟踪配置
        $config = Get-TrackingConfig -TrackingID $TrackingID
        
        # 管理跟踪
        foreach ($type in $TrackingTypes) {
            $status = [PSCustomObject]@{
                Type = $type
                Status = "Unknown"
                Config = @{}
                Tracking = @{}
                Metrics = @()
            }
            
            # 应用跟踪配置
            $typeConfig = Apply-TrackingConfig `
                -Config $config `
                -Type $type `
                -Mode $TrackingMode `
                -Settings $TrackingConfig
            
            $status.Config = $typeConfig
            
            # 跟踪系统资产
            $tracking = Track-AssetMetrics `
                -Type $type `
                -Config $typeConfig
            
            $status.Tracking = $tracking
            $tracker.Tracking[$type] = $tracking
            
            # 生成跟踪指标
            $metrics = Generate-TrackingMetrics `
                -Tracking $tracking `
                -Config $typeConfig
            
            $status.Metrics = $metrics
            $tracker.Metrics += $metrics
            
            # 更新跟踪状态
            if ($metrics.Count -gt 0) {
                $status.Status = "Active"
            }
            else {
                $status.Status = "Inactive"
            }
            
            $tracker.TrackingStatus[$type] = $status
        }
        
        # 生成报告
        if ($ReportPath) {
            $report = Generate-TrackingReport `
                -Tracker $tracker `
                -Config $config
            
            $report | ConvertTo-Json -Depth 10 | Out-File -FilePath $ReportPath
        }
        
        # 更新跟踪器状态
        $tracker.EndTime = Get-Date
        
        return $tracker
    }
    catch {
        Write-Error "资产跟踪失败：$_"
        return $null
    }
}
```

## 资产优化

最后，创建一个用于管理资产优化的函数：

```powershell
function Optimize-SystemAssets {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$OptimizationID,
        
        [Parameter()]
        [string[]]$OptimizationTypes,
        
        [Parameter()]
        [ValidateSet("Cost", "Performance", "Utilization")]
        [string]$OptimizationMode = "Cost",
        
        [Parameter()]
        [hashtable]$OptimizationConfig,
        
        [Parameter()]
        [string]$ReportPath
    )
    
    try {
        $optimizer = [PSCustomObject]@{
            OptimizationID = $OptimizationID
            StartTime = Get-Date
            OptimizationStatus = @{}
            Optimizations = @{}
            Actions = @()
        }
        
        # 获取优化配置
        $config = Get-OptimizationConfig -OptimizationID $OptimizationID
        
        # 管理优化
        foreach ($type in $OptimizationTypes) {
            $status = [PSCustomObject]@{
                Type = $type
                Status = "Unknown"
                Config = @{}
                Optimizations = @{}
                Actions = @()
            }
            
            # 应用优化配置
            $typeConfig = Apply-OptimizationConfig `
                -Config $config `
                -Type $type `
                -Mode $OptimizationMode `
                -Settings $OptimizationConfig
            
            $status.Config = $typeConfig
            
            # 优化系统资产
            $optimizations = Optimize-AssetUsage `
                -Type $type `
                -Config $typeConfig
            
            $status.Optimizations = $optimizations
            $optimizer.Optimizations[$type] = $optimizations
            
            # 执行优化动作
            $actions = Execute-OptimizationActions `
                -Optimizations $optimizations `
                -Config $typeConfig
            
            $status.Actions = $actions
            $optimizer.Actions += $actions
            
            # 更新优化状态
            if ($actions.Count -gt 0) {
                $status.Status = "Optimized"
            }
            else {
                $status.Status = "NoAction"
            }
            
            $optimizer.OptimizationStatus[$type] = $status
        }
        
        # 生成报告
        if ($ReportPath) {
            $report = Generate-OptimizationReport `
                -Optimizer $optimizer `
                -Config $config
            
            $report | ConvertTo-Json -Depth 10 | Out-File -FilePath $ReportPath
        }
        
        # 更新优化器状态
        $optimizer.EndTime = Get-Date
        
        return $optimizer
    }
    catch {
        Write-Error "资产优化失败：$_"
        return $null
    }
}
```

## 使用示例

以下是如何使用这些函数来管理资产的示例：

```powershell
# 发现系统资产
$discoverer = Discover-SystemAssets -DiscoveryID "DISCOVERY001" `
    -AssetTypes @("Hardware", "Software", "Network", "Storage") `
    -DiscoveryMode "Full" `
    -DiscoveryConfig @{
        "Hardware" = @{
            "Categories" = @("Server", "Desktop", "Mobile")
            "Attributes" = @("CPU", "Memory", "Storage")
            "Filter" = "Status = Active"
            "Retention" = 7
        }
        "Software" = @{
            "Categories" = @("OS", "Application", "Driver")
            "Attributes" = @("Version", "License", "InstallDate")
            "Filter" = "Status = Installed"
            "Retention" = 7
        }
        "Network" = @{
            "Categories" = @("Device", "Connection", "Protocol")
            "Attributes" = @("IP", "MAC", "Speed")
            "Filter" = "Status = Connected"
            "Retention" = 7
        }
        "Storage" = @{
            "Categories" = @("Disk", "Volume", "Share")
            "Attributes" = @("Size", "Free", "Type")
            "Filter" = "Status = Online"
            "Retention" = 7
        }
    } `
    -LogPath "C:\Logs\asset_discovery.json"

# 跟踪系统资产
$tracker = Track-SystemAssets -TrackingID "TRACKING001" `
    -TrackingTypes @("Usage", "Cost", "Lifecycle") `
    -TrackingMode "Usage" `
    -TrackingConfig @{
        "Usage" = @{
            "Metrics" = @("CPU", "Memory", "Storage", "Network")
            "Threshold" = 80
            "Interval" = 60
            "Report" = $true
        }
        "Cost" = @{
            "Metrics" = @("License", "Maintenance", "Support")
            "Threshold" = 1000
            "Interval" = 30
            "Report" = $true
        }
        "Lifecycle" = @{
            "Metrics" = @("Age", "Warranty", "Depreciation")
            "Threshold" = 365
            "Interval" = 90
            "Report" = $true
        }
    } `
    -ReportPath "C:\Reports\asset_tracking.json"

# 优化系统资产
$optimizer = Optimize-SystemAssets -OptimizationID "OPTIMIZATION001" `
    -OptimizationTypes @("Cost", "Performance", "Utilization") `
    -OptimizationMode "Cost" `
    -OptimizationConfig @{
        "Cost" = @{
            "Metrics" = @("License", "Maintenance", "Support")
            "Threshold" = 1000
            "Actions" = @("Renew", "Upgrade", "Terminate")
            "Report" = $true
        }
        "Performance" = @{
            "Metrics" = @("CPU", "Memory", "Storage", "Network")
            "Threshold" = 80
            "Actions" = @("Scale", "Upgrade", "Migrate")
            "Report" = $true
        }
        "Utilization" = @{
            "Metrics" = @("Usage", "Efficiency", "Availability")
            "Threshold" = 60
            "Actions" = @("Consolidate", "Optimize", "Decommission")
            "Report" = $true
        }
    } `
    -ReportPath "C:\Reports\asset_optimization.json"
```

## 最佳实践

1. 实施资产发现
2. 跟踪资产使用
3. 优化资产利用
4. 保持详细的资产记录
5. 定期进行资产评估
6. 实施优化策略
7. 建立成本控制
8. 保持系统文档更新 