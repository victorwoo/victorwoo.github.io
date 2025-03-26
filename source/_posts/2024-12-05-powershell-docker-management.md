---
layout: post
date: 2024-12-05 08:00:00
title: "PowerShell 技能连载 - Docker容器管理技巧"
description: PowerTip of the Day - PowerShell Docker Container Management
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
在现代应用程序开发中，Docker容器已经成为不可或缺的工具。本文将介绍如何使用PowerShell来管理和操作Docker容器，包括容器生命周期管理、资源监控、网络配置等功能。

## 容器生命周期管理

首先，让我们创建一个用于管理Docker容器生命周期的函数：

```powershell
function Manage-DockerContainer {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateSet('Create', 'Start', 'Stop', 'Remove', 'Restart', 'Pause', 'Resume')]
        [string]$Action,
        
        [Parameter(Mandatory = $true)]
        [string]$ContainerName,
        
        [Parameter()]
        [string]$Image,
        
        [Parameter()]
        [string[]]$PortMappings,
        
        [Parameter()]
        [string[]]$EnvironmentVariables,
        
        [Parameter()]
        [string[]]$Volumes,
        
        [Parameter()]
        [string]$Network,
        
        [Parameter()]
        [hashtable]$ResourceLimits,
        
        [Parameter()]
        [switch]$AutoRemove,
        
        [Parameter()]
        [switch]$Detached
    )
    
    try {
        $containerConfig = [PSCustomObject]@{
            Name = $ContainerName
            Action = $Action
            Timestamp = Get-Date
            Status = "Pending"
            Details = @{}
        }
        
        switch ($Action) {
            'Create' {
                if (-not $Image) {
                    throw "创建容器时必须指定镜像"
                }
                
                $dockerArgs = @(
                    "create"
                    "--name", $ContainerName
                )
                
                if ($PortMappings) {
                    foreach ($mapping in $PortMappings) {
                        $dockerArgs += "-p", $mapping
                    }
                }
                
                if ($EnvironmentVariables) {
                    foreach ($env in $EnvironmentVariables) {
                        $dockerArgs += "-e", $env
                    }
                }
                
                if ($Volumes) {
                    foreach ($volume in $Volumes) {
                        $dockerArgs += "-v", $volume
                    }
                }
                
                if ($Network) {
                    $dockerArgs += "--network", $Network
                }
                
                if ($ResourceLimits) {
                    if ($ResourceLimits.ContainsKey('Memory')) {
                        $dockerArgs += "--memory", $ResourceLimits.Memory
                    }
                    if ($ResourceLimits.ContainsKey('CpuShares')) {
                        $dockerArgs += "--cpu-shares", $ResourceLimits.CpuShares
                    }
                }
                
                if ($AutoRemove) {
                    $dockerArgs += "--rm"
                }
                
                if ($Detached) {
                    $dockerArgs += "-d"
                }
                
                $dockerArgs += $Image
                
                $result = docker $dockerArgs
                $containerConfig.Details.Result = $result
                $containerConfig.Status = "Created"
            }
            
            'Start' {
                $result = docker start $ContainerName
                $containerConfig.Details.Result = $result
                $containerConfig.Status = "Started"
            }
            
            'Stop' {
                $result = docker stop $ContainerName
                $containerConfig.Details.Result = $result
                $containerConfig.Status = "Stopped"
            }
            
            'Remove' {
                $result = docker rm -f $ContainerName
                $containerConfig.Details.Result = $result
                $containerConfig.Status = "Removed"
            }
            
            'Restart' {
                $result = docker restart $ContainerName
                $containerConfig.Details.Result = $result
                $containerConfig.Status = "Restarted"
            }
            
            'Pause' {
                $result = docker pause $ContainerName
                $containerConfig.Details.Result = $result
                $containerConfig.Status = "Paused"
            }
            
            'Resume' {
                $result = docker unpause $ContainerName
                $containerConfig.Details.Result = $result
                $containerConfig.Status = "Resumed"
            }
        }
        
        # 记录操作日志
        $logEntry = [PSCustomObject]@{
            Timestamp = Get-Date
            Action = "Docker容器操作"
            Container = $ContainerName
            Operation = $Action
            Config = $containerConfig
        }
        
        Write-Host "容器操作完成：$($logEntry | ConvertTo-Json)"
        
        return $containerConfig
    }
    catch {
        Write-Error "Docker容器操作失败：$_"
        return $null
    }
}
```

## 容器资源监控

接下来，创建一个用于监控Docker容器资源的函数：

```powershell
function Get-DockerContainerMetrics {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$ContainerName,
        
        [Parameter()]
        [ValidateSet('CPU', 'Memory', 'Network', 'Disk', 'All')]
        [string[]]$Metrics = @('All'),
        
        [Parameter()]
        [int]$DurationSeconds = 60,
        
        [Parameter()]
        [int]$IntervalSeconds = 5
    )
    
    try {
        $metrics = [PSCustomObject]@{
            ContainerName = $ContainerName
            StartTime = Get-Date
            EndTime = (Get-Date).AddSeconds($DurationSeconds)
            DataPoints = @()
        }
        
        $endTime = (Get-Date).AddSeconds($DurationSeconds)
        
        while ((Get-Date) -lt $endTime) {
            $dataPoint = [PSCustomObject]@{
                Timestamp = Get-Date
            }
            
            if ($Metrics -contains 'All' -or $Metrics -contains 'CPU') {
                $cpuStats = docker stats $ContainerName --no-stream --format "{{.CPUPerc}}"
                $dataPoint.CPUUsage = $cpuStats
            }
            
            if ($Metrics -contains 'All' -or $Metrics -contains 'Memory') {
                $memoryStats = docker stats $ContainerName --no-stream --format "{{.MemUsage}}"
                $dataPoint.MemoryUsage = $memoryStats
            }
            
            if ($Metrics -contains 'All' -or $Metrics -contains 'Network') {
                $networkStats = docker stats $ContainerName --no-stream --format "{{.NetIO}}"
                $dataPoint.NetworkIO = $networkStats
            }
            
            if ($Metrics -contains 'All' -or $Metrics -contains 'Disk') {
                $diskStats = docker stats $ContainerName --no-stream --format "{{.BlockIO}}"
                $dataPoint.DiskIO = $diskStats
            }
            
            $metrics.DataPoints += $dataPoint
            Start-Sleep -Seconds $IntervalSeconds
        }
        
        # 计算统计数据
        $metrics.Statistics = [PSCustomObject]@{
            AverageCPUUsage = ($metrics.DataPoints | Measure-Object -Property CPUUsage -Average).Average
            AverageMemoryUsage = ($metrics.DataPoints | Measure-Object -Property MemoryUsage -Average).Average
            MaxCPUUsage = ($metrics.DataPoints | Measure-Object -Property CPUUsage -Maximum).Maximum
            MaxMemoryUsage = ($metrics.DataPoints | Measure-Object -Property MemoryUsage -Maximum).Maximum
        }
        
        return $metrics
    }
    catch {
        Write-Error "获取容器指标失败：$_"
        return $null
    }
}
```

## 容器网络管理

最后，创建一个用于管理Docker容器网络的函数：

```powershell
function Manage-DockerNetwork {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateSet('Create', 'Remove', 'Connect', 'Disconnect', 'Inspect')]
        [string]$Action,
        
        [Parameter(Mandatory = $true)]
        [string]$NetworkName,
        
        [Parameter()]
        [ValidateSet('Bridge', 'Host', 'None', 'Overlay')]
        [string]$Driver = "Bridge",
        
        [Parameter()]
        [string]$Subnet,
        
        [Parameter()]
        [string]$Gateway,
        
        [Parameter()]
        [string]$ContainerName,
        
        [Parameter()]
        [hashtable]$IPAMConfig,
        
        [Parameter()]
        [switch]$Internal,
        
        [Parameter()]
        [switch]$Attachable
    )
    
    try {
        $networkConfig = [PSCustomObject]@{
            Name = $NetworkName
            Action = $Action
            Timestamp = Get-Date
            Status = "Pending"
            Details = @{}
        }
        
        switch ($Action) {
            'Create' {
                $dockerArgs = @(
                    "network", "create"
                    "--driver", $Driver
                )
                
                if ($Subnet) {
                    $dockerArgs += "--subnet", $Subnet
                }
                
                if ($Gateway) {
                    $dockerArgs += "--gateway", $Gateway
                }
                
                if ($IPAMConfig) {
                    $dockerArgs += "--ip-range", $IPAMConfig.IPRange
                }
                
                if ($Internal) {
                    $dockerArgs += "--internal"
                }
                
                if ($Attachable) {
                    $dockerArgs += "--attachable"
                }
                
                $dockerArgs += $NetworkName
                
                $result = docker $dockerArgs
                $networkConfig.Details.Result = $result
                $networkConfig.Status = "Created"
            }
            
            'Remove' {
                $result = docker network rm $NetworkName
                $networkConfig.Details.Result = $result
                $networkConfig.Status = "Removed"
            }
            
            'Connect' {
                if (-not $ContainerName) {
                    throw "连接网络时必须指定容器名称"
                }
                
                $result = docker network connect $NetworkName $ContainerName
                $networkConfig.Details.Result = $result
                $networkConfig.Status = "Connected"
            }
            
            'Disconnect' {
                if (-not $ContainerName) {
                    throw "断开网络时必须指定容器名称"
                }
                
                $result = docker network disconnect $NetworkName $ContainerName
                $networkConfig.Details.Result = $result
                $networkConfig.Status = "Disconnected"
            }
            
            'Inspect' {
                $result = docker network inspect $NetworkName
                $networkConfig.Details.Result = $result
                $networkConfig.Status = "Inspected"
            }
        }
        
        # 记录操作日志
        $logEntry = [PSCustomObject]@{
            Timestamp = Get-Date
            Action = "Docker网络操作"
            Network = $NetworkName
            Operation = $Action
            Config = $networkConfig
        }
        
        Write-Host "网络操作完成：$($logEntry | ConvertTo-Json)"
        
        return $networkConfig
    }
    catch {
        Write-Error "Docker网络操作失败：$_"
        return $null
    }
}
```

## 使用示例

以下是如何使用这些函数来管理Docker容器的示例：

```powershell
# 创建并启动一个容器
$container = Manage-DockerContainer -Action "Create" `
    -ContainerName "myapp" `
    -Image "nginx:latest" `
    -PortMappings @("8080:80") `
    -EnvironmentVariables @("ENV=production") `
    -Volumes @("/host/path:/container/path") `
    -Network "my-network" `
    -ResourceLimits @{
        "Memory" = "512m"
        "CpuShares" = "512"
    } `
    -Detached

# 监控容器资源使用情况
$metrics = Get-DockerContainerMetrics -ContainerName "myapp" `
    -Metrics @("CPU", "Memory") `
    -DurationSeconds 300 `
    -IntervalSeconds 10

# 创建自定义网络
$network = Manage-DockerNetwork -Action "Create" `
    -NetworkName "my-network" `
    -Driver "Bridge" `
    -Subnet "172.18.0.0/16" `
    -Gateway "172.18.0.1" `
    -IPAMConfig @{
        "IPRange" = "172.18.0.2/24"
    } `
    -Attachable
```

## 最佳实践

1. 始终为容器指定资源限制，防止资源耗尽
2. 使用命名卷而不是绑定挂载，提高可移植性
3. 定期清理未使用的容器、镜像和网络
4. 实施容器健康检查机制
5. 使用容器编排工具（如Kubernetes）管理大规模部署
6. 实施日志轮转和监控告警
7. 定期更新容器镜像以修复安全漏洞
8. 使用多阶段构建优化镜像大小 