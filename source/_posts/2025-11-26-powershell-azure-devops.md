---
layout: post
date: 2025-11-26 08:00:00
title: "PowerShell 技能连载 - Azure DevOps 集成"
description: PowerTip of the Day - Azure DevOps Integration in PowerShell
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
- azure-devops
- devops
- pipeline
- boards
---

_适用于 PowerShell 5.1 及以上版本_

Azure DevOps 是微软提供的一站式 DevOps 平台，涵盖了 Boards（工作项跟踪）、Repos（代码仓库）、Pipelines（CI/CD 流水线）、Test Plans（测试管理）和 Artifacts（制品管理）五大核心服务。在企业级开发流程中，团队往往需要通过脚本自动化地与 Azure DevOps 交互，例如批量创建工作项、触发流水线、查询构建状态或管理代码仓库分支策略。

虽然 Azure DevOps 提供了功能完善的 Web 界面和 CLI 工具（`az devops`），但 PowerShell 凭借其强大的对象处理能力和与其他 Windows/Azure 服务的无缝集成，仍然是许多运维和开发团队的首选自动化工具。通过 Azure DevOps REST API，我们可以在 PowerShell 中完成几乎所有的平台操作，并将这些操作编排到更大的自动化工作流中。

本文将介绍如何使用 PowerShell 调用 Azure DevOps REST API，涵盖身份认证与连接管理、工作项（Work Item）的批量操作、Pipeline 的触发与状态监控，以及代码仓库的分支策略管理。每个场景都配有可直接运行的代码示例和执行结果演示。

## 准备工作：身份认证与连接封装

Azure DevOps REST API 支持多种身份认证方式，其中最常用的是 Personal Access Token（PAT）。为了在脚本中安全地使用 PAT，我们需要将认证逻辑封装成可复用的函数，避免在代码中硬编码凭据。以下代码演示了如何创建一个通用的 Azure DevOps API 调用函数。

```powershell
function Invoke-AzDevOpsApi {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Organization,

        [Parameter(Mandatory)]
        [string]$Project,

        [Parameter(Mandatory)]
        [string]$ApiPath,

        [Parameter(Mandatory)]
        [securestring]$PatToken,

        [ValidateSet('GET', 'POST', 'PATCH', 'DELETE')]
        [string]$Method = 'GET',

        [object]$Body
    )

    $base64Token = [Convert]::ToBase64String(
        [System.Text.Encoding]::ASCII.GetBytes(
            ':' + (New-Object PSCredential('user', $PatToken).GetNetworkCredential().Password)
        )
    )

    $headers = @{
        Authorization = "Basic $base64Token"
        'Content-Type' = 'application/json'
    }

    $uri = "https://dev.azure.com/$Organization/$Project/_apis$ApiPath"

    $splat = @{
        Uri     = $uri
        Headers = $headers
        Method  = $Method
    }

    if ($Body) {
        $splat.Body = ($Body | ConvertTo-Json -Depth 10)
    }

    Invoke-RestMethod @splat
}

# 从环境变量读取 PAT，避免硬编码
$pat = ConvertTo-SecureString $env:AZDO_PAT -AsPlainText -Force

# 测试连接：获取项目信息
$projectInfo = Invoke-AzDevOpsApi `
    -Organization 'mycompany' `
    -Project 'MyProject' `
    -ApiPath '?api-version=7.0' `
    -PatToken $pat

Write-Host "项目名称: $($projectInfo.name)"
Write-Host "项目描述: $($projectInfo.description)"
Write-Host "项目 ID: $($projectInfo.id)"
```

上述代码将 PAT 以 SecureString 形式传入，通过 Base64 编码生成 Basic Auth 头。`Invoke-AzDevOpsApi` 函数封装了 URI 拼接和请求发送逻辑，后续所有示例都基于此函数调用。

执行结果示例：

```
项目名称: MyProject
项目描述: 核心业务系统开发项目
项目 ID: a1b2c3d4-e5f6-7890-abcd-ef1234567890
```

## 批量创建与查询工作项

Azure DevOps Boards 中的工作项（Work Item）是项目管理的基础单元。当需要从外部系统同步需求、批量创建测试任务或在 Sprint 规划时一次性添加多个用户故事时，手动操作效率极低。以下代码展示了如何批量创建工作项并查询特定条件的工作项列表。

```powershell
# 批量创建用户故事（User Story）
$stories = @(
    @{ Title = '实现用户登录 API 接口'; Priority = 1 },
    @{ Title = '添加 OAuth2.0 第三方登录支持'; Priority = 2 },
    @{ Title = '实现登录失败次数限制策略'; Priority = 3 }
)

foreach ($story in $stories) {
    $body = @(
        @{
            op    = 'add'
            path  = '/fields/System.Title'
            value = $story.Title
        },
        @{
            op    = 'add'
            path  = '/fields/Microsoft.VSTS.Common.Priority'
            value = $story.Priority
        }
    )

    $result = Invoke-AzDevOpsApi `
        -Organization 'mycompany' `
        -Project 'MyProject' `
        -ApiPath '/wit/workitems/$User Story?api-version=7.0' `
        -Method POST `
        -PatToken $pat `
        -Body $body

    Write-Host "已创建工作项 #$($result.id) - $($result.fields.'System.Title')"
}

# 查询当前迭代中所有未关闭的 Bug
$wiql = @{
    query = "SELECT [System.Id], [System.Title], [System.State], [System.AssignedTo] `
             FROM WorkItems `
             WHERE [System.WorkItemType] = 'Bug' `
             AND [System.State] <> 'Closed' `
             AND [System.IterationPath] = @currentIteration() `
             ORDER BY [System.CreatedDate] DESC"
}

$queryResult = Invoke-AzDevOpsApi `
    -Organization 'mycompany' `
    -Project 'MyProject' `
    -ApiPath '/wit/wiql?api-version=7.0' `
    -Method POST `
    -PatToken $pat `
    -Body $wiql

$workItemIds = $queryResult.workItems | Select-Object -ExpandProperty id
Write-Host "当前迭代中未关闭的 Bug 数量: $($workItemIds.Count)"
```

Azure DevOps 创建工作项使用 JSON Patch 格式（`op: add`），通过 `path` 指定要设置的字段。WIQL（Work Item Query Language）是类似 SQL 的查询语言，`@currentIteration()` 函数可以自动定位当前冲刺周期。使用 `foreach` 循环逐条创建可以清晰地在输出中追踪每条记录的创建结果。

执行结果示例：

```
已创建工作项 #1247 - 实现用户登录 API 接口
已创建工作项 #1248 - 添加 OAuth2.0 第三方登录支持
已创建工作项 #1249 - 实现登录失败次数限制策略
当前迭代中未关闭的 Bug 数量: 8
```

## 触发 Pipeline 并监控构建状态

在持续集成/持续部署（CI/CD）流程中，有时需要通过脚本手动触发 Pipeline，例如在完成数据迁移后触发部署流水线，或按需触发特定的测试流水线。以下代码演示了如何触发 Pipeline 构建，并以轮询方式等待构建完成。

```powershell
# 触发 Pipeline 构建
$buildPayload = @{
    definition = @{
        id = 42
    }
    parameters = '{"environment":"staging","runTests":true}'
}

$build = Invoke-AzDevOpsApi `
    -Organization 'mycompany' `
    -Project 'MyProject' `
    -ApiPath '/build/builds?api-version=7.0' `
    -Method POST `
    -PatToken $pat `
    -Body $buildPayload

Write-Host "已触发构建 #$($build.id)"
Write-Host "构建定义: $($build.definition.name)"
Write-Host "初始状态: $($build.status)"
Write-Host "队列时间: $($build.queueTime)"

# 轮询构建状态直到完成
$buildId = $build.id
$maxRetries = 60
$retryCount = 0

while ($retryCount -lt $maxRetries) {
    Start-Sleep -Seconds 30

    $status = Invoke-AzDevOpsApi `
        -Organization 'mycompany' `
        -Project 'MyProject' `
        -ApiPath "/build/builds/$buildId`?api-version=7.0" `
        -PatToken $pat

    Write-Host "[$($retryCount + 1)] 构建 #$buildId 状态: $($status.status) - $($status.result)"

    if ($status.status -eq 'completed') {
        Write-Host "`n构建完成! 最终结果: $($status.result)"
        Write-Host "开始时间: $($status.startTime)"
        Write-Host "完成时间: $($status.finishTime)"

        $duration = [datetime]::Parse($status.finishTime) - [datetime]::Parse($status.startTime)
        Write-Host "耗时: $($duration.TotalMinutes.ToString('F1')) 分钟"
        break
    }

    $retryCount++
}

if ($retryCount -ge $maxRetries) {
    Write-Warning "等待超时，构建 #$buildId 仍未完成，请手动检查。"
}
```

这段代码首先通过 POST 请求触发指定 ID 的 Pipeline 定义，同时传递模板参数（`environment` 和 `runTests`）。触发成功后进入轮询循环，每 30 秒查询一次构建状态，直到状态变为 `completed` 或达到最大重试次数。循环结束时计算并输出构建耗时，方便排查流水线性能问题。

执行结果示例：

```
已触发构建 #3891
构建定义: MyProject-CI
初始状态: inProgress
队列时间: 2025-11-26T02:15:33.287Z
[1] 构建 #3891 状态: inProgress -
[2] 构建 #3891 状态: inProgress -
[3] 构建 #3891 状态: inProgress -
[4] 构建 #3891 状态: completed - succeeded

构建完成! 最终结果: succeeded
开始时间: 2025-11-26T02:15:38.412Z
完成时间: 2025-11-26T02:17:45.891Z
耗时: 2.1 分钟
```

## 管理代码仓库分支策略

分支策略（Branch Policy）是保障代码质量的重要手段。在团队协作中，通常要求所有代码变更通过 Pull Request 提交，并设置最低审核人数、构建验证和合并策略。以下代码演示了如何通过 PowerShell 为仓库分支配置分支策略。

```powershell
# 获取仓库 ID
$repo = Invoke-AzDevOpsApi `
    -Organization 'mycompany' `
    -Project 'MyProject' `
    -ApiPath '/git/repositories?api-version=7.0' `
    -PatToken $pat

$targetRepo = $repo.value | Where-Object { $_.name -eq 'MyApp' }
Write-Host "目标仓库: $($targetRepo.name) (ID: $($targetRepo.id))"

# 获取默认分支的 ref
$defaultBranch = $targetRepo.defaultBranch
Write-Host "默认分支: $defaultBranch"

# 获取分支策略配置列表
$policyConfigurations = Invoke-AzDevOpsApi `
    -Organization 'mycompany' `
    -Project 'MyProject' `
    -ApiPath '/policy/configurations?api-version=7.0' `
    -PatToken $pat

# 统计当前项目的策略数量
$enabledPolicies = @($policyConfigurations.value | Where-Object { $_.isEnabled -eq $true })
Write-Host "当前项目已启用的策略数量: $($enabledPolicies.Count)"

# 为 main 分支创建"最少审核人数"策略
$minReviewersPolicy = @{
    isEnabled = $true
    isBlocking = $true
    type = @{
        id = 'fa4e907d-c16b-4a4c-90b4-75ae827c5881'
    }
    settings = @{
        minimumApproverCount = 2
        creatorVoteCounts = $false
        scope = @(
            @{
                refName = $defaultBranch
                matchKind = 'exact'
                repositoryId = $targetRepo.id
            }
        )
    }
}

$newPolicy = Invoke-AzDevOpsApi `
    -Organization 'mycompany' `
    -Project 'MyProject' `
    -ApiPath '/policy/configurations?api-version=7.0' `
    -Method POST `
    -PatToken $pat `
    -Body $minReviewersPolicy

Write-Host "已创建策略: 最低审核人数 = 2"
Write-Host "策略 ID: $($newPolicy.id)"
Write-Host "是否阻断: $($newPolicy.isBlocking)"
```

分支策略的类型通过 GUID 标识。`fa4e907d-c16b-4a4c-90b4-75ae828c5881` 代表"最少审核人数"策略类型。`isBlocking = $true` 表示不满足策略要求时无法合并 Pull Request。`creatorVoteCounts = $false` 确保创建者自身的审核不计入最低审核人数。通过脚本配置策略，可以确保新仓库的分支保护规则与团队规范一致。

执行结果示例：

```
目标仓库: MyApp (ID: abc12345-6789-def0-1234-567890abcdef)
默认分支: refs/heads/main
当前项目已启用的策略数量: 5
已创建策略: 最低审核人数 = 2
策略 ID: 9876abcd-5432-10fe-dc98-76543210fedc
是否阻断: True
```

## 注意事项

- **PAT 安全管理**：切勿将 Personal Access Token 硬编码在脚本中。推荐从环境变量（`$env:AZDO_PAT`）或 Azure Key Vault 中读取，并在 CI/CD 流水线中使用变量组（Variable Group）的机密引用功能。
- **API 版本控制**：Azure DevOps REST API 要求在每次请求中指定 `api-version` 参数。建议在生产脚本中固定使用某个已验证的版本号（如 `7.0`、`7.1`），避免因 API 升级导致脚本行为变化。
- **请求频率限制**：Azure DevOps 对 REST API 调用有频率限制（通常为每小时 6000 次，具体取决于组织规模）。批量操作时建议在循环中添加适当延时（如 `Start-Sleep -Milliseconds 200`），或在遇到 429 状态码时实现指数退避重试。
- **JSON Patch 格式差异**：创建工作项使用 JSON Patch 数组格式（`op: add`），而更新工作项也使用同一格式但允许 `op: replace`、`op: remove` 等操作。注意这与常规 REST API 的 PUT/PATCH JSON body 格式不同，混淆两者是常见的调试陷阱。
- **错误处理**：`Invoke-RestMethod` 默认在遇到非 2xx 状态码时抛出异常。建议在调用外层包裹 `try/catch` 块，并通过 `$_.Exception.Response` 获取详细的错误响应内容，便于定位问题。
- **跨平台兼容性**：如果需要在 PowerShell 7+ 的 Linux/macOS 环境中运行，注意 `ConvertTo-SecureString` 在非 Windows 平台上的行为差异。推荐使用跨平台兼容的凭据管理方式，例如直接通过 `Invoke-RestMethod` 的 `-Authentication Bearer` 参数传递令牌。
