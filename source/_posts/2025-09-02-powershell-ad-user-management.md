---
layout: post
date: 2025-09-02 08:00:00
updated: 2025-09-02 08:00:00
title: "PowerShell 技能连载 - Active Directory 用户管理"
description: PowerTip of the Day - Active Directory User Management in PowerShell
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
- active-directory
- user-management
- windows-server
---

_适用于 PowerShell 5.1（Windows），需要 ActiveDirectory 模块及管理员权限_

Active Directory 是企业 Windows 网络的身份基础，用户账号的创建、修改、禁用、报告是系统管理员的日常任务。AD 用户管理看似简单——在图形界面里点几下鼠标就行，但当需要批量处理几十上百个账号时，手动操作既耗时又容易出错。PowerShell 的 `ActiveDirectory` 模块提供了完整的用户生命周期管理能力，从批量创建到权限审计，一条命令就能替代数十次点击。

本文将介绍 AD 用户管理的常用操作和批量自动化方案。

<!-- more -->

## 用户查询与报告

```powershell
# 导入模块
Import-Module ActiveDirectory

# 查询用户基本信息
Get-ADUser -Identity "zhangsan" -Properties DisplayName, Department, Title, LastLogonDate |
    Select-Object SamAccountName, DisplayName, Department, Title, Enabled, LastLogonDate |
    Format-List

# 搜索特定部门的用户
$users = Get-ADUser -Filter { Department -eq "工程部" -and Enabled -eq $true } `
    -Properties DisplayName, EmailAddress, Title, WhenCreated

$users | Select-Object DisplayName, EmailAddress, Title, WhenCreated |
    Format-Table -AutoSize

Write-Host "工程部活跃用户：$($users.Count) 人" -ForegroundColor Green

# 查找长期未登录的用户（90 天未活动）
$inactiveDate = (Get-Date).AddDays(-90)
$inactive = Get-ADUser -Filter { LastLogonDate -lt $inactiveDate -and Enabled -eq $true } `
    -Properties DisplayName, LastLogonDate, Department |
    Sort-Object LastLogonDate |
    Select-Object DisplayName, Department, LastLogonDate

Write-Host "90 天未登录的活跃账号：$($inactive.Count) 个" -ForegroundColor Yellow
$inactive | Format-Table -AutoSize

# 即将过期的密码统计
$expiringSoon = Get-ADUser -Filter { Enabled -eq $true -and PasswordNeverExpires -eq $false } `
    -Properties DisplayName, PasswordLastSet, "msDS-UserPasswordExpiryTimeComputed" |
    Where-Object {
        $expiry = [datetime]::FromFileTime($_."msDS-UserPasswordExpiryTimeComputed")
        $expiry -lt (Get-Date).AddDays(7) -and $expiry -gt (Get-Date)
    } |
    Select-Object DisplayName,
        @{N='PasswordExpires'; E={ [datetime]::FromFileTime($_."msDS-UserPasswordExpiryTimeComputed") }}

Write-Host "7 天内密码过期的用户：$($expiringSoon.Count) 人" -ForegroundColor Red
$expiringSoon | Format-Table -AutoSize
```

执行结果示例：

```
SamAccountName : zhangsan
DisplayName    : 张三
Department     : 工程部
Title          : 高级工程师
Enabled        : True
LastLogonDate  : 2025/9/1 14:30:00

工程部活跃用户：15 人
90 天未登录的活跃账号：8 个
DisplayName Department LastLogonDate
----------- ---------- -------------
王五        市场部     2025/5/10
赵六        财务部     2025/4/15

7 天内密码过期的用户：3 人
DisplayName PasswordExpires
----------- ----------------
张三        2025/9/5
李四        2025/9/3
```

## 批量用户创建

```powershell
# 从 CSV 批量创建用户
$csvData = @"
Name,DisplayName,Department,Title,Manager
li.si,李四,工程部,工程师,zhangsan
wang.wu,王五,市场部,市场专员,zhangsan
zhao.liu,赵六,财务部,会计,lisi
chen.qi,陈七,工程部,初级工程师,zhangsan
"@ | ConvertFrom-Csv

function New-BatchADUsers {
    param(
        [Parameter(Mandatory)]
        [object[]]$UserData,

        [string]$BaseOU = "OU=员工,DC=contoso,DC=com",

        [string]$DefaultPassword = "P@ssw0rd!2025",

        [string]$UPNSuffix = "contoso.com"
    )

    $results = @()
    $successCount = 0
    $failCount = 0

    $securePassword = ConvertTo-SecureString $DefaultPassword -AsPlainText -Force

    foreach ($user in $UserData) {
        try {
            # 检查是否已存在
            $existing = Get-ADUser -Filter { SamAccountName -eq $user.Name } -ErrorAction SilentlyContinue
            if ($existing) {
                Write-Host "用户已存在：$($user.Name)" -ForegroundColor Yellow
                $results += @{ Name = $user.Name; Status = "已存在" }
                continue
            }

            # 创建用户
            $newUserParams = @{
                Name                  = $user.DisplayName
                DisplayName           = $user.DisplayName
                SamAccountName        = $user.Name
                UserPrincipalName     = "$($user.Name)@$UPNSuffix"
                GivenName             = ($user.DisplayName -split '')[1]
                Surname               = ($user.DisplayName -split '')[0]
                Department            = $user.Department
                Title                 = $user.Title
                Path                  = $BaseOU
                AccountPassword       = $securePassword
                Enabled               = $true
                ChangePasswordAtLogon = $true
            }

            if ($user.Manager) {
                $newUserParams['Manager'] = $user.Manager
            }

            New-ADUser @newUserParams
            $successCount++
            Write-Host "已创建：$($user.Name)（$($user.Department)）" -ForegroundColor Green
            $results += @{ Name = $user.Name; Status = "成功" }
        } catch {
            $failCount++
            Write-Host "创建失败：$($user.Name) - $($_.Exception.Message)" -ForegroundColor Red
            $results += @{ Name = $user.Name; Status = "失败：$($_.Exception.Message)" }
        }
    }

    Write-Host "`n汇总：成功 $successCount，失败 $failCount" -ForegroundColor Cyan
    return $results
}

# 执行批量创建
New-BatchADUsers -UserData $csvData

# 从 CSV 文件导入（生产环境常用）
# $importData = Import-Csv "C:\HR\NewEmployees_202509.csv"
# New-BatchADUsers -UserData $importData
```

执行结果示例：

```
已创建：li.si（工程部）
已创建：wang.wu（市场部）
已创建：zhao.liu（财务部）
已创建：chen.qi（工程部）
汇总：成功 4，失败 0
```

## 用户生命周期管理

```powershell
# 批量修改用户属性
$users = @("li.si", "wang.wu")
foreach ($name in $users) {
    Set-ADUser -Identity $name -Department "研发部" -Company "Contoso Corp"
    Write-Host "已更新 $name 的部门和公司信息" -ForegroundColor Green
}

# 禁用离职用户
function Disable-DepartedUsers {
    param([string[]]$UserNames)

    foreach ($name in $UserNames) {
        try {
            $user = Get-ADUser -Identity $name -Properties DisplayName
            Disable-ADAccount -Identity $name

            # 移动到离职 OU
            Move-ADObject -Identity $user.DistinguishedName `
                -TargetPath "OU=离职员工,DC=contoso,DC=com"

            # 移除所有组（保留 Domain Users）
            $groups = Get-ADPrincipalGroupMembership -Identity $name |
                Where-Object { $_.Name -ne "Domain Users" }
            foreach ($group in $groups) {
                Remove-ADGroupMember -Identity $group.SamAccountName -Members $name -Confirm:$false
            }

            Write-Host "已禁用并归档：$($user.DisplayName)（$name）" -ForegroundColor Yellow
        } catch {
            Write-Host "处理失败：$name - $($_.Exception.Message)" -ForegroundColor Red
        }
    }
}

Disable-DepartedUsers -UserNames @("zhao.liu")

# 用户组管理
function Set-UserDepartmentGroups {
    param(
        [string]$UserName,
        [string]$Department
    )

    $deptGroups = @{
        "工程部" = @("SG_Developers", "SG_Git_Access", "SG_Build_Servers")
        "市场部" = @("SG_Marketing", "SG_CRM_Access")
        "财务部" = @("SG_Finance", "SG_ERP_Access", "SG_Reporting")
    }

    $groups = $deptGroups[$Department]
    if (-not $groups) {
        Write-Host "未定义 $Department 的默认组" -ForegroundColor Yellow
        return
    }

    foreach ($group in $groups) {
        try {
            Add-ADGroupMember -Identity $group -Members $UserName -ErrorAction Stop
            Write-Host "已加入组：$group" -ForegroundColor Green
        } catch {
            Write-Host "加入组失败：$group - $($_.Exception.Message)" -ForegroundColor Red
        }
    }
}

Set-UserDepartmentGroups -UserName "chen.qi" -Department "工程部"
```

执行结果示例：

```
已更新 li.si 的部门和公司信息
已更新 wang.wu 的部门和公司信息
已禁用并归档：赵六（zhao.liu）
已加入组：SG_Developers
已加入组：SG_Git_Access
已加入组：SG_Build_Servers
```

## 注意事项

1. **权限要求**：AD 操作需要相应权限，建议使用最小权限原则，为管理账号分配专门的 OU 管理权限
2. **密码策略**：批量创建用户时设置的初始密码应符合域密码策略要求
3. **测试先行**：批量操作前先用 `-WhatIf` 参数预览变更，确认无误后再执行
4. **日志审计**：AD 关键操作应记录日志，包括操作人、时间、变更内容
5. **OU 结构**：用户创建前确认目标 OU 路径正确，避免创建到错误位置
6. **同步延迟**：多域控制器环境下，修改后存在复制延迟，不要立即在另一台 DC 上查询验证
