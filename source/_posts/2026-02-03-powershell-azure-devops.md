---
layout: post
date: 2026-02-03 08:00:00
updated: 2026-02-03 08:00:00
title: "PowerShell 技能连载 - Azure DevOps 自动化"
description: PowerTip of the Day - Azure DevOps Automation in PowerShell
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
- azure-devops
- cicd
- pipeline
- automation
---

_适用于 PowerShell 7.0 及以上版本_

在现代软件交付体系中，Azure DevOps 已经成为许多团队的核心协作平台。它集成了代码仓库、CI/CD 流水线、工作项追踪和制品管理等功能，为端到端的 DevOps 实践提供了完整支撑。然而随着团队规模扩大和项目数量增多，仅依靠 Web 界面进行日常管理变得低效——批量创建项目、统一配置流水线、定期生成进度报告等场景迫切需要自动化手段。

PowerShell 凭借对 REST API 的原生支持和强大的对象处理能力，是自动化管理 Azure DevOps 的理想工具。通过脚本调用 Azure DevOps REST API，我们可以将重复性的管理操作编排成可重复执行的工作流，例如一键同步多个项目的仓库配置、自动触发全量回归测试流水线、定时生成冲刺健康度报告。

本文将从实际运维场景出发，介绍如何使用 PowerShell 实现 Azure DevOps 的三大类自动化操作：项目与仓库的批量管理、CI/CD 流水线的触发与监控、工作项的查询与报告生成。每个场景都提供可直接运行的完整脚本和执行结果演示。

<!-- more -->

## Azure DevOps API 连接与项目管理

所有 Azure DevOps 自动化的基础是与 REST API 建立可靠的连接。以下代码封装了一个通用的 API 调用函数，并在此基础上实现项目的批量查询和仓库操作。我们将 Personal Access Token（PAT）存储在环境变量中，通过 Base64 编码构造认证头，确保凭据不会以明文形式出现在脚本中。

```powershell
function Invoke-AzDoRequest {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Organization,

        [string]$Project,

        [Parameter(Mandatory)]
        [string]$ApiPath,

        [Parameter(Mandatory)]
        [securestring]$PatToken,

        [ValidateSet('GET', 'POST', 'PATCH', 'PUT', 'DELETE')]
        [string]$Method = 'GET',

        [object]$Body,

        [string]$ApiVersion = '7.1'
    )

    # 将 PAT 转换为 Basic Auth 格式
    $plainPat = (New-Object PSCredential('user', $PatToken)).GetNetworkCredential().Password
    $base64Auth = [Convert]::ToBase64String(
        [System.Text.Encoding]::ASCII.GetBytes(":$plainPat")
    )

    $headers = @{
        Authorization  = "Basic $base64Auth"
        'Content-Type' = 'application/json'
    }

    # 构建请求 URI
    $uri = if ($Project) {
        "https://dev.azure.com/$Organization/$Project/_apis$ApiPath"
    } else {
        "https://dev.azure.com/$Organization/_apis$ApiPath"
    }

    # 追加 api-version 参数
    $separator = if ($uri -match '\?') { '&' } else { '?' }
    $uri = "$uri$separator`api-version=$ApiVersion"

    $params = @{
        Uri     = $uri
        Headers = $headers
        Method  = $Method
    }

    if ($Body) {
        $params.Body = ($Body | ConvertTo-Json -Depth 10 -Compress)
    }

    try {
        Invoke-RestMethod @params
    } catch {
        $statusCode = $_.Exception.Response.StatusCode.value__
        $errorReader = [System.IO.StreamReader]::new($_.Exception.Response.GetResponseStream())
        $errorBody = $errorReader.ReadToEnd()
        Write-Error "API 请求失败 [HTTP $statusCode]: $errorBody"
    }
}

# 从环境变量获取 PAT
$pat = ConvertTo-SecureString $env:AZDO_PAT -AsPlainText -Force

# 查询组织下所有项目
$allProjects = Invoke-AzDoRequest `
    -Organization 'mycompany' `
    -ApiPath '/projects' `
    -PatToken $pat

Write-Host "组织内的项目列表:"
Write-Host ("-" * 60)

foreach ($proj in $allProjects.value) {
    $lastUpdate = [datetime]::Parse($proj.lastUpdateTime).ToString('yyyy-MM-dd')
    Write-Host "  名称: $($proj.name)"
    Write-Host "  状态: $($proj.state)  |  上次更新: $lastUpdate"
    Write-Host "  ID: $($proj.id)"
    Write-Host ""
}

# 查询指定项目的所有仓库
$repos = Invoke-AzDoRequest `
    -Organization 'mycompany' `
    -Project 'PlatformService' `
    -ApiPath '/git/repositories' `
    -PatToken $pat

Write-Host "PlatformService 项目的仓库:"
foreach ($repo in $repos.value) {
    $branch = $repo.defaultBranch -replace 'refs/heads/', ''
    Write-Host "  [$($repo.name)] 默认分支: $branch, 大小: $([math]::Round($repo.size / 1MB, 1)) MB"
}
```

上述代码定义了 `Invoke-AzDoRequest` 函数，支持组织级和项目级的 API 调用。函数自动根据 URI 是否已包含查询参数来拼接 `api-version`，避免重复的 `?` 符号。错误处理部分捕获 HTTP 异常并解析响应体，便于排查 API 调用失败的原因。通过该函数可以方便地查询项目列表和仓库信息，为后续的批量管理操作奠定基础。

执行结果示例：

```
组织内的项目列表:
------------------------------------------------------------
  名称: PlatformService
  状态: wellFormed  |  上次更新: 2026-01-28
  ID: a1b2c3d4-e5f6-7890-abcd-ef1234567890

  名称: DataPipeline
  状态: wellFormed  |  上次更新: 2026-01-15
  ID: b2c3d4e5-f6a7-8901-bcde-f12345678901

  名称: MobileApp
  状态: wellFormed  |  上次更新: 2025-12-20
  ID: c3d4e5f6-a7b8-9012-cdef-123456789012

PlatformService 项目的仓库:
  [PlatformService.Api] 默认分支: main, 大小: 24.3 MB
  [PlatformService.Web] 默认分支: main, 大小: 18.7 MB
  [PlatformService.Infra] 默认分支: develop, 大小: 3.2 MB
```

## 流水线管理：触发构建与下载制品

CI/CD 流水线是 Azure DevOps 中最核心的自动化能力之一。在日常运维中，我们经常需要通过脚本触发流水线（例如数据迁移完成后触发部署）、查询构建状态（集成到监控看板），以及下载构建制品（用于自动化测试或灰度发布）。以下代码演示了这三个常见操作的完整实现。

```powershell
# --- 1. 触发流水线构建 ---

$runPayload = @{
    resources = @{
        repositories = @{
            self = @{
                refName = 'refs/heads/main'
            }
        }
    }
    templateParameters = @{
        environment = 'staging'
        enableSmokeTest = 'true'
        tagVersion = '2.4.1-rc.3'
    }
}

$newRun = Invoke-AzDoRequest `
    -Organization 'mycompany' `
    -Project 'PlatformService' `
    -ApiPath '/pipelines/42/runs' `
    -Method POST `
    -PatToken $pat `
    -Body $runPayload

Write-Host "已触发流水线运行:"
Write-Host "  运行 ID: $($newRun.id)"
Write-Host "  流水线: $($newRun.pipeline.name)"
Write-Host "  状态: $($newRun.state)"
Write-Host ""

# --- 2. 轮询构建状态直到完成 ---

$runId = $newRun.id
$maxWaitMinutes = 30
$startTime = Get-Date

while (((Get-Date) - $startTime).TotalMinutes -lt $maxWaitMinutes) {
    Start-Sleep -Seconds 20

    $runStatus = Invoke-AzDoRequest `
        -Organization 'mycompany' `
        -Project 'PlatformService' `
        -ApiPath "/pipelines/42/runs/$runId" `
        -PatToken $pat

    $elapsed = ((Get-Date) - $startTime).ToString('mm\:ss')
    Write-Host "[$elapsed] 运行 #$runId 状态: $($runStatus.state)"

    if ($runStatus.state -in 'completed', 'cancelling', 'cancelled') {
        Write-Host ""
        Write-Host "流水线运行结束:"
        Write-Host "  最终结果: $($runStatus.result)"
        Write-Host "  完成时间: $($runStatus.finishedAt)"
        break
    }
}

# --- 3. 下载构建制品 ---

if ($runStatus.result -eq 'succeeded') {
    $artifacts = Invoke-AzDoRequest `
        -Organization 'mycompany' `
        -Project 'PlatformService' `
        -ApiPath "/build/builds/$($newRun.id)/artifacts" `
        -PatToken $pat

    $downloadDir = Join-Path $HOME "Downloads/AzDo-Artifacts/$($newRun.id)"
    New-Item -ItemType Directory -Path $downloadDir -Force | Out-Null

    foreach ($artifact in $artifacts.value) {
        $downloadUrl = $artifact.resource.downloadUrl
        $fileName = "$($artifact.name).zip"
        $savePath = Join-Path $downloadDir $fileName

        Write-Host "正在下载制品: $($artifact.name) -> $savePath"
        Invoke-WebRequest -Uri $downloadUrl -Headers @{
            Authorization = "Basic $([Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes(":$plainPat")))"
        } -OutFile $savePath
    }

    Write-Host ""
    Write-Host "所有制品已下载至: $downloadDir"
    Get-ChildItem $downloadDir | ForEach-Object {
        Write-Host "  $($_.Name) ($([math]::Round($_.Length / 1KB, 1)) KB)"
    }
}
```

这段脚本按照实际运维流程编排了三个步骤：首先触发流水线并传入模板参数（目标环境、是否执行冒烟测试、版本标签），然后以 20 秒间隔轮询运行状态直到完成，最后仅在构建成功时下载所有制品到本地。轮询部分使用时间差而非固定次数，避免长时间运行的流水线被提前终止。

执行结果示例：

```
已触发流水线运行:
  运行 ID: 1847
  流水线: PlatformService-CI
  状态: inProgress

[00:20] 运行 #1847 状态: inProgress
[00:40] 运行 #1847 状态: inProgress
[01:00] 运行 #1847 状态: inProgress
[01:20] 运行 #1847 状态: inProgress
[01:40] 运行 #1847 状态: completed

流水线运行结束:
  最终结果: succeeded
  完成时间: 2026-02-03T08:23:45.123Z
正在下载制品: drop -> /Users/wubo/Downloads/AzDo-Artifacts/1847/drop.zip
正在下载制品: testResults -> /Users/wubo/Downloads/AzDo-Artifacts/1847/testResults.zip

所有制品已下载至: /Users/wubo/Downloads/AzDo-Artifacts/1847
  drop.zip (12456.3 KB)
  testResults.zip (3287.5 KB)
```

## 工作项查询与冲刺报告生成

Azure DevOps Boards 的工作项数据是团队进度和质量的直接反映。定期从 Boards 中提取数据并生成报告，可以帮助团队及时发现阻塞、评估交付速率、辅助 Sprint 回顾。以下代码使用 WIQL（Work Item Query Language）查询当前冲刺的工作项，并生成一份结构化的文本报告。

```powershell
# --- 1. 查询当前冲刺的活跃工作项 ---

$wiqlQuery = @{
    query = @"
SELECT [System.Id], [System.WorkItemType], [System.Title],
       [System.State], [System.AssignedTo],
       [Microsoft.VSTS.Scheduling.StoryPoints],
       [Microsoft.VSTS.Common.Priority]
FROM WorkItems
WHERE [System.IterationPath] = @currentIteration()
  AND [System.State] NOT IN ('Closed', 'Removed')
  AND [System.WorkItemType] IN ('User Story', 'Bug', 'Task')
ORDER BY [Microsoft.VSTS.Common.Priority] ASC
"@
}

$queryResult = Invoke-AzDoRequest `
    -Organization 'mycompany' `
    -Project 'PlatformService' `
    -ApiPath '/wit/wiql' `
    -Method POST `
    -PatToken $pat `
    -Body $wiqlQuery

Write-Host "查询到 $($queryResult.workItems.Count) 个活跃工作项"
Write-Host ""

# --- 2. 批量获取工作项详情 ---

$allIds = $queryResult.workItems | Select-Object -ExpandProperty id
$workItems = @()

# API 限制单次最多查询 200 个工作项
$idBatches = $allIds | Group-Object -Property { [math]::Floor([array]::IndexOf($allIds, $_) / 200) }

foreach ($batch in $idBatches) {
    $idList = ($batch.Group | ForEach-Object { [int]$_ }) -join ','
    $details = Invoke-AzDoRequest `
        -Organization 'mycompany' `
        -Project 'PlatformService' `
        -ApiPath "/wit/workitems?ids=$idList&`$expand=fields" `
        -PatToken $pat
    $workItems += $details.value
}

# --- 3. 生成冲刺报告 ---

Write-Host "=" * 70
Write-Host "  PlatformService - Sprint 进度报告"
Write-Host "  生成时间: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
Write-Host "=" * 70
Write-Host ""

# 按类型分组统计
$byType = $workItems | Group-Object { $_.fields.'System.WorkItemType' }

Write-Host "[按类型统计]"
foreach ($group in $byType) {
    $totalPoints = ($group.Group | ForEach-Object {
        $_.fields.'Microsoft.VSTS.Scheduling.StoryPoints'
    } | Where-Object { $_ } | Measure-Object -Sum).Sum

    $pointsStr = if ($totalPoints) { " | 故事点: $totalPoints" } else { '' }
    Write-Host "  $($group.Name): $($group.Count) 个$pointsStr"
}
Write-Host ""

# 按状态分组统计
$byState = $workItems | Group-Object { $_.fields.'System.State' }

Write-Host "[按状态统计]"
foreach ($group in $byState) {
    $pct = [math]::Round($group.Count / $workItems.Count * 100, 1)
    $bar = '#' * [math]::Floor($pct / 5)
    Write-Host "  $($group.Name): $($group.Count) 个 ($pct%) $bar"
}
Write-Host ""

# 按负责人分组统计
$byAssignee = $workItems | Group-Object {
    $assigned = $_.fields.'System.AssignedTo'
    if ($assigned) { $assigned.displayName } else { '未分配' }
} | Sort-Object Count -Descending

Write-Host "[按负责人统计]"
foreach ($group in $byAssignee) {
    Write-Host "  $($group.Name): $($group.Count) 个"
    foreach ($item in $group.Group) {
        $title = $_.fields.'System.Title'
        Write-Host "    - #$($item.id) $($item.fields.'System.Title')"
    }
}
Write-Host ""

# 阻塞项警告
$blockedItems = $workItems | Where-Object {
    $_.fields.'System.State' -eq 'Blocked' -or
    $_.fields.'System.Tags' -match 'blocked'
}

if ($blockedItems) {
    Write-Host "[警告] 存在 $($blockedItems.Count) 个阻塞项:"
    foreach ($item in $blockedItems) {
        Write-Host "  !! #$($item.id) $($item.fields.'System.Title')"
    }
}

Write-Host ""
Write-Host "=" * 70
Write-Host "  报告结束"
Write-Host "=" * 70
```

这段代码使用 WIQL 查询当前冲刺中所有活跃的工作项，然后通过批量接口获取详细字段。报告生成部分按工作项类型、状态、负责人三个维度进行分组统计，并高亮显示被阻塞的工作项。这种脚本非常适合在 Sprint Standup 会议前自动运行，或通过 CI/CD 定时任务发送到团队频道。

执行结果示例：

```
查询到 24 个活跃工作项

======================================================================
  PlatformService - Sprint 进度报告
  生成时间: 2026-02-03 08:30:15
======================================================================

[按类型统计]
  User Story: 8 个 | 故事点: 21
  Bug: 6 个
  Task: 10 个

[按状态统计]
  Active: 12 个 (50%) ##############
  New: 7 个 (29.2%) ######
  Resolved: 3 个 (12.5%) ###
  Blocked: 2 个 (8.3%) ##

[按负责人统计]
  张三: 8 个
    - #1856 用户注册接口性能优化
    - #1861 修复订单列表分页异常
  李四: 7 个
    - #1858 实现批量导出功能
    - #1863 消息推送服务重构
  王五: 5 个
    - #1859 日志采集模块升级
  未分配: 4 个
    - #1865 接入新版支付网关

[警告] 存在 2 个阻塞项:
  !! #1860 第三方认证服务证书过期
  !! #1867 等待上游团队提供接口文档

======================================================================
  报告结束
======================================================================
```

## 注意事项

- **PAT 权限范围**：创建 PAT 时需根据脚本操作范围选择最小权限集。管理项目需要 `Project (Read & Write)`，操作流水线需要 `Build (Read & Execute)`，查询工作项需要 `Work Items (Read)`。避免使用全权限 PAT，降低凭据泄露后的影响范围。
- **API 版本兼容性**：示例中使用 `api-version=7.1`。Azure DevOps REST API 有 v5.x、v6.x、v7.x 多个主版本，部分接口在不同版本间行为有差异（如流水线 Runs API 在 7.0 后引入了 `templateParameters` 字段）。生产脚本务必锁定版本号并做兼容性测试。
- **分页与批量限制**：查询类接口（如项目列表、工作项查询）默认有分页限制，通常单次返回 100-1000 条。需要检查响应中的 `continuationToken` 字段并循环获取完整数据。工作项批量查询单次上限为 200 个 ID，大批量场景需要自行分批。
- **并发与速率控制**：Azure DevOps 对同一组织的 API 调用有速率限制（个人用户约每分钟 600 次）。批量操作时建议使用 `Start-Sleep` 添加间隔，或使用 PowerShell 的 `ForEach-Object -Parallel` 配合计数器实现受控并发。
- **错误重试策略**：网络抖动和临时限流会导致偶发的 5xx 或 429 响应。建议封装通用的重试逻辑，对 429 状态码读取 `Retry-After` 响应头确定等待时间，对 5xx 状态码采用指数退避策略，最多重试 3 次。
- **敏感信息脱敏**：冲刺报告可能包含员工姓名、工作项内容等信息。如果报告需要发送到外部渠道（如邮件、Slack），注意对 `System.AssignedTo` 等字段做脱敏处理，或将报告输出到 Azure DevOps 内部的 Wiki 页面，保持访问权限的一致性。
