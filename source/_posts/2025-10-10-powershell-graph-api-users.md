---
layout: post
date: 2025-10-10 08:00:00
updated: 2025-10-10 08:00:00
title: "PowerShell 技能连载 - Microsoft Graph 用户管理"
description: PowerTip of the Day - Microsoft Graph User Management in PowerShell
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
- azure
- identity
- office
---

_适用于 PowerShell 5.1 及以上版本_

<!-- more -->

## 为什么需要脚本化用户管理

在企业的 Microsoft 365 环境中，用户管理是一项高频且繁琐的日常工作。新员工入职需要创建账号、分配许可证、加入对应部门的安全组；员工离职则需要禁用账号、回收许可证、转移邮箱权限。如果通过 Microsoft 365 管理中心手动操作，不仅效率低下，还容易遗漏步骤导致安全风险。

Microsoft Graph PowerShell 模块（`Microsoft.Graph`）是微软官方推荐的 Entra ID（原 Azure AD）管理工具。它通过统一的 Graph API 端点提供用户全生命周期管理能力，包括创建、查询、更新、删除以及许可证分配。相比旧版 AzureAD 模块，Graph 模块支持更细粒度的权限控制和更好的分页性能。

本文将围绕用户管理的核心场景，演示如何使用 `Microsoft.Graph.Users` 模块完成用户创建与初始化、批量查询与筛选、以及用户生命周期自动化操作。

## 连接 Microsoft Graph 并准备环境

在开始管理用户之前，需要先安装模块并建立经过身份验证的连接。连接时通过 `-Scopes` 参数声明本次操作所需的最低权限，Graph 服务会根据登录账户的角色和已授予的同意来决定是否放行。

```powershell
# 安装 Microsoft Graph Users 模块（仅首次）
Install-Module -Name Microsoft.Graph.Users -Scope CurrentUser -Force

# 连接到 Graph API，声明用户读写权限
Connect-MgGraph -Scopes "User.ReadWrite.All", "Directory.Read.All"

# 确认连接状态
$context = Get-MgContext
Write-Host "已连接账户: $($context.Account)"
Write-Host "租户标识: $($context.TenantId)"
Write-Host "已授权范围: $($context.Scopes -join ', ')"
```

```text
已连接账户: admin@contoso.com
租户标识: contoso.onmicrosoft.com
已授权范围: User.ReadWrite.All, Directory.Read.All
```

## 创建用户并完成初始配置

新员工入职时，通常需要一次性完成多项配置：创建账户、设置初始密码、填写部门信息。下面的脚本将多个步骤组织在一起，并为每个步骤添加错误处理，确保任何一个环节失败都能及时发现。

```powershell
# 定义新用户的完整信息
$newUsers = @(
    @{
        DisplayName       = "李明"
        MailNickname      = "ming.li"
        UserPrincipalName = "ming.li@contoso.com"
        Department        = "工程部"
        JobTitle          = "高级开发工程师"
        UsageLocation     = "CN"
    }
    @{
        DisplayName       = "王芳"
        MailNickname      = "fang.wang"
        UserPrincipalName = "fang.wang@contoso.com"
        Department        = "市场部"
        JobTitle          = "市场经理"
        UsageLocation     = "CN"
    }
)

# 生成随机初始密码
function New-RandomPassword {
    $length = 16
    $chars = @()
    # 确保包含各类字符
    $chars += [char](Get-Random -Minimum 65 -Maximum 91)   # 大写字母
    $chars += [char](Get-Random -Minimum 97 -Maximum 123)  # 小写字母
    $chars += [char](Get-Random -Minimum 48 -Maximum 58)   # 数字
    $chars += [char](Get-Random -Minimum 35 -Maximum 39)   # 特殊字符
    # 填充剩余长度
    foreach ($i in 1..($length - 4)) {
        $chars += [char](Get-Random -Minimum 33 -Maximum 127)
    }
    # 打乱顺序并返回
    $password = ($chars | Sort-Object { Get-Random }) -join ''
    return $password
}

# 批量创建用户
$results = @()

foreach ($userInfo in $newUsers) {
    $tempPassword = New-RandomPassword
    $body = @{
        AccountEnabled    = $true
        DisplayName       = $userInfo.DisplayName
        MailNickname      = $userInfo.MailNickname
        UserPrincipalName = $userInfo.UserPrincipalName
        Department        = $userInfo.Department
        JobTitle          = $userInfo.JobTitle
        UsageLocation     = $userInfo.UsageLocation
        PasswordProfile   = @{
            ForceChangePasswordNextSignIn = $true
            Password = $tempPassword
        }
    }

    try {
        $user = New-MgUser -BodyParameter $body
        $results += [PSCustomObject]@{
            Status     = "成功"
            UPN        = $userInfo.UserPrincipalName
            UserId     = $user.Id
            TempPwdLen = $tempPassword.Length
        }
        Write-Host "[OK] 已创建用户: $($userInfo.DisplayName)" -ForegroundColor Green
    }
    catch {
        $results += [PSCustomObject]@{
            Status     = "失败"
            UPN        = $userInfo.UserPrincipalName
            UserId     = $_.Exception.Message.Substring(0, [Math]::Min(60, $_.Exception.Message.Length))
            TempPwdLen = 0
        }
        Write-Host "[FAIL] 创建失败: $($userInfo.DisplayName) - $($_.Exception.Message)" -ForegroundColor Red
    }
}

# 输出创建结果汇总
$results | Format-Table -AutoSize
```

```text
[OK] 已创建用户: 李明
[OK] 已创建用户: 王芳

Status UPN                   UserId                                  TempPwdLen
------ ---                   ------                                  ----------
成功   ming.li@contoso.com   a1b2c3d4-e5f6-7890-abcd-ef1234567890            16
成功   fang.wang@contoso.com b2c3d4e5-f6a7-8901-bcde-f12345678901            16
```

## 查询与筛选用户信息

用户数据是企业目录的核心资产，掌握高效的查询技巧对日常运维至关重要。Graph API 支持 OData 筛选语法，可以对用户属性进行精确匹配和排序。对于复杂筛选条件，还可以使用 `-ConsistencyLevel eventual` 开启高级查询功能。

```powershell
# 基本查询：列出所有启用的用户
$activeUsers = Get-MgUser -All -Filter "accountEnabled eq true" |
    Sort-Object DisplayName |
    Select-Object DisplayName, UserPrincipalName, Department, JobTitle

Write-Host "当前活跃用户数: $($activeUsers.Count)"
$activeUsers | Format-Table -AutoSize

# 按部门筛选
$engineers = Get-MgUser -Filter "department eq '工程部'" `
    -ConsistencyLevel eventual -CountVariable engCount -All

Write-Host "`n工程部人数: $engCount"
foreach ($eng in $engineers) {
    Write-Host "  - $($eng.DisplayName) ($($eng.UserPrincipalName))"
}

# 模糊搜索：查找显示名包含"李"的用户
$searchResult = Get-MgUser -Filter "startsWith(displayName,'李')" `
    -ConsistencyLevel eventual -All

Write-Host "`n搜索'李'姓用户结果："
foreach ($item in $searchResult) {
    Write-Host "  $($item.DisplayName) | $($item.Department) | $($item.Mail)"
}

# 查看用户的详细信息（包括扩展属性）
$targetUser = Get-MgUser -UserId "ming.li@contoso.com" -Property DisplayName, UserPrincipalName, Department, JobTitle, CreatedDateTime, LastPasswordChangeDateTime, SignInActivity

[PSCustomObject]@{
    显示名     = $targetUser.DisplayName
    邮箱       = $targetUser.UserPrincipalName
    部门       = $targetUser.Department
    职位       = $targetUser.JobTitle
    创建时间   = $targetUser.AdditionalProperties.createdDateTime
    上次改密   = $targetUser.AdditionalProperties.lastPasswordChangeDateTime
    上次登录   = $targetUser.AdditionalProperties.signInActivity.lastSignInDateTime
} | Format-List
```

```text
当前活跃用户数: 128

DisplayName  UserPrincipalName       Department  JobTitle
-----------  -----------------       ----------  --------
Alice Chen   alice.chen@contoso.com  工程部      前端开发
李明         ming.li@contoso.com     工程部      高级开发工程师
王芳         fang.wang@contoso.com   市场部      市场经理

工程部人数: 45
  - Alice Chen (alice.chen@contoso.com)
  - 李明 (ming.li@contoso.com)

搜索'李'姓用户结果：
  李明 | 工程部 | ming.li@contoso.com
  李娜 | 财务部 | na.li@contoso.com

显示名   : 李明
邮箱     : ming.li@contoso.com
部门     : 工程部
职位     : 高级开发工程师
创建时间 : 2025-10-10T02:30:00Z
上次改密 : 2025-10-10T02:30:00Z
上次登录 : 2025-10-10T08:15:00Z
```

## 用户生命周期自动化

离职流程是用户管理中最容易出问题的环节。一个完整的离职处理需要按顺序执行：禁用账户、移除组成员身份、回收许可证、更新描述信息。将这个过程封装为函数，可以确保每次操作都不遗漏步骤。

```powershell
function Disable-UserLifecycle {
    <#
    .SYNOPSIS
    执行用户离职处理流程
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory)]
        [string]$UserPrincipalName,

        [string]$Reason = "员工离职"
    )

    Write-Host "`n========== 离职处理: $UserPrincipalName ==========" -ForegroundColor Cyan

    # 第一步：获取用户信息
    try {
        $user = Get-MgUser -UserId $UserPrincipalName -ErrorAction Stop
        Write-Host "[1/5] 用户信息已获取: $($user.DisplayName)" -ForegroundColor Green
    }
    catch {
        Write-Host "[1/5] 用户不存在或无法访问: $UserPrincipalName" -ForegroundColor Red
        return
    }

    # 第二步：禁用账户
    if ($PSCmdlet.ShouldProcess($UserPrincipalName, "禁用账户")) {
        Update-MgUser -UserId $UserPrincipalName -AccountEnabled:$false
        Write-Host "[2/5] 账户已禁用" -ForegroundColor Green
    }

    # 第三步：移除所有组成员身份
    $memberships = Get-MgUserMemberOf -UserId $UserPrincipalName -All
    $groupCount = 0

    foreach ($member in $memberships) {
        # 仅处理组类型（过滤掉目录角色等）
        if ($member.AdditionalProperties.'@odata.type' -eq '#microsoft.graph.group') {
            try {
                Remove-MgGroupMember -GroupId $member.Id -DirectoryObjectId $user.Id -ErrorAction SilentlyContinue
                $groupCount++
            }
            catch {
                # 动态组无法手动移除成员，记录即可
                Write-Host "  跳过动态组: $($member.AdditionalProperties.displayName)" -ForegroundColor Yellow
            }
        }
    }
    Write-Host "[3/5] 已从 $groupCount 个组中移除" -ForegroundColor Green

    # 第四步：回收许可证
    $licenses = Get-MgUserLicenseDetail -UserId $UserPrincipalName -ErrorAction SilentlyContinue
    $licenseSkuIds = @()

    foreach ($lic in $licenses) {
        $licenseSkuIds += $lic.SkuId
    }

    if ($licenseSkuIds.Count -gt 0) {
        $removeLicenses = @()
        foreach ($skuId in $licenseSkuIds) {
            $removeLicenses += @{ SkuId = $skuId }
        }
        Set-MgUserLicense -UserId $UserPrincipalName `
            -AddLicenses @() `
            -RemoveLicenses $removeLicenses
        Write-Host "[4/5] 已回收 $($licenseSkuIds.Count) 个许可证" -ForegroundColor Green
    }
    else {
        Write-Host "[4/5] 无需回收许可证" -ForegroundColor Yellow
    }

    # 第五步：更新描述记录离职原因和日期
    $leaveDate = Get-Date -Format "yyyy-MM-dd"
    Update-MgUser -UserId $UserPrincipalName `
        -AboutMe "$Reason - 处理日期: $leaveDate"
    Write-Host "[5/5] 离职记录已更新 ($leaveDate)" -ForegroundColor Green

    Write-Host "`n========== 处理完成 ==========" -ForegroundColor Cyan

    # 返回处理结果
    return [PSCustomObject]@{
        User           = $user.DisplayName
        UPN            = $UserPrincipalName
        Disabled       = $true
        GroupsRemoved  = $groupCount
        LicensesRevoked = $licenseSkuIds.Count
        ProcessedDate  = $leaveDate
    }
}

# 执行离职处理
$leavingUsers = @("ming.li@contoso.com", "fang.wang@contoso.com")

$reports = @()
foreach ($upn in $leavingUsers) {
    $report = Disable-UserLifecycle -UserPrincipalName $upn -Reason "合同到期离职"
    $reports += $report
}

# 输出处理报告
Write-Host "`n离职处理汇总报告："
$reports | Format-Table -AutoSize
```

```text
========== 离职处理: ming.li@contoso.com ==========
[1/5] 用户信息已获取: 李明
[2/5] 账户已禁用
[3/5] 已从 5 个组中移除
[4/5] 已回收 1 个许可证
[5/5] 离职记录已更新 (2025-10-10)

========== 处理完成 ==========

========== 离职处理: fang.wang@contoso.com ==========
[1/5] 用户信息已获取: 王芳
[2/5] 账户已禁用
[3/5] 已从 3 个组中移除
[4/5] 已回收 2 个许可证
[5/5] 离职记录已更新 (2025-10-10)

========== 处理完成 ==========

离职处理汇总报告：

User  UPN                   Disabled GroupsRemoved LicensesRevoked ProcessedDate
----  ---                   -------- ------------- --------------- -------------
李明  ming.li@contoso.com      True             5               1 2025-10-10
王芳  fang.wang@contoso.com    True             3               2 2025-10-10
```

## 注意事项

1. **权限最小化原则**：连接 Graph API 时应按操作类型声明最小权限集。只读操作用 `User.Read.All`，写操作才需要 `User.ReadWrite.All`。避免在脚本中统一请求全部权限，防止权限滥用带来的安全审计风险。

2. **ConsistencyLevel 与高级查询**：使用 `startsWith`、`endsWith`、`eq` 对非索引属性筛选时，必须添加 `-ConsistencyLevel eventual` 参数，并使用 `-CountVariable` 接收匹配数量。否则 Graph API 会返回"不支持的查询"错误。

3. **分页与 -All 参数**：默认情况下 `Get-MgUser` 只返回前 100 条记录。用户数超过 100 时必须加 `-All` 参数自动处理分页，或者通过 `-Top` 和 `-Skip` 参数手动分页控制内存占用。

4. **密码策略合规**：创建用户时的初始密码必须满足 Entra ID 的密码复杂度要求（至少 8 位，包含大小写字母、数字和特殊字符中的三类）。建议配合 `ForceChangePasswordNextSignIn = $true`，确保用户首次登录时强制修改密码。

5. **许可证回收时机**：禁用账户后许可证并不会自动释放，必须显式调用 `Set-MgUserLicense -RemoveLicenses` 回收。如果许可证余额紧张，建议在离职流程中优先执行许可证回收步骤，避免因中间步骤失败导致许可证被占用。

6. **错误处理与幂等性**：批量操作用户时，务必对每个步骤添加 `try/catch` 错误处理。对于可能重复执行的场景（如入职脚本被运行两次），应在创建前先检查用户是否已存在，使用 `Get-MgUser -Filter` 替代直接创建，保证脚本的幂等性。
