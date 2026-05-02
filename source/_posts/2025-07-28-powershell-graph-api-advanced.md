---
layout: post
date: 2025-07-28 08:00:00
updated: 2025-07-28 08:00:00
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
- azure
---

_适用于 PowerShell 5.1 及以上版本，需要 Microsoft Graph PowerShell SDK 或 Azure AD 租户_

Microsoft Graph API 是微软云服务的统一入口——Azure AD（Entra ID）用户管理、Teams 消息、SharePoint 文件、Outlook 邮件、OneDrive，几乎所有 Microsoft 365 服务都通过 Graph API 暴露。Microsoft Graph PowerShell SDK 封装了这些 API，让运维人员可以用 PowerShell 管理整个 Microsoft 365 生态。

本文将讲解 Microsoft Graph PowerShell SDK 的高级用法和实用的管理场景。

<!-- more -->

## 连接与认证

```powershell
# 安装 Microsoft Graph PowerShell SDK
# Install-Module Microsoft.Graph -Scope CurrentUser

# 连接到 Graph API（交互式登录）
Connect-MgGraph -Scopes "User.Read.All", "Group.Read.All", "Directory.Read.All"

# 查看当前连接信息
Get-MgContext | Format-List

# 使用应用权限连接（适合自动化）
# $clientId = "your-app-id"
# $tenantId = "your-tenant-id"
# $certThumbprint = "cert-thumbprint"
# Connect-MgGraph -ClientId $clientId -TenantId $tenantId -CertificateThumbprint $certThumbprint

# 断开连接
# Disconnect-MgGraph
```

执行结果示例：

```
ClientId              : 14d82eec-204b-4c2f-b7e8-296a70dab67e
TenantId              : contoso.onmicrosoft.com
Scopes                : {User.Read.All, Group.Read.All, Directory.Read.All}
AuthType              : Delegated
TokenCredentialType   : InteractiveBrowser
Account               : admin@contoso.onmicrosoft.com
```

## 用户管理

```powershell
# 查询用户
# 获取所有用户
$users = Get-MgUser -All -Property DisplayName, Mail, JobTitle, Department, AccountEnabled
Write-Host "总用户数：$($users.Count)" -ForegroundColor Cyan

# 按部门筛选
$engineering = $users | Where-Object { $_.Department -eq "工程部" }
Write-Host "工程部人数：$($engineering.Count)"

# 搜索特定用户
$targetUser = Get-MgUser -Filter "DisplayName eq '张三'" -Property DisplayName, Mail, JobTitle
$targetUser | Format-List DisplayName, Mail, JobTitle

# 创建新用户
$newUser = @{
    AccountEnabled = $true
    DisplayName    = "测试用户"
    MailNickname   = "testuser"
    UserPrincipalName = "testuser@contoso.onmicrosoft.com"
    PasswordProfile = @{
        Password = "TempP@ss123!"
        ForceChangePasswordNextSignIn = $true
    }
}

# $created = New-MgUser -BodyParameter $newUser
# Write-Host "已创建用户：$($created.DisplayName) ($($created.Id))"

# 批量禁用离职用户
$disabledUsers = Get-MgUser -Filter "AccountEnabled eq false" -Property DisplayName, Mail
Write-Host "`n已禁用账户：$($disabledUsers.Count) 个" -ForegroundColor Yellow
$disabledUsers | Select-Object DisplayName, Mail | Format-Table -AutoSize

# 查看用户的登录日志
$signIns = Get-MgAuditLogSignIn -Top 5 -Filter "UserId eq '$($targetUser.Id)'"
$signIns | Select-Object CreatedDateTime, AppDisplayName, ClientAppUsed, Status |
    Format-Table -AutoSize
```

执行结果示例：

```
总用户数：2456
工程部人数：128

DisplayName : 张三
Mail        : zhangsan@contoso.com
JobTitle    : 高级工程师

已禁用账户：15 个
DisplayName     Mail
-----------     ----
离职用户A       usera@contoso.com
离职用户B       userb@contoso.com

CreatedDateTime       AppDisplayName  ClientAppUsed Status
---------------       --------------  ------------- ------
2025-07-28T07:30:15Z  Outlook         Browser       Success
2025-07-28T07:15:22Z  Microsoft Teams Desktop App    Success
```

## 组与许可证管理

```powershell
# 组管理
$groups = Get-MgGroup -All -Property DisplayName, Description, GroupTypes, MembershipRule
Write-Host "总组数：$($groups.Count)" -ForegroundColor Cyan

# 查找安全组
$securityGroups = $groups | Where-Object { $_.GroupTypes -notcontains "Unified" }
Write-Host "安全组：$($securityGroups.Count) 个"

# 查找 Microsoft 365 组
$m365Groups = $groups | Where-Object { $_.GroupTypes -contains "Unified" }
Write-Host "M365 组：$($m365Groups.Count) 个"

# 查看组成员
$groupName = "工程部-开发组"
$group = Get-MgGroup -Filter "DisplayName eq '$groupName'"
$members = Get-MgGroupMember -GroupId $group.Id -All
Write-Host "`n$groupName 成员（$($members.Count) 人）：" -ForegroundColor Cyan
$members | ForEach-Object {
    $user = Get-MgUser -UserId $_.Id -Property DisplayName, Mail
    Write-Host "  $($user.DisplayName) - $($user.Mail)"
}

# 许可证管理
$subscribedSkus = Get-MgSubscribedSku
Write-Host "`n许可证概览：" -ForegroundColor Cyan
foreach ($sku in $subscribedSkus) {
    $available = $sku.PrepaidUnits.Enabled - $sku.ConsumedUnits
    Write-Host "  $($sku.SkuPartNumber)：已购买 $($sku.PrepaidUnits.Enabled)，已分配 $($sku.ConsumedUnits)，可用 $available"
}

# 批量添加用户到组
function Add-UsersToGroup {
    param(
        [string]$GroupName,
        [string[]]$UserEmails
    )

    $group = Get-MgGroup -Filter "DisplayName eq '$GroupName'"
    if (-not $group) {
        Write-Host "组不存在：$GroupName" -ForegroundColor Red
        return
    }

    foreach ($email in $UserEmails) {
        $user = Get-MgUser -Filter "Mail eq '$email'" -Property Id, DisplayName
        if ($user) {
            try {
                New-MgGroupMember -GroupId $group.Id -DirectoryObjectId $user.Id
                Write-Host "已添加：$($user.DisplayName) => $GroupName" -ForegroundColor Green
            } catch {
                Write-Host "添加失败：$email - $($_.Exception.Message)" -ForegroundColor Yellow
            }
        }
    }
}
```

执行结果示例：

```
总组数：89
安全组：65 个
M365 组：24 个

工程部-开发组 成员（15 人）：
  张三 - zhangsan@contoso.com
  李四 - lisi@contoso.com
  王五 - wangwu@contoso.com

许可证概览：
  ENTERPRISEPACK：已购买 500，已分配 245，可用 255
  EMS_E5：已购买 200，已分配 180，可用 20
```

## 设备与条件访问

```powershell
# 设备管理
$devices = Get-MgDevice -All -Property DisplayName, OperatingSystem, ApproximateLastSignInDateTime, TrustType
Write-Host "已注册设备：$($devices.Count)" -ForegroundColor Cyan

$deviceSummary = $devices | Group-Object OperatingSystem | Sort-Object Count -Descending
$deviceSummary | ForEach-Object {
    Write-Host "  $($_.Name)：$($_.Count) 台" -ForegroundColor Cyan
}

# 查找过期设备（90 天未登录）
$cutoff = (Get-Date).AddDays(-90)
$staleDevices = $devices | Where-Object {
    $_.ApproximateLastSignInDateTime -and
    [datetime]$_.ApproximateLastSignInDateTime -lt $cutoff
}
Write-Host "`n过期设备（90天未活跃）：$($staleDevices.Count) 台" -ForegroundColor Yellow

# 条件访问策略
$caPolicies = Get-MgIdentityConditionalAccessPolicy
Write-Host "`n条件访问策略：$($caPolicies.Count) 条" -ForegroundColor Cyan
$caPolicies | Select-Object DisplayName, State |
    Format-Table -AutoSize

# 导出用户报告
function Export-MgUserReport {
    param([string]$OutputPath = "C:\Reports\users.csv")

    $users = Get-MgUser -All -Property DisplayName, Mail, Department, JobTitle, AccountEnabled, CreatedDateTime

    $report = $users | Select-Object DisplayName, Mail, Department, JobTitle,
        @{N='Enabled'; E={$_.AccountEnabled}},
        @{N='Created'; E={$_.CreatedDateTime.ToString('yyyy-MM-dd')}}

    $report | Export-Csv $OutputPath -NoTypeInformation -Encoding UTF8
    Write-Host "用户报告已导出：$OutputPath ($($users.Count) 条)" -ForegroundColor Green
}

Export-MgUserReport
```

执行结果示例：

```
已注册设备：356
  Windows：245 台
  macOS：67 台
  iOS：32 台
  Android：12 台

过期设备（90天未活跃）：23 台

条件访问策略：8 条
DisplayName                 State
-----------                 -----
要求 MFA                    enabled
阻止旧版浏览器             enabled
要求合规设备               enabled
报告专用模式 - 位置检测    enabledForReportingButNotEnforced

用户报告已导出：C:\Reports\users.csv (2456 条)
```

## 注意事项

1. **权限范围**：连接时指定最小必要权限，避免使用过大的权限范围
2. **分页**：大量数据需要使用 `-All` 参数或手动处理分页，默认只返回部分结果
3. **速率限制**：Graph API 有请求频率限制，批量操作时添加 `Start-Sleep` 避免触发限流
4. **应用权限 vs 委托权限**：自动化脚本使用应用权限（证书认证），交互操作使用委托权限（用户登录）
5. **Consent**：某些权限需要管理员同意（Admin Consent），首次使用时需要授权
6. **模块更新**：Graph API 更新频繁，定期更新 SDK 模块：`Update-Module Microsoft.Graph`
