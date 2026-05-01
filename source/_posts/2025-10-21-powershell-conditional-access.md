---
layout: post
date: 2025-10-21 08:00:00
title: "PowerShell 技能连载 - 条件访问策略管理"
description: PowerTip of the Day - Conditional Access Policy Management in PowerShell
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
- conditional-access
- entra-id
- security-policy
- azure-ad
---

_适用于 PowerShell 5.1 及以上版本_

在混合办公和零信任架构日益普及的今天，条件访问（Conditional Access）已成为 Microsoft Entra ID（原 Azure AD）中最核心的安全控制手段之一。通过条件访问策略，管理员可以根据用户位置、设备状态、风险等级等信号，动态决定是否允许访问特定资源。然而，随着策略数量增长，手动管理门户中的数十条策略变得极其低效且容易出错。

PowerShell 与 Microsoft Graph API 的结合为条件访问策略的管理提供了自动化能力。无论是批量审计现有策略、快速创建标准化的安全基线策略，还是在紧急安全事件中快速调整策略状态，脚本化操作都比手动点击门户界面更可靠、更快速。特别是在多租户环境下，统一的脚本可以帮助安全团队确保所有租户的策略配置保持一致。

本文将介绍如何使用 PowerShell 通过 Microsoft Graph API 查询、创建、更新和报告条件访问策略，帮助你在日常运维和安全运营中提升效率。

## 连接 Microsoft Graph 并获取现有策略

操作条件访问策略需要 `Policy.Read.All` 和 `Policy.ReadWrite.ConditionalAccess` 等权限。以下代码展示了如何连接 Graph 并列出所有现有策略的关键信息。

```powershell
# 连接 Microsoft Graph，请求条件访问策略所需权限
Connect-MgGraph -Scopes `
    "Policy.Read.All", `
    "Policy.ReadWrite.ConditionalAccess", `
    "Agreement.Read.All"

# 获取所有条件访问策略
$allPolicies = Get-MgIdentityConditionalAccessPolicy

# 输出策略摘要
$summary = foreach ($policy in $allPolicies) {
    [PSCustomObject]@{
        名称     = $policy.DisplayName
        状态     = $policy.State
        创建时间 = $policy.CreatedDateTime.ToString("yyyy-MM-dd")
        修改时间 = $policy.ModifiedDateTime.ToString("yyyy-MM-dd")
        包含用户 = if ($policy.Conditions.Users.IncludeUsers -contains "All") {
            "所有用户"
        } else {
            "$($policy.Conditions.Users.IncludeUsers.Count) 个用户/组"
        }
    }
}

$summary | Format-Table -AutoSize
```

上述脚本首先连接到 Microsoft Graph 并声明必要的权限范围。然后使用 `Get-MgIdentityConditionalAccessPolicy` cmdlet 拉取所有条件访问策略，并通过 `foreach` 循环提取关键信息生成摘要对象。注意判断 `IncludeUsers` 是否包含 "All" 来显示友好的用户范围描述。

执行结果示例：

```
名称                                  状态     创建时间   修改时间   包含用户
----                                  ----     --------   --------   --------
要求所有用户使用 MFA                   enabled  2024-03-15 2025-09-20 所有用户
阻止来自高风险国家的登录               enabled  2024-06-01 2025-08-12 所有用户
要求管理员使用合规设备                 enabled  2024-08-20 2025-10-01 3 个用户/组
仅限批准的客户端应用                   enabled  2025-01-10 2025-01-10 所有用户
标记为报告专用的新设备策略             enabled  forReportingButNotEnforced 2025-10-15 2025-10-15 所有用户
```

## 创建条件访问策略

创建策略时需要构造条件访问策略的完整参数对象，包括条件（Conditions）和访问控制（GrantControls）。以下示例创建一条要求特定组用户必须使用 MFA 的策略。

```powershell
# 定义目标组和排除组
$targetGroupId   = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
$excludeGroupId  = "yyyyyyyy-yyyy-yyyy-yyyy-yyyyyyyyyyyy"

# 构建策略参数
$newPolicyParams = @{
    DisplayName = "要求运维组使用 MFA - 自动创建"
    State       = "enabledForReportingButNotEnforced"
    Conditions  = @{
        Applications = @{
            IncludeApplications = @("All")
        }
        Users = @{
            IncludeUsers = @("None")
            IncludeGroups = @($targetGroupId)
            ExcludeGroups = @($excludeGroupId)
        }
        ClientAppTypes = @("browser", "mobileAppsAndDesktopClients")
        Locations = @{
            IncludeLocations = @("All")
        }
    }
    GrantControls = @{
        Operator = "OR"
        BuiltInControls = @("mfa")
    }
}

# 创建策略，初始设为仅报告模式以避免影响生产环境
$newPolicy = New-MgIdentityConditionalAccessPolicy -BodyParameter $newPolicyParams

Write-Host "策略已创建，ID: $($newPolicy.Id)"
Write-Host "当前状态: $($newPolicy.State)（仅报告模式）"
Write-Host "请在验证后手动切换为 'enabled'"
```

这个示例有几个值得注意的设计决策。首先，策略初始状态设为 `enabledForReportingButNotEnforced`（仅报告模式），这样在确认策略不会产生意外阻断之前，不会影响用户正常访问。其次，`IncludeApplications` 设为 `@("All")` 表示该策略应用于所有云应用。最后，`GrantControls` 使用 `OR` 操作符和 `mfa` 内置控制，表示只要满足 MFA 要求即可放行。

执行结果示例：

```
策略已创建，ID: abc12345-6789-def0-1234-567890abcdef
当前状态: enabledForReportingButNotEnforced（仅报告模式）
请在验证后手动切换为 'enabled'
```

## 批量切换策略状态

在安全事件响应场景中，可能需要快速启用或禁用一批条件访问策略。以下脚本演示如何按名称模式批量切换策略状态，并记录操作日志。

```powershell
# 定义要切换的策略名称关键词和目标状态
$namePattern = "高风险"
$targetState  = "disabled"

# 获取匹配的策略
$matchedPolicies = Get-MgIdentityConditionalAccessPolicy | `
    Where-Object { $_.DisplayName -like "*$namePattern*" }

if ($matchedPolicies.Count -eq 0) {
    Write-Host "未找到匹配 '$namePattern' 的策略"
    return
}

Write-Host "找到 $($matchedPolicies.Count) 条匹配策略："

# 记录操作日志
$logEntries = foreach ($policy in $matchedPolicies) {
    $previousState = $policy.State

    Write-Host ("  切换: {0} ({1} -> {2})" -f `
        $policy.DisplayName, $previousState, $targetState)

    # 更新策略状态
    Update-MgIdentityConditionalAccessPolicy `
        -ConditionalAccessPolicyId $policy.Id `
        -BodyParameter @{ State = $targetState }

    # 构建日志记录
    [PSCustomObject]@{
        操作时间   = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        策略ID     = $policy.Id
        策略名称   = $policy.DisplayName
        原状态     = $previousState
        新状态     = $targetState
        操作人     = "自动化脚本"
    }
}

# 导出操作日志到 CSV
$logPath = "ConditionalAccess_ChangeLog_{0:yyyyMMdd_HHmmss}.csv" -f (Get-Date)
$logEntries | Export-Csv -Path $logPath -NoTypeInformation -Encoding UTF8
Write-Host "`n操作日志已保存至: $logPath"
```

这段代码的核心逻辑是先按名称关键词筛选策略，然后逐一切换状态。每次操作都记录到对象数组中，最终导出为带时间戳的 CSV 文件。这种日志记录方式在安全审计中非常重要，可以追溯每次策略变更的详细上下文。使用 `foreach` 而非管道中的 `ForEach-Object`，使代码逻辑更清晰且方便调试。

执行结果示例：

```
找到 2 条匹配策略：
  切换: 阻止来自高风险国家的登录 (enabled -> disabled)
  切换: 高风险会话要求重新认证 (enabled -> disabled)

操作日志已保存至: ConditionalAccess_ChangeLog_20251021_143022.csv
```

## 生成条件访问策略合规报告

定期审计条件访问策略的配置是否符合安全基线要求是安全运营的重要环节。以下脚本生成一份包含策略详情和合规性检查的 HTML 报告。

```powershell
# 定义合规检查规则
$complianceRules = @{
    MustHaveMFAPolicy        = "必须有一条针对所有用户的 MFA 策略"
    MustBlockLegacyAuth      = "必须阻止旧版身份验证协议"
    MustHaveDeviceCompliance = "建议包含设备合规性检查策略"
}

# 获取所有策略并分析
$allPolicies = Get-MgIdentityConditionalAccessPolicy

$reportData = foreach ($policy in $allPolicies) {
    $conditions = $policy.Conditions
    $grantControls = $policy.GrantControls

    # 提取关键属性用于分析
    $appliesToAllUsers = $conditions.Users.IncludeUsers -contains "All"
    $requiresMFA = $grantControls.BuiltInControls -contains "mfa"
    $blocksAccess = $grantControls.BuiltInControls -contains "block"
    $clientAppTypes = $conditions.ClientAppTypes -join ", "

    [PSCustomObject]@{
        策略名称       = $policy.DisplayName
        状态           = $policy.State
        应用于所有用户 = if ($appliesToAllUsers) { "是" } else { "否" }
        要求MFA        = if ($requiresMFA) { "是" } else { "否" }
        阻止访问       = if ($blocksAccess) { "是" } else { "否" }
        客户端类型     = $clientAppTypes
    }
}

# 合规性检查
$hasEnabledMFA = $allPolicies | Where-Object {
    $_.State -eq "enabled" -and
    $_.Conditions.Users.IncludeUsers -contains "All" -and
    $_.GrantControls.BuiltInControls -contains "mfa"
}

$hasBlockLegacy = $allPolicies | Where-Object {
    $_.State -eq "enabled" -and
    $_.Conditions.ClientAppTypes -contains "exchangeActiveSyncClients" -and
    $_.GrantControls.BuiltInControls -contains "block"
}

Write-Host "=== 条件访问策略合规报告 ==="
Write-Host ("报告生成时间: {0}" -f (Get-Date -Format "yyyy-MM-dd HH:mm:ss"))
Write-Host ("策略总数: {0}" -f $allPolicies.Count)
Write-Host ""
Write-Host ("[合规检查] 全局 MFA 策略: {0}" -f $(if ($hasEnabledMFA) { "PASS" } else { "FAIL" }))
Write-Host ("[合规检查] 阻止旧版认证:   {0}" -f $(if ($hasBlockLegacy) { "PASS" } else { "FAIL" }))
Write-Host ""
Write-Host "策略明细："
$reportData | Format-Table -AutoSize
```

这个脚本实现了两层逻辑。第一层通过 `foreach` 循环为每条策略生成详细属性记录，用于展示策略的配置细节。第二层通过 `Where-Object` 进行合规性检查，判断是否存在启用的全局 MFA 策略和旧版认证阻止策略。这种结构化的报告方式可以帮助安全团队快速识别配置缺口。

执行结果示例：

```
=== 条件访问策略合规报告 ===
报告生成时间: 2025-10-21 14:30:00
策略总数: 5

[合规检查] 全局 MFA 策略: PASS
[合规检查] 阻止旧版认证:   FAIL

策略明细：

策略名称                              状态        应用于所有用户 要求MFA 阻止访问 客户端类型
--------                              ----        -------------- ------- -------- ----------
要求所有用户使用 MFA                   enabled     是             是      否       browser, mobileAppsAndDesktopClients
阻止来自高风险国家的登录               enabled     是             否      是       browser, mobileAppsAndDesktopClients
要求管理员使用合规设备                 enabled     否             否      否       browser, mobileAppsAndDesktopClients
仅限批准的客户端应用                   enabled     是             否      否       browser, mobileAppsAndDesktopClients
标记为报告专用的新设备策略             enabled     否             否      否       browser, mobileAppsAndDesktopClients
```

## 注意事项

1. **权限要求**：管理条件访问策略需要 Entra ID 中的条件访问管理员或安全管理员角色。使用 `Connect-MgGraph` 时，确保请求了 `Policy.ReadWrite.ConditionalAccess` 权限，且管理员已在门户中同意该权限。

2. **先报告后启用**：新建策略时务必先将 `State` 设为 `enabledForReportingButNotEnforced`（仅报告模式），在日志中确认策略不会误阻断正常用户后，再切换为 `enabled`。误启用的策略可能导致大面积锁定。

3. **策略冲突检测**：多条策略之间可能产生冲突或叠加效果。例如一条策略要求 MFA，另一条策略要求合规设备，两者同时满足时用户需要完成两种验证。建议在脚本中记录策略间的覆盖关系。

4. **命名规范**：为策略建立统一的命名规范（如 `[类别] - [描述]`），便于脚本按名称模式筛选和批量操作。避免使用无意义的默认名称如"New Policy"。

5. **排除紧急访问账户**：每条策略都应排除紧急访问（Break Glass）账户，确保在策略配置错误或服务中断时，紧急账户仍能登录进行修复。建议在脚本中加入自动化检查。

6. **操作日志留存**：所有通过脚本执行的策略变更都应记录到外部日志（CSV、数据库或 SIEM），包含操作时间、策略 ID、变更前后状态和操作人信息，以满足安全审计和合规要求。
