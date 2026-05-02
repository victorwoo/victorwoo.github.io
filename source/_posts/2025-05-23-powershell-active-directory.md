---
layout: post
date: 2025-05-23 08:00:00
updated: 2025-05-23 08:00:00
title: "PowerShell 技能连载 - Active Directory 管理"
description: PowerTip of the Day - Active Directory Management in PowerShell
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
- identity
---

_适用于 Windows Server 2012 R2 及以上版本，需安装 ActiveDirectory 模块_

Active Directory（AD）是企业 IT 基础设施的核心——用户、计算机、组策略、DNS 都围绕 AD 展开。传统上管理员依赖 Active Directory Users and Computers（ADUC）图形界面操作，但面对成百上千的用户账户和组管理需求时，GUI 操作效率极低。PowerShell 的 `ActiveDirectory` 模块提供了完整的 AD 管理能力，可以实现批量创建、查询、修改和审计。

本文将讲解 AD 用户管理、组管理、计算机管理和常见自动化场景。

<!-- more -->

## 环境准备

使用 AD 相关命令前，需要安装并导入模块：

```powershell
# 安装 AD PowerShell 模块（Windows Server）
Install-WindowsFeature -Name RSAT-AD-PowerShell

# Windows 10/11 客户端安装 RSAT
# 设置 > 应用 > 可选功能 > 添加 RSAT: Active Directory Domain Services 工具

# 导入模块
Import-Module ActiveDirectory

# 验证模块已加载
Get-Command -Module ActiveDirectory |
    Select-Object Name, CommandType |
    Sort-Object Name |
    Select-Object -First 20 |
    Format-Table -AutoSize

# 测试域连接
Get-ADDomain | Select-Object Name, DNSRoot, Forest, DomainMode |
    Format-List
```

执行结果示例：

```
Name                    CommandType
----                    -----------
Get-ADComputer          Function
Get-ADDomain            Function
Get-ADGroup             Function
Get-ADGroupMember       Function
Get-ADUser              Function
New-ADUser              Function
Remove-ADUser           Function
Set-ADUser              Function

Name       : contoso
DNSRoot    : contoso.com
Forest     : contoso.com
DomainMode : Windows2016Domain
```

## 用户管理

用户管理是 AD 运维中最频繁的操作，包括创建、查询、修改和批量操作：

```powershell
# 查询用户信息
Get-ADUser -Identity "john.doe" -Properties * |
    Select-Object Name, SamAccountName, EmailAddress, Department,
        Title, Manager, Enabled, LastLogonDate, PasswordLastSet |
    Format-List

# 搜索用户（模糊匹配）
Get-ADUser -Filter "Name -like '*Smith*'" |
    Select-Object Name, SamAccountName, Department |
    Format-Table -AutoSize

# 创建新用户
$newUserParams = @{
    Name            = "张伟"
    GivenName       = "伟"
    Surname         = "张"
    SamAccountName  = "wei.zhang"
    UserPrincipalName = "wei.zhang@contoso.com"
    EmailAddress    = "wei.zhang@contoso.com"
    Department      = "IT"
    Title           = "高级运维工程师"
    Path            = "OU=IT,OU=Users,DC=contoso,DC=com"
    AccountPassword = (Read-Host "设置密码" -AsSecureString)
    Enabled         = $true
    ChangePasswordAtLogon = $true
}
New-ADUser @newUserParams
Write-Host "用户已创建：wei.zhang" -ForegroundColor Green

# 修改用户属性
Set-ADUser -Identity "wei.zhang" -Department "DevOps" -Title "DevOps 工程师"

# 禁用/启用账户
Disable-ADAccount -Identity "wei.zhang"
Enable-ADAccount -Identity "wei.zhang"

# 解锁账户（用户多次输错密码后被锁定）
Unlock-ADAccount -Identity "john.doe"
```

执行结果示例：

```
Name           : John Doe
SamAccountName : john.doe
EmailAddress   : john.doe@contoso.com
Department     : Engineering
Title          : Senior Developer
Manager        : CN=Jane Smith,OU=Managers,DC=contoso,DC=com
Enabled        : True
LastLogonDate  : 2025-05-22 17:30:00
PasswordLastSet: 2025-04-15 09:00:00

Name          SamAccountName  Department
----          --------------  ----------
Alice Smith   alice.smith     HR
Bob Smith     bob.smith       Engineering

用户已创建：wei.zhang
```

## 批量用户管理

从 CSV 文件批量创建用户是最常见的自动化场景：

```powershell
# 批量创建用户（从 CSV）
$usersCsv = @"
Name,SamAccountName,Department,Title,Email
李明,ming.li,Engineering,开发工程师,ming.li@contoso.com
王芳,fang.wang,Marketing,市场经理,fang.wang@contoso.com
赵强,qiang.zhao,Finance,财务分析师,qiang.zhao@contoso.com
刘洋,yang.liu,IT,系统管理员,yang.liu@contoso.com
"@ | ConvertFrom-Csv

$password = ConvertTo-SecureString "P@ssw0rd123!" -AsPlainText -Force

$results = foreach ($user in $usersCsv) {
    try {
        $ouPath = "OU=$($user.Department),OU=Users,DC=contoso,DC=com"

        New-ADUser -Name $user.Name `
            -SamAccountName $user.SamAccountName `
            -UserPrincipalName "$($user.SamAccountName)@contoso.com" `
            -EmailAddress $user.Email `
            -Department $user.Department `
            -Title $user.Title `
            -Path $ouPath `
            -AccountPassword $password `
            -Enabled $true `
            -ChangePasswordAtLogon $true `
            -ErrorAction Stop

        [PSCustomObject]@{
            User   = $user.SamAccountName
            Status = 'Created'
            OU     = $ouPath
        }
    } catch {
        [PSCustomObject]@{
            User   = $user.SamAccountName
            Status = "Failed: $($_.Exception.Message)"
            OU     = $ouPath
        }
    }
}

$results | Format-Table -AutoSize
```

执行结果示例：

```
User        Status  OU
----        ------  --
ming.li     Created OU=Engineering,OU=Users,DC=contoso,DC=com
fang.wang   Created OU=Marketing,OU=Users,DC=contoso,DC=com
qiang.zhao  Created OU=Finance,OU=Users,DC=contoso,DC=com
yang.liu    Created OU=IT,OU=Users,DC=contoso,DC=com
```

## 组管理

组是 AD 权限管理的基础单元：

```powershell
# 查询组信息
Get-ADGroup -Identity "IT-Admins" -Properties * |
    Select-Object Name, GroupScope, GroupCategory, Description, Members |
    Format-List

# 查看组成员
Get-ADGroupMember -Identity "IT-Admins" |
    Select-Object Name, SamAccountName, ObjectClass |
    Format-Table -AutoSize

# 添加用户到组
Add-ADGroupMember -Identity "IT-Admins" -Members "wei.zhang"
Write-Host "已将 wei.zhang 添加到 IT-Admins 组" -ForegroundColor Green

# 批量添加组成员
$members = @("ming.li", "yang.liu")
Add-ADGroupMember -Identity "DevOps-Team" -Members $members

# 从组中移除用户
Remove-ADGroupMember -Identity "IT-Admins" -Members "john.doe" -Confirm:$false

# 创建新组
New-ADGroup -Name "Cloud-Admins" `
    -GroupScope Global `
    -GroupCategory Security `
    -Description "云平台管理员组" `
    -Path "OU=Groups,DC=contoso,DC=com"

# 查找用户所属的所有组
Get-ADUser -Identity "wei.zhang" -Properties MemberOf |
    Select-Object -ExpandProperty MemberOf |
    ForEach-Object { ($_ -split ',')[0] -replace 'CN=','' } |
    Sort-Object
```

执行结果示例：

```
Name          SamAccountName ObjectClass
----          -------------- -----------
John Doe      john.doe       user
Jane Smith    jane.smith     user
Server01$     SERVER01       computer

已将 wei.zhang 添加到 IT-Admins 组

Cloud-Admins
DevOps-Team
Domain Users
IT-Admins
```

## 计算机管理

AD 中的计算机账户管理用于跟踪和管理域中的服务器和工作站：

```powershell
# 查询域中所有计算机
Get-ADComputer -Filter * -Properties Name, OperatingSystem, LastLogonDate, Enabled |
    Select-Object Name, OperatingSystem, LastLogonDate, Enabled |
    Sort-Object Name |
    Format-Table -AutoSize

# 按操作系统筛选
Get-ADComputer -Filter "OperatingSystem -like '*Server 2022*'" |
    Select-Object Name, DNSHostName |
    Format-Table -AutoSize

# 查找不活跃的计算机（90 天未登录）
$cutoffDate = (Get-Date).AddDays(-90)
$inactiveComputers = Get-ADComputer -Filter { LastLogonDate -lt $cutoffDate } `
    -Properties Name, LastLogonDate, OperatingSystem

$inactiveComputers |
    Select-Object Name, OperatingSystem,
        @{N='LastLogon'; E={$_.LastLogonDate.ToString('yyyy-MM-dd')}} |
    Format-Table -AutoSize

Write-Host "不活跃计算机数量：$($inactiveComputers.Count)" -ForegroundColor Yellow

# 禁用不活跃的计算机账户
foreach ($comp in $inactiveComputers) {
    Set-ADComputer -Identity $comp -Enabled $false
    Write-Host "已禁用：$($comp.Name)" -ForegroundColor Yellow
}
```

执行结果示例：

```
Name       OperatingSystem                  LastLogonDate      Enabled
----       ---------------                  -------------      -------
DC01       Windows Server 2022 Standard     2025-05-23         True
SRV-WEB01  Windows Server 2022 Datacenter   2025-05-22         True
WS-HR01    Windows 11 Enterprise            2025-05-20         True
OLD-SRV01  Windows Server 2016 Standard     2025-02-15         True

Name       OperatingSystem                LastLogon  Enabled
----       ---------------                ---------  -------
OLD-SRV01  Windows Server 2016 Standard   2025-02-15  True
OLD-WS01   Windows 10 Enterprise          2025-01-20  True

不活跃计算机数量：2
已禁用：OLD-SRV01
已禁用：OLD-WS01
```

## 密码策略与合规检查

```powershell
# 查看域密码策略
Get-ADDefaultDomainPasswordPolicy |
    Select-Object ComplexityEnabled, MinPasswordLength,
        MaxPasswordAge, PasswordHistoryCount, LockoutThreshold |
    Format-List

# 查找密码即将过期的用户
$maxAge = (Get-ADDefaultDomainPasswordPolicy).MaxPasswordAge.Days
$notifyDays = 14
$cutoffDate = (Get-Date).AddDays($notifyDays)

$expiringUsers = Get-ADUser -Filter { Enabled -eq $true -and PasswordNeverExpires -eq $false } `
    -Properties Name, EmailAddress, PasswordLastSet, PasswordNeverExpires

$results = foreach ($user in $expiringUsers) {
    $expiryDate = $user.PasswordLastSet.AddDays($maxAge)
    if ($expiryDate -le $cutoffDate) {
        $daysLeft = [math]::Floor(($expiryDate - (Get-Date)).TotalDays)
        [PSCustomObject]@{
            Name        = $user.Name
            Email       = $user.EmailAddress
            ExpiresOn   = $expiryDate.ToString('yyyy-MM-dd')
            DaysLeft    = $daysLeft
        }
    }
}

$results | Sort-Object DaysLeft | Format-Table -AutoSize
```

执行结果示例：

```
ComplexityEnabled  : True
MinPasswordLength  : 8
MaxPasswordAge     : 90.00:00:00
PasswordHistoryCount : 24
LockoutThreshold   : 5

Name        Email                    ExpiresOn  DaysLeft
----        -----                    ---------  --------
John Doe    john.doe@contoso.com     2025-05-28        5
Alice Smith alice.smith@contoso.com  2025-06-01        9
Bob Smith   bob.smith@contoso.com    2025-06-05       13
```

## 注意事项

1. **权限要求**：AD 操作需要足够的权限。普通用户只能查询和修改自己的部分属性，管理操作需要 AD 管理员或委派权限
2. **批量操作加 `-WhatIf`**：大批量修改前始终使用 `-WhatIf` 参数预览操作，确认无误后再执行
3. **OU 路径正确性**：`-Path` 参数必须使用完整的 DN（Distinguished Name）格式，如 `OU=IT,DC=contoso,DC=com`
4. **密码策略合规**：创建用户时设置的密码必须符合域密码策略（复杂度、最小长度等），否则创建会失败
5. **管道效率**：使用 `-Filter` 参数在服务端过滤比管道 `Where-Object` 高效得多
6. **回收站**：删除用户前建议启用 AD 回收站功能，以便误删时恢复
