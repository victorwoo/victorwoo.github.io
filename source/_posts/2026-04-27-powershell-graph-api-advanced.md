---
layout: post
date: 2026-04-27 08:00:00
title: "PowerShell 技能连载 - Microsoft Graph API 高级操作"
description: PowerTip of the Day - Advanced Microsoft Graph API Operations in PowerShell
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
- microsoft-graph
- graph-api
- entra-id
- office-365
---

_适用于 PowerShell 7.0 及以上版本，需要 Microsoft.Graph 模块_

Microsoft Graph 已经成为访问 Microsoft 365 和 Entra ID 数据的统一 API 网关。无论是用户管理、邮件处理、团队协作还是安全合规，几乎所有 Microsoft 云服务的数据和操作都可以通过 Graph API 完成。对于 PowerShell 运维人员来说，掌握 Graph API 的高级用法意味着能够构建更高效、更可靠的自动化流程。

然而，在实际生产环境中，简单的 API 调用往往不够。当需要处理成千上万个用户对象、执行批量许可分配、或者生成复杂的安全审计报告时，必须考虑认证效率、请求优化、分页处理和错误重试等工程化问题。本文将围绕这些高级场景，分享一套可直接用于生产环境的 Graph API 操作模式。

## Graph API 认证与查询优化

在规模化操作中，认证方式和查询策略直接影响执行效率。以下代码展示了应用权限认证、分页自动处理、`$select`/`$filter` 查询优化以及批量请求（Batch）的完整实现。

```powershell
function Connect-GraphApp {
    param(
        [Parameter(Mandatory)]
        [string]$TenantId,
        [Parameter(Mandatory)]
        [string]$ClientId,
        [Parameter(Mandatory)]
        [string]$CertificateThumbprint
    )

    Connect-MgGraph -TenantId $TenantId `
        -ClientId $ClientId `
        -CertificateThumbprint $CertificateThumbprint `
        -NoWelcome

    $context = Get-MgContext
    Write-Host "已连接: $($context.AppName) @ $($context.TenantId)" -ForegroundColor Green
}

function Invoke-GraphPagedQuery {
    param(
        [Parameter(Mandatory)]
        [string]$Uri,
        [int]$PageSize = 100,
        [string[]]$Select,
        [string]$Filter
    )

    $params = @()
    if ($PageSize)  { $params += "`$top=$PageSize" }
    if ($Select)    { $params += "`$select=$($Select -join ',')" }
    if ($Filter)    { $params += "`$filter=$Filter" }

    $queryString = if ($params) { '?' + ($params -join '&') } else { '' }
    $fullUri = if ($Uri -match '\?') { "$Uri&$($params -join '&')" } else { "$Uri$queryString" }

    $allResults = [System.Collections.Generic.List[object]]::new()
    $currentUri = $fullUri
    $requestCount = 0

    while ($currentUri) {
        $requestCount++
        $response = Invoke-MgGraphRequest -Uri $currentUri -Method GET -OutputType Hashtable

        if ($response.value) {
            $allResults.AddRange($response.value)
        }

        $currentUri = $response.'@odata.nextLink'
        Write-Verbose "已获取 $($allResults.Count) 条记录 (请求 #$requestCount)"
    }

    Write-Host "查询完成: 共 $($allResults.Count) 条, 发送 $requestCount 次请求" -ForegroundColor Cyan
    return $allResults
}

function Invoke-GraphBatch {
    param(
        [Parameter(Mandatory)]
        [hashtable[]]$Requests,
        [int]$BatchSize = 20
    )

    $batches = for ($i = 0; $i -lt $Requests.Count; $i += $BatchSize) {
        ,($Requests[$i..([Math]::Min($i + $BatchSize - 1, $Requests.Count - 1))])
    }

    $allResponses = @()
    $batchNum = 0

    foreach ($batch in $batches) {
        $batchNum++
        $batchBody = @{
            requests = @($batch | ForEach-Object -Begin { $id = 0 } -Process {
                $id++
                @{
                    id     = "$id"
                    method = $_.Method ?? 'GET'
                    url    = $_.Url
                    body   = $_.Body
                    headers = @{ 'Content-Type' = 'application/json' }
                }
            })
        }

        $response = Invoke-MgGraphRequest `
            -Uri 'https://graph.microsoft.com/v1.0/$batch' `
            -Method POST `
            -Body ($batchBody | ConvertTo-Json -Depth 5)

        $allResponses += $response.responses
        Write-Verbose "批次 $batchNum/$($batches.Count) 完成"
    }

    return $allResponses
}
```

执行结果示例：

```text
已连接: MyApp-Graph@ 72f988bf-86f1-41af-91ab-2d7cd011db47
查询完成: 共 2847 条, 发送 29 次请求
批次 1/5 完成
批次 2/5 完成
批次 3/5 完成
批次 4/5 完成
批次 5/5 完成
```

通过 `$select` 只返回需要的字段可以显著减少响应体积，`$filter` 在服务端完成过滤避免传输冗余数据。批量请求（Batch）最多可在一个 HTTP 调用中打包 20 个操作，大幅降低网络开销。

## 用户与组批量管理

在大型组织中，用户入职、离职和部门调动都涉及批量操作。以下代码实现了批量用户创建与更新、组生命周期管理以及许可（License）分配的完整流程。

```powershell
function New-BulkUsers {
    param(
        [Parameter(Mandatory)]
        [array]$UserList,
        [string]$Domain = 'contoso.com'
    )

    $results = @()

    foreach ($user in $UserList) {
        $mailNickname = "$($user.GivenName).$($user.Surname)".ToLower() -replace '\s', ''
        $upn = "$mailNickname@$Domain"
        $tempPassword = -join ((48..57) + (65..90) + (97..122) | Get-Random -Count 16 | ForEach-Object { [char]$_ })

        $passwordProfile = @{
            password                    = $tempPassword
            forceChangePasswordNextSignIn = $true
        }

        try {
            $newUser = New-MgUser -BodyParameter @{
                accountEnabled    = $true
                displayName       = "$($user.GivenName) $($user.Surname)"
                givenName         = $user.GivenName
                surname           = $user.Surname
                mailNickname      = $mailNickname
                userPrincipalName = $upn
                passwordProfile   = $passwordProfile
                department        = $user.Department
                jobTitle          = $user.JobTitle
                usageLocation     = $user.UsageLocation ?? 'CN'
            } -ErrorAction Stop

            $results += [PSCustomObject]@{
                Status   = 'Created'
                UPN      = $upn
                UserId   = $newUser.Id
                TempPass = $tempPassword
            }
            Write-Verbose "已创建用户: $upn"
        }
        catch {
            $results += [PSCustomObject]@{
                Status   = 'Failed'
                UPN      = $upn
                UserId   = $null
                TempPass = $null
                Error    = $_.Exception.Message
            }
            Write-Warning "创建用户失败 $upn : $($_.Exception.Message)"
        }
    }

    return $results
}

function Set-GroupLifecycle {
    param(
        [Parameter(Mandatory)]
        [string]$GroupId,
        [ValidateSet('Archive', 'Reactivate', 'RotateOwner')]
        [string]$Action,
        [string]$NewOwnerId
    )

    $group = Get-MgGroup -GroupId $GroupId
    if (-not $group) { throw "组 $GroupId 不存在" }

    switch ($Action) {
        'Archive' {
            Update-MgGroup -GroupId $GroupId -BodyParameter @{
                description    = "[已归档] $($group.Description)"
                mailEnabled    = $false
                visibility     = 'HiddenMembership'
            }
            Write-Host "已归档组: $($group.DisplayName)" -ForegroundColor Yellow
        }
        'Reactivate' {
            Update-MgGroup -GroupId $GroupId -BodyParameter @{
                mailEnabled = $true
                visibility  = 'Public'
            }
            Write-Host "已重新激活组: $($group.DisplayName)" -ForegroundColor Green
        }
        'RotateOwner' {
            if (-not $NewOwnerId) { throw "更换所有者需要提供 NewOwnerId" }
            $currentOwners = Get-MgGroupOwner -GroupId $GroupId
            foreach ($owner in $currentOwners) {
                Remove-MgGroupOwnerByRef -GroupId $GroupId -DirectoryObjectId $owner.Id
            }
            New-MgGroupOwnerByRef -GroupId $GroupId -BodyParameter @{
                '@odata.id' = "https://graph.microsoft.com/v1.0/directoryObjects/$NewOwnerId"
            }
            Write-Host "已更换组 $($group.DisplayName) 的所有者为 $NewOwnerId" -ForegroundColor Green
        }
    }
}

function Set-BulkLicenseAssignment {
    param(
        [Parameter(Mandatory)]
        [string[]]$UserIds,
        [Parameter(Mandatory)]
        [string[]]$SkuIds,
        [bool]$Remove = $false
    )

    $total = $UserIds.Count
    $processed = 0
    $successCount = 0
    $failCount = 0

    foreach ($userId in $UserIds) {
        $processed++
        $addLicenses = @()
        $removeLicenses = @()

        if ($Remove) {
            $removeLicenses = @($SkuIds | ForEach-Object { @{ skuId = $_ } })
        }
        else {
            $addLicenses = @($SkuIds | ForEach-Object {
                @{ skuId = $_; disabledPlans = @() }
            })
        }

        try {
            Set-MgUserLicense -UserId $userId `
                -AddLicenses $addLicenses `
                -RemoveLicenses $removeLicenses `
                -ErrorAction Stop
            $successCount++
        }
        catch {
            $failCount++
            Write-Verbose "许可操作失败 ($userId): $($_.Exception.Message)"
        }

        if ($processed % 50 -eq 0) {
            Write-Progress -Activity "许可分配" -Status "$processed / $total" `
                -PercentComplete (($processed / $total) * 100)
        }
    }

    return [PSCustomObject]@{
        Total    = $total
        Success  = $successCount
        Failed   = $failCount
        Action   = if ($Remove) { 'Remove' } else { 'Assign' }
    }
}
```

执行结果示例：

```text
已创建用户: zhang.wei@contoso.com
已创建用户: li.na@contoso.com
创建用户失败 wang.fang@contoso.com : Another object with the same value for property
userPrincipalName already exists.
已归档组: 2024-Q3-项目组
已更换组 安全审计组 的所有者为 3a5b7c9d-1234-5678-abcd-ef0123456789

Total   : 150
Success : 147
Failed  : 3
Action  : Assign
```

批量操作中需要注意 Graph API 的节流限制（Throttling）。用户管理操作通常限制在每 30 秒若干次请求，当返回 429 状态码时应实现指数退避重试。

## 安全与合规报告

安全运维是 Graph API 的高价值场景之一。通过查询 Entra ID 的登录日志、风险检测和条件访问策略，可以构建自动化的安全态势报告。

```powershell
function Get-SignInAuditReport {
    param(
        [int]$Days = 7,
        [string]$RiskFilter
    )

    $startDate = (Get-Date).AddDays(-$Days).ToString('yyyy-MM-ddTHH:mm:ssZ')
    $filterQuery = "createdDateTime ge $startDate"

    if ($RiskFilter) {
        $filterQuery += " and riskLevelDuringSignIn eq '$RiskFilter'"
    }

    $signIns = Invoke-GraphPagedQuery `
        -Uri 'https://graph.microsoft.com/v1.0/auditLogs/signIns' `
        -Select @('createdDateTime', 'userDisplayName', 'userPrincipalName',
                  'ipAddress', 'location', 'status', 'riskLevelAggregation',
                  'clientAppUsed', 'conditionalAccessStatus') `
        -Filter $filterQuery `
        -PageSize 100

    $summary = $signIns | Group-Object userPrincipalName | ForEach-Object {
        $userSignIns = $_.Group
        $failedCount = @($userSignIns | Where-Object {
            $_.status.errorCode -and $_.status.errorCode -ne 0
        }).Count

        [PSCustomObject]@{
            UserPrincipalName = $_.Name
            TotalSignIns      = $_.Count
            FailedAttempts    = $failedCount
            UniqueIPs         = @($userSignIns.ipAddress | Sort-Object -Unique).Count
            RiskEvents        = @($userSignIns | Where-Object {
                $_.riskLevelAggregation -and $_.riskLevelAggregation -ne 'none'
            }).Count
            LastSignIn        = @($userSignIns.createdDateTime | Sort-Object -Descending)[0]
            Locations         = @($userSignIns | ForEach-Object {
                $_.location.city
            } | Where-Object { $_ } | Sort-Object -Unique) -join ', '
        }
    } | Sort-Object FailedAttempts -Descending

    return $summary
}

function Get-RiskDetectionReport {
    param(
        [int]$Days = 30
    )

    $startDate = (Get-Date).AddDays(-$Days).ToString('yyyy-MM-ddTHH:mm:ssZ')

    $detections = Invoke-GraphPagedQuery `
        -Uri 'https://graph.microsoft.com/v1.0/identityProtection/riskDetections' `
        -Select @('riskEventType', 'riskLevel', 'riskState', 'detectedDateTime',
                  'userDisplayName', 'userPrincipalName', 'ipAddress',
                  'location', 'activity') `
        -Filter "detectedDateTime ge $startDate" `
        -PageSize 100

    $report = [PSCustomObject]@{
        Period            = "$Days 天"
        TotalDetections   = $detections.Count
        HighRiskCount     = @($detections | Where-Object { $_.riskLevel -eq 'high' }).Count
        MediumRiskCount   = @($detections | Where-Object { $_.riskLevel -eq 'medium' }).Count
        ByType            = $detections | Group-Object riskEventType |
            Sort-Object Count -Descending |
            Select-Object Count, Name -First 10
        AffectedUsers     = @($detections.userPrincipalName | Sort-Object -Unique).Count
        TopRiskUsers      = $detections | Where-Object { $_.riskLevel -eq 'high' } |
            Group-Object userPrincipalName |
            Sort-Object Count -Descending |
            Select-Object Count, Name -First 10
        Remediated        = @($detections | Where-Object {
            $_.riskState -eq 'remediated'
        }).Count
    }

    return $report
}

function Get-ConditionalAccessAudit {
    param()

    $policies = Get-MgIdentityConditionalAccessPolicy -All

    $audit = foreach ($policy in $policies) {
        $grantControls = $policy.GrantControls
        $conditions = $policy.Conditions

        $includedApps = @()
        if ($conditions.Applications.IncludeApplications) {
            $includedApps = $conditions.Applications.IncludeApplications
        }

        [PSCustomObject]@{
            DisplayName          = $policy.DisplayName
            State                = $policy.State
            CreatedDateTime      = $policy.CreatedDateTime
            ModifiedDateTime     = $policy.ModifiedDateTime
            IncludedApps         = if ($includedApps -contains 'All') {
                'All applications'
            } else {
                "$($includedApps.Count) apps"
            }
            IncludedUsers        = if ($conditions.Users.IncludeUsers -contains 'All') {
                'All users'
            } else {
                "$($conditions.Users.IncludeUsers.Count) users"
            }
            GrantControl         = $grantControls.BuiltInControls -join ', '
            Operator             = $grantControls.Operator
            ClientAppTypes       = $conditions.ClientAppTypes -join ', '
            SignInRiskLevels     = $conditions.SignInRiskLevels -join ', '
        }
    }

    $summary = [PSCustomObject]@{
        TotalPolicies   = $policies.Count
        EnabledPolicies = @($audit | Where-Object { $_.State -eq 'enabled' }).Count
        ReportOnly      = @($audit | Where-Object { $_.State -eq 'enabledForReportingButNotEnforced' }).Count
        Disabled        = @($audit | Where-Object { $_.State -eq 'disabled' }).Count
        Policies        = $audit
    }

    return $summary
}
```

执行结果示例：

```text
查询完成: 共 15632 条, 发送 157 次请求
查询完成: 共 423 条, 发送 5 次请求

UserPrincipalName    : admin@contoso.com
TotalSignIns         : 89
FailedAttempts       : 12
UniqueIPs            : 5
RiskEvents           : 3
LastSignIn           : 2026-04-27T06:32:15Z
Locations            : Beijing, Shanghai, Unknown

Period           : 30 天
TotalDetections  : 423
HighRiskCount    : 18
MediumRiskCount  : 67
AffectedUsers    : 42
Remediated       : 156

TotalPolicies   : 15
EnabledPolicies : 11
ReportOnly      : 2
Disabled        : 2
```

安全报告函数可以与计划任务（Scheduled Task）或 Azure Automation Runbook 结合，实现每日自动生成安全态势摘要并通过 Teams Webhook 或邮件发送给安全团队。

## 注意事项

1. **认证方式选择**：生产环境应使用应用权限（Application Permission）配合证书认证，避免交互式登录。证书建议使用 Azure Key Vault 托管，定期自动轮换。

2. **API 节流处理**：Graph API 对不同端点有不同的节流限制。遇到 429 响应时必须读取 `Retry-After` 头部并等待指定时间，切勿简单循环重试，否则会加剧限流。

3. **分页最佳实践**：对于可能返回大量结果的查询，始终使用 `$top` 控制每页大小，并跟随 `@odata.nextLink` 逐页获取。避免在内存中缓存全量数据后再处理。

4. **批量请求限制**：单个 Batch 请求最多包含 20 个子请求，且不支持嵌套 Batch。对于超大批量操作，应分批次提交并在批次之间加入适当延迟。

5. **许可分配注意事项**：分配许可前务必确认用户的 `usageLocation` 属性已设置，否则操作会失败。同时要注意许可计划的依赖关系，某些高级许可需要基础许可作为前提。

6. **日志保留期限**：Entra ID 登录日志默认保留 30 天（Premium P2 许可），风险检测数据保留同样有限。如需长期分析，应将数据导出到 Log Analytics 工作区或外部存储。
