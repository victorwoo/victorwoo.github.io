---
layout: post
date: 2025-12-26 08:00:00
updated: 2025-12-26 08:00:00
title: "PowerShell 技能连载 - Azure Functions 无服务器自动化"
description: PowerTip of the Day - Azure Functions Serverless Automation in PowerShell
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
- azure
- scripting
- cloud
---

_适用于 PowerShell 7.0 及以上版本_

在传统运维模式中，自动化脚本通常运行在虚拟机或容器上，无论脚本是否执行，底层计算资源都在持续消耗成本。对于定时清理、事件响应、API 集成等轻量级任务来说，这种模式既浪费资源又增加了运维负担——你不仅要维护脚本本身，还要操心服务器的补丁更新、高可用和扩缩容。

Azure Functions 是微软 Azure 提供的无服务器（Serverless）计算平台，支持使用 PowerShell 作为运行时语言。函数只在被事件触发时才执行，按实际运行时间和调用次数计费，空闲时不产生任何费用。PowerShell 运行时内置了 Az 模块和大量常用 cmdlet，让你可以直接在云端编写和运行自动化逻辑，无需自行管理基础设施。

本文将从三个实战场景出发：搭建 Azure Functions PowerShell 项目并编写 HTTP 触发器函数、使用定时触发器和队列触发器处理周期性与事件驱动任务，以及部署、监控与错误处理的最佳实践。

<!-- more -->

## 项目结构与 HTTP 触发器函数

Azure Functions PowerShell 项目有固定的目录结构。`function.json` 定义触发器绑定，`run.ps1` 是入口脚本。以下示例展示如何使用命令行工具初始化项目，并编写一个接收 HTTP 请求、查询 Azure 资源状态的 HTTP 触发器函数。

```powershell
# 安装 Azure Functions Core Tools（如尚未安装）
# macOS / Linux:
# curl https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > microsoft.gpg
# sudo mv microsoft.gpg /etc/apt/trusted.gpg.d/microsoft.gpg
# npm install -g azure-functions-core-tools@4 --unsafe-perm true

# Windows:
# winget install Microsoft.AzureFunctionsCoreTools

# 创建函数项目
func init PsFuncDemo --worker-runtime powershell --managed-dependencies

# 进入项目目录，创建 HTTP 触发器函数
Set-Location PsFuncDemo
func new --name Get-ResourceStatus --template "HTTP trigger" --authlevel "function"

# 查看生成的项目结构
Get-ChildItem -Recurse |
    Where-Object { -not $_.PSIsContainer } |
    Select-Object FullName |
    Format-Table -AutoSize
```

生成的项目中，`Get-ResourceStatus/run.ps1` 是函数入口，`Get-ResourceStatus/function.json` 定义绑定。下面我们来改造 `run.ps1`，实现一个查询 Azure 资源组状态的 API。

```powershell
# Get-ResourceStatus/run.ps1 的内容
# 注意：以下内容应替换到 run.ps1 文件中

using namespace System.Net

param($Request, $TriggerMetadata)

# 从查询参数中获取资源组名称
$ResourceGroupName = $Request.Query.ResourceGroup
if (-not $ResourceGroupName) {
    $ResourceGroupName = $Request.Body.ResourceGroup
}

# 如果未指定资源组，返回用法说明
if (-not $ResourceGroupName) {
    Push-OutputBinding -Name Response -Value (
        [HttpResponseContext]@{
            StatusCode = [HttpStatusCode]::BadRequest
            Body       = @{
                error = "请提供 ResourceGroup 参数"
                usage = "GET /api/Get-ResourceStatus?ResourceGroup=<名称>"
            }
        }
    )
    return
}

try {
    # 使用托管标识连接 Azure（Azure Functions 默认支持）
    Connect-AzAccount -Identity -ErrorAction Stop | Out-Null

    # 查询资源组信息
    $rg = Get-AzResourceGroup -Name $ResourceGroupName -ErrorAction Stop

    # 获取该资源组下的资源列表
    $resources = Get-AzResource -ResourceGroupName $ResourceGroupName |
        Select-Object Name, ResourceType, Location, Tags

    # 构造响应
    $result = @{
        status          = 'success'
        resourceGroup   = $rg.ResourceGroupName
        location        = $rg.Location
        provisioning    = $rg.ProvisioningState
        resourceCount   = $resources.Count
        resources       = $resources
        queriedAt       = (Get-Date).ToString('yyyy-MM-ddTHH:mm:ssZ')
    }

    Push-OutputBinding -Name Response -Value (
        [HttpResponseContext]@{
            StatusCode = [HttpStatusCode]::OK
            Body       = $result
        }
    )
}
catch {
    Push-OutputBinding -Name Response -Value (
        [HttpResponseContext]@{
            StatusCode = [HttpStatusCode]::InternalServerError
            Body       = @{
                status = 'error'
                error  = $_.Exception.Message
            }
        }
    )
}
```

以下是 `function.json` 的绑定配置：

```json
{
  "bindings": [
    {
      "authLevel": "function",
      "type": "httpTrigger",
      "direction": "in",
      "name": "Request",
      "methods": ["get", "post"]
    },
    {
      "type": "http",
      "direction": "out",
      "name": "Response"
    }
  ]
}
```

执行结果示例：

```
# 项目目录结构
FullName
--------
/Users/demo/PsFuncDemo/.gitignore
/Users/demo/PsFuncDemo/host.json
/Users/demo/PsFuncDemo/local.settings.json
/Users/demo/PsFuncDemo/requirements.psd1
/Users/demo/PsFuncDemo/profile.ps1
/Users/demo/PsFuncDemo/extensions.csproj
/Users/demo/PsFuncDemo/Get-ResourceStatus/run.ps1
/Users/demo/PsFuncDemo/Get-ResourceStatus/function.json

# 本地测试调用 func start 后，curl 触发函数
# curl "http://localhost:7071/api/Get-ResourceStatus?ResourceGroup=rg-demo"

HTTP/1.1 200 OK
Content-Type: application/json

{
  "status": "success",
  "resourceGroup": "rg-demo",
  "location": "eastasia",
  "provisioning": "Succeeded",
  "resourceCount": 5,
  "resources": [
    {
      "Name": "vm-web-01",
      "ResourceType": "Microsoft.Compute/virtualMachines",
      "Location": "eastasia",
      "Tags": { "env": "production" }
    },
    ...
  ],
  "queriedAt": "2025-12-26T08:30:15Z"
}
```

## 定时触发器与队列触发器

除了 HTTP 触发器，Azure Functions 还支持定时触发器（Timer Trigger）和队列触发器（Queue Trigger），分别用于周期性任务和消息驱动的异步处理。以下示例分别创建一个每天凌晨执行的资源清理函数和一个监听存储队列的自动处理函数。

```powershell
# 创建定时触发器函数 —— 每天 UTC 2:00 执行资源清理
func new --name Daily-Cleanup --template "Timer trigger"

# Daily-Cleanup/function.json 的 cron 表达式
# "0 0 2 * * *" 表示每天 UTC 凌晨 2 点
```

`Daily-Cleanup/function.json` 配置：

```json
{
  "bindings": [
    {
      "name": "Timer",
      "type": "timerTrigger",
      "direction": "in",
      "schedule": "0 0 2 * * *"
    }
  ]
}
```

`Daily-Cleanup/run.ps1` 内容：

```powershell
# Daily-Cleanup/run.ps1
param($Timer, $TriggerMetadata)

# 记录任务开始
$startTime = Get-Date
Write-Host "[$startTime] 每日清理任务启动"

# 连接 Azure（使用托管标识）
Connect-AzAccount -Identity | Out-Null

# 1. 清理超过 30 天未使用的快照
$cutoffDate = (Get-Date).AddDays(-30)
$snapshots = Get-AzSnapshot |
    Where-Object { $_.TimeCreated -lt $cutoffDate }

$cleanedCount = 0
foreach ($snapshot in $snapshots) {
    Write-Host "删除过期快照: $($snapshot.Name) (创建于 $($snapshot.TimeCreated))"
    Remove-AzSnapshot -ResourceGroupName $snapshot.ResourceGroupName `
        -SnapshotName $snapshot.Name -Force
    $cleanedCount++
}

# 2. 清理空的资源组
$emptyGroups = Get-AzResourceGroup | Where-Object {
    $resources = Get-AzResource -ResourceGroupName $_.ResourceGroupName
    $resources.Count -eq 0 -and
    $_.ResourceGroupName -notmatch '^rg-shared-|^rg-network-'
}

$removedGroups = 0
foreach ($group in $emptyGroups) {
    Write-Host "删除空资源组: $($group.ResourceGroupName)"
    Remove-AzResourceGroup -Name $group.ResourceGroupName -Force
    $removedGroups++
}

# 3. 汇总输出
$duration = ((Get-Date) - $startTime).ToString('hh\:mm\:ss')
Write-Host "清理完成。删除快照: $cleanedCount 个，删除空资源组: $removedGroups 个，耗时: $duration"
```

接下来创建队列触发器函数：

```powershell
# 创建队列触发器函数 —— 监听存储队列处理消息
func new --name Process-QueueMessage --template "Azure Queue Storage trigger"
```

`Process-QueueMessage/function.json` 配置：

```json
{
  "bindings": [
    {
      "name": "QueueItem",
      "type": "queueTrigger",
      "direction": "in",
      "queueName": "automation-tasks",
      "connection": "AzureWebJobsStorage"
    }
  ]
}
```

`Process-QueueMessage/run.ps1` 内容：

```powershell
# Process-QueueMessage/run.ps1
param($QueueItem, $TriggerMetadata)

# 队列消息为 JSON 格式，解析操作指令
$message = $QueueItem | ConvertFrom-Json
Write-Host "收到队列消息，操作类型: $($message.action)"

switch ($message.action) {
    'restart-vm' {
        Write-Host "重启虚拟机: $($message.vmName) in $($message.resourceGroup)"
        Connect-AzAccount -Identity | Out-Null
        Restart-AzVM -ResourceGroupName $message.resourceGroup `
            -Name $message.vmName -NoWait
        Write-Host "已发送重启指令"
    }

    'scale-webapp' {
        Write-Host "调整 Web 应用规模: $($message.appName) -> $($message.tier)"
        Connect-AzAccount -Identity | Out-Null
        $app = Get-AzWebApp -ResourceGroupName $message.resourceGroup `
            -Name $message.appName
        $app.ServerFarmId = $message.newPlanId
        Set-AzWebApp -WebApp $app | Out-Null
        Write-Host "Web 应用规模已调整"
    }

    'send-notification' {
        Write-Host "发送通知: $($message.subject)"
        $body = @{
            title   = $message.subject
            message = $message.body
            channel = $message.channel
        } | ConvertTo-Json -Compress

        Invoke-RestMethod -Uri $message.webhookUrl `
            -Method Post `
            -Body $body `
            -ContentType 'application/json'
        Write-Host "通知已发送"
    }

    default {
        Write-Warning "未知的操作类型: $($message.action)"
    }
}
```

执行结果示例：

```
# 定时清理任务日志
[12/26/2025 02:00:00] 每日清理任务启动
[12/26/2025 02:00:01] 删除过期快照: snap-backup-20251120 (创建于 11/20/2025)
[12/26/2025 02:00:03] 删除过期快照: snap-backup-20251115 (创建于 11/15/2025)
[12/26/2025 02:00:04] 删除过期快照: snap-backup-20251110 (创建于 11/10/2025)
[12/26/2025 02:00:05] 删除空资源组: rg-test-deploy-20251201
[12/26/2025 02:00:07] 清理完成。删除快照: 3 个，删除空资源组: 1 个，耗时: 00:00:07

# 队列触发器处理日志
收到队列消息，操作类型: restart-vm
重启虚拟机: vm-api-02 in rg-production
已发送重启指令

收到队列消息，操作类型: send-notification
发送通知: 扩容完成通知
通知已发送

收到队列消息，操作类型: unknown-action
警告: 未知的操作类型: unknown-action
```

## 部署、监控与错误处理最佳实践

函数开发完成后，需要部署到 Azure 并建立完善的监控和错误处理机制。以下脚本展示了使用 PowerShell 完成函数应用的创建、代码部署、日志查询以及结构化错误处理的完整流程。

```powershell
# --- 部署 Azure Functions ---

$ResourceGroup = 'rg-func-demo'
$Location = 'eastasia'
$FuncAppName = 'func-ps-automation-2025'
$StorageAccount = "stpsfunc$(Get-Random -Maximum 9999)"

# 1. 创建基础设施
New-AzResourceGroup -Name $ResourceGroup -Location $Location -Force

# 创建存储账户（Functions 运行必需）
New-AzStorageAccount `
    -ResourceGroupName $ResourceGroup `
    -Name $StorageAccount `
    -Location $Location `
    -SkuName Standard_LRS `
    -Kind StorageV2

# 创建函数应用（PowerShell 运行时）
$plan = New-AzAppServicePlan `
    -ResourceGroupName $ResourceGroup `
    -Name "$FuncAppName-plan" `
    -Location $Location `
    -Tier Consumption `
    -NumberofWorkers 1

New-AzFunctionApp `
    -ResourceGroupName $ResourceGroup `
    -Name $FuncAppName `
    -StorageAccountName $StorageAccount `
    -Runtime PowerShell `
    -RuntimeVersion '7.4' `
    -PlanName $plan.ServerFarmName `
    -FunctionsVersion 4 `
    -ManagedIdentity SystemAssigned

# 为函数应用授予所需 RBAC 权限（如 Reader 角色）
$identity = Get-AzWebApp -ResourceGroupName $ResourceGroup -Name $FuncAppName
$principalId = $identity.Identity.PrincipalId
New-AzRoleAssignment `
    -ObjectId $principalId `
    -RoleDefinitionName 'Reader' `
    -Scope "/subscriptions/$((Get-AzContext).Subscription.Id)"

# 2. 部署函数代码
Publish-AzWebApp `
    -ResourceGroupName $ResourceGroup `
    -Name $FuncAppName `
    -ArchivePath (Resolve-Path './PsFuncDemo.zip')

Write-Host "函数应用已部署: $FuncAppName"

# --- 监控与日志查询 ---

# 查询函数应用最近 1 小时的执行日志
$query = @"
AppTraces
| where AppRoleName == '$FuncAppName'
| where TimeGenerated > ago(1h)
| project TimeGenerated, MessageSeverity, Message
| order by TimeGenerated desc
"@

$results = Invoke-AzOperationalInsightsQuery `
    -WorkspaceId $env:LOG_ANALYTICS_WORKSPACE_ID `
    -Query $query

$results.Results | Format-Table -AutoSize

# 获取函数应用的执行统计
$stats = Get-AzFunctionApp `
    -ResourceGroupName $ResourceGroup `
    -Name $FuncAppName

Write-Host "函数应用状态: $($stats.State)"
Write-Host "运行时版本: $($stats.SiteConfig.PowerShellVersion)"
```

接下来在函数代码中加入结构化错误处理和重试逻辑。以下是 `profile.ps1` 中的全局错误处理配置，以及一个带重试机制的辅助函数：

```powershell
# profile.ps1 —— 函数应用启动时自动加载
# 全局错误处理：将错误写入 Application Insights
$ErrorActionPreference = 'Stop'

# 注册全局异常处理
$ExecutionContext.SessionState.Module.OnRemove = {
    Write-Host "函数执行结束，清理资源"
}

# 带重试机制的辅助函数
function Invoke-WithRetry {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [scriptblock]$ScriptBlock,

        [int]$MaxRetries = 3,
        [int]$DelaySeconds = 5,
        [string]$OperationName = '操作'
    )

    $attempt = 0
    while ($attempt -lt $MaxRetries) {
        $attempt++
        try {
            $result = & $ScriptBlock
            Write-Host "[$OperationName] 第 $attempt 次尝试成功"
            return $result
        }
        catch {
            $errorMessage = $_.Exception.Message
            Write-Warning "[$OperationName] 第 $attempt 次尝试失败: $errorMessage"

            if ($attempt -ge $MaxRetries) {
                Write-Error "[$OperationName] 已达最大重试次数 ($MaxRetries)，操作失败"
                throw
            }

            # 指数退避
            $waitTime = $DelaySeconds * [Math]::Pow(2, $attempt - 1)
            Write-Host "等待 $waitTime 秒后重试..."
            Start-Sleep -Seconds $waitTime
        }
    }
}

# 使用示例：在 run.ps1 中调用
# Invoke-WithRetry -OperationName '查询资源组' -ScriptBlock {
#     Get-AzResourceGroup -Name 'rg-production'
# }
```

执行结果示例：

```
# 部署输出
ResourceGroupName : rg-func-demo
Location          : eastasia
ProvisioningState : Succeeded

StorageAccountName  : stpsfunc4821
Kind                : StorageV2
Sku                 : Standard_LRS

Name              : func-ps-automation-2025
State             : Running
Runtime           : PowerShell
RuntimeVersion    : 7.4
FunctionsVersion  : 4
ManagedIdentity   : SystemAssigned

函数应用已部署: func-ps-automation-2025

# 日志查询结果
TimeGenerated               MessageSeverity Message
--------------               --------------- -------
2025-12-26T02:00:07Z         Information     清理完成。删除快照: 3 个，删除空资源组: 1 个，耗时: 00:00:07
2025-12-26T02:00:05Z         Information     删除空资源组: rg-test-deploy-20251201
2025-12-26T02:00:03Z         Information     删除过期快照: snap-backup-20251120 (创建于 11/20/2025)
2025-12-26T01:30:12Z         Information     收到队列消息，操作类型: restart-vm

# 函数应用状态
函数应用状态: Running
运行时版本: 7.4

# 重试辅助函数执行日志
[查询资源组] 第 1 次尝试失败: Resource group 'rg-production' not found.
等待 5 秒后重试...
[查询资源组] 第 2 次尝试失败: Resource group 'rg-production' not found.
等待 10 秒后重试...
[查询资源组] 第 3 次尝试成功
```

## 注意事项

1. **使用 Consumption 计划控制成本**：开发和测试阶段使用 Consumption（消耗量）计划，按实际执行时间和调用次数计费，空闲时不收费。只有当函数需要长时间运行（超过 10 分钟）或需要稳定的低延迟响应时，才考虑升级到 Premium 计划。

2. **启用托管标识替代密钥认证**：为函数应用开启系统分配的托管标识，并通过 RBAC 授予最小权限。这比在应用设置中存储服务主体密钥更安全，也避免了密钥轮换的运维负担。

3. **注意冷启动影响**：Consumption 计划的函数在长时间空闲后会经历冷启动（Cold Start），首次调用响应时间可能较长。对于对延迟敏感的场景，可以在 `host.json` 中配置 `minimumConcurrency` 或使用 Premium 计划保持常驻实例。

4. **利用 `requirements.psd1` 管理模块依赖**：PowerShell Functions 的模块依赖在 `requirements.psd1` 中声明，部署时会自动安装。不要在 `run.ps1` 中使用 `Install-Module`，这不仅会增加冷启动时间，还可能因网络问题导致函数启动失败。

5. **为队列触发器实现幂等处理**：队列消息可能被重复投递（至少一次语义），因此队列触发器函数必须具备幂等性。处理逻辑应先检查目标状态是否已经符合预期，避免重复执行产生副作用（如重复发送通知、重复创建资源）。

6. **配置 Application Insights 收集运行日志**：创建函数应用时务必关联 Application Insights 资源，它自动采集函数执行的请求追踪、异常信息和依赖项调用。配合 Log Analytics 查询，可以快速定位线上问题并设置告警规则，实现从开发到运维的全链路可观测性。
