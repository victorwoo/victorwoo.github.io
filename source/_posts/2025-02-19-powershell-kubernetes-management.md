---
layout: post
date: 2025-02-19 08:00:00
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
在 PowerShell 中管理 Kubernetes 是一项重要任务，本文将介绍一些实用的 Kubernetes 管理技巧。

首先，让我们看看基本的 Kubernetes 操作：

```powershell
# 创建 Kubernetes 集群管理函数
function Manage-K8sCluster {
    param(
        [string]$ClusterName,
        [string]$ResourceGroup,
        [string]$Location,
        [string]$NodeCount,
        [string]$NodeSize,
        [ValidateSet('Create', 'Update', 'Delete', 'Start', 'Stop')]
        [string]$Action
    )
    
    try {
        Import-Module Az.Aks
        
        switch ($Action) {
            'Create' {
                New-AzAksCluster -Name $ClusterName -ResourceGroupName $ResourceGroup -Location $Location -NodeCount $NodeCount -NodeSize $NodeSize
                Write-Host "Kubernetes 集群 $ClusterName 创建成功"
            }
            'Update' {
                Update-AzAksCluster -Name $ClusterName -ResourceGroupName $ResourceGroup -NodeCount $NodeCount
                Write-Host "Kubernetes 集群 $ClusterName 更新成功"
            }
            'Delete' {
                Remove-AzAksCluster -Name $ClusterName -ResourceGroupName $ResourceGroup -Force
                Write-Host "Kubernetes 集群 $ClusterName 删除成功"
            }
            'Start' {
                Start-AzAksCluster -Name $ClusterName -ResourceGroupName $ResourceGroup
                Write-Host "Kubernetes 集群 $ClusterName 已启动"
            }
            'Stop' {
                Stop-AzAksCluster -Name $ClusterName -ResourceGroupName $ResourceGroup
                Write-Host "Kubernetes 集群 $ClusterName 已停止"
            }
        }
    }
    catch {
        Write-Host "Kubernetes 集群操作失败：$_"
    }
}
```

Kubernetes 资源部署：

```powershell
# 创建 Kubernetes 资源部署函数
function Deploy-K8sResource {
    param(
        [string]$Namespace,
        [string]$ManifestPath,
        [string]$Context,
        [switch]$DryRun
    )
    
    try {
        Import-Module Kubernetes
        
        if ($DryRun) {
            $result = kubectl apply -f $ManifestPath -n $Namespace --context $Context --dry-run=client
            Write-Host "部署预览："
            $result
        }
        else {
            $result = kubectl apply -f $ManifestPath -n $Namespace --context $Context
            Write-Host "资源已部署到命名空间 $Namespace"
        }
        
        return [PSCustomObject]@{
            Namespace = $Namespace
            ManifestPath = $ManifestPath
            Context = $Context
            Result = $result
        }
    }
    catch {
        Write-Host "资源部署失败：$_"
    }
}
```

Kubernetes 日志收集：

```powershell
# 创建 Kubernetes 日志收集函数
function Get-K8sLogs {
    param(
        [string]$Namespace,
        [string]$Pod,
        [string]$Container,
        [int]$Lines = 100,
        [datetime]$Since,
        [string]$OutputPath
    )
    
    try {
        Import-Module Kubernetes
        
        $logParams = @(
            "logs",
            $Pod,
            "-n", $Namespace,
            "--tail=$Lines"
        )
        
        if ($Container) {
            $logParams += "-c", $Container
        }
        
        if ($Since) {
            $logParams += "--since=$($Since.ToString('yyyy-MM-ddTHH:mm:ssZ'))"
        }
        
        $logs = kubectl $logParams
        
        if ($OutputPath) {
            $logs | Out-File -FilePath $OutputPath -Encoding UTF8
        }
        
        return [PSCustomObject]@{
            Pod = $Pod
            Namespace = $Namespace
            Container = $Container
            LogCount = $logs.Count
            OutputPath = $OutputPath
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
        [string]$ResourceType,
        [int]$Duration = 3600,
        [int]$Interval = 60
    )
    
    try {
        Import-Module Kubernetes
        
        $metrics = @()
        $endTime = Get-Date
        $startTime = $endTime.AddSeconds(-$Duration)
        
        while ($startTime -lt $endTime) {
            $resourceMetrics = switch ($ResourceType) {
                "Pod" {
                    kubectl top pods -n $Namespace
                }
                "Node" {
                    kubectl top nodes
                }
                "Deployment" {
                    kubectl top deployment -n $Namespace
                }
                default {
                    throw "不支持的资源类型：$ResourceType"
                }
            }
            
            $metrics += [PSCustomObject]@{
                Time = $startTime
                ResourceType = $ResourceType
                Metrics = $resourceMetrics
            }
            
            $startTime = $startTime.AddSeconds($Interval)
            Start-Sleep -Seconds $Interval
        }
        
        return [PSCustomObject]@{
            Namespace = $Namespace
            ResourceType = $ResourceType
            Duration = $Duration
            Interval = $Interval
            Metrics = $metrics
        }
    }
    catch {
        Write-Host "资源监控失败：$_"
    }
}
```

Kubernetes 问题诊断：

```powershell
# 创建 Kubernetes 问题诊断函数
function Debug-K8sIssues {
    param(
        [string]$Namespace,
        [string]$Pod,
        [string]$OutputPath
    )
    
    try {
        Import-Module Kubernetes
        
        $diagnostics = @{
            PodStatus = kubectl get pod $Pod -n $Namespace -o yaml
            PodDescription = kubectl describe pod $Pod -n $Namespace
            PodEvents = kubectl get events -n $Namespace --field-selector involvedObject.name=$Pod
            PodLogs = kubectl logs $Pod -n $Namespace
        }
        
        if ($OutputPath) {
            $diagnostics | ConvertTo-Json -Depth 10 | Out-File -FilePath $OutputPath -Encoding UTF8
        }
        
        return [PSCustomObject]@{
            Pod = $Pod
            Namespace = $Namespace
            Diagnostics = $diagnostics
            OutputPath = $OutputPath
        }
    }
    catch {
        Write-Host "问题诊断失败：$_"
    }
}
```

这些技巧将帮助您更有效地管理 Kubernetes。记住，在处理 Kubernetes 时，始终要注意安全性和性能。同时，建议使用适当的错误处理和日志记录机制来跟踪所有操作。 