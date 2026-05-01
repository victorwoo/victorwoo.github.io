---
layout: post
date: 2026-03-03 08:00:00
title: "PowerShell 技能连载 - Azure App Configuration 集中配置"
description: PowerTip of the Day - Azure App Configuration Centralized Settings
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
- azure
- app-configuration
- config-management
- feature-flags
---

_适用于 PowerShell 7.0 及以上版本_

在微服务架构中，每个服务都有自己的 `appsettings.json` 或环境变量文件来管理配置。随着服务数量增长，配置分散在各处的问题日益严重：修改一个数据库连接字符串需要逐个服务更新并重新部署，不同环境之间的配置差异难以追踪，紧急开关的生效时间更是无法保证。这种"配置碎片化"不仅增加了运维成本，也埋下了安全隐患。

Azure App Configuration 正是为解决这些问题而生的集中化配置管理服务。它提供统一的键值存储，支持标签（Label）实现环境隔离，内置 Feature Flag 功能支持灰度发布，并通过 Sentinel 机制实现配置的动态刷新——所有这些都不需要重启应用。结合 PowerShell 的自动化能力，我们可以将配置管理纳入 CI/CD 流水线，实现配置的版本控制、审计追踪和跨环境同步。

本文将围绕三个核心场景展开：配置存储的日常管理操作、Feature Flag 的创建与条件控制，以及配置的批量导入导出与环境间同步。掌握这些技能后，你就能用 PowerShell 构建一套完整的配置管理自动化方案。

## 配置存储管理

日常配置管理是最基础也是最频繁的操作。下面的脚本封装了连接 App Configuration 存储、读写键值对、使用标签隔离环境以及查询配置修订历史等常用功能，适合直接集成到运维工具链中。

```powershell
function Invoke-AppConfigOperation {
    <#
    .SYNOPSIS
    管理 Azure App Configuration 键值对
    #>
    param(
        [Parameter(Mandatory)]
        [string]$Endpoint,

        [ValidateSet('Get', 'Set', 'Remove', 'List', 'History')]
        [string]$Action = 'List',

        [string]$Key,
        [string]$Value,
        [string]$Label,
        [string]$Prefix
    )

    # 使用 Azure CLI 获取访问令牌
    $token = (az account get-access-token --resource "https://azconfig.io" --query accessToken --output tsv)
    $headers = @{
        Authorization  = "Bearer $token"
        'Content-Type' = 'application/vnd.microsoft.appconfig.kv+json'
    }

    switch ($Action) {
        'Get' {
            $uri = "$Endpoint/kv/$($Key)?label=$Label"
            $response = Invoke-RestMethod -Uri $uri -Headers $headers -Method Get
            return [PSCustomObject]@{
                Key   = $response.key
                Value = $response.value
                Label = $response.label
                ETag = $response.etag
            }
        }

        'Set' {
            $uri = "$Endpoint/kv/$($Key)?label=$Label"
            $body = @{
                key   = $Key
                value = $Value
                label = $Label
            } | ConvertTo-Json

            $response = Invoke-RestMethod -Uri $uri -Headers $headers -Method Put -Body $body
            Write-Host "已设置配置项: $Key = $Value (标签: $Label)" -ForegroundColor Green
            return $response
        }

        'Remove' {
            # 先获取当前 ETag
            $existing = Invoke-AppConfigOperation -Endpoint $Endpoint -Action 'Get' -Key $Key -Label $Label
            $uri = "$Endpoint/kv/$($Key)?label=$Label"
            Invoke-RestMethod -Uri $uri -Headers $headers -Method Delete
            Write-Host "已删除配置项: $Key (标签: $Label)" -ForegroundColor Yellow
        }

        'List' {
            $filterParam = if ($Prefix) { "&key=$Prefix*" } else { '' }
            $labelParam = if ($Label) { "&label=$Label" } else { '' }
            $uri = "$Endpoint/kv?$filterParam$labelParam"
            $response = Invoke-RestMethod -Uri $uri -Headers $headers -Method Get
            $items = $response.items
            return $items | ForEach-Object {
                [PSCustomObject]@{
                    Key   = $_.key
                    Value = $_.value
                    Label = $_.label
                }
            }
        }

        'History' {
            $uri = "$Endpoint/revisions?key=$Key&label=$Label"
            $response = Invoke-RestMethod -Uri $uri -Headers $headers -Method Get
            return $response.items | ForEach-Object {
                [PSCustomObject]@{
                    Key       = $_.key
                    Value     = $_.value
                    Label     = $_.label
                    ETag      = $_.etag
                    Timestamp = $_.last_modified
                }
            }
        }
    }
}

# 示例：按环境管理配置
$endpoint = "https://myappconfig.azconfig.io"

# 设置开发环境和生产环境的数据库连接串
Invoke-AppConfigOperation -Endpoint $endpoint -Action 'Set' `
    -Key "Database:ConnectionString" -Value "Server=dev-sql;Database=MyApp" -Label "dev"

Invoke-AppConfigOperation -Endpoint $endpoint -Action 'Set' `
    -Key "Database:ConnectionString" -Value "Server=prod-sql;Database=MyApp" -Label "prod"

# 列出开发环境下所有 Database 前缀的配置
Invoke-AppConfigOperation -Endpoint $endpoint -Action 'List' -Prefix "Database" -Label "dev"

# 查看某个配置项的修改历史
Invoke-AppConfigOperation -Endpoint $endpoint -Action 'History' `
    -Key "Database:ConnectionString" -Label "prod"
```

执行结果示例：

```
已设置配置项: Database:ConnectionString = Server=dev-sql;Database=MyApp (标签: dev)
已设置配置项: Database:ConnectionString = Server=prod-sql;Database=MyApp (标签: prod)

Key                          Value                             Label
---                          -----                             -----
Database:ConnectionString    Server=dev-sql;Database=MyApp     dev
Database:MaxPoolSize         50                                dev
Database:CommandTimeout      30                                dev

Key                          Value                             Label   ETag            Timestamp
---                          -----                             -----   ----            ---------
Database:ConnectionString    Server=prod-sql;Database=MyApp    prod    "abc123"        2026-03-03T10:15:00Z
Database:ConnectionString    Server=staging-sql;Database=MyApp prod    "def456"        2026-03-01T08:30:00Z
Database:ConnectionString    Server=prod-sql;Database=MyApp    prod    "ghi789"        2026-02-28T14:00:00Z
```

通过标签（Label）机制，同一个键可以对应不同环境的值。查询时指定标签即可获取对应环境的配置，无需维护多套命名规则。修订历史功能可以追溯每次配置变更，为审计和回滚提供依据。

## Feature Flag 管理

Feature Flag 是实现灰度发布、A/B 测试和功能开关的核心机制。App Configuration 原生支持 Feature Flag 的存储和管理，下面演示如何用 PowerShell 创建、查询和配置带条件过滤器的 Feature Flag。

```powershell
function Manage-FeatureFlag {
    <#
    .SYNOPSIS
    管理 Azure App Configuration 中的 Feature Flag
    #>
    param(
        [Parameter(Mandatory)]
        [string]$Endpoint,

        [Parameter(Mandatory)]
        [string]$FlagName,

        [ValidateSet('Create', 'Get', 'Enable', 'Disable', 'SetPercentage', 'SetTargeting')]
        [string]$Action = 'Get',

        [string]$Label,
        [double]$Percentage = 50,
        [string[]]$TargetGroups,
        [string[]]$ExcludeUsers
    )

    $token = (az account get-access-token --resource "https://azconfig.io" --query accessToken --output tsv)
    $headers = @{
        Authorization  = "Bearer $token"
        'Content-Type' = 'application/vnd.microsoft.appconfig.kv+json'
    }

    $featureKey = ".appconfig.featureflag/$FlagName"

    switch ($Action) {
        'Create' {
            $body = @{
                key   = $featureKey
                value = @{
                    id          = $FlagName
                    description = "Feature flag for $FlagName"
                    enabled     = $false
                    conditions  = @{
                        client_filters = @()
                    }
                } | ConvertTo-Json -Depth 5
                label        = $Label
                content_type = 'application/vnd.microsoft.appconfig.featureflag+json'
            } | ConvertTo-Json -Depth 5

            Invoke-RestMethod -Uri "$Endpoint/kv/$featureKey?label=$Label" `
                -Headers $headers -Method Put -Body $body
            Write-Host "已创建 Feature Flag: $FlagName (状态: 关闭)" -ForegroundColor Green
        }

        'Enable' {
            $existing = Invoke-RestMethod -Uri "$Endpoint/kv/$featureKey?label=$Label" `
                -Headers $headers -Method Get
            $flagValue = $existing.value | ConvertFrom-Json
            $flagValue.enabled = $true

            $body = @{
                key   = $featureKey
                value = ($flagValue | ConvertTo-Json -Depth 5)
                label = $Label
                content_type = 'application/vnd.microsoft.appconfig.featureflag+json'
            } | ConvertTo-Json -Depth 5

            Invoke-RestMethod -Uri "$Endpoint/kv/$featureKey?label=$Label" `
                -Headers $headers -Method Put -Body $body
            Write-Host "已启用 Feature Flag: $FlagName" -ForegroundColor Green
        }

        'Disable' {
            $existing = Invoke-RestMethod -Uri "$Endpoint/kv/$featureKey?label=$Label" `
                -Headers $headers -Method Get
            $flagValue = $existing.value | ConvertFrom-Json
            $flagValue.enabled = $false

            $body = @{
                key   = $featureKey
                value = ($flagValue | ConvertTo-Json -Depth 5)
                label = $Label
                content_type = 'application/vnd.microsoft.appconfig.featureflag+json'
            } | ConvertTo-Json -Depth 5

            Invoke-RestMethod -Uri "$Endpoint/kv/$featureKey?label=$Label" `
                -Headers $headers -Method Put -Body $body
            Write-Host "已禁用 Feature Flag: $FlagName" -ForegroundColor Yellow
        }

        'SetPercentage' {
            # 配置百分比灰度：按用户比例逐步放开功能
            $existing = Invoke-RestMethod -Uri "$Endpoint/kv/$featureKey?label=$Label" `
                -Headers $headers -Method Get
            $flagValue = $existing.value | ConvertFrom-Json
            $flagValue.enabled = $true
            $flagValue.conditions.client_filters = @(
                @{
                    name   = 'Microsoft.Targeting'
                    parameters = @{
                        Audiences = @(
                            @{
                                Id         = "rollout-group"
                                Inclusion  = $Percentage
                                Exclusion  = 0
                            }
                        )
                        DefaultRolloutPercentage = $Percentage
                    }
                }
            )

            $body = @{
                key   = $featureKey
                value = ($flagValue | ConvertTo-Json -Depth 10)
                label = $Label
                content_type = 'application/vnd.microsoft.appconfig.featureflag+json'
            } | ConvertTo-Json -Depth 10

            Invoke-RestMethod -Uri "$Endpoint/kv/$featureKey?label=$Label" `
                -Headers $headers -Method Put -Body $body
            Write-Host "已设置 $FlagName 灰度比例为 ${Percentage}%" -ForegroundColor Cyan
        }

        'SetTargeting' {
            # 配置定向投放：指定用户组可见
            $existing = Invoke-RestMethod -Uri "$Endpoint/kv/$featureKey?label=$Label" `
                -Headers $headers -Method Get
            $flagValue = $existing.value | ConvertFrom-Json
            $flagValue.enabled = $true
            $flagValue.conditions.client_filters = @(
                @{
                    name   = 'Microsoft.Targeting'
                    parameters = @{
                        Users    = @()
                        Groups   = @(
                            @{
                                Name       = "beta-testers"
                                RolloutPercentage = 100
                            }
                        )
                        DefaultRolloutPercentage = 0
                    }
                }
            )

            $body = @{
                key   = $featureKey
                value = ($flagValue | ConvertTo-Json -Depth 10)
                label = $Label
                content_type = 'application/vnd.microsoft.appconfig.featureflag+json'
            } | ConvertTo-Json -Depth 10

            Invoke-RestMethod -Uri "$Endpoint/kv/$featureKey?label=$Label" `
                -Headers $headers -Method Put -Body $body
            Write-Host "已设置 $FlagName 定向投放: beta-testers 组 100% 可见" -ForegroundColor Cyan
        }
    }
}

# 创建并配置新功能的 Feature Flag
$endpoint = "https://myappconfig.azconfig.io"

# 创建开关（初始关闭）
Manage-FeatureFlag -Endpoint $endpoint -FlagName "NewDashboard" `
    -Action 'Create' -Label "prod"

# 开启灰度：先对 10% 用户开放
Manage-FeatureFlag -Endpoint $endpoint -FlagName "NewDashboard" `
    -Action 'SetPercentage' -Percentage 10 -Label "prod"

# 逐步放量到 50%
Manage-FeatureFlag -Endpoint $endpoint -FlagName "NewDashboard" `
    -Action 'SetPercentage' -Percentage 50 -Label "prod"

# 设置定向投放：beta-testers 组全部可见
Manage-FeatureFlag -Endpoint $endpoint -FlagName "NewDashboard" `
    -Action 'SetTargeting' -Label "prod"
```

执行结果示例：

```
已创建 Feature Flag: NewDashboard (状态: 关闭)
已设置 NewDashboard 灰度比例为 10%
已设置 NewDashboard 灰度比例为 50%
已设置 NewDashboard 定向投放: beta-testers 组 100% 可见
```

Feature Flag 的核心价值在于将功能发布与代码部署解耦。通过百分比灰度，可以按照 10% → 50% → 100% 的节奏逐步放量；通过定向投放，可以让内部测试团队或特定用户组优先体验新功能。所有调整都是实时生效的，不需要重新部署应用。

## 配置导入导出与同步

在多环境管理中，将配置从开发环境同步到测试、预发布和生产环境是常见的运维任务。下面的脚本支持批量导入配置、跨环境同步，并能生成配置差异报告供审核。

```powershell
function Sync-AppConfigEnvironment {
    <#
    .SYNOPSIS
    跨环境同步 Azure App Configuration 配置
    #>
    param(
        [Parameter(Mandatory)]
        [string]$SourceEndpoint,

        [Parameter(Mandatory)]
        [string]$TargetEndpoint,

        [string]$SourceLabel = 'dev',

        [string]$TargetLabel = 'staging',

        [string]$KeyPrefix,

        [switch]$DryRun,

        [switch]$Force
    )

    $token = (az account get-access-token --resource "https://azconfig.io" --query accessToken --output tsv)
    $headers = @{
        Authorization  = "Bearer $token"
        'Content-Type' = 'application/vnd.microsoft.appconfig.kv+json'
    }

    # 从源环境读取全部配置
    Write-Host "正在从源环境读取配置 (标签: $SourceLabel)..." -ForegroundColor Cyan
    $filter = if ($KeyPrefix) { "&key=$KeyPrefix*" } else { '' }
    $sourceResponse = Invoke-RestMethod -Uri "$SourceEndpoint/kv?label=$SourceLabel$filter" `
        -Headers $headers -Method Get
    $sourceItems = @{}
    foreach ($item in $sourceResponse.items) {
        $sourceItems[$item.key] = $item.value
    }
    Write-Host "  读取到 $($sourceItems.Count) 个配置项"

    # 从目标环境读取对应配置
    Write-Host "正在从目标环境读取配置 (标签: $TargetLabel)..." -ForegroundColor Cyan
    $targetResponse = Invoke-RestMethod -Uri "$TargetEndpoint/kv?label=$TargetLabel$filter" `
        -Headers $headers -Method Get
    $targetItems = @{}
    foreach ($item in $targetResponse.items) {
        $targetItems[$item.key] = $item.value
    }
    Write-Host "  读取到 $($targetItems.Count) 个配置项"

    # 计算差异
    $toAdd = $sourceItems.Keys | Where-Object { $_ -notin $targetItems.Keys }
    $toUpdate = $sourceItems.Keys | Where-Object {
        $_ -in $targetItems.Keys -and $sourceItems[$_] -ne $targetItems[$_]
    }
    $toRemove = $targetItems.Keys | Where-Object { $_ -notin $sourceItems.Keys }

    # 输出差异报告
    Write-Host "`n===== 配置同步差异报告 =====" -ForegroundColor White
    Write-Host "源: $SourceLabel → 目标: $TargetLabel"
    Write-Host "新增: $($toAdd.Count) 项 | 更新: $($toUpdate.Count) 项 | 删除: $($toRemove.Count) 项"
    Write-Host "=============================`n"

    if ($toAdd.Count -gt 0) {
        Write-Host "[新增] 以下配置将添加到目标环境:" -ForegroundColor Green
        $toAdd | ForEach-Object { Write-Host "  + $_ = $($sourceItems[$_].Substring(0, [Math]::Min(60, $sourceItems[$_].Length)))" }
    }

    if ($toUpdate.Count -gt 0) {
        Write-Host "[更新] 以下配置将在目标环境更新:" -ForegroundColor Yellow
        $toUpdate | ForEach-Object {
            Write-Host "  ~ $_"
            Write-Host "      旧值: $($targetItems[$_].Substring(0, [Math]::Min(50, $targetItems[$_].Length)))"
            Write-Host "      新值: $($sourceItems[$_].Substring(0, [Math]::Min(50, $sourceItems[$_].Length)))"
        }
    }

    if ($toRemove.Count -gt 0) {
        Write-Host "[删除] 以下配置将从目标环境移除:" -ForegroundColor Red
        $toRemove | ForEach-Object { Write-Host "  - $_" }
    }

    if ($DryRun) {
        Write-Host "`n[试运行模式] 未执行任何变更。移除 -DryRun 参数以实际执行同步。" -ForegroundColor Magenta
        return
    }

    if (-not $Force) {
        $confirm = Read-Host "`n确认执行同步？(输入 YES 确认)"
        if ($confirm -ne 'YES') {
            Write-Host "已取消同步操作。" -ForegroundColor Yellow
            return
        }
    }

    # 执行新增和更新
    $changeCount = 0
    foreach ($key in ($toAdd + $toUpdate)) {
        $body = @{
            key   = $key
            value = $sourceItems[$key]
            label = $TargetLabel
        } | ConvertTo-Json

        Invoke-RestMethod -Uri "$TargetEndpoint/kv/$key?label=$TargetLabel" `
            -Headers $headers -Method Put -Body $body
        $changeCount++
    }

    Write-Host "`n同步完成！共处理 $changeCount 个配置项。" -ForegroundColor Green
}

# 导出配置为本地 JSON 文件（用于备份或版本控制）
function Export-AppConfigToJson {
    param(
        [string]$Endpoint,
        [string]$Label,
        [string]$OutputPath = "./appconfig-backup.json"
    )

    $token = (az account get-access-token --resource "https://azconfig.io" --query accessToken --output tsv)
    $headers = @{ Authorization = "Bearer $token" }

    $labelParam = if ($Label) { "?label=$Label" } else { '' }
    $response = Invoke-RestMethod -Uri "$Endpoint/kv$labelParam" -Headers $headers -Method Get

    $export = $response.items | ForEach-Object {
        [PSCustomObject]@{
            key   = $_.key
            value = $_.value
            label = $_.label
            etag  = $_.etag
        }
    }

    $export | ConvertTo-Json -Depth 5 | Out-File -FilePath $OutputPath -Encoding utf8
    Write-Host "已导出 $($export.Count) 个配置项到 $OutputPath" -ForegroundColor Green
}

# 使用示例
$devEndpoint = "https://myappconfig-dev.azconfig.io"
$stagingEndpoint = "https://myappconfig-staging.azconfig.io"

# 先试运行查看差异
Sync-AppConfigEnvironment -SourceEndpoint $devEndpoint `
    -TargetEndpoint $stagingEndpoint `
    -SourceLabel "dev" -TargetLabel "staging" -DryRun

# 确认无误后执行同步
Sync-AppConfigEnvironment -SourceEndpoint $devEndpoint `
    -TargetEndpoint $stagingEndpoint `
    -SourceLabel "dev" -TargetLabel "staging" -Force

# 导出生产配置为 JSON 备份
Export-AppConfigToJson -Endpoint "https://myappconfig.azconfig.io" `
    -Label "prod" -OutputPath "./config-backup-prod-20260303.json"
```

执行结果示例：

```
正在从源环境读取配置 (标签: dev)...
  读取到 24 个配置项
正在从目标环境读取配置 (标签: staging)...
  读取到 22 个配置项

===== 配置同步差异报告 =====
源: dev → 目标: staging
新增: 3 项 | 更新: 2 项 | 删除: 1 项
============================

[新增] 以下配置将添加到目标环境:
  + Cache:RedisUrl = redis-staging.cache.windows.net:6380
  + Feature:NewSearch = true
  + Logging:StructuredJson = true
[更新] 以下配置将在目标环境更新:
  ~ Database:CommandTimeout
      旧值: 30
      新值: 60
  ~ Api:RateLimitPerMinute
      旧值: 100
      新值: 200
[删除] 以下配置将从目标环境移除:
  - Legacy:OldApiEndpoint

同步完成！共处理 5 个配置项。
已导出 22 个配置项到 ./config-backup-prod-20260303.json
```

同步脚本采用"先报告后执行"的模式：先通过 `DryRun` 参数生成差异报告，确认无误后再实际执行。这种方式可以有效防止误操作，尤其是在生产环境同步时更为重要。导出的 JSON 文件可以纳入 Git 版本控制，实现配置的代码化管理。

## 注意事项

1. **访问权限控制**：App Configuration 支持 Azure RBAC 和访问密钥两种认证方式。生产环境建议使用托管标识（Managed Identity）配合 RBAC，避免在脚本中硬编码连接字符串或访问密钥。

2. **配置值的加密**：虽然 App Configuration 在传输和存储时都会加密，但敏感值（如数据库密码、API 密钥）应配合 Azure Key Vault 使用。App Configuration 支持通过 Key Vault 引用将敏感值存储在 Key Vault 中，配置中只保存引用指针。

3. **标签命名规范**：建议统一使用环境名称作为标签（如 `dev`、`staging`、`prod`），避免混用不同维度的标签。如果需要多维度分类（如环境 + 区域），建议在键名中体现区域信息，保持标签维度的单一性。

4. **Feature Flag 的清理**：长期未使用的 Feature Flag 应及时清理。可以编写定时脚本扫描所有 Feature Flag，标记超过 90 天未变更且处于启用状态的 Flag，通知相关团队评估是否可以移除。

5. **同步操作的原子性**：跨环境同步不具备事务特性，如果中途失败可能导致部分配置已更新而部分未更新的不一致状态。建议在同步前先导出目标环境的配置作为备份，失败时可以从备份恢复。

6. **网络延迟与重试策略**：App Configuration 的 REST API 调用可能因网络波动失败。在生产脚本中应加入重试逻辑（如指数退避），并设置合理的超时时间。可以使用 PowerShell 的 `$MaximumRetryCount` 和 `$RetryIntervalSec` 参数简化重试实现。
