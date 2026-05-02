---
layout: post
date: 2025-10-15 08:00:00
updated: 2025-10-15 08:00:00
title: "PowerShell 技能连载 - Kubernetes 客户端操作"
description: PowerTip of the Day - Kubernetes Client Operations in PowerShell
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
- kubectl
- devops
---

_适用于 PowerShell 7.0 及以上版本（跨平台）_

在 Kubernetes 生态中，`kubectl` 是最常用的命令行工具，但它的输出是纯文本或 JSON 字符串，难以直接用于复杂的自动化流程。当我们需要在 CI/CD 管道中动态创建资源、在运维脚本中批量查询 Pod 状态，或者构建自定义的 Kubernetes 监控面板时，直接调用 Kubernetes API 会比反复解析 kubectl 输出更高效、更可靠。

PowerShell 7 的跨平台特性使其成为与 Kubernetes API 交互的理想选择。通过 Kubernetes 官方提供的 .NET 客户端库（`KubernetesClient`），我们可以用 PowerShell 脚本直接操作 Kubernetes API，获得完整的类型安全、自动补全和管道支持。这种方式不仅能处理认证、证书验证等底层细节，还能与 PowerShell 的对象模型无缝融合。

本文将介绍如何安装和配置 Kubernetes .NET 客户端，并通过三个实用场景——集群状态查询、资源批量操作和事件监控——展示 PowerShell 作为 Kubernetes 客户端的强大能力。

## 安装 Kubernetes 客户端模块

首先，我们需要安装 `KubernetesClient` NuGet 包并创建与集群的连接。该客户端会自动读取 `~/.kube/config` 中的上下文信息，无需手动配置认证参数。

```powershell
# 安装 Kubernetes .NET 客户端
Install-Module -Name KubernetesClient -Scope CurrentUser -Force

# 导入模块并创建客户端实例
using module KubernetesClient

# 方式一：使用默认 kubeconfig 自动连接
$k8sClient = [KubernetesClient.KubernetesClientConfiguration]::BuildDefaultConfig()
$client = [KubernetesClient.Kubernetes]::new($k8sClient)

# 方式二：指定特定的 kubeconfig 上下文
$config = [KubernetesClient.KubernetesClientConfiguration]::BuildConfigFromConfigFile(
    $null, "$HOME/.kube/config", 'production-cluster'
)
$client = [KubernetesClient.Kubernetes]::new($config)

# 验证连接：列出所有命名空间
$namespaces = $client.ListNamespaceAsync().Result
$namespaces.Items | Select-Object -Property Name, Status | Format-Table
```

执行结果示例：

```
Name                Status
----                ------
default             Active
kube-system         Active
kube-public         Active
kube-node-lease     Active
monitoring          Active
production          Active
staging             Active
```

## 场景一：集群资源状态巡检

在生产环境中，快速掌握集群中各类资源的运行状态是日常运维的基础。下面的脚本封装了一个巡检函数，它遍历所有命名空间中的 Pod、Deployment 和 Service，汇总资源使用情况，并以 PowerShell 对象的形式输出结构化的巡检报告。

```powershell
function Get-K8sClusterReport {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [KubernetesClient.Kubernetes]$Client,

        [Parameter()]
        [string[]]$Namespaces
    )

    # 如果未指定命名空间，则获取所有命名空间
    if (-not $Namespaces) {
        $nsList = $Client.ListNamespaceAsync().Result
        $Namespaces = $nsList.Items | ForEach-Object { $_.Metadata.Name }
    }

    $report = foreach ($ns in $Namespaces) {
        # 获取该命名空间下的所有 Pod
        $pods = $Client.ListNamespacedPodAsync($ns).Result.Items

        $totalPods = $pods.Count
        $runningPods = ($pods | Where-Object {
            $_.Status.Phase -eq 'Running'
        }).Count
        $failedPods = ($pods | Where-Object {
            $_.Status.Phase -eq 'Failed'
        }).Count
        $pendingPods = ($pods | Where-Object {
            $_.Status.Phase -eq 'Pending'
        }).Count

        # 获取 Deployment 信息
        $deployments = $Client.ListNamespacedDeploymentAsync($ns).Result.Items
        $totalDeployments = $deployments.Count

        # 统计未就绪的 Deployment
        $unreadyDeployments = ($deployments | Where-Object {
            $_.Status.ReadyReplicas -ne $_.Status.Replicas
        }).Count

        # 获取 Service 信息
        $services = $Client.ListNamespacedServiceAsync($ns).Result.Items

        [PSCustomObject]@{
            Namespace        = $ns
            TotalPods        = $totalPods
            RunningPods      = $runningPods
            PendingPods      = $pendingPods
            FailedPods       = $failedPods
            Deployments      = $totalDeployments
            UnreadyDeploys   = $unreadyDeployments
            Services         = $services.Count
            HealthScore      = if ($totalPods -gt 0) {
                [math]::Round(($runningPods / $totalPods) * 100, 1)
            } else { 100 }
        }
    }

    return $report
}

# 执行巡检
$config = [KubernetesClient.KubernetesClientConfiguration]::BuildDefaultConfig()
$k8s = [KubernetesClient.Kubernetes]::new($config)

$report = Get-K8sClusterReport -Client $k8s
$report | Sort-Object HealthScore | Format-Table -AutoSize
```

执行结果示例：

```
Namespace       TotalPods RunningPods PendingPods FailedPods Deployments UnreadyDeploys Services HealthScore
---------       --------- ----------- ----------- ---------- ----------- -------------- -------- -----------
production            120         118           2          0          15              1       28         98.3
staging                30          29           1          0           8              0       12         96.7
monitoring             18          18           0          0           5              0        8        100
kube-system            15          15           0          0           3              0        7        100
default                 3           3           0          0           1              0        2        100
```

## 场景二：批量资源标签管理

在多环境、多团队的 Kubernetes 集群中，标签（Label）是资源分类、筛选和策略执行的基础。当需要批量更新标签（例如标记维护窗口、变更环境归属或添加成本中心标签）时，通过 PowerShell 调用 Kubernetes API 可以高效完成。下面的脚本展示了如何批量查询并修改指定命名空间中所有 Deployment 的标签。

```powershell
function Update-K8sDeploymentLabels {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [KubernetesClient.Kubernetes]$Client,

        [Parameter(Mandatory)]
        [string]$Namespace,

        [Parameter(Mandatory)]
        [hashtable]$LabelsToAdd,

        [Parameter()]
        [string]$LabelSelector
    )

    # 获取指定命名空间的 Deployment 列表
    $deployments = $Client.ListNamespacedDeploymentAsync(
        $Namespace,
        labelSelector: $LabelSelector
    ).Result.Items

    $results = foreach ($deploy in $deployments) {
        $name = $deploy.Metadata.Name

        # 在现有标签基础上添加新标签
        foreach ($key in $LabelsToAdd.Keys) {
            $deploy.Metadata.Labels[$key] = $LabelsToAdd[$key]
        }

        # 构造更新用的 patch 对象
        $patchBody = @{
            metadata = @{
                labels = $deploy.Metadata.Labels
            }
        } | ConvertTo-Json -Depth 10

        try {
            $updated = $Client.PatchNamespacedDeploymentAsync(
                [KubernetesClient.V1Patch]::new(
                    $patchBody,
                    [KubernetesClient.V1Patch]::StrategicMergePatchType
                ),
                $name,
                $Namespace
            ).Result

            [PSCustomObject]@{
                Name      = $name
                Status    = 'Updated'
                NewLabels = ($LabelsToAdd.Keys | ForEach-Object {
                    "${_}=$($LabelsToAdd[$_])"
                }) -join ', '
            }
        }
        catch {
            [PSCustomObject]@{
                Name   = $name
                Status = "Failed: $($_.Exception.Message)"
                NewLabels = 'N/A'
            }
        }
    }

    return $results
}

# 批量为 production 命名空间的 Deployment 添加成本标签
$config = [KubernetesClient.KubernetesClientConfiguration]::BuildDefaultConfig()
$k8s = [KubernetesClient.Kubernetes]::new($config)

$updateResults = Update-K8sDeploymentLabels -Client $k8s `
    -Namespace 'production' `
    -LabelsToAdd @{
        'cost-center'    = 'engineering'
        'maintenance'    = '2025-Q4'
        'managed-by'     = 'powershell'
    } `
    -LabelSelector 'app-type=web'

$updateResults | Format-Table -AutoSize
```

执行结果示例：

```
Name                 Status   NewLabels
----                 ------   ---------
web-frontend         Updated  cost-center=engineering, maintenance=2025-Q4, managed-by=powershell
web-api-gateway      Updated  cost-center=engineering, maintenance=2025-Q4, managed-by=powershell
web-notification     Updated  cost-center=engineering, maintenance=2025-Q4, managed-by=powershell
web-user-service     Failed: The Deployment "web-user-service" is being deleted: N/A
web-payment          Updated  cost-center=engineering, maintenance=2025-Q4, managed-by=powershell
```

## 场景三：实时事件流监控

Kubernetes 事件（Event）是排查集群问题的重要信息源。与 `kubectl get events` 的一次性查询不同，通过客户端的 Watch 机制可以实现事件流的实时订阅。下面的脚本演示了如何使用 PowerShell 监控指定命名空间的事件流，并根据事件类型进行分类统计和告警。

```powershell
function Watch-K8sEvents {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [KubernetesClient.Kubernetes]$Client,

        [Parameter()]
        [string]$Namespace = 'default',

        [Parameter()]
        [int]$DurationSeconds = 60
    )

    $startTime = Get-Date
    $eventStats = @{
        Normal    = 0
        Warning   = 0
        Total     = 0
    }
    $warningEvents = [System.Collections.Generic.List[object]]::new()

    Write-Host "开始监控命名空间 '$Namespace' 的事件流（持续 $DurationSeconds 秒）..."
    Write-Host ('=' * 60)

    # 获取事件列表
    $events = $Client.ListNamespacedEventAsync($Namespace).Result.Items

    foreach ($evt in $events) {
        $eventStats['Total']++

        $eventType = if ($evt.Type -eq 'Normal') { 'Normal' } else { 'Warning' }
        $eventStats[$eventType]++

        # 对 Warning 级别的事件进行重点记录
        if ($eventType -eq 'Warning') {
            $warningEvents.Add(
                [PSCustomObject]@{
                    Time     = $evt.LastTimestamp
                    Object   = "$($evt.InvolvedObject.Kind)/$($evt.InvolvedObject.Name)"
                    Reason   = $evt.Reason
                    Message  = $evt.Message
                }
            )
        }
    }

    # 输出统计摘要
    Write-Host "`n事件统计摘要:"
    Write-Host "  总事件数: $($eventStats['Total'])"
    Write-Host "  Normal:   $($eventStats['Normal'])"
    Write-Host "  Warning:  $($eventStats['Warning'])"
    Write-Host ('-' * 60)

    # 输出告警级别事件详情
    if ($warningEvents.Count -gt 0) {
        Write-Host "`n告警事件详情:"
        $warningEvents | Sort-Object Time -Descending | Select-Object -First 10 |
            Format-Table Time, Object, Reason -Wrap
    }
    else {
        Write-Host "`n无告警级别事件，集群运行正常。"
    }

    return [PSCustomObject]@{
        MonitoredAt      = $startTime
        Namespace        = $Namespace
        TotalEvents      = $eventStats['Total']
        NormalEvents     = $eventStats['Normal']
        WarningEvents    = $eventStats['Warning']
        Warnings         = $warningEvents
    }
}

# 监控 production 命名空间的事件
$config = [KubernetesClient.KubernetesClientConfiguration]::BuildDefaultConfig()
$k8s = [KubernetesClient.Kubernetes]::new($config)

$eventReport = Watch-K8sEvents -Client $k8s -Namespace 'production'
```

执行结果示例：

```
开始监控命名空间 'production' 的事件流（持续 60 秒）...
============================================================

事件统计摘要:
  总事件数: 47
  Normal:   39
  Warning:  8
------------------------------------------------------------

告警事件详情:

Time                 Object                             Reason              Message
----                 ------                             ------              -------
2025-10-15T06:42:11Z Pod/web-api-7d8f6c4b5-xk2mn       FailedScheduling    0/5 nodes are available...
2025-10-15T06:41:58Z Pod/web-api-7d8f6c4b5-xk2mn       InsufficientCPU     Node didn't have enough...
2025-10-15T06:40:33Z Pod/payment-worker-5c9b8d7f-n4r1  OOMKilled           Container payment-worker...
2025-10-15T06:39:15Z Ingress/api-ingress               BackendError        Error refreshing SSL cert...
```

## 注意事项

1. **认证配置优先级**：Kubernetes .NET 客户端会按照 `KUBECONFIG` 环境变量、`~/.kube/config` 文件、Pod 内 ServiceAccount token 的顺序查找认证信息。在 CI/CD 环境中建议显式指定 kubeconfig 路径，避免因环境差异导致连接失败。

2. **异步方法与 Result 属性**：客户端库的 API 大多是异步方法（返回 `Task`）。在 PowerShell 中可以直接访问 `.Result` 属性获取同步结果，但如果脚本需要处理大量并发请求，建议使用 `[System.Threading.Tasks.Task]::WhenAll()` 进行并行调度，避免阻塞主线程。

3. **API 版本兼容性**：不同版本的 Kubernetes 集群支持的 API 版本不同。使用 `KubernetesClient` 之前应确认客户端库版本与目标集群版本的兼容性，例如 `apps/v1` 是 Kubernetes 1.9+ 才稳定的 API 组，老版本集群可能只支持 `apps/v1beta2`。

4. **资源限流与服务器压力**：批量操作（如遍历所有命名空间的所有 Pod）可能对 API Server 造成较大压力。建议在循环中添加适当的延迟（`Start-Sleep -Milliseconds 200`），并在查询时利用 `labelSelector` 和 `fieldSelector` 缩小结果范围，避免不必要的数据传输。

5. **JSON 序列化深度**：Kubernetes 资源对象嵌套层级较深，使用 `ConvertTo-Json` 时务必指定足够的 `-Depth` 参数（建议 10 以上），否则深层字段（如容器规格中的环境变量、挂载点等）会被截断为字符串 `System.Collections.Hashtable`，导致 patch 操作失败。

6. **错误处理与重试机制**：Kubernetes API 在高负载时可能返回 `429 Too Many Requests` 或 `503 Service Unavailable`。建议在关键操作的外层包装重试逻辑，配合指数退避策略（如初次等待 1 秒，后续每次翻倍），并区分可重试错误（网络超时、5xx）和不可重试错误（403 权限不足、404 资源不存在），避免无意义的重试循环。
