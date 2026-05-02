---
layout: post
date: 2025-06-17 08:00:00
updated: 2025-06-17 08:00:00
title: "PowerShell 技能连载 - Microsoft Graph API 集成"
description: PowerTip of the Day - Microsoft Graph API Integration in PowerShell
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
- microsoft-graph
- api
- entra-id
- office365
---

_适用于 PowerShell 5.1 及以上版本，需安装 Microsoft.Graph 模块_

Microsoft Graph 是 Microsoft 365 平台的统一 API 网关——它整合了 Azure AD（现称 Entra ID）、Exchange Online、SharePoint、Teams、OneDrive 等所有 Microsoft 365 服务的数据和操作。通过 PowerShell 的 `Microsoft.Graph` 模块，运维人员可以用脚本化管理用户、组、许可证、设备策略等，替代传统的多个独立模块。

本文将讲解 Microsoft Graph PowerShell 的连接、用户管理、组操作和常用自动化场景。

## 连接与认证

```powershell
# 安装 Microsoft Graph 模块
Install-Module -Name Microsoft.Graph -Scope CurrentUser -Force

# 选择性安装（更快）
# Install-Module -Name Microsoft.Graph.Users, Microsoft.Graph.Groups -Scope CurrentUser

# 连接到 Microsoft Graph（交互式登录）
Connect-MgGraph -Scopes "User.Read.All", "Group.Read.All", "Directory.Read.All"

# 查看当前连接信息
Get-MgContext | Select-Object Account, Tenant, Scopes |
    Format-List

# 使用应用权限连接（自动化场景）
$clientId = "your-app-client-id"
$tenantId = "your-tenant-id"
$certThumbprint = "ABC123DEF456"

Connect-MgGraph -ClientId $clientId -TenantId $tenantId `
    -CertificateThumbprint $certThumbprint

# 断开连接
Disconnect-MgGraph
```

执行结果示例：

```
Account : admin@contoso.com
Tenant  : contoso.onmicrosoft.com
Scopes  : {User.Read.All, Group.Read.All, Directory.Read.All}

Welcome To Microsoft Graph!
```

## 用户管理

```powershell
# 列出所有用户
Get-MgUser -All -ConsistencyLevel eventual |
    Select-Object DisplayName, UserPrincipalName, Mail, Department, JobTitle |
    Format-Table -AutoSize

# 搜索特定用户
$user = Get-MgUser -Filter "displayName eq 'John Doe'" -ConsistencyLevel eventual
$user | Select-Object Id, DisplayName, UserPrincipalName, Department

# 创建新用户
$newUser = @{
    AccountEnabled    = $true
    DisplayName       = "张伟"
    MailNickname      = "wei.zhang"
    UserPrincipalName = "wei.zhang@contoso.com"
    Department        = "IT"
    JobTitle          = "DevOps 工程师"
    PasswordProfile   = @{
        ForceChangePasswordNextSignIn = $true
        Password = "TempP@ssw0rd123!"
    }
}

New-MgUser -BodyParameter $newUser
Write-Host "用户已创建：wei.zhang@contoso.com" -ForegroundColor Green

# 更新用户信息
Update-MgUser -UserId "wei.zhang@contoso.com" -Department "DevOps"

# 禁用用户账户
Update-MgUser -UserId "wei.zhang@contoso.com" -AccountEnabled:$false

# 获取用户的组成员身份
Get-MgUserMemberOf -UserId "john.doe@contoso.com" |
    ForEach-Object {
        $group = Get-MgGroup -GroupId $_.Id
        [PSCustomObject]@{
            GroupName = $group.DisplayName
            GroupType = $group.GroupTypes -join ','
        }
    } | Format-Table -AutoSize
```

执行结果示例：

```
DisplayName  UserPrincipalName       Department  JobTitle
-----------  -----------------       ----------  --------
John Doe     john.doe@contoso.com    Engineering Senior Dev
Jane Smith   jane.smith@contoso.com  HR          HR Manager

Id        : 12345678-abcd-...
DisplayName : John Doe
UserPrincipalName : john.doe@contoso.com

用户已创建：wei.zhang@contoso.com

GroupName        GroupType
---------        ---------
All Users        {}
IT-Admins        {}
Developers       {DynamicMembership}
```

## 组管理

```powershell
# 列出所有组
Get-MgGroup -All |
    Select-Object DisplayName, Description,
        @{N='类型'; E={if ($_.GroupTypes -contains 'Unified') { 'Microsoft 365' } else { 'Security' }}},
        @{N='成员数'; E={$_.Members.Count}} |
    Sort-Object DisplayName |
    Format-Table -AutoSize

# 创建安全组
New-MgGroup -DisplayName "Cloud-Admins" `
    -Description "云平台管理员组" `
    -MailEnabled:$false `
    -SecurityEnabled:$true

# 添加成员到组
$userId = (Get-MgUser -Filter "displayName eq 'John Doe'").Id
$groupId = (Get-MgGroup -Filter "displayName eq 'Cloud-Admins'").Id

New-MgGroupMember -GroupId $groupId -DirectoryObjectId $userId
Write-Host "已将 John Doe 添加到 Cloud-Admins 组" -ForegroundColor Green

# 查看组成员
Get-MgGroupMember -GroupId $groupId |
    ForEach-Object {
        Get-MgUser -UserId $_.Id |
            Select-Object DisplayName, UserPrincipalName
    } | Format-Table -AutoSize

# 创建动态组（基于规则的自动成员管理）
$dynamicGroup = @{
    DisplayName       = "All-Engineering"
    Description       = "工程部门所有成员"
    GroupTypes        = @("DynamicMembership")
    MailEnabled       = $false
    SecurityEnabled   = $true
    MembershipRule    = 'user.department -eq "Engineering"'
    MembershipRuleProcessingState = "On"
}

New-MgGroup -BodyParameter $dynamicGroup
```

执行结果示例：

```
DisplayName    类型           成员数
-----------    ----           ------
All Users      Security           245
IT-Admins      Security            12
Developers     Microsoft 365       35
Cloud-Admins   Security             3

已将 John Doe 添加到 Cloud-Admins 组

DisplayName UserPrincipalName
----------- -----------------
John Doe    john.doe@contoso.com
Jane Smith  jane.smith@contoso.com
```

## 许可证管理

```powershell
# 查看租户可用的许可证
Get-MgSubscribedSku |
    Select-Object SkuPartNumber,
        @{N='已用'; E={$_.PrepaidUnits.Enabled - $_.Consumed}},
        @{N='总量'; E={$_.PrepaidUnits.Enabled}},
        @{N='已消耗'; E={$_.Consumed}} |
    Format-Table -AutoSize

# 为用户分配许可证
$license = Get-MgSubscribedSku | Where-Object SkuPartNumber -eq 'ENTERPRISEPACK'

Set-MgUserLicense -UserId "wei.zhang@contoso.com" `
    -AddLicenses @{ SkuId = $license.SkuId } `
    -RemoveLicenses @()

Write-Host "已分配 Office 365 E3 许可证" -ForegroundColor Green

# 批量分配许可证
$users = Get-MgUser -Filter "department eq 'Engineering'" -ConsistencyLevel eventual -All
$skuId = (Get-MgSubscribedSku | Where-Object SkuPartNumber -eq 'ENTERPRISEPACK').SkuId

foreach ($user in $users) {
    Set-MgUserLicense -UserId $user.Id `
        -AddLicenses @{ SkuId = $skuId } `
        -RemoveLicenses @()
    Write-Host "已分配：$($user.DisplayName)" -ForegroundColor Green
}
```

执行结果示例：

```
SkuPartNumber       已用 总量 已消耗
------------        ---- ---- ------
ENTERPRISEPACK       120  250     130
EMS                  45   100      55

已分配 Office 365 E3 许可证
已分配：John Doe
已分配：Alice Smith
```

## 注意事项

1. **权限范围**：使用 `-Scopes` 参数指定最小必要权限，避免过度授权
2. **ConsistencyLevel**：部分高级查询需要添加 `-ConsistencyLevel eventual` 和 `$Count` 参数
3. **分页处理**：大量结果时使用 `-All` 参数自动处理分页，否则只返回第一页
4. **应用权限**：自动化脚本应使用应用权限（Client Credentials 流），而非用户委派权限
5. **Graph API 版本**：MgGraph 模块默认使用 v1.0 端点，使用 `Invoke-MgGraphRequest` 可以调用 beta 端点
6. **速率限制**：Microsoft Graph 有 API 调用频率限制，大批量操作时添加适当延迟
