---
layout: post
date: 2026-04-24 08:00:00
updated: 2026-04-24 08:00:00
title: "PowerShell 技能连载 - Azure App Service 部署槽管理"
description: PowerTip of the Day - Azure App Service Deployment Slot Management in PowerShell
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
- azure
- app-service
- deployment
- blue-green
---

_适用于 PowerShell 7.0 及以上版本，需要 Az.Websites 模块_

<!-- more -->

## 部署槽：零停机部署的基石

在现代云原生应用的运维实践中，零停机部署已经成为一项基本要求。传统的"停机发布"模式不仅影响用户体验，还可能导致流量丢失和请求中断。Azure App Service 提供的部署槽（Deployment Slots）功能，正是解决这一问题的利器。

部署槽本质上是应用服务内部的独立运行环境，每个槽拥有自己的主机名、应用设置和连接字符串。通过在"暂存槽（Staging Slot）"完成新版本的部署与预热验证，再将流量无缝切换到生产槽，即可实现蓝绿部署（Blue-Green Deployment）。整个过程对终端用户完全透明，不会出现任何服务中断。

本文将介绍如何使用 PowerShell 和 Az 模块，对 Azure App Service 部署槽进行全生命周期管理，涵盖槽的创建、蓝绿部署自动化、多环境配置与预热验证等核心场景。

## 部署槽生命周期管理

第一个示例演示部署槽的完整生命周期操作：创建新槽、从已有槽克隆配置、查看所有槽的状态，以及配置流量路由比例。

```powershell
# 连接 Azure 账户并选择订阅
Connect-AzAccount
Set-AzContext -SubscriptionId 'xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx'

$ResourceGroup = 'rg-myapp-prod'
$AppName = 'app-myapp-prod'

# 查看当前应用的所有部署槽
Get-AzWebAppSlot -ResourceGroupName $ResourceGroup -Name $AppName |
    Select-Object Name, State, DefaultHostName, TrafficManagerPolicies

# 创建新的 Staging 槽，从 Production 克隆配置
New-AzWebAppSlot `
    -ResourceGroupName $ResourceGroup `
    -Name $AppName `
    -Slot 'staging' `
    -ConfigurationSource (Get-AzWebApp -ResourceGroupName $ResourceGroup -Name $AppName)

# 为 Staging 槽单独设置应用配置（不与生产槽共享）
$StagingSlot = Get-AzWebAppSlot -ResourceGroupName $ResourceGroup -Name $AppName -Slot 'staging'
$StagingSlot.SiteConfig.AppSettings | ForEach-Object {
    Write-Host "  $($_.Name) = $($_.Value)"
}

# 配置流量路由：将 10% 的流量发送到 Staging 槽用于金丝雀测试
Set-AzWebAppTrafficRouting `
    -ResourceGroupName $ResourceGroup `
    -WebAppName $AppName `
    -RoutingRule @{ ActionHostName = "$AppName-staging.azurewebsites.net"; ReroutePercentage = 10 }

# 查看当前流量路由配置
Get-AzWebAppTrafficRouting -ResourceGroupName $ResourceGroup -WebAppName $AppName
```

执行结果示例：

```
Name     State  DefaultHostName                        TrafficManagerPolicies
----     -----  ---------------                        ----------------------
Production  Running  app-myapp-prod.azurewebsites.net
staging     Running  app-myapp-prod-staging.azurewebsites.net

  ASPNETCORE_ENVIRONMENT = Staging
  APP_VERSION = 2.1.0
  API_ENDPOINT = https://api-staging.example.com

ActionHostName                           ReroutePercentage
--------------                           -----------------
app-myapp-prod-staging.azurewebsites.net                10
```

## 蓝绿部署自动化

蓝绿部署是部署槽最核心的使用场景。下面的脚本封装了一个完整的蓝绿部署流程：部署到 Staging 槽、执行预热验证、将流量切换到 Staging、验证生产环境稳定后删除旧的生产版本。

```powershell
function Invoke-BlueGreenDeployment {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$ResourceGroup,

        [Parameter(Mandatory)]
        [string]$AppName,

        [Parameter(Mandatory)]
        [string]$PackagePath,

        [int]$WarmupTimeoutSeconds = 120,

        [int]$HealthCheckRetries = 5
    )

    $StagingUrl = "https://$AppName-staging.azurewebsites.net"
    $ProdUrl = "https://$AppName.azurewebsites.net"

    # 步骤 1：部署新版本到 Staging 槽
    Write-Host "[$(Get-Date -Format 'HH:mm:ss')] 正在部署到 Staging 槽..." -ForegroundColor Cyan
    Publish-AzWebApp `
        -ResourceGroupName $ResourceGroup `
        -Name $AppName `
        -Slot 'staging' `
        -ArchivePath $PackagePath

    # 步骤 2：预热并验证 Staging 槽健康状态
    Write-Host "[$(Get-Date -Format 'HH:mm:ss')] 预热 Staging 槽..." -ForegroundColor Cyan
    $Healthy = $false
    for ($i = 1; $i -le $HealthCheckRetries; $i++) {
        try {
            $Response = Invoke-WebRequest -Uri "$StagingUrl/health" -TimeoutSec 10 -UseBasicParsing
            if ($Response.StatusCode -eq 200) {
                $Healthy = $true
                Write-Host "[$(Get-Date -Format 'HH:mm:ss')] Staging 槽健康检查通过 (尝试 $i/$HealthCheckRetries)" -ForegroundColor Green
                break
            }
        } catch {
            Write-Host "[$(Get-Date -Format 'HH:mm:ss')] 健康检查失败，等待重试 (尝试 $i/$HealthCheckRetries)..." -ForegroundColor Yellow
            Start-Sleep -Seconds ([Math]::Min(10 * $i, 30))
        }
    }

    if (-not $Healthy) {
        throw "Staging 槽预热失败，终止部署"
    }

    # 步骤 3：执行槽位交换（Staging → Production）
    Write-Host "[$(Get-Date -Format 'HH:mm:ss')] 正在交换槽位..." -ForegroundColor Cyan
    Invoke-AzResourceAction `
        -ResourceGroupName $ResourceGroup `
        -ResourceType 'Microsoft.Web/sites/slots' `
        -ResourceName "$AppName/staging" `
        -Action 'slotsswap' `
        -Parameters @{ targetSlot = 'production'; preserveVnet = $true } `
        -Force

    # 步骤 4：验证生产环境
    Write-Host "[$(Get-Date -Format 'HH:mm:ss')] 验证生产环境..." -ForegroundColor Cyan
    $ProdResponse = Invoke-WebRequest -Uri "$ProdUrl/health" -TimeoutSec 10 -UseBasicParsing
    if ($ProdResponse.StatusCode -eq 200) {
        Write-Host "[$(Get-Date -Format 'HH:mm:ss')] 部署完成！生产环境正常运行" -ForegroundColor Green
    } else {
        Write-Host "[$(Get-Date -Format 'HH:mm:ss')] 生产环境异常，准备回滚..." -ForegroundColor Red
        # 立即交换回 Staging（旧版本仍在 Staging 槽中）
        Invoke-AzResourceAction `
            -ResourceGroupName $ResourceGroup `
            -ResourceType 'Microsoft.Web/sites/slots' `
            -ResourceName "$AppName/staging" `
            -Action 'slotsswap' `
            -Parameters @{ targetSlot = 'production'; preserveVnet = $true } `
            -Force
        throw "部署后验证失败，已回滚到上一版本"
    }
}

# 调用示例
Invoke-BlueGreenDeployment `
    -ResourceGroup 'rg-myapp-prod' `
    -AppName 'app-myapp-prod' `
    -PackagePath './publish/app-myapp-2.2.0.zip' `
    -HealthCheckRetries 5
```

执行结果示例：

```
[10:15:32] 正在部署到 Staging 槽...
[10:15:58] 预热 Staging 槽...
[10:16:05] 健康检查失败，等待重试 (尝试 1/5)...
[10:16:25] Staging 槽健康检查通过 (尝试 2/5)
[10:16:25] 正在交换槽位...
[10:16:48] 验证生产环境...
[10:16:49] 部署完成！生产环境正常运行
```

## 多环境配置与预热验证

实际生产中，不同部署槽往往需要差异化的配置。下面的脚本展示了如何为每个槽配置独立的应用设置、连接字符串，并在部署前执行完整的预热验证流程。

```powershell
# 定义各槽的差异化配置
$SlotConfigs = @{
    staging = @{
        AppSettings = @{
            ASPNETCORE_ENVIRONMENT = 'Staging'
            APP_VERSION            = '2.2.0'
            API_ENDPOINT           = 'https://api-staging.example.com'
            LOG_LEVEL              = 'Debug'
            FEATURE_FLAGS          = '{"NewDashboard":true,"BetaAPI":true}'
        }
        ConnectionStrings = @{
            DefaultConnection = 'Server=tcp:staging-sql.database.windows.net,1433;Database=myapp_staging;'
            RedisCache        = 'staging-redis.redis.cache.windows.net:6380,abortConnect=False'
        }
    }
    production = @{
        AppSettings = @{
            ASPNETCORE_ENVIRONMENT = 'Production'
            APP_VERSION            = '2.2.0'
            API_ENDPOINT           = 'https://api.example.com'
            LOG_LEVEL              = 'Warning'
            FEATURE_FLAGS          = '{"NewDashboard":false,"BetaAPI":false}'
        }
        ConnectionStrings = @{
            DefaultConnection = 'Server=tcp:prod-sql.database.windows.net,1433;Database=myapp_prod;'
            RedisCache        = 'prod-redis.redis.cache.windows.net:6380,abortConnect=False'
        }
    }
}

$ResourceGroup = 'rg-myapp-prod'
$AppName = 'app-myapp-prod'

# 应用 Staging 槽的独立配置
$StagingSlot = Get-AzWebAppSlot -ResourceGroupName $ResourceGroup -Name $AppName -Slot 'staging'

# 设置"槽位粘性"配置（不随槽交换而移动的设置）
$SlotSettingNames = @('ASPNETCORE_ENVIRONMENT', 'API_ENDPOINT', 'LOG_LEVEL', 'FEATURE_FLAGS')
$appSettingsList = @()
foreach ($Key in $SlotConfigs.staging.AppSettings.Keys) {
    $appSettingsList += @{
        Name  = $Key
        Value = $SlotConfigs.staging.AppSettings[$Key]
    }
}

Set-AzWebAppSlot `
    -ResourceGroupName $ResourceGroup `
    -Name $AppName `
    -Slot 'staging' `
    -AppSettings $appSettingsList

# 部署前预热验证：检查关键页面和 API 端点
$StagingBaseUrl = "https://$AppName-staging.azurewebsites.net"
$Endpoints = @(
    @{ Name = '健康检查';   Path = '/health' },
    @{ Name = '就绪检查';   Path = '/health/ready' },
    @{ Name = '首页';       Path = '/' },
    @{ Name = 'API 版本';   Path = '/api/version' }
)

Write-Host "`n=== Staging 槽预热验证 ===" -ForegroundColor Cyan
$AllPassed = $true
foreach ($Endpoint in $Endpoints) {
    $Url = "$StagingBaseUrl$($Endpoint.Path)"
    try {
        $Response = Invoke-WebRequest -Uri $Url -TimeoutSec 15 -UseBasicParsing
        $Status = if ($Response.StatusCode -eq 200) { 'PASS' } else { "WARN ($($Response.StatusCode))" }
        $Color = if ($Response.StatusCode -eq 200) { 'Green' } else { 'Yellow' }
    } catch {
        $Status = "FAIL ($($_.Exception.Message.Split([Environment]::NewLine)[0]))"
        $Color = 'Red'
        $AllPassed = $false
    }
    Write-Host "  [$Status] $($Endpoint.Name) ($($Endpoint.Path))" -ForegroundColor $Color
}

if ($AllPassed) {
    Write-Host "`n所有端点验证通过，可以安全地进行槽位交换。" -ForegroundColor Green
} else {
    Write-Host "`n存在验证失败的端点，请检查后再部署！" -ForegroundColor Red
}
```

执行结果示例：

```
=== Staging 槽预热验证 ===
  [PASS] 健康检查 (/health)
  [PASS] 就绪检查 (/health/ready)
  [PASS] 首页 (/)
  [PASS] API 版本 (/api/version)

所有端点验证通过，可以安全地进行槽位交换。
```

## 注意事项

- **槽位数量限制**：不同定价 tier 支持的部署槽数量不同。免费（F1）和共享（D1）层不支持部署槽；基本（B1）层最多 1 个槽；标准（S1）及以上最多 5 个槽；高级（P1v3）和隔离（I1）层最多 20 个槽。规划槽位时要提前确认 tier 配额。
- **槽位粘性设置**：标记为"槽位设置"（Slot Setting）的应用配置和连接字符串不会随槽位交换而移动。务必将环境相关的配置（如数据库连接字符串、外部 API 地址）设为槽位粘性，避免交换后生产环境连接到测试资源。
- **预热冷却时间**：槽位交换并非瞬间完成，Azure 需要执行文件同步、配置应用和实例预热。对于大型应用，整个过程可能需要 1-3 分钟。在此期间不建议执行连续多次交换。
- **自动交换**：可以通过 `Set-AzWebAppSlot` 的 `-AutoSwapSlotName` 参数启用自动交换。当新代码推送到 Staging 槽并完成预热后，Azure 会自动将其交换到生产槽。但建议在稳定的 CI/CD 流水线中使用，手动场景下保持关闭。
- **回滚策略**：槽位交换后，旧的生产版本会保留在 Staging 槽中。如果发现问题，只需再次交换即可回滚。但如果在交换后又向 Staging 槽部署了新版本，旧版本将被覆盖，回滚窗口关闭。建议在交换后至少保留旧版本 30 分钟再进行下一次部署。
- **VNet 集成**：如果应用使用了 VNet 集成，交换时务必设置 `preserveVnet = $true`，否则 VNet 配置会被重置，导致应用无法访问内部资源。这一点在使用私有端点（Private Endpoint）连接数据库时尤为重要。
