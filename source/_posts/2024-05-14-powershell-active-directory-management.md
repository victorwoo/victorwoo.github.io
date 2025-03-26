---
layout: post
date: 2024-05-14 08:00:00
title: "PowerShell 技能连载 - Active Directory 管理技巧"
description: PowerTip of the Day - PowerShell Active Directory Management Tips
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
在 PowerShell 中管理 Active Directory 是一项重要任务，本文将介绍一些实用的 Active Directory 管理技巧。

首先，让我们看看基本的 Active Directory 操作：

```powershell
# 创建 Active Directory 用户管理函数
function Manage-ADUser {
    param(
        [string]$Username,
        [string]$DisplayName,
        [string]$Password,
        [string]$OUPath,
        [string]$Department,
        [string]$Title,
        [ValidateSet('Create', 'Update', 'Delete', 'Disable', 'Enable')]
        [string]$Action
    )
    
    try {
        Import-Module ActiveDirectory
        
        switch ($Action) {
            'Create' {
                $securePassword = ConvertTo-SecureString -String $Password -AsPlainText -Force
                New-ADUser -Name $Username -DisplayName $DisplayName -GivenName $DisplayName.Split(' ')[0] -Surname $DisplayName.Split(' ')[1] -Path $OUPath -Department $Department -Title $Title -AccountPassword $securePassword -Enabled $true
                Write-Host "用户 $Username 创建成功"
            }
            'Update' {
                Set-ADUser -Identity $Username -DisplayName $DisplayName -Department $Department -Title $Title
                Write-Host "用户 $Username 更新成功"
            }
            'Delete' {
                Remove-ADUser -Identity $Username -Confirm:$false
                Write-Host "用户 $Username 删除成功"
            }
            'Disable' {
                Disable-ADAccount -Identity $Username
                Write-Host "用户 $Username 已禁用"
            }
            'Enable' {
                Enable-ADAccount -Identity $Username
                Write-Host "用户 $Username 已启用"
            }
        }
    }
    catch {
        Write-Host "Active Directory 操作失败：$_"
    }
}
```

Active Directory 组管理：

```powershell
# 创建 Active Directory 组管理函数
function Manage-ADGroup {
    param(
        [string]$GroupName,
        [string]$GroupScope,
        [string]$OUPath,
        [string[]]$Members,
        [ValidateSet('Create', 'Update', 'Delete', 'AddMembers', 'RemoveMembers')]
        [string]$Action
    )
    
    try {
        Import-Module ActiveDirectory
        
        switch ($Action) {
            'Create' {
                New-ADGroup -Name $GroupName -GroupScope $GroupScope -Path $OUPath
                Write-Host "组 $GroupName 创建成功"
            }
            'Update' {
                Set-ADGroup -Identity $GroupName -GroupScope $GroupScope
                Write-Host "组 $GroupName 更新成功"
            }
            'Delete' {
                Remove-ADGroup -Identity $GroupName -Confirm:$false
                Write-Host "组 $GroupName 删除成功"
            }
            'AddMembers' {
                Add-ADGroupMember -Identity $GroupName -Members $Members
                Write-Host "成员已添加到组 $GroupName"
            }
            'RemoveMembers' {
                Remove-ADGroupMember -Identity $GroupName -Members $Members -Confirm:$false
                Write-Host "成员已从组 $GroupName 移除"
            }
        }
    }
    catch {
        Write-Host "Active Directory 组操作失败：$_"
    }
}
```

Active Directory 密码管理：

```powershell
# 创建 Active Directory 密码管理函数
function Manage-ADPassword {
    param(
        [string]$Username,
        [string]$NewPassword,
        [switch]$ForceChange,
        [switch]$CannotChange,
        [switch]$PasswordNeverExpires
    )
    
    try {
        Import-Module ActiveDirectory
        
        $securePassword = ConvertTo-SecureString -String $NewPassword -AsPlainText -Force
        Set-ADAccountPassword -Identity $Username -NewPassword $securePassword
        
        if ($ForceChange) {
            Set-ADUser -Identity $Username -ChangePasswordAtLogon $true
        }
        if ($CannotChange) {
            Set-ADUser -Identity $Username -CannotChangePassword $true
        }
        if ($PasswordNeverExpires) {
            Set-ADUser -Identity $Username -PasswordNeverExpires $true
        }
        
        Write-Host "用户 $Username 密码已更新"
    }
    catch {
        Write-Host "密码管理失败：$_"
    }
}
```

Active Directory 权限管理：

```powershell
# 创建 Active Directory 权限管理函数
function Manage-ADPermissions {
    param(
        [string]$Identity,
        [string]$Target,
        [string[]]$Permissions,
        [ValidateSet('Grant', 'Revoke', 'Reset')]
        [string]$Action
    )
    
    try {
        Import-Module ActiveDirectory
        
        $acl = Get-Acl -Path $Target
        
        switch ($Action) {
            'Grant' {
                $rule = New-Object System.Security.AccessControl.ActiveDirectoryAccessRule(
                    $Identity,
                    $Permissions,
                    "Allow"
                )
                $acl.AddAccessRule($rule)
                Set-Acl -Path $Target -AclObject $acl
                Write-Host "权限已授予 $Identity"
            }
            'Revoke' {
                $acl.Access | Where-Object { $_.IdentityReference -eq $Identity } | ForEach-Object {
                    $acl.RemoveAccessRule($_) | Out-Null
                }
                Set-Acl -Path $Target -AclObject $acl
                Write-Host "权限已从 $Identity 撤销"
            }
            'Reset' {
                $acl.SetAccessRuleProtection($true, $false)
                Set-Acl -Path $Target -AclObject $acl
                Write-Host "权限已重置"
            }
        }
    }
    catch {
        Write-Host "权限管理失败：$_"
    }
}
```

Active Directory 审计和报告：

```powershell
# 创建 Active Directory 审计和报告函数
function Get-ADAuditReport {
    param(
        [string]$SearchBase,
        [datetime]$StartDate,
        [datetime]$EndDate,
        [string]$ReportPath
    )
    
    try {
        Import-Module ActiveDirectory
        
        $report = @()
        
        # 获取用户账户变更
        $userChanges = Get-ADUser -Filter * -SearchBase $SearchBase | ForEach-Object {
            $history = Get-ADUser -Identity $_.DistinguishedName -Properties whenChanged, whenCreated
            if ($history.whenChanged -ge $StartDate -and $history.whenChanged -le $EndDate) {
                [PSCustomObject]@{
                    Type = "User Change"
                    Name = $_.Name
                    DN = $_.DistinguishedName
                    ChangeDate = $history.whenChanged
                }
            }
        }
        
        # 获取组变更
        $groupChanges = Get-ADGroup -Filter * -SearchBase $SearchBase | ForEach-Object {
            $history = Get-ADGroup -Identity $_.DistinguishedName -Properties whenChanged, whenCreated
            if ($history.whenChanged -ge $StartDate -and $history.whenChanged -le $EndDate) {
                [PSCustomObject]@{
                    Type = "Group Change"
                    Name = $_.Name
                    DN = $_.DistinguishedName
                    ChangeDate = $history.whenChanged
                }
            }
        }
        
        $report = $userChanges + $groupChanges
        $report | Export-Csv -Path $ReportPath -NoTypeInformation
        
        return [PSCustomObject]@{
            TotalChanges = $report.Count
            UserChanges = $userChanges.Count
            GroupChanges = $groupChanges.Count
            ReportPath = $ReportPath
        }
    }
    catch {
        Write-Host "审计报告生成失败：$_"
    }
}
```

这些技巧将帮助您更有效地管理 Active Directory。记住，在处理 Active Directory 时，始终要注意安全性和权限管理。同时，建议使用适当的错误处理和日志记录机制来跟踪所有操作。 