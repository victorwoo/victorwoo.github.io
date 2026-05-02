---
layout: post
date: 2025-05-14 08:00:00
updated: 2025-05-14 08:00:00
title: "PowerShell 技能连载 - 文件与注册表 ACL 管理"
description: PowerTip of the Day - File and Registry ACL Management in PowerShell
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
- acl
- security
- ntfs
- registry
---

_适用于 PowerShell 5.1 及以上版本（Windows）_

Windows 的权限管理核心是访问控制列表（ACL，Access Control List）。无论是文件共享、网站目录还是注册表键，权限配置错误都可能导致数据泄露或服务中断。传统的 GUI 方式（右键→属性→安全）效率低下且容易遗漏，而 PowerShell 提供了完整的 ACL 管理能力，可以实现精确、可重复、可审计的权限配置。

本文将系统讲解 NTFS 文件权限和注册表权限的查看、修改、备份和批量管理。

## 理解 ACL 结构

ACL 由两条列表组成：DACL（自主访问控制列表，决定谁可以访问）和 SACL（系统访问控制列表，决定哪些操作被审计）。每个 ACL 由多个 ACE（访问控制项）组成。

```powershell
# 查看文件夹的 ACL
$acl = Get-Acl -Path "C:\Projects\MyApp"
$acl | Format-List

# 查看 ACL 的详细访问规则
$acl.Access | Select-Object IdentityReference, FileSystemRights,
    AccessControlType, IsInherited, InheritanceFlags, PropagationFlags |
    Format-Table -AutoSize

# 查看所有者信息
Write-Host "当前所有者：$($acl.Owner)"
Write-Host "访问规则数量：$($acl.Access.Count)"
```

执行结果示例：

```
Path      Owner                       Access
----      -----                       ------
MyApp     BUILTIN\Administrators      {System.Security.AccessControl...

IdentityReference      FileSystemRights  AccessControlType IsInherited
-----------------      ----------------  ----------------- -----------
BUILTIN\Administrators FullControl       Allow                 True
NT AUTHORITY\SYSTEM     FullControl       Allow                 True
CONTOSO\Developers      Modify            Allow                False
CONTOSO\Readers         ReadAndExecute    Allow                False

当前所有者：BUILTIN\Administrators
访问规则数量：6
```

## 修改文件权限

添加或修改文件权限是最常见的操作。以下是标准的权限修改流程：

```powershell
# 为用户组添加文件夹权限
$acl = Get-Acl -Path "C:\Projects\MyApp"

# 创建新的访问规则
$rule = New-Object System.Security.AccessControl.FileSystemAccessRule(
    "CONTOSO\DevOps",          # 用户或组
    "Modify",                   # 权限级别
    "ContainerInherit,ObjectInherit",  # 继承方式
    "None",                     # 传播方式
    "Allow"                     # 允许或拒绝
)

# 添加规则
$acl.AddAccessRule($rule)

# 应用修改
Set-Acl -Path "C:\Projects\MyApp" -AclObject $acl
Write-Host "已为 CONTOSO\DevOps 添加 Modify 权限" -ForegroundColor Green

# 验证
(Get-Acl -Path "C:\Projects\MyApp").Access |
    Where-Object IdentityReference -match 'DevOps' |
    Format-Table IdentityReference, FileSystemRights, AccessControlType -AutoSize
```

执行结果示例：

```
已为 CONTOSO\DevOps 添加 Modify 权限

IdentityReference  FileSystemRights AccessControlType
-----------------  ---------------- -----------------
CONTOSO\DevOps     Modify           Allow
```

```powershell
# 常用的文件系统权限级别
$rights = @{
    FullControl   = '完全控制'
    Modify        = '修改（读+写+删除）'
    ReadAndExecute = '读取和执行'
    Read          = '只读'
    Write         = '写入'
    ListDirectory = '列出文件夹内容'
}

foreach ($key in $rights.Keys) {
    $value = [System.Security.AccessControl.FileSystemRights]::$key
    Write-Host "$key => $value ($($rights[$key]))"
}
```

执行结果示例：

```
FullControl => FullControl (完全控制)
Modify => Modify (修改（读+写+删除）)
ReadAndExecute => ReadAndExecute (读取和执行)
Read => Read (只读)
Write => Write (写入)
```

## 移除和替换权限

移除权限时需要精确匹配原有规则的参数，否则操作不会生效：

```powershell
# 移除特定用户的权限（需要完全匹配参数）
$acl = Get-Acl -Path "C:\Projects\MyApp"

# 找到要移除的规则
$rulesToRemove = $acl.Access |
    Where-Object { $_.IdentityReference -eq 'CONTOSO\OldTeam' }

foreach ($rule in $rulesToRemove) {
    $acl.RemoveAccessRule($rule) | Out-Null
    Write-Host "已移除规则：$($rule.IdentityReference) - $($rule.FileSystemRights)"
}

Set-Acl -Path "C:\Projects\MyApp" -AclObject $acl

# 移除继承并复制现有规则
$acl = Get-Acl -Path "C:\Projects\MyApp"
$acl.SetAccessRuleProtection($true, $true)  # $true=阻止继承, $true=复制现有规则
Set-Acl -Path "C:\Projects\MyApp" -AclObject $acl
Write-Host "已阻止权限继承并保留现有规则" -ForegroundColor Yellow

# 完全重置权限（替换所有规则）
$acl = Get-Acl -Path "C:\Projects\MyApp"

# 清除所有现有非继承规则
$acl.Access | Where-Object { -not $_.IsInherited } | ForEach-Object {
    $acl.RemoveAccessRule($_) | Out-Null
}

# 添加新的权限集
$adminRule = New-Object System.Security.AccessControl.FileSystemAccessRule(
    "BUILTIN\Administrators", "FullControl",
    "ContainerInherit,ObjectInherit", "None", "Allow"
)
$systemRule = New-Object System.Security.AccessControl.FileSystemAccessRule(
    "NT AUTHORITY\SYSTEM", "FullControl",
    "ContainerInherit,ObjectInherit", "None", "Allow"
)
$userRule = New-Object System.Security.AccessControl.FileSystemAccessRule(
    "CONTOSO\AppService", "ReadAndExecute",
    "ContainerInherit,ObjectInherit", "None", "Allow"
)

$acl.AddAccessRule($adminRule)
$acl.AddAccessRule($systemRule)
$acl.AddAccessRule($userRule)
Set-Acl -Path "C:\Projects\MyApp" -AclObject $acl

Write-Host "权限已重置为标准配置" -ForegroundColor Green
```

执行结果示例：

```
已移除规则：CONTOSO\OldTeam - Modify
已阻止权限继承并保留现有规则
权限已重置为标准配置
```

## 注册表权限管理

注册表权限管理与文件权限类似，但使用 `RegistryAccessRule` 类：

```powershell
# 查看注册表键的权限
$regPath = "HKLM:\SOFTWARE\MyApp"
$acl = Get-Acl -Path $regPath
$acl.Access | Select-Object IdentityReference, RegistryRights,
    AccessControlType, IsInherited |
    Format-Table -AutoSize

# 为注册表键添加权限
$acl = Get-Acl -Path $regPath
$rule = New-Object System.Security.AccessControl.RegistryAccessRule(
    "CONTOSO\AppService",
    "ReadKey",
    "ContainerInherit",
    "None",
    "Allow"
)
$acl.AddAccessRule($rule)
Set-Acl -Path $regPath -AclObject $acl
Write-Host "已为 CONTOSO\AppService 添加注册表读取权限" -ForegroundColor Green

# 注册表权限级别说明
$regRights = @{
    FullControl      = '完全控制'
    ReadKey          = '读取'
    WriteKey         = '写入'
    CreateSubKey     = '创建子键'
    Delete           = '删除'
    QueryValues      = '查询值'
    SetValue         = '设置值'
    EnumerateSubKeys = '枚举子键'
}
```

执行结果示例：

```
IdentityReference       RegistryRights    AccessControlType IsInherited
-----------------       --------------    ----------------- -----------
BUILTIN\Administrators  FullControl       Allow                 True
NT AUTHORITY\SYSTEM     FullControl       Allow                 True
CONTOSO\AppService      ReadKey           Allow                False

已为 CONTOSO\AppService 添加注册表读取权限
```

## ACL 备份与恢复

在进行权限修改前，务必备份当前 ACL 以便回滚：

```powershell
function Backup-Acl {
    <#
    .SYNOPSIS
    备份文件或注册表的 ACL
    #>
    param(
        [Parameter(Mandatory)]
        [string]$Path,

        [string]$BackupDir = "C:\ACLBackups"
    )

    if (-not (Test-Path $BackupDir)) {
        New-Item -Path $BackupDir -ItemType Directory | Out-Null
    }

    $acl = Get-Acl -Path $Path
    $safeName = $Path -replace '[\\/:]', '_'
    $backupPath = Join-Path $BackupDir "$safeName.acl.xml"
    $acl | Export-Clixml -Path $backupPath

    Write-Host "ACL 已备份到：$backupPath" -ForegroundColor Green
    return $backupPath
}

function Restore-Acl {
    <#
    .SYNOPSIS
    从备份恢复 ACL
    #>
    param(
        [Parameter(Mandatory)]
        [string]$Path,

        [Parameter(Mandatory)]
        [string]$BackupFile
    )

    $acl = Import-Clixml -Path $BackupFile
    Set-Acl -Path $Path -AclObject $acl

    Write-Host "ACL 已从备份恢复：$BackupFile" -ForegroundColor Green
}

# 使用示例
$backupFile = Backup-Acl -Path "C:\Projects\MyApp"

# ... 修改权限 ...

# 如果需要回滚
Restore-Acl -Path "C:\Projects\MyApp" -BackupFile $backupFile
```

执行结果示例：

```
ACL 已备份到：C:\ACLBackups_C_Projects_MyApp.acl.xml
ACL 已从备份恢复：C:\ACLBackups_C_Projects_MyApp.acl.xml
```

## 批量权限配置

在服务器部署场景中，通常需要对大量目录应用统一的权限模板：

```powershell
function Set-DirectoryPermissionTemplate {
    <#
    .SYNOPSIS
    批量为目录应用权限模板
    #>
    param(
        [Parameter(Mandatory)]
        [string]$BasePath,

        [hashtable[]]$PermissionRules,

        [switch]$Recurse,
        [switch]$RemoveInheritance
    )

    $paths = if ($Recurse) {
        Get-ChildItem -Path $BasePath -Directory -Recurse | Select-Object -ExpandProperty FullName
        $BasePath
    } else {
        @($BasePath)
    }

    foreach ($path in $paths) {
        $acl = Get-Acl -Path $path

        if ($RemoveInheritance) {
            $acl.SetAccessRuleProtection($true, $true)
        }

        foreach ($rule in $PermissionRules) {
            $accessRule = New-Object System.Security.AccessControl.FileSystemAccessRule(
                $rule.Identity,
                $rule.Rights,
                $rule.Inheritance,
                "None",
                $rule.Type
            )
            $acl.AddAccessRule($accessRule)
        }

        Set-Acl -Path $path -AclObject $acl
        Write-Host "已配置：$path" -ForegroundColor Green
    }
}

# 定义权限模板
$template = @(
    @{ Identity = 'BUILTIN\Administrators'; Rights = 'FullControl'; Inheritance = 'ContainerInherit,ObjectInherit'; Type = 'Allow' }
    @{ Identity = 'NT AUTHORITY\SYSTEM'; Rights = 'FullControl'; Inheritance = 'ContainerInherit,ObjectInherit'; Type = 'Allow' }
    @{ Identity = 'CONTOSO\DevOps'; Rights = 'Modify'; Inheritance = 'ContainerInherit,ObjectInherit'; Type = 'Allow' }
    @{ Identity = 'CONTOSO\AppService'; Rights = 'ReadAndExecute'; Inheritance = 'ContainerInherit,ObjectInherit'; Type = 'Allow' }
)

# 应用到 Web 站点目录
Set-DirectoryPermissionTemplate -BasePath "C:\inetpub\wwwroot\MyApp" `
    -PermissionRules $template -RemoveInheritance
```

执行结果示例：

```
已配置：C:\inetpub\wwwroot\MyApp
```

## 注意事项

1. **备份优先**：修改 ACL 前务必使用 `Export-Clixml` 备份当前权限，以便出错时快速恢复
2. **继承机制**：理解继承（`ContainerInherit`, `ObjectInherit`）和传播（`None`, `InheritOnly`, `NoPropagateInherit`）的组合效果
3. **拒绝优先**：DACL 中 Deny 规则优先于 Allow 规则，即使 Allow 规则赋予更高级别权限
4. **所有权**：修改 ACL 需要对目标有 `TakeOwnership` 权限或当前是所有者。管理员可以通过 `TakeOwnership` 权限获取所有权
5. **注册表路径**：使用 PowerShell 注册表提供程序路径（`HKLM:\`, `HKCU:\`），而非 `HKEY_LOCAL_MACHINE\` 格式
6. **最小权限原则**：只授予完成任务所需的最低权限，避免过度授权
