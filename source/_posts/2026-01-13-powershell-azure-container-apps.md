---
layout: post
date: 2026-01-13 08:00:00
updated: 2026-01-13 08:00:00
title: "PowerShell 技能连载 - Azure Container Apps 管理"
description: PowerTip of the Day - Azure Container Apps Management in PowerShell
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
- azure
- container
---

_适用于 PowerShell 7.0 及以上版本_

Azure Container Apps 是微软推出的全托管无服务器容器平台，它在底层基于 Kubernetes 却将集群管理完全抽象化，让开发者无需编写 YAML 清单就能享受容器编排的好处。内置的流量分流、自动扩缩容、服务发现和 Dapr 集成，使其特别适合微服务和事件驱动型工作负载。

对于运维工程师而言，手工在 Azure 门户中点击操作不仅效率低下，也无法纳入版本控制和审计流程。通过 PowerShell 的 Az 模块，我们可以将容器应用的创建、环境配置、版本管理和扩缩容策略全部脚本化，实现真正的 GitOps 工作流。今天就来详细介绍如何用 PowerShell 完成 Azure Container Apps 的全生命周期管理。

<!-- more -->

## 环境创建与应用部署

一切从 Container Apps 环境开始。每个容器应用都必须部署在一个环境中，环境定义了应用之间的网络边界和共享基础设施。下面的脚本演示了如何创建环境、部署一个 Web API 容器，并配置基本的入站流量规则。

```powershell
# 定义变量
$resourceGroup = "rg-microservice-demo"
$location = "eastasia"
$envName = "cae-microservice"
$appName = "ca-weather-api"
$acrLoginServer = "myacr.azurecr.io"
$imageTag = "$acrLoginServer/weather-api:v1.0.0"

# 登录并选择订阅
Connect-AzAccount
Set-AzContext -SubscriptionId "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"

# 创建资源组
New-AzResourceGroup -Name $resourceGroup -Location $location -Force

# 创建 Container Apps 环境（包含 Log Analytics 工作区）
$workspace = New-AzOperationalInsightsWorkspace `
    -ResourceGroupName $resourceGroup `
    -Name "log-microservice" `
    -Location $location `
    -Sku Standard

$envArgs = @{
    Name                = $envName
    ResourceGroupName   = $resourceGroup
    Location            = $location
    AppLogConfiguration = @{
        LogAnalyticsConfiguration = @{
            CustomerId = $workspace.CustomerId
            SharedKey  = (Get-AzOperationalInsightsWorkspaceSharedKey `
                -ResourceGroupName $resourceGroup `
                -Name $workspace.Name).PrimarySharedKey
        }
    }
}
$containerEnv = New-AzContainerAppManagedEnv @envArgs

# 获取 ACR 凭据并创建托管标识拉取镜像
$acr = Get-AzContainerRegistry -ResourceGroupName $resourceGroup -Name "myacr"
$acrCred = Get-AzContainerRegistryCredential -Registry $acr

# 部署容器应用
$appArgs = @{
    Name                = $appName
    ResourceGroupName   = $resourceGroup
    Location            = $location
    ManagedEnvironment  = $containerEnv
    Configuration       = @{
        ActiveRevisionsMode = "Single"
        Ingress             = @{
            External   = $true
            TargetPort = 8080
            Traffic    = @(
                @{
                    RevisionName = "$appName--v1"
                    Weight       = 100
                }
            )
        }
    }
    Template            = @{
        Containers = @(
            @{
                Name  = "weather-api"
                Image = $imageTag
                Env   = @(
                    @{
                        Name  = "ASPNETCORE_ENVIRONMENT"
                        Value = "Production"
                    }
                    @{
                        Name  = "LOG_LEVEL"
                        Value = "Information"
                    }
                )
                Resources = @{
                    Cpu    = "0.5"
                    Memory = "1.0Gi"
                }
            }
        )
    }
}
New-AzContainerApp @appArgs

Write-Host "容器应用部署完成: $appName"
```

执行结果示例：

```
ResourceGroupName : rg-microservice-demo
Location          : eastasia
Name              : ca-weather-api
ProvisioningState : Succeeded
Fqdn              : ca-weather-api.politebay-xxxxxxxx.eastasia.azurecontainerapps.io
LatestRevision    : ca-weather-api--v1
TrafficWeight     : 100%

容器应用部署完成: ca-weather-api
```

上面的脚本完成了从零到一的部署。首先创建了 Log Analytics 工作区用于日志收集，然后基于工作区创建 Container Apps 环境。容器配置中指定了镜像地址、环境变量和资源限额，入站配置将 8080 端口暴露为外部 HTTP 端点。`ActiveRevisionsMode` 设为 `Single` 表示同时只运行一个活跃版本。

## 版本管理与流量分流

微服务的迭代发布要求我们能够在不同版本之间平滑切换。Container Apps 的修订版本（Revision）机制天然支持蓝绿部署和金丝雀发布。下面的脚本展示了如何推送新版本、配置流量分流比例，以及在出现问题时快速回滚。

```powershell
# 推送 v2.0.0 版本并配置金丝雀发布（10% 流量到新版本）
$v2Image = "$acrLoginServer/weather-api:v2.0.0"

$updateArgs = @{
    Name              = $appName
    ResourceGroupName = $resourceGroup
    Configuration     = @{
        ActiveRevisionsMode = "Multiple"
        Ingress             = @{
            External   = $true
            TargetPort = 8080
            Traffic    = @(
                @{
                    RevisionName = "$appName--v1"
                    Weight       = 90
                }
                @{
                    RevisionName = "$appName--v2"
                    Weight       = 10
                }
            )
        }
    }
    Template          = @{
        Containers = @(
            @{
                Name  = "weather-api"
                Image = $v2Image
                Env   = @(
                    @{
                        Name  = "ASPNETCORE_ENVIRONMENT"
                        Value = "Production"
                    }
                    @{
                        Name  = "LOG_LEVEL"
                        Value = "Debug"
                    }
                )
                Resources = @{
                    Cpu    = "0.5"
                    Memory = "1.0Gi"
                }
            }
        )
    }
}
New-AzContainerApp @updateArgs

Write-Host "金丝雀发布已配置: v1(90%) -> v2(10%)"

# 观察新版本运行状态
Start-Sleep -Seconds 30

# 查看所有修订版本及状态
$revisions = Get-AzContainerAppRevision `
    -Name $appName `
    -ResourceGroupName $resourceGroup

$revisions | Format-Table Name, Active, TrafficWeight, Replicas, CreatedTime -AutoSize

# 确认新版本稳定后，切换全量流量到 v2
$fullCutArgs = @{
    Name              = $appName
    ResourceGroupName = $resourceGroup
    Configuration     = @{
        ActiveRevisionsMode = "Multiple"
        Ingress             = @{
            External   = $true
            TargetPort = 8080
            Traffic    = @(
                @{
                    RevisionName = "$appName--v2"
                    Weight       = 100
                }
            )
        }
    }
}
Update-AzContainerApp @fullCutArgs

Write-Host "全量切换完成: v2(100%)"

# 如果发现问题，一键回滚到 v1
# Update-AzContainerApp @fullCutArgs -Configuration @{
#     Ingress = @{
#         Traffic = @(@{ RevisionName = "$appName--v1"; Weight = 100 })
#     }
# }
```

执行结果示例：

```
金丝雀发布已配置: v1(90%) -> v2(10%)

Name                  Active TrafficWeight Replicas CreatedTime
----                  ------ ------------- -------- -----------
ca-weather-api--v1    True   90            2        2026-01-13 08:30:00
ca-weather-api--v2    True   10            1        2026-01-13 09:15:00

全量切换完成: v2(100%)
```

流量分流的原理在于将 `ActiveRevisionsMode` 切换为 `Multiple`，此时多个修订版本可以同时运行。通过 `Traffic` 数组中每个条目的 `Weight` 字段控制流量比例，总和必须为 100。金丝雀发布时先用小比例流量验证新版本，观察日志和监控指标后再逐步放量。回滚只需将流量权重重新指向旧版本即可，秒级生效。

## 自动扩缩容与监控

无服务器容器的核心优势之一是根据负载自动调整实例数量。Container Apps 使用 KEDA（Kubernetes Event-Driven Autoscaler）作为扩缩容引擎，支持基于 HTTP 并发、CPU/内存利用率、消息队列长度等多种触发器。下面的脚本展示了如何配置扩缩容规则并设置监控告警。

```powershell
# 配置基于 HTTP 并发的自动扩缩容
$scaleArgs = @{
    Name              = $appName
    ResourceGroupName = $resourceGroup
    Template          = @{
        Containers = @(
            @{
                Name  = "weather-api"
                Image = "$acrLoginServer/weather-api:v2.0.0"
                Resources = @{
                    Cpu    = "1.0"
                    Memory = "2.0Gi"
                }
            }
        )
        Scale = @{
            MinReplicas = 1
            MaxReplicas = 20
            Rules       = @(
                @{
                    Name = "http-concurrency"
                    Custom = @{
                        Type  = "http"
                        Metadata = @{
                            concurrentRequests = "100"
                        }
                    }
                }
                @{
                    Name = "cpu-utilization"
                    Custom = @{
                        Type  = "cpu"
                        Metadata = @{
                            type  = "Utilization"
                            value = "70"
                        }
                    }
                }
            )
        }
    }
}
Update-AzContainerApp @scaleArgs

Write-Host "自动扩缩容已配置: 1-20 副本，HTTP 并发阈值 100"

# 查询容器应用日志
$logQuery = @"
ContainerAppConsoleLogs_CL
| where ContainerAppName_s == '$appName'
| where TimeGenerated > ago(1h)
| project TimeGenerated, Log_s, RevisionName_s
| order by TimeGenerated desc
| limit 50
"@

$queryResult = Invoke-AzOperationalInsightsQuery `
    -WorkspaceId $workspace.CustomerId `
    -Query $logQuery

$queryResult.Results | Format-Table TimeGenerated, RevisionName_s, Log_s -AutoSize

# 配置监控告警：当副本数超过 15 时触发通知
$actionGroup = New-AzActionGroup `
    -ResourceGroupName $resourceGroup `
    -Name "ag-container-alerts" `
    -ShortName "caAlert"

$alertRule = New-AzMetricAlertRuleV2 `
    -Name "alert-high-scale" `
    -ResourceGroupName $resourceGroup `
    -WindowSize (New-TimeSpan -Minutes 5) `
    -Frequency (New-TimeSpan -Minutes 1) `
    -TargetResourceId (Get-AzContainerApp `
        -Name $appName `
        -ResourceGroupName $resourceGroup).Id `
    -Condition @{ `
        MetricName = "ReplicaCount"; `
        Operator   = "GreaterThan"; `
        Threshold  = 15 `
    } `
    -ActionGroupId $actionGroup.Id `
    -Severity 2

Write-Host "告警规则已创建: 副本数 > 15 时通知运维团队"
```

执行结果示例：

```
自动扩缩容已配置: 1-20 副本，HTTP 并发阈值 100

TimeGenerated                RevisionName_s         Log_s
-------------                --------------         -----
2026-01-13T09:20:15Z         ca-weather-api--v2     [INFO] Request GET /api/weather/beijing - 200 OK (45ms)
2026-01-13T09:20:14Z         ca-weather-api--v2     [INFO] Request GET /api/weather/shanghai - 200 OK (32ms)
2026-01-13T09:20:12Z         ca-weather-api--v2     [INFO] Request GET /api/weather/guangzhou - 200 OK (38ms)
2026-01-13T09:20:10Z         ca-weather-api--v1     [INFO] Health check passed

告警规则已创建: 副本数 > 15 时通知运维团队
```

扩缩容规则中，`http-concurrency` 规则表示当单个副本的并发请求数超过 100 时触发扩容，`cpu-utilization` 规则表示当 CPU 使用率超过 70% 时也会触发。两个规则是 OR 关系，任一条件满足即扩容。`MinReplicas = 1` 保证至少有一个实例在运行，即使流量为零也不会缩容到零（除非设为 0）。通过 Log Analytics 的 KQL 查询可以实时查看应用日志，配合告警规则在异常时及时通知运维团队。

## 注意事项

1. **先创建环境再部署应用**：Container Apps 环境是一次性的基础设施决策，创建后无法更改所在区域和 VNet 配置。建议在项目初期就规划好网络拓扑，将环境和共享资源放在同一个资源组中统一管理。

2. **镜像拉取凭据要安全传递**：不要在脚本中硬编码 ACR 的用户名和密码。推荐使用托管标识（Managed Identity）让 Container Apps 自动拉取镜像，或通过 `Get-AzContainerRegistryCredential` 在运行时动态获取并注入。

3. **流量分流的权重总和必须为 100**：配置多版本流量时，所有条目的 `Weight` 值加起来必须等于 100。如果总和不对，部署会失败。建议在脚本中增加前置校验逻辑。

4. **扩缩容冷却时间会影响响应速度**：KEDA 默认的冷却期为 300 秒（5 分钟），即缩容后至少等待 5 分钟才会再次缩容。如果业务流量有突发尖峰，可以适当调大 `MinReplicas` 以保证足够的缓冲容量。

5. **日志查询会产生额外费用**：Log Analytics 按数据摄入量和查询量收费。在生产环境中建议设置每日上限，并在查询时添加时间范围过滤（如 `ago(1h)`），避免全表扫描导致费用飙升。

6. **Az 模块版本要保持最新**：Container Apps 的 PowerShell 支持仍在快速迭代，新功能（如 Dapr 组件、服务间 mTLS）可能需要最新版 Az 模块。部署脚本开头建议加一行 `Update-Module Az -Force` 或至少检查模块版本是否满足要求。
