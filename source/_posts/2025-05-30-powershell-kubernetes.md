---
layout: post
date: 2025-05-30 08:00:00
title: "PowerShell 技能连载 - Kubernetes 运维管理"
description: PowerTip of the Day - Kubernetes Operations Management in PowerShell
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
- kubernetes
- k8s
- devops
---

_适用于 PowerShell 7.0 及以上版本，需安装 kubectl_

Kubernetes 已成为容器编排的事实标准，无论是自建集群还是使用托管服务（AKS、EKS、GKE），日常运维都离不开与 Kubernetes API 交互。虽然 `kubectl` 是官方命令行工具，但 PowerShell 的管道、对象处理和脚本能力可以为 Kubernetes 运维带来更高的效率——特别是在批量操作、日志聚合和自动化巡检等场景中。

本文将讲解如何使用 PowerShell 封装 kubectl 命令，实现高效的 Kubernetes 运维管理。

## kubectl 环境准备

```powershell
# 检查 kubectl 是否可用
kubectl version --client 2>$null
if ($LASTEXITCODE -ne 0) {
    Write-Host "kubectl 未安装" -ForegroundColor Red
    # 安装 kubectl
    Install-Script -Name install-kubectl -Scope CurrentUser -Force
}

# 查看当前集群信息
kubectl cluster-info

# 查看节点状态
kubectl get nodes -o wide

# 切换命名空间（使用 kubens 或 kubectl）
$kubeConfig = "$env:USERPROFILE\.kube\config"

# 列出所有命名空间
kubectl get namespaces | Select-Object -Skip 1 |
    ForEach-Object { ($_ -split '\s+')[0] }
```

执行结果示例：

```
Client Version: v1.30.0
Kubernetes control plane is running at https://k8s-api.example.com:6443

NAME       STATUS   ROLES           AGE   VERSION   INTERNAL-IP
node-01    Ready    control-plane   90d   v1.30.0   10.0.0.1
node-02    Ready    worker          90d   v1.30.0   10.0.0.2
node-03    Ready    worker          90d   v1.30.0   10.0.0.3
```

## 解析 kubectl 输出为 PowerShell 对象

kubectl 的文本输出可以通过管道解析为结构化对象：

```powershell
function Get-K8sPod {
    <#
    .SYNOPSIS
    获取 Kubernetes Pod 信息
    #>
    param(
        [string]$Namespace = "default",
        [string]$LabelSelector,
        [string]$FieldSelector
    )

    $args = @('get', 'pods', '-n', $Namespace, '-o', 'custom-columns=NAME:.metadata.name,STATUS:.status.phase,NODE:.spec.nodeName,RESTARTS:.status.containerStatuses[0].restartCount,AGE:.metadata.creationTimestamp,IP:.status.podIP')

    if ($LabelSelector) { $args += @('-l', $LabelSelector) }
    if ($FieldSelector) { $args += @('--field-selector', $FieldSelector) }

    $output = kubectl @args 2>$null
    if ($output.Count -le 1) { return @() }

    $output | Select-Object -Skip 1 | ForEach-Object {
        $parts = $_ -split '\s+'
        [PSCustomObject]@{
            Name     = $parts[0]
            Status   = $parts[1]
            Node     = $parts[2]
            Restarts = [int]$parts[3]
            Age      = $parts[4]
            IP       = $parts[5]
        }
    }
}

# 查看所有 Pod
Get-K8sPod -Namespace "production" | Format-Table -AutoSize

# 按标签筛选
Get-K8sPod -Namespace "production" -LabelSelector "app=web" |
    Format-Table -AutoSize

# 查看失败的 Pod
Get-K8sPod | Where-Object { $_.Status -ne 'Running' }
```

执行结果示例：

```
Name                    Status   Node     Restarts Age      IP
----                    ------   ----     -------- ---      --
web-app-7d4f8b-x2k9l   Running  node-02  0        5d       10.244.1.15
web-app-7d4f8b-m8n3p   Running  node-03  0        5d       10.244.2.22
api-server-5c9a2d-q7j4 Running  node-02  3        12d      10.244.1.10
redis-master-0          Running  node-01  0        30d      10.244.0.5

Name                    Status   Node     Restarts Age      IP
----                    ------   ----     -------- ---      --
web-app-7d4f8b-x2k9l   Running  node-02  0        5d       10.244.1.15
web-app-7d4f8b-m8n3p   Running  node-03  0        5d       10.244.2.22
```

## 集群健康巡检

使用 PowerShell 构建自动化的 Kubernetes 集群健康检查：

```powershell
function Get-K8sClusterHealth {
    <#
    .SYNOPSIS
    Kubernetes 集群健康巡检
    #>
    param(
        [string[]]$Namespaces = @('default', 'production', 'monitoring')
    )

    Write-Host "========== Kubernetes 集群健康报告 ==========" -ForegroundColor Cyan
    Write-Host "检查时间：$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')`n"

    # 1. 节点状态
    Write-Host "--- 节点状态 ---" -ForegroundColor Yellow
    $nodes = kubectl get nodes -o json | ConvertFrom-Json
    foreach ($node in $nodes.items) {
        $conditions = $node.status.conditions | Where-Object { $_.type -eq 'Ready' }
        $status = $conditions.status
        $cpuAlloc = $node.status.allocatable.cpu
        $memAlloc = $node.status.allocatable.memory

        $color = if ($status -eq 'True') { 'Green' } else { 'Red' }
        Write-Host "  $($node.metadata.name): " -NoNewline
        Write-Host $status -ForegroundColor $color -NoNewline
        Write-Host " (CPU: $cpuAlloc, Memory: $memAlloc)"
    }

    # 2. Pod 健康检查
    Write-Host "`n--- Pod 状态汇总 ---" -ForegroundColor Yellow
    foreach ($ns in $Namespaces) {
        $pods = kubectl get pods -n $ns -o json 2>$null | ConvertFrom-Json
        if (-not $pods.items) { continue }

        $running = ($pods.items | Where-Object { $_.status.phase -eq 'Running' }).Count
        $failed = ($pods.items | Where-Object { $_.status.phase -eq 'Failed' }).Count
        $pending = ($pods.items | Where-Object { $_.status.phase -eq 'Pending' }).Count
        $total = $pods.items.Count

        $highRestart = $pods.items | Where-Object {
            ($_.status.containerStatuses | Measure-Object -Property restartCount -Maximum).Maximum -gt 5
        }

        Write-Host "  命名空间 $ns : $total 个 Pod" -NoNewline
        Write-Host " (Running: $running, Failed: $failed, Pending: $pending)" -ForegroundColor $(if ($failed -gt 0) { 'Red' } elseif ($pending -gt 0) { 'Yellow' } else { 'Green' })

        if ($highRestart) {
            Write-Host "    高重启 Pod：" -ForegroundColor Red
            $highRestart | ForEach-Object {
                $restarts = ($_.status.containerStatuses | Measure-Object -Property restartCount -Maximum).Maximum
                Write-Host "      $($_.metadata.name) - 重启 $restarts 次" -ForegroundColor Red
            }
        }
    }

    # 3. 资源使用率
    Write-Host "`n--- 资源使用 Top ---" -ForegroundColor Yellow
    $topNodes = kubectl top nodes 2>$null
    if ($topNodes) {
        $topNodes | Select-Object -Skip 1 | ForEach-Object {
            $parts = $_ -split '\s+'
            $cpuPct = $parts[2] -replace '%',''
            $memPct = $parts[4] -replace '%',''
            $color = if ([int]$cpuPct -gt 80 -or [int]$memPct -gt 80) { 'Red' }
                     elseif ([int]$cpuPct -gt 60 -or [int]$memPct -gt 60) { 'Yellow' }
                     else { 'Green' }
            Write-Host "  $($_)" -ForegroundColor $color
        }
    } else {
        Write-Host "  Metrics Server 未安装，无法获取资源使用率" -ForegroundColor DarkGray
    }

    # 4. 事件检查
    Write-Host "`n--- 最近事件（Warning） ---" -ForegroundColor Yellow
    $events = kubectl get events -A --field-selector type=Warning --sort-by='.lastTimestamp' 2>$null
    if ($events) {
        $events | Select-Object -First 5 | ForEach-Object { Write-Host "  $_" }
    } else {
        Write-Host "  无警告事件" -ForegroundColor Green
    }
}

Get-K8sClusterHealth
```

执行结果示例：

```
========== Kubernetes 集群健康报告 ==========
检查时间：2025-05-30 08:30:00

--- 节点状态 ---
  node-01: True (CPU: 4, Memory: 16Gi)
  node-02: True (CPU: 8, Memory: 32Gi)
  node-03: True (CPU: 8, Memory: 32Gi)

--- Pod 状态汇总 ---
  命名空间 default : 5 个 Pod (Running: 5, Failed: 0, Pending: 0)
  命名空间 production : 12 个 Pod (Running: 11, Failed: 1, Pending: 0)
    高重启 Pod：
      api-server-5c9a2d-q7j4 - 重启 15 次
  命名空间 monitoring : 3 个 Pod (Running: 3, Failed: 0, Pending: 0)

--- 资源使用 Top ---
  node-01  1200m/4  8Gi/16Gi    (30%/50%)
  node-02  4500m/8  28Gi/32Gi   (56%/87%)
  node-03  2100m/8  18Gi/32Gi   (26%/56%)

--- 最近事件（Warning） ---
  15m  Warning  PodLoadBalancer api-server-5c9a2d  Failed to pull image
```

## 批量操作与日志收集

```powershell
# 批量重启 Deployment
function Restart-K8sDeployment {
    param(
        [Parameter(Mandatory)]
        [string]$Namespace,

        [string]$LabelSelector
    )

    $deployments = kubectl get deployments -n $Namespace -l $LabelSelector -o json |
        ConvertFrom-Json

    foreach ($deploy in $deployments.items) {
        $name = $deploy.metadata.name
        Write-Host "重启 Deployment：$name" -ForegroundColor Cyan
        kubectl rollout restart deployment/$name -n $Namespace

        # 等待滚动更新完成
        kubectl rollout status deployment/$name -n $Namespace --timeout=300s
    }
}

# 收集多个 Pod 的日志
function Get-K8sPodLogs {
    param(
        [string]$Namespace = "default",
        [string]$LabelSelector,
        [int]$Tail = 100
    )

    $pods = kubectl get pods -n $Namespace -l $LabelSelector -o json |
        ConvertFrom-Json

    $allLogs = @()
    foreach ($pod in $pods.items) {
        $podName = $pod.metadata.name
        $logs = kubectl logs $podName -n $Namespace --tail $Tail 2>$null

        foreach ($line in $logs -split "`n") {
            if ($line -match 'ERROR|WARN|Exception') {
                $allLogs += [PSCustomObject]@{
                    Pod     = $podName
                    Level   = if ($line -match 'ERROR|FATAL') { 'Error' } else { 'Warning' }
                    Message = $line.Trim()
                }
            }
        }
    }

    $allLogs | Sort-Object Level, Pod | Format-Table -AutoSize -Wrap
}

# 收集所有 Web 服务的错误日志
Get-K8sPodLogs -Namespace "production" -LabelSelector "app=web" -Tail 500
```

执行结果示例：

```
重启 Deployment：web-app
deployment "web-app" successfully rolled out

Pod              Level   Message
----              -----   -------
web-app-7d4f8b-x2k9l Error   ERROR [DB] Connection pool exhausted
web-app-7d4f8b-m8n3p Warning WARN Cache miss rate exceeded 50%
api-server-5c9a2d-q7j4 Error   ERROR Failed to process request: timeout
```

## 注意事项

1. **JSON 输出解析**：kubectl 的 `-o json` 输出通过 `ConvertFrom-Json` 解析为 PowerShell 对象，比文本解析更可靠
2. **API Server 连接**：确保 kubeconfig 正确配置，可以访问目标集群的 API Server
3. **命名空间隔离**：多命名空间环境下操作时，始终使用 `-n` 参数指定命名空间，避免误操作
4. **资源配额**：大规模集群中避免频繁 `kubectl get all` 类型的查询，可能给 API Server 造成压力
5. **日志量控制**：生产 Pod 日志量可能很大，使用 `--tail` 和 `--since` 参数限制查询范围
6. **kubectl 插件**：kubectx、kubens、kubectl-tree 等插件可以提升操作效率，建议安装
