---
layout: post
date: 2025-10-22 08:00:00
updated: 2025-10-22 08:00:00
title: "PowerShell 技能连载 - Grafana 仪表板集成"
description: PowerTip of the Day - Grafana Dashboard Integration in PowerShell
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
- grafana
- dashboard
- monitoring
- visualization
---

_适用于 PowerShell 7.0 及以上版本_

在 DevOps 和 SRE 实践中，Grafana 已经成为基础设施和应用监控可视化的事实标准。通过丰富的仪表板和告警规则，运维团队可以实时洞察系统健康状态。然而，当需要管理大量仪表板、在不同环境间迁移配置、或者将监控数据与其他系统联动时，手动操作 Grafana Web 界面效率低下且难以保持一致性。

Grafana 提供了功能完善的 HTTP API，PowerShell 天然擅长与 REST API 交互。两者的结合使自动化仪表板管理成为可能：批量创建标准化的监控面板、在不同 Grafana 实例之间同步仪表板配置、定期备份仪表板定义、以及基于外部数据源动态生成面板。这种脚本化的管理方式特别适合多环境、多团队的运维场景。

本文将介绍如何使用 PowerShell 调用 Grafana HTTP API，实现仪表板的查询、创建、导出备份和批量管理操作。

<!-- more -->

## 连接 Grafana 并获取仪表板列表

Grafana 的 HTTP API 使用基本认证或 API Token 进行身份验证。以下代码展示了如何封装连接参数，并列出所有仪表板的基本信息。

```powershell
# Grafana 连接配置
$grafanaConfig = @{
    BaseUrl  = "http://localhost:3000"
    User     = "admin"
    Password = "admin"
}

# 构建 Basic Auth Header
$authPair = "{0}:{1}" -f $grafanaConfig.User, $grafanaConfig.Password
$authBytes = [System.Text.Encoding]::UTF8.GetBytes($authPair)
$authHeader = "Basic {0}" -f [Convert]::ToBase64String($authBytes)

# 查询所有仪表板
$searchUrl = "{0}/api/search?type=dash-db" -f $grafanaConfig.BaseUrl
$response = Invoke-RestMethod -Uri $searchUrl -Headers @{ Authorization = $authHeader } -Method Get

# 提取仪表板摘要
$dashboards = foreach ($item in $response) {
    [PSCustomObject]@{
        标题   = $item.title
        UID    = $item.uid
        URI    = $item.uri
        类型   = $item.type
        是否星标 = $item.isStarred
        标签   = ($item.tags -join ", ")
    }
}

$dashboards | Format-Table -AutoSize
```

上述脚本首先将 Grafana 的连接信息封装到哈希表中，方便后续复用。然后构建 HTTP Basic Authentication 头，调用 `/api/search` 接口并指定 `type=dash-db` 仅返回已保存的仪表板（排除文件夹等非仪表板资源）。通过 `foreach` 循环将返回的 JSON 数据映射为结构化的 PowerShell 对象，方便后续筛选和格式化输出。

执行结果示例：

```
标题                         UID              URI                              类型   是否星标 标签
----                         ---              ---                              ----   -------- ----
系统总览                     abc123xy         db/system-overview               dash-db    True operations
API 响应时间                 def456gh         db/api-response-time             dash-db   False monitoring, api
数据库性能                   ghi789ij         db/database-performance          dash-db   False database
Kubernetes 集群监控          jkl012mn         db/kubernetes-cluster             dash-db    True k8s, operations
```

## 创建新的 Grafana 仪表板

通过 API 创建仪表板时，需要构造完整的仪表板 JSON 定义。以下示例创建一个包含系统 CPU 和内存使用率面板的监控仪表板。

```powershell
# 定义仪表板 JSON 结构
$dashboardJson = @{
    dashboard = @{
        uid        = "ps-auto-system"
        title      = "PowerShell 自动创建 - 系统监控"
        tags       = @("automated", "powershell", "system")
        timezone   = "browser"
        schemaVersion = 39
        refresh    = "30s"
        time       = @{
            from = "now-1h"
            to   = "now"
        }
        panels     = @(
            @{
                id       = 1
                title    = "CPU 使用率 (%)"
                type     = "stat"
                gridPos  = @{ h = 8; w = 6; x = 0; y = 0 }
                targets  = @(
                    @{
                        expr       = '100 - (avg by (instance) (rate(node_cpu_seconds_total{mode="idle"}[5m])) * 100)'
                        refId      = "A"
                        legendFormat = "{{instance}}"
                    }
                )
                fieldConfig = @{
                    defaults = @{
                        unit  = "percent"
                        thresholds = @{
                            steps = @(
                                @{ color = "green"; value = $null }
                                @{ color = "yellow"; value = 60 }
                                @{ color = "red"; value = 85 }
                            )
                        }
                    }
                }
            }
            @{
                id       = 2
                title    = "内存使用率 (%)"
                type     = "gauge"
                gridPos  = @{ h = 8; w = 6; x = 6; y = 0 }
                targets  = @(
                    @{
                        expr       = '(1 - (node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes)) * 100'
                        refId      = "A"
                        legendFormat = "{{instance}}"
                    }
                )
                fieldConfig = @{
                    defaults = @{
                        unit  = "percent"
                        thresholds = @{
                            steps = @(
                                @{ color = "green"; value = $null }
                                @{ color = "yellow"; value = 70 }
                                @{ color = "red"; value = 90 }
                            )
                        }
                    }
                }
            }
        )
    }
    overwrite = $true
}

# 发送创建请求
$createUrl = "{0}/api/dashboards/db" -f $grafanaConfig.BaseUrl
$body = $dashboardJson | ConvertTo-Json -Depth 10

$result = Invoke-RestMethod -Uri $createUrl -Headers @{
    Authorization = $authHeader
    "Content-Type" = "application/json"
} -Method Post -Body $body

Write-Host "仪表板创建成功"
Write-Host "  URL: {0}{1}" -f $grafanaConfig.BaseUrl, $result.url
Write-Host "  版本: $($result.version)"
Write-Host "  UID: $($result.uid)"
```

这段代码的核心是构造 Grafana 所需的仪表板 JSON 结构。`dashboard` 对象包含仪表板的元信息（标题、标签、时区）和面板定义。每个面板通过 `gridPos` 控制在仪表板网格中的位置和尺寸，`targets` 定义 Prometheus 查询表达式，`fieldConfig` 配置显示单位和阈值颜色。将 `overwrite` 设为 `$true` 允许重复执行脚本更新已有仪表板，实现幂等操作。

执行结果示例：

```
仪表板创建成功
  URL: http://localhost:3000/d/ps-auto-system
  版本: 1
  UID: ps-auto-system
```

## 批量导出并备份仪表板

定期备份仪表板配置是运维最佳实践。以下脚本将所有仪表板导出为独立的 JSON 文件，并按日期归档。

```powershell
# 创建备份目录
$backupDate = Get-Date -Format "yyyyMMdd"
$backupDir = "GrafanaBackup_$backupDate"
New-Item -Path $backupDir -ItemType Directory -Force | Out-Null

Write-Host "开始备份 Grafana 仪表板至: $backupDir"

# 获取所有仪表板
$searchUrl = "{0}/api/search?type=dash-db" -f $grafanaConfig.BaseUrl
$allDashboards = Invoke-RestMethod -Uri $searchUrl -Headers @{ Authorization = $authHeader } -Method Get

$backupResults = foreach ($dashboard in $allDashboards) {
    # 获取仪表板完整定义
    $detailUrl = "{0}/api/dashboards/uid/{1}" -f $grafanaConfig.BaseUrl, $dashboard.uid
    $detail = Invoke-RestMethod -Uri $detailUrl -Headers @{ Authorization = $authHeader } -Method Get

    # 生成安全的文件名（替换特殊字符）
    $safeName = $dashboard.title -replace '[\\/:*?\"<>|]', '_'
    $filePath = Join-Path $backupDir "$safeName.json"

    # 导出仪表板 JSON，包含版本和元数据
    $exportData = @{
        meta        = @{
            exportedAt   = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
            grafanaVersion = $detail.meta.version
            uid           = $dashboard.uid
        }
        dashboard   = $detail.dashboard
    }

    $exportData | ConvertTo-Json -Depth 20 | Set-Content -Path $filePath -Encoding UTF8

    [PSCustomObject]@{
        仪表板   = $dashboard.title
        UID      = $dashboard.uid
        面板数   = $detail.dashboard.panels.Count
        文件大小 = "{0:N1} KB" -f ((Get-Item $filePath).Length / 1KB)
        状态     = "已备份"
    }
}

Write-Host "`n备份完成，共导出 $($backupResults.Count) 个仪表板"
$backupResults | Format-Table -AutoSize

# 生成备份摘要文件
$summaryPath = Join-Path $backupDir "_backup_summary.txt"
$summaryContent = @(
    "Grafana 仪表板备份摘要"
    "备份时间: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
    "仪表板总数: $($backupResults.Count)"
    "备份来源: $($grafanaConfig.BaseUrl)"
    ""
    "仪表板列表:"
    foreach ($r in $backupResults) {
        "  - $($r.仪表板) (UID: $($r.UID), 面板数: $($r.面板数))"
    }
)
$summaryContent | Set-Content -Path $summaryPath -Encoding UTF8
```

这个脚本实现了完整的备份流程。首先创建以日期命名的备份目录，然后逐一获取每个仪表板的完整 JSON 定义。文件名经过特殊字符清理确保在文件系统上合法。导出的 JSON 不仅包含仪表板定义本身，还附加了导出时间、Grafana 版本等元数据，方便后续追溯。最终还生成一份文本格式的备份摘要文件，便于快速查看备份内容。

执行结果示例：

```
开始备份 Grafana 仪表板至: GrafanaBackup_20251022

备份完成，共导出 4 个仪表板

仪表板                         UID              面板数 文件大小 状态
--------                         ---              ------ -------- ----
系统总览                         abc123xy              6 12.3 KB  已备份
API 响应时间                     def456gh              3  5.7 KB  已备份
数据库性能                       ghi789ij              5  9.1 KB  已备份
Kubernetes 集群监控              jkl012mn              8 18.4 KB  已备份
```

## 跨实例同步仪表板配置

在多环境（开发、测试、生产）部署场景中，保持 Grafana 仪表板配置一致是常见需求。以下脚本从源实例拉取仪表板并推送到目标实例。

```powershell
# 定义源和目标 Grafana 实例
$sourceConfig = @{
    BaseUrl  = "http://grafana-dev.internal:3000"
    User     = "admin"
    Password = "dev-admin-pass"
}

$targetConfig = @{
    BaseUrl  = "http://grafana-prod.internal:3000"
    User     = "admin"
    Password = "prod-admin-pass"
}

# 辅助函数：构建认证头
function New-GrafanaAuthHeader {
    param($User, $Password)
    $pair = "{0}:{1}" -f $User, $Password
    $bytes = [System.Text.Encoding]::UTF8.GetBytes($pair)
    "Basic {0}" -f [Convert]::ToBase64String($bytes)
}

$sourceAuth = New-GrafanaAuthHeader @sourceConfig
$targetAuth = New-GrafanaAuthHeader @targetConfig

# 从源实例获取所有带 "sync" 标签的仪表板
$searchUrl = "{0}/api/search?type=dash-db&tag=sync" -f $sourceConfig.BaseUrl
$syncDashboards = Invoke-RestMethod -Uri $searchUrl -Headers @{ Authorization = $sourceAuth } -Method Get

Write-Host "找到 $($syncDashboards.Count) 个标记为同步的仪表板"

$syncResults = foreach ($dashboard in $syncDashboards) {
    # 从源获取完整定义
    $sourceUrl = "{0}/api/dashboards/uid/{1}" -f $sourceConfig.BaseUrl, $dashboard.uid
    $sourceData = Invoke-RestMethod -Uri $sourceUrl -Headers @{ Authorization = $sourceAuth } -Method Get

    # 构造推送请求体
    $pushBody = @{
        dashboard = $sourceData.dashboard
        overwrite = $true
    }

    # 推送到目标实例
    $targetUrl = "{0}/api/dashboards/db" -f $targetConfig.BaseUrl
    $body = $pushBody | ConvertTo-Json -Depth 20

    try {
        $pushResult = Invoke-RestMethod -Uri $targetUrl -Headers @{
            Authorization  = $targetAuth
            "Content-Type" = "application/json"
        } -Method Post -Body $body

        [PSCustomObject]@{
            仪表板     = $dashboard.title
            目标UID    = $pushResult.uid
            目标版本   = $pushResult.version
            同步状态   = "成功"
            同步时间   = Get-Date -Format "HH:mm:ss"
        }
    }
    catch {
        [PSCustomObject]@{
            仪表板     = $dashboard.title
            目标UID    = $dashboard.uid
            目标版本   = "N/A"
            同步状态   = "失败: $($_.Exception.Message)"
            同步时间   = Get-Date -Format "HH:mm:ss"
        }
    }
}

Write-Host "`n同步结果："
$syncResults | Format-Table -AutoSize
```

这段代码实现了跨 Grafana 实例的仪表板同步。通过自定义函数 `New-GrafanaAuthHeader` 封装认证逻辑，避免重复代码。同步策略基于标签筛选：只有在源实例中标记为 `sync` 的仪表板才会被同步。使用 `try/catch` 处理推送过程中的异常，确保单条仪表板同步失败不会中断整个批处理。`overwrite = $true` 保证幂等性，重复执行不会创建重复仪表板。

执行结果示例：

```
找到 3 个标记为同步的仪表板

同步结果：

仪表板               目标UID           目标版本 同步状态 同步时间
--------               -------           -------- -------- --------
系统总览               abc123xy                 4 成功     14:35:12
API 响应时间           def456gh                 2 成功     14:35:14
数据库性能             ghi789ij                 3 成功     14:35:16
```

## 注意事项

1. **认证安全**：避免在脚本中硬编码 Grafana 用户名和密码。建议使用环境变量、Azure Key Vault 或 PowerShell SecretManagement 模块存储凭据。生产环境中优先使用 Grafana Service Account Token 而非管理员账号密码。

2. **API 权限控制**：为自动化脚本创建专用的 Service Account，仅授予必要的权限（如 Dashboard Viewer、Dashboard Editor），避免使用全局管理员权限。通过最小权限原则降低误操作风险。

3. **JSON 序列化深度**：Grafana 仪表板的 JSON 结构嵌套层级较深，使用 `ConvertTo-Json` 时务必指定足够的 `-Depth` 参数（建议 10 以上），否则深层配置可能被截断为字符串 `System.Object[]`。

4. **版本管理**：每次通过 API 更新仪表板都会递增版本号。建议在 CI/CD 流水线中将导出的 JSON 文件纳入 Git 版本控制，实现仪表板配置的可追溯和回滚能力。

5. **数据源依赖**：仪表板中的查询面板依赖特定的数据源（如 Prometheus、InfluxDB）。跨实例同步时需确保目标实例已配置同名数据源，否则面板将显示查询错误。可先通过 `/api/datasources` 接口同步数据源配置。

6. **并发控制**：批量操作仪表板时，注意 Grafana 对并发请求的速率限制。在循环中使用 `Start-Sleep` 添加适当间隔（如 100-200 毫秒），或使用 `-ThrottleLimit` 参数控制并发度，避免触发 HTTP 429 Too Many Requests 错误。
