---
layout: post
date: 2025-02-17 08:00:00
title: "PowerShell 技能连载 - Kubernetes 管理技巧"
description: PowerTip of the Day - PowerShell Kubernetes Management Tips
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
在 PowerShell 中管理 Kubernetes 集群是一项重要任务，本文将介绍一些实用的 Kubernetes 管理技巧。

首先，让我们看看基本的 Kubernetes 操作：

```powershell
# 创建 Kubernetes 集群信息获取函数
function Get-K8sClusterInfo {
    param(
        [string]$Context
    )
    
    try {
        $kubectl = "kubectl"
        if ($Context) {
            $kubectl += " --context=$Context"
        }
        
        $nodes = & $kubectl get nodes -o json | ConvertFrom-Json
        $pods = & $kubectl get pods --all-namespaces -o json | ConvertFrom-Json
        
        return [PSCustomObject]@{
            NodeCount = $nodes.items.Count
            PodCount = $pods.items.Count
            Namespaces = ($pods.items | Select-Object -ExpandProperty metadata | Select-Object -ExpandProperty namespace -Unique).Count
            NodeStatus = $nodes.items | ForEach-Object {
                [PSCustomObject]@{
                    Name = $_.metadata.name
                    Status = $_.status.conditions | Where-Object { $_.type -eq "Ready" } | Select-Object -ExpandProperty status
                    Version = $_.status.nodeInfo.kubeletVersion
                }
            }
        }
    }
    catch {
        Write-Host "获取集群信息失败：$_"
    }
}
```

Kubernetes 资源部署：

```powershell
# 创建 Kubernetes 资源部署函数
function Deploy-K8sResource {
    param(
        [string]$ManifestPath,
        [string]$Namespace,
        [string]$Context,
        [switch]$DryRun
    )
    
    try {
        $kubectl = "kubectl"
        if ($Context) {
            $kubectl += " --context=$Context"
        }
        if ($Namespace) {
            $kubectl += " -n $Namespace"
        }
        if ($DryRun) {
            $kubectl += " --dry-run=client"
        }
        
        $command = "$kubectl apply -f `"$ManifestPath`""
        Invoke-Expression $command
        
        Write-Host "资源部署完成"
    }
    catch {
        Write-Host "部署失败：$_"
    }
}
```

Kubernetes 日志收集：

```powershell
# 创建 Kubernetes 日志收集函数
function Get-K8sLogs {
    param(
        [string]$PodName,
        [string]$Namespace,
        [string]$Container,
        [int]$Lines = 100,
        [string]$Context,
        [datetime]$Since
    )
    
    try {
        $kubectl = "kubectl"
        if ($Context) {
            $kubectl += " --context=$Context"
        }
        if ($Namespace) {
            $kubectl += " -n $Namespace"
        }
        if ($Container) {
            $kubectl += " -c $Container"
        }
        if ($Since) {
            $kubectl += " --since=$($Since.ToString('yyyy-MM-ddTHH:mm:ssZ'))"
        }
        
        $command = "$kubectl logs $PodName --tail=$Lines"
        $logs = Invoke-Expression $command
        
        return [PSCustomObject]@{
            PodName = $PodName
            Container = $Container
            Logs = $logs
            Timestamp = Get-Date
        }
    }
    catch {
        Write-Host "日志收集失败：$_"
    }
}
```

Kubernetes 资源监控：

```powershell
# 创建 Kubernetes 资源监控函数
function Monitor-K8sResources {
    param(
        [string]$Namespace,
        [string]$Context,
        [int]$Interval = 60,
        [int]$Duration = 3600
    )
    
    try {
        $kubectl = "kubectl"
        if ($Context) {
            $kubectl += " --context=$Context"
        }
        if ($Namespace) {
            $kubectl += " -n $Namespace"
        }
        
        $startTime = Get-Date
        $metrics = @()
        
        while ((Get-Date) - $startTime).TotalSeconds -lt $Duration {
            $pods = & $kubectl get pods -o json | ConvertFrom-Json
            $nodes = & $kubectl get nodes -o json | ConvertFrom-Json
            
            $metrics += [PSCustomObject]@{
                Timestamp = Get-Date
                PodCount = $pods.items.Count
                NodeCount = $nodes.items.Count
                PodStatus = $pods.items | Group-Object { $_.status.phase } | ForEach-Object {
                    [PSCustomObject]@{
                        Status = $_.Name
                        Count = $_.Count
                    }
                }
                NodeStatus = $nodes.items | Group-Object { $_.status.conditions | Where-Object { $_.type -eq "Ready" } | Select-Object -ExpandProperty status } | ForEach-Object {
                    [PSCustomObject]@{
                        Status = $_.Name
                        Count = $_.Count
                    }
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

Kubernetes 故障排查：

```powershell
# 创建 Kubernetes 故障排查函数
function Debug-K8sIssues {
    param(
        [string]$PodName,
        [string]$Namespace,
        [string]$Context,
        [switch]$IncludeEvents,
        [switch]$IncludeLogs
    )
    
    try {
        $kubectl = "kubectl"
        if ($Context) {
            $kubectl += " --context=$Context"
        }
        if ($Namespace) {
            $kubectl += " -n $Namespace"
        }
        
        $diagnostics = @{
            PodStatus = & $kubectl get pod $PodName -o json | ConvertFrom-Json
            PodDescription = & $kubectl describe pod $PodName
        }
        
        if ($IncludeEvents) {
            $diagnostics.Events = & $kubectl get events --field-selector involvedObject.name=$PodName
        }
        
        if ($IncludeLogs) {
            $diagnostics.Logs = & $kubectl logs $PodName
        }
        
        return [PSCustomObject]$diagnostics
    }
    catch {
        Write-Host "故障排查失败：$_"
    }
}
```

这些技巧将帮助您更有效地管理 Kubernetes 集群。记住，在处理 Kubernetes 资源时，始终要注意集群的安全性和稳定性。同时，建议在处理大型集群时使用适当的资源限制和监控机制。 