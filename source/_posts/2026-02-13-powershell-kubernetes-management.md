---
layout: post
date: 2026-02-13 08:00:00
updated: 2026-02-13 08:00:00
title: "PowerShell 技能连载 - Kubernetes 管理自动化"
description: "PowerTip of the Day - Kubernetes Management Automation in PowerShell"
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
- container
- devops
---

_适用于 PowerShell 7.0 及以上版本_

Kubernetes 已成为容器编排的事实标准，几乎所有的云原生应用都运行在 K8s 集群之上。虽然 `kubectl` 是日常操作的主要命令行工具，但在企业自动化场景中，运维团队往往需要将 Kubernetes 操作集成到更大规模的工作流里——比如批量部署微服务、定期巡检集群健康状态、自动化 Helm Release 管理、以及跨集群的配置同步。纯靠手敲 `kubectl` 命令既容易出错，也无法做到可重复、可审计。

PowerShell 凭借强大的对象管道和脚本编排能力，是构建 K8s 自动化工作流的理想胶水语言。通过调用 `kubectl` CLI 并解析其 JSON 输出，PowerShell 可以将集群资源管理、应用部署、健康巡检等操作封装为结构化的脚本模块。结合 .NET 的 Kubernetes 客户端 SDK，还能实现更细粒度的 API 交互。

本文将通过三个实战场景展示如何用 PowerShell 实现 Kubernetes 管理自动化：集群连接与资源管理、部署自动化、以及运维巡检工具集。每个场景都提供了可运行的脚本模板，帮助你快速搭建自己的 K8s 运维工具箱。

<!-- more -->

## 集群连接与资源管理

管理多个 Kubernetes 集群时，频繁切换上下文是日常操作。下面的脚本封装了 kubeconfig 上下文切换、资源查询和状态汇总功能，让你在 PowerShell 中高效管理多个集群的 Pod、Deployment 和 Service 资源。

```powershell
# K8s 集群管理辅助函数集

function Get-K8sContexts {
    <# 获取所有可用的 K8s 上下文 #>
    $Raw = kubectl config get-contexts -o name 2>$null
    if ($LASTEXITCODE -ne 0) {
        Write-Error "无法获取 K8s 上下文，请确认 kubeconfig 已配置"
        return @()
    }
    return $Raw | Where-Object { $_.Trim() }
}

function Switch-K8sContext {
    param([Parameter(Mandatory)][string]$ContextName)
    kubectl config use-context $ContextName 2>$null | Out-Null
    if ($LASTEXITCODE -eq 0) {
        Write-Host "已切换到上下文: $ContextName" -ForegroundColor Green
    } else {
        Write-Error "切换上下文失败: $ContextName"
    }
}

function Get-K8sResourceSummary {
    param(
        [string]$Namespace = 'default',
        [string]$Context
    )

    if ($Context) { Switch-K8sContext $Context }

    # 查询 Pod 状态汇总
    $Pods = kubectl get pods -n $Namespace -o json 2>$null |
        ConvertFrom-Json

    $PodSummary = $Pods.items | Group-Object status.phase |
        Select-Object @{N='Phase'; E={$_.Name}}, Count

    # 查询 Deployment 状态
    $Deployments = kubectl get deployments -n $Namespace -o json 2>$null |
        ConvertFrom-Json

    $DeployStatus = $Deployments.items | ForEach-Object {
        $Replicas = $_.status.replicas ?? 0
        $Ready = $_.status.readyReplicas ?? 0
        $Updated = $_.status.updatedReplicas ?? 0
        [PSCustomObject]@{
            Name      = $_.metadata.name
            Replicas  = $Replicas
            Ready     = $Ready
            Updated   = $Updated
            Available = $_.status.availableReplicas ?? 0
            Status    = if ($Ready -eq $Replicas -and $Replicas -gt 0) { 'Healthy' } else { 'Degraded' }
        }
    }

    # 查询 Service 端点
    $Services = kubectl get services -n $Namespace -o json 2>$null |
        ConvertFrom-Json

    $SvcInfo = $Services.items | ForEach-Object {
        $Ports = ($_.spec.ports | ForEach-Object { "$($_.port):$($_.targetPort)/$($_.protocol)" }) -join ', '
        [PSCustomObject]@{
            Name  = $_.metadata.name
            Type  = $_.spec.type
            Ports = $Ports
            IP    = if ($_.spec.type -eq 'LoadBalancer') {
                $_.status.loadBalancer.ingress[0].ip ?? 'Pending'
            } else {
                $_.spec.clusterIP
            }
        }
    }

    Write-Host "`n=== Pod 状态汇总 (Namespace: $Namespace) ===" -ForegroundColor Cyan
    $PodSummary | Format-Table -AutoSize

    Write-Host "=== Deployment 状态 ===" -ForegroundColor Cyan
    $DeployStatus | Format-Table -AutoSize

    Write-Host "=== Service 列表 ===" -ForegroundColor Cyan
    $SvcInfo | Format-Table -AutoSize
}

# 使用示例
Write-Host "当前可用上下文:" -ForegroundColor Yellow
Get-K8sContexts

# 切换到生产集群并查看资源概况
Get-K8sResourceSummary -Namespace 'production' -Context 'prod-cluster'
```

执行结果示例：

```
当前可用上下文:
prod-cluster
staging-cluster
dev-cluster

已切换到上下文: prod-cluster

=== Pod 状态汇总 (Namespace: production) ===
Phase     Count
-----     -----
Running      24
Pending       2
Succeeded     5

=== Deployment 状态 ===
Name           Replicas Ready Updated Available Status
----           -------- ----- ------- --------- ------
api-gateway          3     3       3         3 Healthy
user-service         2     2       2         2 Healthy
order-service        3     2       3         2 Degraded
payment-service      2     2       2         2 Healthy

=== Service 列表 ===
Name             Type          Ports                IP
----             ----          -----                --
api-gateway      LoadBalancer  80:8080/TCP          203.0.113.50
user-service     ClusterIP     8080:8080/TCP        10.96.0.10
order-service    ClusterIP     8080:8080/TCP        10.96.0.20
payment-service  ClusterIP     8443:443/TCP         10.96.0.30
```

## 部署自动化

手动执行 `kubectl apply` 和 `kubectl rollout` 在管理少量应用时尚可应对，但当微服务数量超过几十个时，就需要自动化部署流水线。下面的脚本演示了如何用 PowerShell 生成部署 YAML、执行滚动更新、监控发布状态、以及在出现问题时快速回滚。

```powershell
# K8s 部署自动化工具

function New-K8sDeploymentManifest {
    param(
        [Parameter(Mandatory)][string]$AppName,
        [Parameter(Mandatory)][string]$Image,
        [int]$Replicas = 2,
        [int]$Port = 8080,
        [hashtable]$Labels = @{},
        [string]$Namespace = 'default'
    )

    $AllLabels = @{ app = $AppName } + $Labels

    $Manifest = @{
        apiVersion = 'apps/v1'
        kind       = 'Deployment'
        metadata   = @{
            name      = $AppName
            namespace = $Namespace
            labels    = $AllLabels
        }
        spec       = @{
            replicas = $Replicas
            selector = @{ matchLabels = @{ app = $AppName } }
            template = @{
                metadata = @{ labels = $AllLabels }
                spec     = @{
                    containers = @(
                        @{
                            name  = $AppName
                            image = $Image
                            ports = @(@{ containerPort = $Port })
                            resources = @{
                                requests = @{ cpu = '100m'; memory = '128Mi' }
                                limits   = @{ cpu = '500m'; memory = '512Mi' }
                            }
                            readinessProbe = @{
                                httpGet       = @{ path = '/health'; port = $Port }
                                initialDelaySeconds = 5
                                periodSeconds       = 10
                            }
                            livenessProbe = @{
                                httpGet       = @{ path = '/health'; port = $Port }
                                initialDelaySeconds = 15
                                periodSeconds       = 20
                            }
                        }
                    )
                }
            }
        }
    }

    return $Manifest
}

function Start-K8sRollingUpdate {
    param(
        [Parameter(Mandatory)][string]$AppName,
        [Parameter(Mandatory)][string]$NewImage,
        [string]$Namespace = 'default',
        [int]$TimeoutSeconds = 300
    )

    Write-Host "开始滚动更新: $AppName -> $NewImage" -ForegroundColor Cyan

    # 设置新镜像
    kubectl set image "deployment/$AppName" `
        "$AppName=$NewImage" -n $Namespace 2>$null | Out-Null

    if ($LASTEXITCODE -ne 0) {
        Write-Error "设置镜像失败"
        return $false
    }

    # 等待滚动更新完成
    Write-Host "等待滚动更新完成 (超时: ${TimeoutSeconds}s)..." -ForegroundColor Yellow
    $Deadline = (Get-Date).AddSeconds($TimeoutSeconds)

    while ((Get-Date) -lt $Deadline) {
        $Status = kubectl rollout status "deployment/$AppName" `
            -n $Namespace --timeout=30s 2>&1

        if ($LASTEXITCODE -eq 0) {
            Write-Host "滚动更新成功: $AppName" -ForegroundColor Green
            return $true
        }

        # 显示当前 Pod 状态
        $Pods = kubectl get pods -n $Namespace -l "app=$AppName" -o json 2>$null |
            ConvertFrom-Json

        $Pods.items | ForEach-Object {
            $Phase = $_.status.phase
            $Containers = $_.status.containerStatuses
            $Ready = ($Containers | Where-Object { $_.ready }).Count
            $Total = $Containers.Count
            Write-Host "  Pod: $($_.metadata.name) | Phase: $Phase | Ready: $Ready/$Total"
        }

        Start-Sleep -Seconds 5
    }

    Write-Warning "滚动更新超时，准备回滚..."
    Undo-K8sRollout -AppName $AppName -Namespace $Namespace
    return $false
}

function Undo-K8sRollout {
    param(
        [Parameter(Mandatory)][string]$AppName,
        [string]$Namespace = 'default',
        [int]$Revision = 0
    )

    if ($Revision -eq 0) {
        Write-Host "回滚到上一版本: $AppName" -ForegroundColor Yellow
        kubectl rollout undo "deployment/$AppName" -n $Namespace 2>$null
    } else {
        Write-Host "回滚到修订版本 $Revision: $AppName" -ForegroundColor Yellow
        kubectl rollout undo "deployment/$AppName" -n $Namespace --to-revision=$Revision 2>$null
    }

    if ($LASTEXITCODE -eq 0) {
        Write-Host "回滚成功" -ForegroundColor Green
        # 查看部署历史
        kubectl rollout history "deployment/$AppName" -n $Namespace
    } else {
        Write-Error "回滚失败"
    }
}

# 生成部署清单并应用
$Manifest = New-K8sDeploymentManifest `
    -AppName 'web-frontend' `
    -Image 'registry.example.com/web-frontend:v2.3.0' `
    -Replicas 3 `
    -Port 8080 `
    -Labels @{ tier = 'frontend'; env = 'production' } `
    -Namespace 'production'

$YamlPath = '/tmp/web-frontend-deployment.yaml'
$Manifest | ConvertTo-Json -Depth 10 | Set-Content $YamlPath
kubectl apply -f $YamlPath

# 执行滚动更新
Start-K8sRollingUpdate `
    -AppName 'web-frontend' `
    -NewImage 'registry.example.com/web-frontend:v2.4.0' `
    -Namespace 'production' `
    -TimeoutSeconds 300
```

执行结果示例：

```
开始滚动更新: web-frontend -> registry.example.com/web-frontend:v2.4.0
等待滚动更新完成 (超时: 300s)...
  Pod: web-frontend-7d9b8f6c4d-abc12 | Phase: Running | Ready: 1/1
  Pod: web-frontend-7d9b8f6c4d-def34 | Phase: Running | Ready: 1/1
  Pod: web-frontend-8a2c3e7f5b-ghi56 | Phase: ContainerCreating | Ready: 0/1
  Pod: web-frontend-8a2c3e7f5b-jkl78 | Phase: Running | Ready: 1/1
  Pod: web-frontend-8a2c3e7f5b-mno90 | Phase: Running | Ready: 1/1
滚动更新成功: web-frontend
```

## 运维巡检工具集

Kubernetes 集群的日常运维需要定期检查节点健康、资源水位、异常 Pod 和事件告警。下面是一套完整的巡检脚本，可以一次性生成集群健康报告，适合集成到定时任务或 CI/CD 流水线中。

```powershell
# K8s 集群运维巡检工具集

function Invoke-K8sClusterHealthCheck {
    param(
        [string]$Context,
        [string]$OutputPath = "./k8s-health-report-$(Get-Date -Format 'yyyyMMdd-HHmmss').txt"
    )

    if ($Context) { Switch-K8sContext $Context }

    $Report = [System.Text.StringBuilder]::new()
    $null = $Report.AppendLine("=" * 60)
    $null = $Report.AppendLine("K8s 集群健康巡检报告 - $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')")
    $null = $Report.AppendLine("=" * 60)

    # 1. 节点状态检查
    $null = $Report.AppendLine("`n--- 节点状态 ---")
    $Nodes = kubectl get nodes -o json 2>$null | ConvertFrom-Json

    foreach ($Node in $Nodes.items) {
        $Name = $Node.metadata.name
        $Conditions = $Node.status.conditions
        $Ready = ($Conditions | Where-Object { $_.type -eq 'Ready' }).status -eq 'True'
        $MemoryPressure = ($Conditions | Where-Object { $_.type -eq 'MemoryPressure' }).status -eq 'True'
        $DiskPressure = ($Conditions | Where-Object { $_.type -eq 'DiskPressure' }).status -eq 'True'

        $StatusIcon = if ($Ready -and -not $MemoryPressure -and -not $DiskPressure) { 'OK' } else { 'WARN' }
        $null = $Report.AppendLine("[$StatusIcon] $Name | Ready: $Ready | MemoryPressure: $MemoryPressure | DiskPressure: $DiskPressure")

        # 节点资源使用
        $Allocatable = $Node.status.allocatable
        $null = $Report.AppendLine("     CPU: $($Allocatable.cpu) | Memory: $($Allocatable.memory)")
    }

    # 2. 异常 Pod 扫描（所有命名空间）
    $null = $Report.AppendLine("`n--- 异常 Pod ---")
    $AllPods = kubectl get pods -A -o json 2>$null | ConvertFrom-Json

    $UnhealthyPods = $AllPods.items | Where-Object {
        $_.status.phase -notin @('Running', 'Succeeded') -or
        ($_.status.containerStatuses | Where-Object { $_.restartCount -gt 5 }).Count -gt 0
    }

    if ($UnhealthyPods) {
        foreach ($Pod in $UnhealthyPods) {
            $Ns = $Pod.metadata.namespace
            $Name = $Pod.metadata.name
            $Phase = $Pod.status.phase
            $Restarts = ($Pod.status.containerStatuses | Measure-Object -Property restartCount -Sum).Sum
            $null = $Report.AppendLine("  [ALERT] $Ns/$Name | Phase: $Phase | Restarts: $Restarts")
        }
    } else {
        $null = $Report.AppendLine("  所有 Pod 运行正常")
    }

    # 3. 资源使用报告（通过 metrics-server）
    $null = $Report.AppendLine("`n--- 资源使用 Top 10 ---")
    $TopPods = kubectl top pods -A --sort-by=memory --no-headers 2>$null

    if ($LASTEXITCODE -eq 0) {
        $Rank = 1
        $TopPods | Select-Object -First 10 | ForEach-Object {
            $null = $Report.AppendLine("  #$Rank $_")
            $Rank++
        }
    } else {
        $null = $Report.AppendLine("  metrics-server 未安装或不可用，跳过资源使用统计")
    }

    # 4. 最近事件告警
    $null = $Report.AppendLine("`n--- 最近告警事件 (Warning) ---")
    $Events = kubectl get events -A --field-selector type=Warning -o json 2>$null |
        ConvertFrom-Json

    $RecentWarnings = $Events.items |
        Sort-Object { [datetime]$_.lastTimestamp } -Descending |
        Select-Object -First 10

    foreach ($Evt in $RecentWarnings) {
        $Time = $Evt.lastTimestamp
        $Ns = $Evt.metadata.namespace
        $Msg = $Evt.message
        $Involved = "$($Evt.involvedObject.kind)/$($Evt.involvedObject.name)"
        $null = $Report.AppendLine("  [$Time] $Ns/$Involved - $Msg")
    }

    # 输出报告
    $ReportContent = $Report.ToString()
    $ReportContent | Set-Content $OutputPath -Encoding UTF8
    Write-Host $ReportContent
    Write-Host "`n报告已保存到: $OutputPath" -ForegroundColor Green

    # 返回摘要对象，便于后续自动化处理
    return [PSCustomObject]@{
        TotalNodes     = $Nodes.items.Count
        UnhealthyPods  = $UnhealthyPods.Count
        WarningEvents  = $RecentWarnings.Count
        ReportPath     = $OutputPath
    }
}

# 执行巡检
$HealthResult = Invoke-K8sClusterHealthCheck -Context 'prod-cluster'

# 根据巡检结果触发告警
if ($HealthResult.UnhealthyPods -gt 0 -or $HealthResult.WarningEvents -gt 5) {
    $AlertMsg = "K8s 巡检告警: 异常Pod=$($HealthResult.UnhealthyPods), 告警事件=$($HealthResult.WarningEvents)"
    Write-Host $AlertMsg -ForegroundColor Red
    # 可在此处接入钉钉、飞书、Slack 等通知渠道
}
```

执行结果示例：

```
============================================================
K8s 集群健康巡检报告 - 2026-02-13 09:30:00
============================================================

--- 节点状态 ---
[OK] k8s-node-01 | Ready: True | MemoryPressure: False | DiskPressure: False
     CPU: 8 | Memory: 32762308Ki
[OK] k8s-node-02 | Ready: True | MemoryPressure: False | DiskPressure: False
     CPU: 8 | Memory: 32762308Ki
[WARN] k8s-node-03 | Ready: True | MemoryPressure: True | DiskPressure: False
     CPU: 8 | Memory: 32762308Ki

--- 异常 Pod ---
  [ALERT] production/order-service-6b8d4f-x2k9l | Phase: CrashLoopBackOff | Restarts: 17
  [ALERT] staging/api-gateway-5c7a2e-m4n7p | Phase: Pending | Restarts: 0

--- 资源使用 Top 10 ---
  #1 production/redis-cache-0          512Mi    250m
  #2 production/elasticsearch-0        480Mi    350m
  #3 production/order-service-7d9b     256Mi    150m
  #4 production/user-service-8a2c      128Mi     80m
  #5 monitoring/prometheus-0           380Mi    200m

--- 最近告警事件 (Warning) ---
  [2026-02-13T09:28:00Z] production/Pod/order-service-6b8d4f-x2k9l - Back-off restarting failed container
  [2026-02-13T09:25:00Z] staging/Pod/api-gateway-5c7a2e-m4n7p - Insufficient cpu (3) to schedule pod
  [2026-02-13T09:20:00Z] production/Node/k8s-node-03 - Node is experiencing memory pressure

报告已保存到: ./k8s-health-report-20260213-093000.txt
```

## 注意事项

1. **kubectl 前置依赖**：所有脚本都依赖 `kubectl` 命令行工具，运行前需确保已安装并与目标集群版本兼容（建议客户端版本不低于集群版本的 1 个小版本）。可通过 `kubectl version --client` 检查客户端版本，集群端需网络可达且 kubeconfig 配置正确。

2. **JSON 输出解析**：脚本中大量使用 `kubectl -o json` 配合 `ConvertFrom-Json` 解析 K8s 资源。当集群资源量非常大（例如上万 Pod）时，JSON 反序列化可能消耗较多内存。建议在大型集群中结合 `-l` 标签选择器或 `--field-selector` 缩小查询范围。

3. **滚动更新超时策略**：`Start-K8sRollingUpdate` 中的超时时间应根据应用启动速度合理设置。Java 等慢启动应用可能需要 5-10 分钟才能通过就绪探针检查，而 Go/Node.js 应用通常在 30 秒内就绪。超时时间过短会导致误判失败并触发不必要的回滚。

4. **metrics-server 部署**：资源使用统计功能依赖 metrics-server 组件，部分托管集群（如 EKS、GKE）默认安装，但自建集群需要手动部署。如果巡检脚本中 `kubectl top` 命令返回错误，请先通过 `kubectl apply -f` 部署 metrics-server 清单。

5. **命名空间与权限控制**：脚本中的 `Get-K8sResourceSummary` 默认只查询指定命名空间。在 RBAC 严格的生产集群中，ServiceAccount 可能只被授权访问部分命名空间。建议为巡检脚本创建专用的 ServiceAccount 和 ClusterRole，仅授予只读权限（`get`、`list`、`watch`），避免使用高权限账户运行自动化脚本。

6. **kubeconfig 安全管理**：多集群环境下，kubeconfig 文件中包含各集群的认证凭据（证书或 Token）。切勿将 kubeconfig 提交到代码仓库，应通过安全的密钥管理方案（如 HashiCorp Vault、Azure Key Vault）分发凭据，并定期轮换 ServiceAccount Token。
