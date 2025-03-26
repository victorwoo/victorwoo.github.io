---
layout: post
date: 2025-01-15 08:00:00
title: "PowerShell 技能连载 - Docker 管理技巧"
description: PowerTip of the Day - PowerShell Docker Management Tips
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
在 PowerShell 中管理 Docker 容器和镜像是一项重要任务，本文将介绍一些实用的 Docker 管理技巧。

首先，让我们看看基本的 Docker 操作：

```powershell
# 创建 Docker 信息获取函数
function Get-DockerInfo {
    param(
        [string]$Host
    )
    
    try {
        $docker = "docker"
        if ($Host) {
            $docker += " -H $Host"
        }
        
        $info = & $docker info --format "{{json .}}" | ConvertFrom-Json
        $images = & $docker images --format "{{json .}}" | ConvertFrom-Json
        $containers = & $docker ps -a --format "{{json .}}" | ConvertFrom-Json
        
        return [PSCustomObject]@{
            Host = $info.Name
            Version = $info.ServerVersion
            Images = $images.Count
            Containers = $containers.Count
            RunningContainers = ($containers | Where-Object { $_.Status -like "*Up*" }).Count
            SystemInfo = [PSCustomObject]@{
                CPUs = $info.NCPU
                Memory = [math]::Round([double]$info.MemTotal / 1GB, 2)
                Storage = [math]::Round([double]$info.DockerRootDir / 1GB, 2)
            }
        }
    }
    catch {
        Write-Host "获取 Docker 信息失败：$_"
    }
}
```

Docker 镜像管理：

```powershell
# 创建 Docker 镜像管理函数
function Manage-DockerImage {
    param(
        [string]$Host,
        [string]$ImageName,
        [string]$Tag = "latest",
        [ValidateSet("build", "pull", "push", "remove")]
        [string]$Action,
        [string]$DockerfilePath,
        [string]$Registry
    )
    
    try {
        $docker = "docker"
        if ($Host) {
            $docker += " -H $Host"
        }
        
        switch ($Action) {
            "build" {
                if (-not $DockerfilePath) {
                    throw "构建镜像需要指定 Dockerfile 路径"
                }
                & $docker build -t "$ImageName`:$Tag" $DockerfilePath
            }
            "pull" {
                $image = if ($Registry) { "$Registry/$ImageName" } else { $ImageName }
                & $docker pull "$image`:$Tag"
            }
            "push" {
                if (-not $Registry) {
                    throw "推送镜像需要指定镜像仓库"
                }
                & $docker push "$Registry/$ImageName`:$Tag"
            }
            "remove" {
                & $docker rmi "$ImageName`:$Tag"
            }
        }
        
        Write-Host "镜像操作完成"
    }
    catch {
        Write-Host "镜像操作失败：$_"
    }
}
```

Docker 容器管理：

```powershell
# 创建 Docker 容器管理函数
function Manage-DockerContainer {
    param(
        [string]$Host,
        [string]$ContainerName,
        [ValidateSet("create", "start", "stop", "restart", "remove")]
        [string]$Action,
        [string]$Image,
        [hashtable]$Environment,
        [string[]]$Ports,
        [string[]]$Volumes
    )
    
    try {
        $docker = "docker"
        if ($Host) {
            $docker += " -H $Host"
        }
        
        switch ($Action) {
            "create" {
                $envParams = $Environment.GetEnumerator() | ForEach-Object { "-e", "$($_.Key)=$($_.Value)" }
                $portParams = $Ports | ForEach-Object { "-p", $_ }
                $volumeParams = $Volumes | ForEach-Object { "-v", $_ }
                
                & $docker create --name $ContainerName $envParams $portParams $volumeParams $Image
            }
            "start" {
                & $docker start $ContainerName
            }
            "stop" {
                & $docker stop $ContainerName
            }
            "restart" {
                & $docker restart $ContainerName
            }
            "remove" {
                & $docker rm -f $ContainerName
            }
        }
        
        Write-Host "容器操作完成"
    }
    catch {
        Write-Host "容器操作失败：$_"
    }
}
```

Docker 网络管理：

```powershell
# 创建 Docker 网络管理函数
function Manage-DockerNetwork {
    param(
        [string]$Host,
        [string]$NetworkName,
        [ValidateSet("create", "remove", "connect", "disconnect")]
        [string]$Action,
        [string]$Driver = "bridge",
        [string]$Subnet,
        [string]$Gateway,
        [string]$ContainerName
    )
    
    try {
        $docker = "docker"
        if ($Host) {
            $docker += " -H $Host"
        }
        
        switch ($Action) {
            "create" {
                $params = @("network", "create")
                if ($Subnet) { $params += "--subnet", $Subnet }
                if ($Gateway) { $params += "--gateway", $Gateway }
                $params += "--driver", $Driver, $NetworkName
                
                & $docker $params
            }
            "remove" {
                & $docker network rm $NetworkName
            }
            "connect" {
                if (-not $ContainerName) {
                    throw "连接网络需要指定容器名称"
                }
                & $docker network connect $NetworkName $ContainerName
            }
            "disconnect" {
                if (-not $ContainerName) {
                    throw "断开网络需要指定容器名称"
                }
                & $docker network disconnect $NetworkName $ContainerName
            }
        }
        
        Write-Host "网络操作完成"
    }
    catch {
        Write-Host "网络操作失败：$_"
    }
}
```

Docker 资源监控：

```powershell
# 创建 Docker 资源监控函数
function Monitor-DockerResources {
    param(
        [string]$Host,
        [string]$ContainerName,
        [int]$Interval = 60,
        [int]$Duration = 3600
    )
    
    try {
        $docker = "docker"
        if ($Host) {
            $docker += " -H $Host"
        }
        
        $startTime = Get-Date
        $metrics = @()
        
        while ((Get-Date) - $startTime).TotalSeconds -lt $Duration {
            $stats = & $docker stats $ContainerName --no-stream --format "{{json .}}" | ConvertFrom-Json
            
            $metrics += [PSCustomObject]@{
                Timestamp = Get-Date
                Container = $stats.Name
                CPU = [math]::Round([double]$stats.CPUPerc.TrimEnd('%'), 2)
                Memory = [math]::Round([double]$stats.MemUsage.Split('/')[0].Trim() / 1MB, 2)
                MemoryLimit = [math]::Round([double]$stats.MemUsage.Split('/')[1].Trim() / 1MB, 2)
                NetworkIO = [PSCustomObject]@{
                    RX = [math]::Round([double]$stats.NetIO.Split('/')[0].Trim() / 1MB, 2)
                    TX = [math]::Round([double]$stats.NetIO.Split('/')[1].Trim() / 1MB, 2)
                }
                BlockIO = [PSCustomObject]@{
                    Read = [math]::Round([double]$stats.BlockIO.Split('/')[0].Trim() / 1MB, 2)
                    Write = [math]::Round([double]$stats.BlockIO.Split('/')[1].Trim() / 1MB, 2)
                }
            }
            
            Start-Sleep -Seconds $Interval
        }
        
        return $metrics
    }
    catch {
        Write-Host "监控失败：$_"
    }
}
```

这些技巧将帮助您更有效地管理 Docker 环境。记住，在处理 Docker 容器和镜像时，始终要注意资源使用和安全性。同时，建议使用适当的监控和日志记录机制来跟踪容器的运行状态。 