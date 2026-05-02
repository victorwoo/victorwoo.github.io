---
layout: post
date: 2025-11-13 08:00:00
updated: 2025-11-13 08:00:00
title: "PowerShell 技能连载 - Entra ID 应用注册"
description: PowerTip of the Day - Entra ID App Registration in PowerShell
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
- azure
---

_适用于 PowerShell 5.1 及以上版本_

在企业云环境中，Entra ID（原 Azure AD）的应用注册（App Registration）是构建自动化和集成方案的基础。无论是让 CI/CD 流水线访问 Azure 资源，还是让自定义应用调用 Microsoft Graph API，都需要先在 Entra ID 中注册一个应用程序，并为其配置权限和凭据。手动在 Azure 门户中点击操作不仅效率低下，而且难以保持多个环境（开发、测试、生产）之间的一致性。

通过 PowerShell 的 `Microsoft.Graph` 模块，我们可以将应用注册的全生命周期管理纳入代码化流程。从创建应用、配置 API 权限、添加客户端密钥，到创建服务主体并授予角色权限，每一步都可以脚本化、参数化，然后集成到基础设施即代码（IaC）流水线中。这种方式不仅提高了效率，更重要的是让安全团队能够审查和审计每一次应用注册的变更。

本文将介绍如何使用 PowerShell 完成 Entra ID 应用注册的常见操作，包括创建应用并配置基本属性、管理客户端密钥和凭据、配置 API 权限委派，以及批量审计租户内的应用注册信息，帮助你构建安全可控的身份管理自动化方案。

<!-- more -->

## 创建应用注册并配置基本属性

使用 Microsoft Graph PowerShell SDK 可以快速创建应用注册，并在创建时设置显示名称、回调 URL 等属性。以下示例演示如何创建一个面向 Web 应用的注册。

```powershell
# 连接到 Microsoft Graph（需要 Application.ReadWrite.All 权限）
Connect-MgGraph -Scopes "Application.ReadWrite.All"

# 定义应用注册的基本参数
$appName = "CI-CD-Pipeline-App"
$signInAudience = "AzureADMyOrg"
$redirectUris = @(
    "https://localhost:3000/auth/callback",
    "https://app.contoso.com/auth/callback"
)

# 创建应用注册
$newApp = New-MgApplication -DisplayName $appName `
    -SignInAudience $signInAudience `
    -Web @{ RedirectUris = $redirectUris }

Write-Host "应用注册创建成功"
Write-Host "  AppId (Client ID): $($newApp.AppId)"
Write-Host "  ObjectId:          $($newApp.Id)"
Write-Host "  DisplayName:       $($newApp.DisplayName)"
```

执行结果示例：

```
应用注册创建成功
  AppId (Client ID): a3b2c1d4-e5f6-7890-abcd-ef1234567890
  ObjectId:          11111111-2222-3333-4444-555555555555
  DisplayName:       CI-CD-Pipeline-App
```

`New-MgApplication` 是 Microsoft Graph PowerShell SDK 中创建应用注册的核心命令。`SignInAudience` 参数控制应用的适用范围：`AzureADMyOrg` 表示仅限当前租户的单租户应用，`AzureADMultipleOrgs` 为多租户应用，`AzureADandPersonalMicrosoftAccount` 则同时支持个人微软账户。`Web` 参数接受一个哈希表，用于配置 Web 平台的 redirect URI 等设置。

## 管理客户端密钥与凭据

应用注册创建后，通常需要为其添加客户端密钥（Client Secret）或证书凭据，以便应用程序在运行时进行身份验证。以下脚本展示如何添加密钥并管理其生命周期。

```powershell
# 获取目标应用的 ObjectId
$app = Get-MgApplication -Filter "displayName eq 'CI-CD-Pipeline-App'"

# 创建客户端密钥，有效期 6 个月
$secretStartDate = Get-Date
$secretEndDate = $secretStartDate.AddMonths(6)

$passwordCred = @{
    DisplayName = "Pipeline-Secret-$(Get-Date -Format 'yyyyMMdd')"
    StartDateTime = $secretStartDate
    EndDateTime = $secretEndDate
}

$secret = Add-MgApplicationPassword -ApplicationId $app.Id `
    -PasswordCredential $passwordCred

Write-Host "客户端密钥已添加"
Write-Host "  KeyId:     $($secret.KeyId)"
Write-Host "  SecretKey: $($secret.SecretText)"
Write-Host "  有效期至:   $secretEndDate"
Write-Host ""
Write-Host "重要：请立即将 SecretText 安全保存，此值仅在创建时显示一次。"

# 列出该应用所有凭据，检查即将过期的密钥
$allCreds = Get-MgApplication -ApplicationId $app.Id
$expiredCount = 0
$expiringSoon = @()

foreach ($cred in $allCreds.PasswordCredentials) {
    $remaining = ($cred.EndDateTime - (Get-Date)).Days
    if ($remaining -le 0) {
        $expiredCount++
    }
    if ($remaining -gt 0 -and $remaining -le 30) {
        $expiringSoon += $cred
    }
}

Write-Host "`n凭据状态统计："
Write-Host "  已过期: $expiredCount 个"
Write-Host "  即将过期（30天内）: $($expiringSoon.Count) 个"
```

执行结果示例：

```
客户端密钥已添加
  KeyId:     aaaabbbb-cccc-dddd-eeee-ffffffffffff
  SecretKey: abc123XYZ789~def456.GHI890-ghi
  有效期至:   05/13/2026 00:00:00

重要：请立即将 SecretText 安全保存，此值仅在创建时显示一次。

凭据状态统计：
  已过期: 1 个
  即将过期（30天内）: 2 个
```

`Add-MgApplicationPassword` 为应用添加密码凭据，返回的 `SecretText` 是密钥的明文值，仅在此刻可见。务必将其存入密钥管理服务（如 Azure Key Vault），切勿写入代码或配置文件。定期扫描即将过期的密钥并提前轮换，是保障服务连续性的关键措施。建议在 CI/CD 流水线中添加自动化检查，当密钥即将过期时自动触发告警。

## 配置 API 权限并创建服务主体

应用注册的另一个关键步骤是声明所需的 API 权限，然后创建服务主体（Enterprise Application）以获取实际访问能力。以下脚本演示如何配置 Microsoft Graph 的委派权限并创建服务主体。

```powershell
# 获取 Microsoft Graph 服务主体的 AppId（租户内固定值）
$graphSp = Get-MgServicePrincipal -Filter "appId eq '00000003-0000-0000-c000-000000000000'"

# 定义需要申请的委派权限（Delegated Permission）
# User.Read        - 读取当前登录用户的基本信息
# Mail.Read        - 读取用户邮件
# Calendars.Read   - 读取用户日历
$requiredPermissions = @(
    @{ Id = "e1fe6dd8-ba31-4d61-89e7-88639da4683d"; Type = "Scope" }
    @{ Id = "810c84a8-4a9e-49e6-bf7d-1441c4f84e72"; Type = "Scope" }
    @{ Id = "465a38f9-76ea-45b9-9f34-2e6e3c3c7a0b"; Type = "Scope" }
)

$app = Get-MgApplication -Filter "displayName eq 'CI-CD-Pipeline-App'"

# 构造 requiredResourceAccess 对象
$resourceAccess = foreach ($perm in $requiredPermissions) {
    @{
        Id   = $perm.Id
        Type = $perm.Type
    }
}

# 更新应用的 API 权限声明
Update-MgApplication -ApplicationId $app.Id `
    -RequiredResourceAccess @(
        @{
            ResourceAppId = $graphSp.AppId
            ResourceAccess = @($resourceAccess)
        }
    )

Write-Host "API 权限已配置，等待管理员同意..."

# 创建服务主体（如已存在则跳过）
$existingSp = Get-MgServicePrincipal -Filter "appId eq '$($app.AppId)'" -ErrorAction SilentlyContinue
if (-not $existingSp) {
    $sp = New-MgServicePrincipal -AppId $app.AppId
    Write-Host "服务主体已创建，ObjectId: $($sp.Id)"
} else {
    Write-Host "服务主体已存在，ObjectId: $($existingSp.Id)"
}

Write-Host "`n注意：委派权限需要管理员通过 Azure 门户或以下 URL 进行同意："
Write-Host "https://login.microsoftonline.com/$((Get-MgContext).TenantId)/adminconsent?client_id=$($app.AppId)"
```

执行结果示例：

```
API 权限已配置，等待管理员同意...
服务主体已创建，ObjectId: 66666666-7777-8888-9999-000000000000

注意：委派权限需要管理员通过 Azure 门户或以下 URL 进行同意：
https://login.microsoftonline.com/contoso.onmicrosoft.com/adminconsent?client_id=a3b2c1d4-e5f6-7890-abcd-ef1234567890
```

API 权限分为两种类型：`Scope`（委派权限，代表用户执行操作）和 `Role`（应用程序权限，应用以自身身份执行操作）。`RequiredResourceAccess` 仅声明了应用"需要"哪些权限，实际生效还需要管理员通过同意流程（Admin Consent）审批。权限 ID 可以通过查询目标 API 服务主体的 `Oauth2PermissionScopes`（委派权限）或 `AppRoles`（应用程序权限）属性获取。

## 批量审计租户内的应用注册

对于安全团队和 IT 管理员而言，定期审计租户内的应用注册状况是保障身份安全的重要环节。以下脚本批量获取所有应用注册，并生成包含凭据状态、权限范围等信息的审计报告。

```powershell
# 获取租户内所有应用注册
$allApps = Get-MgApplication -All

$auditDate = Get-Date -Format "yyyyMMdd"
$reportPath = "$HOME/EntraID_AppAudit_$auditDate.csv"

$auditRows = foreach ($application in $allApps) {
    # 检查凭据状态
    $hasPassword = $application.PasswordCredentials.Count -gt 0
    $hasKeyCert = $application.KeyCredentials.Count -gt 0
    $expiredCreds = @($application.PasswordCredentials | Where-Object {
        $_.EndDateTime -lt (Get-Date)
    })
    $expiringCreds = @($application.PasswordCredentials | Where-Object {
        $remaining = ($_.EndDateTime - (Get-Date)).Days
        $remaining -gt 0 -and $remaining -le 90
    })

    # 统计申请的 API 权限数量
    $apiCount = 0
    foreach ($resource in $application.RequiredResourceAccess) {
        $apiCount += $resource.ResourceAccess.Count
    }

    [PSCustomObject]@{
        AppId              = $application.AppId
        DisplayName        = $application.DisplayName
        CreatedDateTime    = $application.CreatedDateTime
        SignInAudience     = $application.SignInAudience
        HasClientSecret    = $hasPassword
        HasCertificate     = $hasKeyCert
        ExpiredCredCount   = $expiredCreds.Count
        ExpiringCredCount  = $expiringCreds.Count
        ApiPermissionCount = $apiCount
        PublisherDomain    = $application.PublisherDomain
    }
}

# 导出审计报告
$auditRows | Export-Csv -Path $reportPath -NoTypeInformation -Encoding UTF8

# 输出概要统计
$totalApps = $auditRows.Count
$withExpiredCreds = @($auditRows | Where-Object { $_.ExpiredCredCount -gt 0 }).Count
$withExpiringCreds = @($auditRows | Where-Object { $_.ExpiringCredCount -gt 0 }).Count
$multiTenant = @($auditRows | Where-Object { $_.SignInAudience -ne "AzureADMyOrg" }).Count

Write-Host "审计报告已导出: $reportPath"
Write-Host "`n概要统计："
Write-Host "  应用总数:         $totalApps"
Write-Host "  含已过期凭据:     $withExpiredCreds"
Write-Host "  含即将过期凭据:   $withExpiringCreds"
Write-Host "  多租户应用:       $multiTenant"
```

执行结果示例：

```
审计报告已导出: /home/user/EntraID_AppAudit_20251113.csv

概要统计：
  应用总数:         87
  含已过期凭据:     12
  含即将过期凭据:   5
  多租户应用:       8
```

这段脚本对租户内所有应用注册进行了全面审计，重点关注三个安全维度：凭据生命周期（是否存在过期或即将过期的密钥）、权限范围（申请了多少 API 权限）、应用可见性（是否为多租户应用，意味着其他组织的用户也能看到）。建议将此脚本配置为每周自动执行，配合邮件或 Teams 通知，在凭据即将过期或出现异常配置时及时预警。

## 注意事项

1. **模块安装与版本**：本文使用 `Microsoft.Graph.Applications` 模块（属于 Microsoft Graph PowerShell SDK v2），安装命令为 `Install-Module Microsoft.Graph.Applications -Scope CurrentUser`。请确保模块版本不低于 2.0，旧版 `AzureAD` 模块已停止更新，不建议在新项目中使用。

2. **权限最小化原则**：创建和管理应用注册需要 `Application.ReadWrite.All` 等高权限范围。在生产环境中，建议使用专用的高权限账户执行管理操作，日常应用开发使用 `Application.Read.All` 只读权限进行查询。遵循最小权限原则，降低因凭据泄露导致的攻击面。

3. **密钥安全存储**：客户端密钥（Client Secret）仅在创建时返回一次明文值，务必立即存入 Azure Key Vault 或其他受认可的密钥管理系统。禁止将密钥硬编码在代码中、写入配置文件或提交到 Git 仓库。对于生产环境，优先使用证书凭据而非密码凭据，安全性更高。

4. **管理员同意流程**：应用声明 API 权限后，部分高敏感权限（如 `Mail.Read`、`Files.Read.All`）需要全局管理员在 Azure 门户或通过同意 URL 手动审批。自动化场景中可以使用 `New-MgOauth2PermissionGrant` 命令编程式同意，但这本身也需要 `DelegatedPermissionGrant.Write.All` 权限。

5. **多租户应用的安全风险**：当 `SignInAudience` 设为多租户模式时，其他 Entra ID 租户的用户也可以登录并授权该应用。在创建多租户应用前，务必评估是否有业务需求，并在应用中实现必要的租户验证逻辑，防止未预期的跨租户访问。

6. **定期清理废弃应用**：随着时间推移，租户中会积累大量不再使用的应用注册。建议定期运行审计脚本，标记超过 90 天无登录记录、凭据已过期且未续期的应用，经安全团队确认后通过 `Remove-MgApplication` 删除，减少潜在的攻击入口。
