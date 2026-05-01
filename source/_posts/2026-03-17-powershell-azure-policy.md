---
layout: post
date: 2026-03-17 08:00:00
title: "PowerShell 技能连载 - Azure Policy 合规治理"
description: PowerTip of the Day - Azure Policy Compliance Governance in PowerShell
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
- azure
- policy
- compliance
- governance
---

_适用于 PowerShell 7.0 及以上版本_

在多团队、多订阅的云环境中，资源合规性是治理的核心难题。开发团队随手创建了一个 Premium SKU 的 Redis 缓存，费用瞬间翻了十倍；某个资源组忘了打标签，月底账单无法分摊到业务线；还有人不小心把资源部署到了不支持数据驻留的区域。这些问题在单订阅时还能人工检查，到了几十个订阅、上百个资源组的规模，靠人工审计根本忙不过来。

Azure Policy 提供了声明式的合规规则引擎，可以在资源创建或更新时自动评估是否满足预设条件。不满足条件的资源可以被审计记录、拒绝创建，甚至自动修复到合规状态。结合管理组（Management Group）的层级结构，一条策略可以向下继承到所有子订阅，真正做到"治理即代码"。

本文将演示如何通过 PowerShell 完成 Azure Policy 的三大核心操作：策略定义与管理、策略分配与范围控制、合规审计与自动修复。让你从手工巡检的时代彻底迈入自动化合规治理。

## 策略定义与管理

策略定义是合规治理的基础构建块。Azure 提供了数百个内置策略定义，覆盖了命名规范、SKU 限制、区域约束、强制标记等常见场景。当内置策略无法满足需求时，可以通过自定义策略定义来实现精确的合规规则。下面的脚本演示如何检索内置策略、创建参数化的自定义策略，并将策略组织到策略集（Initiative）中统一管理。

```powershell
# 连接 Azure
Connect-AzAccount -Subscription 'production-subscription'

# --- 检索常用内置策略定义 ---
# 查找与"允许位置"相关的内置策略
$builtInPolicies = Get-AzPolicyDefinition | Where-Object {
    $_.DisplayName -like '*allowed locations*' -or
    $_.DisplayName -like '*允许的位置*'
} | Select-Object -First 5 DisplayName, PolicyType, Name

Write-Host '=== 内置策略：允许的位置 ===' -ForegroundColor Cyan
$builtInPolicies | Format-Table -AutoSize

# 查找与"强制标记"相关的内置策略
$tagPolicies = Get-AzPolicyDefinition | Where-Object {
    $_.DisplayName -like '*tag*' -and $_.PolicyType -eq 'BuiltIn'
} | Select-Object -First 5 DisplayName, Name

Write-Host '=== 内置策略：标记相关 ===' -ForegroundColor Cyan
$tagPolicies | Format-Table -AutoSize

# --- 创建自定义策略定义：禁止创建未标记成本中心的资源 ---
$policyRule = @{
    if = @{
        allOf = @(
            @{
                field = 'type'
                notLike = 'Microsoft.Resources/*'
            }
            @{
                field = '[concat(''tags'', ''.'', ''CostCenter'')]'
                exists = 'false'
            }
        )
    }
    then = @{
        effect = 'deny'
    }
}

$policyParameters = @{
    tagName = @{
        type = 'String'
        metadata = @{
            displayName = '标记名称'
            description = '要求必须存在的标记名称'
        }
    }
}

# 使用参数化的方式构建策略规则
$parameterizedRule = @{
    if = @{
        allOf = @(
            @{
                field = 'type'
                notLike = 'Microsoft.Resources/*'
            }
            @{
                field = "[concat('tags', '.', parameters('tagName'))]"
                exists = 'false'
            }
        )
    }
    then = @{
        effect = 'deny'
    }
}

$customPolicy = New-AzPolicyDefinition `
    -Name 'require-mandatory-tag' `
    -DisplayName '要求资源必须包含指定标记' `
    -Description '拒绝创建未包含指定标记的资源，确保成本分摊和资源归属可追溯' `
    -Policy $parameterizedRule `
    -Parameter $policyParameters `
    -Mode 'Indexed'

Write-Host "自定义策略已创建: $($customPolicy.Name)" -ForegroundColor Green

# --- 创建策略集（Initiative）将多个策略打包管理 ---
$initiativeDefinition = @{
    name       = 'cost-governance-initiative'
    displayName = '成本治理策略集'
    description = '统一管理所有与成本控制相关的策略，包括标记、SKU 限制和区域约束'
    policyDefinitions = @(
        @{
            policyDefinitionId = $customPolicy.Id
            parameters = @{
                tagName = @{ value = 'CostCenter' }
            }
        }
    )
}

# 获取内置的"允许位置"策略
$locationPolicy = Get-AzPolicyDefinition |
    Where-Object { $_.Name -eq 'e56962a6-4747-49cd-b67b-bf8b01975c4c' }

if ($locationPolicy) {
    $initiativeDefinition.policyDefinitions += @{
        policyDefinitionId = $locationPolicy.Id
        parameters = @{
            listOfAllowedLocations = @{
                value = @('eastasia', 'southeastasia', 'eastus', 'westus2')
            }
        }
    }
}

$initiative = New-AzPolicySetDefinition `
    -Name $initiativeDefinition.name `
    -DisplayName $initiativeDefinition.displayName `
    -Description $initiativeDefinition.description `
    -PolicyDefinition ($initiativeDefinition.policyDefinitions | ConvertTo-Json -Depth 5)

Write-Host "策略集已创建: $($initiative.Name)" -ForegroundColor Green
```

执行结果示例：

```
=== 内置策略：允许的位置 ===
DisplayName                              PolicyType Name
-----------                              ---------- ----
允许的资源位置                            BuiltIn     e56962a6-4747-49cd-b67b-bf8b01975c4c
允许的资源组位置                          BuiltIn     e765b5de-1225-4ba3-bd56-1ac667b5e923

=== 内置策略：标记相关 ===
DisplayName                              Name
-----------                              ----
要求指定标记值                            1e30110a-5ceb-460c-a204-f92a36c51380
在资源组中添加标记                        96670d01-0a4d-4649-9c89-66d8e766f889
从资源组继承标记                          cd3aa116-7824-4a4f-820e-52c5b31d1d0e
要求资源组具有标记                        96670d01-0a4d-4649-66d8e766f889
强制添加标记及其默认值                    1e30110a-5ceb-460c-a204-f92a36c51380

自定义策略已创建: require-mandatory-tag
策略集已创建: cost-governance-initiative
```

## 策略分配与范围控制

策略定义和策略集创建完成后，需要将它们分配到特定的范围才能生效。Azure Policy 支持多层级范围分配：管理组、订阅、资源组，甚至单个资源。策略分配时可以传入参数值来覆盖默认配置，还可以设置豁免（Exemption）来排除特定资源。下面的脚本演示订阅级分配、管理组级批量分配，以及针对特定资源的豁免配置。

```powershell
# --- 订阅级策略分配 ---
$subscriptionId = (Get-AzContext).Subscription.Id
$scope = "/subscriptions/$subscriptionId"

# 获取之前创建的策略集
$initiative = Get-AzPolicySetDefinition -Name 'cost-governance-initiative'

# 创建订阅级策略分配
$assignment = New-AzPolicyAssignment `
    -Name 'cost-governance-sub' `
    -DisplayName '订阅级成本治理策略' `
    -Scope $scope `
    -PolicySetDefinition $initiative `
    -Description '在此订阅中强制执行标记要求和区域限制'

Write-Host "订阅级策略分配已创建: $($assignment.Name)" -ForegroundColor Green

# --- 资源组级策略分配（更精细的控制） ---
$rgScope = "$scope/resourceGroups/rg-production"
$skuPolicy = Get-AzPolicyDefinition |
    Where-Object { $_.DisplayName -like '*allowed resource types*' } |
    Select-Object -First 1

# 为生产环境资源组分配更严格的策略
$rgAssignment = New-AzPolicyAssignment `
    -Name 'production-sku-restriction' `
    -DisplayName '生产环境 SKU 限制' `
    -Scope $rgScope `
    -PolicyDefinition $skuPolicy `
    -Description '限制生产环境只允许创建特定资源类型'

Write-Host "资源组级策略分配已创建: $($rgAssignment.Name)" -ForegroundColor Green

# --- 管理组级批量分配（跨订阅统一治理） ---
$mgScope = '/providers/Microsoft.Management/managementGroups/mg-enterprise'

# 获取管理组下的所有订阅
$mgSubscriptions = Get-AzManagementGroupSubscription `
    -GroupName 'mg-enterprise' -Expand

Write-Host "管理组下的订阅数量: $($mgSubscriptions.Count)"

# 为管理组分配策略集，所有子订阅自动继承
$mgAssignment = New-AzPolicyAssignment `
    -Name 'enterprise-governance' `
    -DisplayName '企业级合规治理策略' `
    -Scope $mgScope `
    -PolicySetDefinition $initiative `
    -EnforcementMode 'Default'

Write-Host "管理组级策略分配已创建（子订阅将自动继承）" -ForegroundColor Green

# --- 配置策略豁免 ---
# 对特定资源（如测试环境）豁免标记策略
$exemptionScope = "$scope/resourceGroups/rg-sandbox"
$waiverAssignment = Get-AzPolicyAssignment -Name 'cost-governance-sub'

# 创建策略豁免
$exemption = New-AzPolicyExemption `
    -Name 'sandbox-tag-exemption' `
    -DisplayName '沙盒环境标记豁免' `
    -Scope $exemptionScope `
    -PolicyAssignment $waiverAssignment `
    -ExemptionCategory 'Waiver' `
    -ExpiresOn (Get-Date).AddMonths(6) `
    -Description '沙盒环境暂不强制标记要求，6个月后重新评估'

Write-Host "策略豁免已创建，有效期至: $($exemption.Properties.ExpiresOn)" -ForegroundColor Green

# --- 查看所有策略分配 ---
$allAssignments = Get-AzPolicyAssignment | Where-Object {
    $_.Scope -like "*$subscriptionId*"
} | Select-Object DisplayName, Scope, EnforcementMode

Write-Host "`n=== 当前订阅下的策略分配 ===" -ForegroundColor Cyan
$allAssignments | Format-Table -AutoSize
```

执行结果示例：

```
订阅级策略分配已创建: cost-governance-sub
资源组级策略分配已创建: production-sku-restriction
管理组下的订阅数量: 8
管理组级策略分配已创建（子订阅将自动继承）
策略豁免已创建，有效期至: 2026-09-17

=== 当前订阅下的策略分配 ===
DisplayName                     Scope                                                         EnforcementMode
-----------                     -----                                                         ---------------
订阅级成本治理策略               /subscriptions/xxxx-xxxx-xxxx                                 Default
生产环境 SKU 限制               /subscriptions/xxxx-xxxx/.../rg-production                    Default
企业级合规治理策略               /providers/Microsoft.Management/.../mg-enterprise             Default

沙盒环境标记豁免已生效，到期时间: 2026-09-17T08:00:00Z
```

## 合规审计与自动修复

策略分配完成后，持续的合规监控是确保治理有效性的关键。Azure Policy 会定期评估资源的合规状态，对于不合规的资源可以配置自动修复任务将其修正到合规状态。通过 PowerShell 脚本化的合规审计，可以生成定期的合规报告、追踪合规趋势，并针对高优先级的不合规资源触发修复操作。下面的脚本演示如何查询合规状态、创建修复任务以及生成合规趋势报告。

```powershell
# --- 查询合规状态 ---
$subscriptionId = (Get-AzContext).Subscription.Id
$scope = "/subscriptions/$subscriptionId"

# 获取所有策略分配的合规状态摘要
$complianceStates = Get-AzPolicyState | Where-Object {
    $_.ResourceLocation -and $_.PolicyAssignmentName
} | Group-Object PolicyAssignmentName, ComplianceState | ForEach-Object {
    [PSCustomObject]@{
        PolicyAssignment = $_.Values[0]
        ComplianceState  = $_.Values[1]
        ResourceCount    = $_.Count
    }
}

Write-Host '=== 合规状态摘要 ===' -ForegroundColor Cyan
$complianceStates | Sort-Object PolicyAssignment, ComplianceState |
    Format-Table -AutoSize

# 查询不合规资源的详细信息
$nonCompliant = Get-AzPolicyState | Where-Object {
    $_.ComplianceState -eq 'NonCompliant'
} | Select-Object -First 20 `
    ResourceId, ResourceType, ResourceLocation,
    PolicyDefinitionName, PolicyAssignmentName,
    Timestamp

Write-Host "`n=== 不合规资源（前 20 条）===" -ForegroundColor Yellow
$nonCompliant | Format-Table -AutoSize

# --- 创建自动修复任务 ---
# 获取需要修复的策略分配
$tagAssignment = Get-AzPolicyAssignment -Name 'cost-governance-sub'

# 创建修复任务：为缺少标记的资源自动添加默认标记值
$remediationTask = Start-AzPolicyRemediation `
    -Name 'remediate-missing-tags' `
    -PolicyAssignmentId $tagAssignment.PolicyAssignmentId `
    -ResourceDiscoveryMode 'ExistingNonCompliant' `
    -Description '为所有缺少 CostCenter 标记的资源添加默认值'

Write-Host "修复任务已启动: $($remediationTask.Name)" -ForegroundColor Green
Write-Host "待修复资源数: $($remediationTask.ProvisioningState)"

# 轮询修复任务状态
$taskName = $remediationTask.Name
$maxRetries = 12
$retryCount = 0

while ($retryCount -lt $maxRetries) {
    Start-Sleep -Seconds 30
    $task = Get-AzPolicyRemediation -Name $taskName `
        -Scope $scope -ErrorAction SilentlyContinue

    if ($task -and $task.ProvisioningState -eq 'Succeeded') {
        Write-Host "修复任务完成" -ForegroundColor Green
        break
    }

    $retryCount++
    Write-Host "等待修复任务完成... ($retryCount/$maxRetries)"
}

# --- 生成合规趋势报告 ---
function Get-ComplianceTrend {
    param(
        [string]$Scope,
        [int]$Days = 30
    )

    $startDate = (Get-Date).AddDays(-$Days)
    $trend = @()

    for ($day = 0; $day -lt $Days; $day += 7) {
        $checkDate = $startDate.AddDays($day)
        $dateLabel = $checkDate.ToString('yyyy-MM-dd')

        # 获取该时间段的合规统计
        $states = Get-AzPolicyState | Where-Object {
            $_.Timestamp -ge $checkDate -and
            $_.Timestamp -lt $checkDate.AddDays(7)
        }

        $total = ($states | Measure-Object).Count
        $compliant = ($states | Where-Object {
            $_.ComplianceState -eq 'Compliant'
        } | Measure-Object).Count

        $complianceRate = if ($total -gt 0) {
            [math]::Round(($compliant / $total) * 100, 1)
        } else {
            0
        }

        $trend += [PSCustomObject]@{
            Week         = $dateLabel
            TotalResources = $total
            Compliant    = $compliant
            NonCompliant = $total - $compliant
            Rate         = "$complianceRate%"
        }
    }

    return $trend
}

# 生成最近 30 天的合规趋势
$trendReport = Get-ComplianceTrend -Scope $scope -Days 30

Write-Host "`n=== 合规趋势报告（最近 30 天）===" -ForegroundColor Cyan
$trendReport | Format-Table -AutoSize

# 计算总体合规率
$latestWeek = $trendReport | Select-Object -Last 1
Write-Host "`n最新一周合规率: $($latestWeek.Rate)" -ForegroundColor Green
```

执行结果示例：

```
=== 合规状态摘要 ===
PolicyAssignment       ComplianceState ResourceCount
---------------       --------------- -------------
cost-governance-sub    Compliant                  156
cost-governance-sub    NonCompliant                23
enterprise-governance  Compliant                 1024
enterprise-governance  NonCompliant                87
production-sku-restriction Compliant              48
production-sku-restriction NonCompliant            3

=== 不合规资源（前 20 条）===
ResourceId                         ResourceType       ResourceLocation  Timestamp
---------                         ------------       ----------------  ---------
/subs/.../rg-prod/vm-test-01      Microsoft.Compute  eastasia           2026-03-17 07:45:00
/subs/.../rg-prod/st-shared-data  Microsoft.Storage  eastasia           2026-03-17 07:30:00
/subs/.../rg-prod/plan-dev        Microsoft.Web      eastasia           2026-03-17 07:15:00

修复任务已启动: remediate-missing-tags
待修复资源数: Accepted
等待修复任务完成... (1/12)
等待修复任务完成... (2/12)
修复任务完成

=== 合规趋势报告（最近 30 天）===
Week        TotalResources Compliant NonCompliant Rate
----        -------------- --------- ------------ ----
2026-02-15             187       142           45  75.9%
2026-02-22             195       158           37  81.0%
2026-03-01             210       179           31  85.2%
2026-03-08             215       190           25  88.4%
2026-03-15             220       197           23  89.5%

最新一周合规率: 89.5%
```

## 注意事项

1. **策略评估延迟**：策略分配创建或更新后，Azure Policy 引擎需要 15 到 30 分钟完成初次评估。在此期间，Azure Portal 中显示的合规状态可能不准确。如果需要立即验证某个资源的合规性，可以使用 `Get-AzPolicyState` 按 ResourceId 精确查询。

2. **Deny 效果的影响范围**：使用 `deny` 效果的策略会阻止不合规资源的创建和更新操作，这在生产环境中可能影响正常的部署流程。建议先用 `audit` 效果观察一段时间，确认影响范围后再切换为 `deny`。可以在策略定义中使用 `DefaultMode` 来控制效果。

3. **修复任务的权限要求**：自动修复任务使用托管标识来执行资源修改操作。创建修复任务前，必须确保策略定义中配置了正确的 `roleDefinitionIds`，并且修复任务的托管标识已被授予相应的 RBAC 角色，否则修复任务会因权限不足而失败。

4. **策略豁免的审批流程**：虽然 PowerShell 可以直接创建策略豁免，但在企业环境中建议将豁免请求纳入变更管理流程。可以结合 Azure DevOps Pipeline 或 GitHub Actions 实现豁免的审批和自动化创建，确保每一次豁免都有迹可循。

5. **策略定义的模式选择**：策略定义的 `mode` 参数决定了策略评估的资源范围。`All` 模式覆盖所有资源类型，`Indexed` 模式仅评估支持标记和位置的资源类型。针对标记和位置的策略应使用 `Indexed` 模式以减少评估开销，而针对 SKU 限制的策略需要使用 `All` 模式。

6. **大规模环境的性能优化**：在管理组层级管理数百个订阅时，避免为每个订阅单独创建策略分配。优先在管理组层级分配策略集（Initiative），让策略自动向下继承。同时，善用 `resourceSelector` 和 `selectors` 属性来精确控制策略评估的资源范围，减少不必要的评估开销。
