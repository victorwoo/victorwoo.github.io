---
layout: post
date: 2025-11-10 08:00:00
updated: 2025-11-10 08:00:00
title: "PowerShell 技能连载 - Azure Policy 合规管理"
description: PowerTip of the Day - Azure Policy Compliance Management in PowerShell
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
- azure
- security
- best-practices
- cloud
---

_适用于 PowerShell 5.1 及以上版本_

随着企业云基础设施规模不断膨胀，资源合规性管理成为运维团队的核心挑战。Azure Policy 是微软 Azure 平台提供的治理服务，能够在资源创建和更新时自动执行组织规则，例如限制资源类型、强制标签策略、审核配置基线等。通过 PowerShell 的 `Az` 模块，我们可以将策略的定义、分配和合规审查全部纳入自动化流水线，实现"基础设施即代码"的治理闭环。

传统的合规审计往往依赖人工巡检或第三方工具，耗时且容易遗漏。Azure Policy 将合规检查前移到资源生命周期中，一旦资源偏离预期状态就会触发警报甚至自动修正。结合 PowerShell 的批量处理能力，管理员可以在几分钟内对数百个订阅进行策略评估，快速定位不合规资源并生成报告，大幅降低安全风险和审计成本。

本文将介绍如何使用 PowerShell 完成 Azure Policy 的常见操作，包括查询策略定义、分配策略到作用域、检索合规状态，以及批量导出合规报告，帮助你构建可重复、可审计的云治理工作流。

<!-- more -->

## 查询 Azure Policy 内置定义

Azure 提供了大量内置策略定义，覆盖存储、网络、计算、安全等多个领域。我们可以用 PowerShell 快速搜索并筛选需要的策略。

```powershell
# 连接 Azure 账户（如已登录可跳过）
Connect-AzAccount

# 搜索与"标签"相关的内置策略定义
$tagPolicies = Get-AzPolicyDefinition | Where-Object {
    $_.Properties.DisplayName -match "tag" -and
    $_.Properties.PolicyType -eq "BuiltIn"
}

# 输出策略名称和显示名
foreach ($policy in $tagPolicies) {
    [PSCustomObject]@{
        Name        = $policy.Name
        DisplayName = $policy.Properties.DisplayName
        Category    = $policy.Properties.Metadata.category
    }
}
```

执行结果示例：

```
Name                                  DisplayName                                Category
----                                  -----------                                --------
1e30110a-5ceb-460c-a204-fsdfsdf       Require a tag on resources                 Tags
8e346d3c-483d-4fef-8d21-dsfsdf        Inherit a tag from the resource group      Tags
...
```

通过 `Get-AzPolicyDefinition` 获取所有策略定义后，用 `Where-Object` 按 `DisplayName` 或 `Category` 进行筛选，方便找到目标策略。`PolicyType` 为 `BuiltIn` 表示微软内置策略，`Custom` 则是用户自定义策略。

## 分配策略到指定作用域

找到合适的策略后，下一步是将其分配到订阅或资源组级别。以下示例将"要求资源具有环境标签"的内置策略分配到指定资源组。

```powershell
# 获取目标资源组信息
$rg = Get-AzResourceGroup -Name "prod-app-rg"

# 获取内置策略定义（要求资源必须带有指定标签）
$policyDef = Get-AzPolicyDefinition | Where-Object {
    $_.Properties.DisplayName -eq "Require a tag on resources"
} | Select-Object -First 1

# 构造策略参数：指定必须存在的标签名为 "Environment"
$policyParam = @{
    tagName = "Environment"
}

# 分配策略到资源组
$assignment = New-AzPolicyAssignment `
    -Name "require-env-tag" `
    -DisplayName "要求所有资源带有 Environment 标签" `
    -PolicyDefinition $policyDef `
    -Scope $rg.ResourceId `
    -PolicyParameterObject $policyParam

Write-Host "策略已分配，AssignmentId: $($assignment.PolicyAssignmentId)"
```

执行结果示例：

```
策略已分配，AssignmentId: /subscriptions/xxxx-xxxx/resourceGroups/prod-app-rg/providers/Microsoft.Authorization/policyAssignments/require-env-tag
```

`New-AzPolicyAssignment` 的 `Scope` 参数支持订阅级别（`/subscriptions/{id}`）、资源组级别（含 `/resourceGroups/{name}`）甚至单个资源级别。`PolicyParameterObject` 以哈希表形式传递策略所需的参数，不同策略需要的参数各异，可查看策略定义的 `Properties.Parameters` 了解详情。

## 检索合规状态

策略分配完成后，需要定期检查资源的合规情况。以下脚本查询指定订阅下所有策略分配的合规状态，并筛选出不合规的资源。

```powershell
# 获取当前订阅 ID
$subscriptionId = (Get-AzContext).Subscription.Id

# 查询最近一次策略评估的合规状态
$complianceStates = Get-AzPolicyState | Where-Object {
    $_.ComplianceState -eq "NonCompliant"
}

# 按策略分配分组统计不合规资源数量
$summary = @{}
foreach ($state in $complianceStates) {
    $key = $state.PolicyAssignmentName
    if (-not $summary.ContainsKey($key)) {
        $summary[$key] = 0
    }
    $summary[$key]++
}

foreach ($item in $summary.GetEnumerator() | Sort-Object Value -Descending) {
    [PSCustomObject]@{
        PolicyAssignment = $item.Key
        NonCompliantCount = $item.Value
    }
}
```

执行结果示例：

```
PolicyAssignment             NonCompliantCount
----------------             -----------------
require-env-tag                              12
audit-storage-https                           5
deny-public-endpoints                         3
```

`Get-AzPolicyState` 返回的是策略评估的详细记录，每条记录对应一个资源与一条策略的关系。`ComplianceState` 字段取值 `Compliant`（合规）或 `NonCompliant`（不合规）。按策略分配名称分组统计，可以快速了解哪些策略的不合规资源最多，便于优先处理。

## 批量导出合规报告

对于审计和归档需求，我们通常需要将合规数据导出为 CSV 文件。以下脚本将所有不合规资源的详细信息导出为结构化报告。

```powershell
# 定义输出路径
$reportDate = Get-Date -Format "yyyyMMdd"
$csvPath = "$HOME/AzurePolicyReport_$reportDate.csv"

# 获取所有不合规状态记录
$nonCompliant = Get-AzPolicyState | Where-Object {
    $_.ComplianceState -eq "NonCompliant"
}

# 构造报告对象
$reportRows = foreach ($record in $nonCompliant) {
    [PSCustomObject]@{
        Timestamp          = $record.Timestamp
        ResourceId         = $record.ResourceId
        ResourceType       = $record.ResourceType
        ResourceGroup      = $record.ResourceGroup
        PolicyAssignment   = $record.PolicyAssignmentName
        PolicyDefinition   = $record.PolicyDefinitionName
        ComplianceState    = $record.ComplianceState
    }
}

# 导出为 CSV
$reportRows | Export-Csv -Path $csvPath -NoTypeInformation -Encoding UTF8

Write-Host "合规报告已导出: $csvPath"
Write-Host "共 $($reportRows.Count) 条不合规记录"
```

执行结果示例：

```
合规报告已导出: /home/user/AzurePolicyReport_20251110.csv
共 20 条不合规记录
```

导出的 CSV 文件包含资源 ID、类型、所属资源组、关联策略等字段，可以直接用 Excel 打开进行筛选和透视分析，也可以导入到 SIEM 或仪表盘系统中做持续监控。

## 注意事项

1. **模块版本**：确保安装了最新版 `Az.Policy` 和 `Az.Resources` 模块（`Install-Module Az.Resources -Force`），旧版本可能缺少 `Get-AzPolicyState` 等关键命令。PowerShell 5.1 用户注意 .NET Framework 版本兼容性。

2. **权限要求**：执行策略相关操作需要订阅级别的 `Microsoft.Authorization/policyAssignments/*` 权限。建议使用专用的服务主体（Service Principal）并在 CI/CD 流水线中运行，避免使用个人账户。

3. **合规数据延迟**：`Get-AzPolicyState` 返回的是最近一次策略评估引擎扫描的结果，通常有 15-30 分钟的延迟。资源变更后不会立即反映在合规状态中，如需即时验证可手动触发评估：`Start-AzPolicyComplianceScan`。

4. **大数据量处理**：在拥有数千资源的订阅中，`Get-AzPolicyState` 可能返回海量记录。建议通过 `-Filter` 参数缩小范围，例如 `Get-AzPolicyState -Filter "PolicyAssignmentName eq 'require-env-tag'"` 只查询特定策略的合规数据，避免内存溢出。

5. **策略豁免管理**：某些资源可能需要临时豁免策略（如测试环境），可使用 `New-AzPolicyExemption` 创建豁免记录并设置过期时间，而不是直接删除策略分配，以保持治理完整性。

6. **自定义策略定义**：当内置策略无法满足需求时，可通过 `New-AzPolicyDefinition` 创建自定义策略。策略规则使用 JSON 格式声明条件与效果（如 Audit、Deny、DeployIfNotExists），建议将策略 JSON 纳入 Git 版本控制，配合 CI/CD 流水线自动部署，确保策略变更可追溯、可回滚。

掌握以上操作后，你可以将 Azure Policy 的日常管理全部纳入 PowerShell 自动化流程，从策略定义到合规监控再到报告导出，形成完整的治理闭环。
