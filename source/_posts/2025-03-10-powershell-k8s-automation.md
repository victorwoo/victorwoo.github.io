---
layout: post
date: 2025-03-10 08:00:00
title: "PowerShell 技能连载 - Kubernetes 节点智能编排"
description: "使用PowerShell实现Kubernetes节点自动化管理"
categories:
- powershell
- devops
- kubernetes
tags:
- powershell
- kubernetes
- automation
---

```powershell
function Invoke-K8sNodeOrchestration {
    [CmdletBinding()]
    param(
        [ValidateSet('ScaleUp','ScaleDown','Maintenance')]
        [string]$Operation,
        [int]$NodeCount = 1
    )

    $nodePool = Get-AzAksNodePool -ClusterName 'prod-cluster'
    $metrics = Invoke-RestMethod -Uri 'http://k8s-metrics:8080/api/v1/nodes'

    switch ($Operation) {
        'ScaleUp' {
            $newCount = $nodePool.Count + $NodeCount
            Update-AzAksNodePool -Name $nodePool.Name -Count $newCount
            Write-Host "节点池已扩容至$newCount个节点"
        }
        'ScaleDown' {
            $nodesToRemove = $metrics.Nodes | 
                Where-Object { $_.CpuUsage -lt 20 } | 
                Select-Object -First $NodeCount
            $nodesToRemove | ForEach-Object {
                Set-AzAksNode -Name $_.Name -State Draining
            }
        }
        'Maintenance' {
            $metrics.Nodes | Where-Object { $_.HealthStatus -ne 'Healthy' } |
                ForEach-Object {
                    Add-K8sNodeLabel -Node $_.Name -Label @{
                        'maintenance' = (Get-Date).ToString('yyyyMMdd')
                    }
                }
        }
    }
}
```

**核心功能**：
1. 节点自动扩缩容策略
2. 基于资源利用率的智能调度
3. 维护模式自动标签管理
4. 与Azure AKS深度集成

**典型应用场景**：
- 应对突发流量自动扩容节点
- 低负载时段自动缩容节约成本
- 异常节点自动隔离维护
- 跨可用区节点平衡管理