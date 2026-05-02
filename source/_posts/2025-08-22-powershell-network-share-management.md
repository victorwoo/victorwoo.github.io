---
layout: post
date: 2025-08-22 08:00:00
updated: 2025-08-22 08:00:00
title: "PowerShell 技能连载 - 网络共享管理"
description: PowerTip of the Day - Network Share Management in PowerShell
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
- network-share
- file-server
- smb
- acl
---

_适用于 PowerShell 5.1 及以上版本_

网络共享是 Windows 文件服务器最核心的功能，几乎每家企业都依赖 SMB 共享来分发文件、协作办公和存储数据。管理网络共享涉及创建和删除共享、配置访问权限、监控连接状态、审计文件访问等多个维度。随着数据安全法规（如 GDPR、数据安全法）的推行，对共享文件夹的精细化权限管理和访问审计变得越来越重要。

PowerShell 提供了 `SmbShare` 和 `SmbAccess` 系列模块，以及 `System.IO` 和 ACL（Access Control List）管理 API，能够全面管理网络共享的方方面面。本文将介绍如何使用 PowerShell 实现共享的创建、权限配置、连接监控和访问审计。

## 查询现有网络共享

了解服务器上当前存在哪些共享以及它们的配置。

```powershell
function Get-NetworkShareInfo {
    <#
    .SYNOPSIS
    获取所有网络共享的详细信息
    .PARAMETER ServerName
    远程服务器名称（默认本地）
    #>
    [CmdletBinding()]
    param(
        [string]$ServerName = $env:COMPUTERNAME
    )

    $params = @{ ComputerName = $ServerName }

    # 获取共享列表
    $shares = Get-SmbShare @params | Where-Object {
        # 排除系统默认共享（C$、ADMIN$ 等）
        $_.Name -notmatch '\$$' -and $_.Name -ne 'IPC$'
    }

    foreach ($share in $shares) {
        # 获取共享权限
        $access = Get-SmbShareAccess @params -Name $share.Name -ErrorAction SilentlyContinue

        # 获取 NTFS 权限
        $ntfsAcl = $null
        if (Test-Path $share.Path) {
            $ntfsAcl = Get-Acl -Path $share.Path -ErrorAction SilentlyContinue
        }

        # 获取磁盘信息
        $driveLetter = $share.Path.Substring(0, 1)
        $disk = Get-CimInstance -ClassName Win32_LogicalDisk -Filter "DeviceID='$($driveLetter):'" -ErrorAction SilentlyContinue

        [PSCustomObject]@{
            Name         = $share.Name
            Path         = $share.Path
            Description  = $share.Description
            ShareType    = $share.ShareType
            ConcurrentUserLimit = $share.ConcurrentUserLimit
            EncryptData  = $share.EncryptData
            ShareAccess  = ($access | ForEach-Object {
                "$($_.AccountName)=$($_.AccessControlType)-$($_.AccessRight)"
            }) -join '; '
            DiskFreeGB   = if ($disk) { [math]::Round($disk.FreeSpace / 1GB, 2) } else { 'N/A' }
        }
    }
}

# 查看本地所有共享
Get-NetworkShareInfo | Format-Table Name, Path, Description, EncryptData -AutoSize
```

执行结果示例：

```text

Name       Path                Description       EncryptData
----       ----                -----------       -----------
Projects   D:\Shares\Projects  项目文件共享        False
Finance    D:\Shares\Finance   财务部专用共享       True
Public     D:\Shares\Public    公共共享区域        False
Software   D:\Shares\Software  软件分发共享        False
```

## 创建网络共享

创建共享需要同时配置 SMB 共享权限和 NTFS 文件系统权限。

```powershell
function New-NetworkShare {
    <#
    .SYNOPSIS
    创建新的网络共享
    .PARAMETER Name
    共享名称
    .PARAMETER Path
    共享文件夹路径
    .PARAMETER Description
    共享描述
    .PARAMETER FullAccess
    完全控制权限的账户列表
    .PARAMETER ChangeAccess
    修改权限的账户列表
    .PARAMETER ReadAccess
    只读权限的账户列表
    .PARAMETER EncryptData
    是否启用 SMB 加密
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Name,

        [Parameter(Mandatory)]
        [string]$Path,

        [string]$Description,

        [string[]]$FullAccess,

        [string[]]$ChangeAccess,

        [string[]]$ReadAccess,

        [switch]$EncryptData
    )

    # 创建文件夹（如果不存在）
    if (-not (Test-Path $Path)) {
        Write-Verbose "创建目录：$Path"
        New-Item -Path $Path -ItemType Directory -Force | Out-Null
    }

    # 创建 SMB 共享
    $shareParams = @{
        Name        = $Name
        Path        = $Path
        Description = if ($Description) { $Description } else { '' }
        ErrorAction = 'Stop'
    }

    if ($FullAccess) { $shareParams['FullAccess'] = $FullAccess }
    if ($ChangeAccess) { $shareParams['ChangeAccess'] = $ChangeAccess }
    if ($ReadAccess) { $shareParams['ReadAccess'] = $ReadAccess }
    if ($EncryptData) { $shareParams['EncryptData'] = $true }

    Write-Verbose "创建共享：$Name -> $Path"
    $share = New-SmbShare @shareParams

    # 配置 NTFS 权限
    Write-Verbose "配置 NTFS 权限"
    $acl = Get-Acl -Path $Path

    # 移除继承的权限
    $acl.SetAccessRuleProtection($true, $false)

    # 添加 NTFS 规则
    $ntfsRules = @(
        @{ Account = 'BUILTIN\Administrators'; Rights = 'FullControl' }
        @{ Account = 'NT AUTHORITY\SYSTEM'; Rights = 'FullControl' }
    )

    if ($FullAccess) {
        foreach ($account in $FullAccess) {
            $ntfsRules += @{ Account = $account; Rights = 'FullControl' }
        }
    }
    if ($ChangeAccess) {
        foreach ($account in $ChangeAccess) {
            $ntfsRules += @{ Account = $account; Rights = 'Modify' }
        }
    }
    if ($ReadAccess) {
        foreach ($account in $ReadAccess) {
            $ntfsRules += @{ Account = $account; Rights = 'ReadAndExecute' }
        }
    }

    foreach ($rule in $ntfsRules) {
        $identity = New-Object System.Security.Principal.NTAccount($rule.Account)
        $fileSystemRights = [System.Security.AccessControl.FileSystemRights]$rule.Rights
        $inheritance = [System.Security.AccessControl.InheritanceFlags]::ContainerInherit -bor
                       [System.Security.AccessControl.InheritanceFlags]::ObjectInherit
        $propagation = [System.Security.AccessControl.PropagationFlags]::None
        $type = [System.Security.AccessControl.AccessControlType]::Allow

        $accessRule = New-Object System.Security.AccessControl.FileSystemAccessRule(
            $identity, $fileSystemRights, $inheritance, $propagation, $type
        )
        $acl.AddAccessRule($accessRule)
    }

    Set-Acl -Path $Path -AclObject $acl

    [PSCustomObject]@{
        Name        = $Name
        Path        = $Path
        Description = $Description
        EncryptData = $EncryptData
        NTFSRules   = $ntfsRules.Count
        Status      = '已创建'
    }
}

# 创建项目共享
$newShare = New-NetworkShare `
    -Name 'NewProject' `
    -Path 'D:\Shares\NewProject' `
    -Description '新项目协作共享' `
    -FullAccess 'CONTOSO\ITAdmins' `
    -ChangeAccess 'CONTOSO\ProjectTeam' `
    -ReadAccess 'CONTOSO\AllUsers' `
    -EncryptData `
    -Verbose

$newShare | Format-List
```

执行结果示例：

```text
详细: 创建目录：D:\Shares\NewProject
详细: 创建共享：NewProject -> D:\Shares\NewProject
详细: 配置 NTFS 权限

Name        : NewProject
Path        : D:\Shares\NewProject
Description : 新项目协作共享
EncryptData : True
NTFSRules   : 5
Status      : 已创建
```

## 管理共享访问权限

共享创建后，需要持续管理权限，包括添加、修改和撤销访问权限。

```powershell
function Set-NetworkSharePermission {
    <#
    .SYNOPSIS
    修改网络共享的访问权限
    .PARAMETER ShareName
    共享名称
    .PARAMETER AccountName
    账户名称（DOMAIN\User 格式）
    .PARAMETER AccessRight
    权限级别（Full、Change、Read）
    .PARAMETER Action
    操作类型（Grant、Revoke）
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$ShareName,

        [Parameter(Mandatory)]
        [string]$AccountName,

        [ValidateSet('Full', 'Change', 'Read')]
        [string]$AccessRight = 'Read',

        [ValidateSet('Grant', 'Revoke')]
        [string]$Action = 'Grant'
    )

    if ($Action -eq 'Grant') {
        # 授予 SMB 共享权限
        Grant-SmbShareAccess -Name $ShareName `
            -AccountName $AccountName `
            -AccessRight $AccessRight `
            -Force

        Write-Verbose "已授予 $AccountName 对 $ShareName 的 $AccessRight 权限"

        # 同步配置 NTFS 权限
        $share = Get-SmbShare -Name $ShareName
        $ntfsRights = switch ($AccessRight) {
            'Full'   { 'FullControl' }
            'Change' { 'Modify' }
            'Read'   { 'ReadAndExecute' }
        }

        $acl = Get-Acl -Path $share.Path
        $identity = New-Object System.Security.Principal.NTAccount($AccountName)
        $fileSystemRights = [System.Security.AccessControl.FileSystemRights]$ntfsRights
        $inheritance = [System.Security.AccessControl.InheritanceFlags]::ContainerInherit -bor
                       [System.Security.AccessControl.InheritanceFlags]::ObjectInherit
        $propagation = [System.Security.AccessControl.PropagationFlags]::None
        $type = [System.Security.AccessControl.AccessControlType]::Allow

        $accessRule = New-Object System.Security.AccessControl.FileSystemAccessRule(
            $identity, $fileSystemRights, $inheritance, $propagation, $type
        )
        $acl.AddAccessRule($accessRule)
        Set-Acl -Path $share.Path -AclObject $acl

        Write-Verbose "已同步 NTFS 权限"
    } else {
        # 撤销 SMB 共享权限
        Revoke-SmbShareAccess -Name $ShareName `
            -AccountName $AccountName `
            -Force

        Write-Verbose "已撤销 $AccountName 对 $ShareName 的共享权限"

        # 移除 NTFS 权限
        $share = Get-SmbShare -Name $ShareName
        $acl = Get-Acl -Path $share.Path
        $identity = New-Object System.Security.Principal.NTAccount($AccountName)

        $rulesToRemove = $acl.Access | Where-Object {
            $_.IdentityReference -eq $identity
        }

        foreach ($rule in $rulesToRemove) {
            $acl.RemoveAccessRule($rule) | Out-Null
        }
        Set-Acl -Path $share.Path -AclObject $acl

        Write-Verbose "已移除 NTFS 权限"
    }

    # 返回当前权限状态
    Get-SmbShareAccess -Name $ShareName | Format-Table AccountName, AccessControlType, AccessRight -AutoSize
}

# 授予权限
Set-NetworkSharePermission -ShareName 'Projects' `
    -AccountName 'CONTOSO\NewUser' `
    -AccessRight 'Change' `
    -Action 'Grant' `
    -Verbose

# 撤销权限
Set-NetworkSharePermission -ShareName 'Projects' `
    -AccountName 'CONTOSO\DepartedUser' `
    -Action 'Revoke' `
    -Verbose
```

执行结果示例：

```text
详细: 已授予 CONTOSO\NewUser 对 Projects 的 Change 权限
详细: 已同步 NTFS 权限

AccountName          AccessControlType AccessRight
-----------          ----------------- -----------
BUILTIN\Administrators Allow            Full
CONTOSO\ITAdmins      Allow            Full
CONTOSO\ProjectTeam   Allow            Change
CONTOSO\NewUser       Allow            Change
CONTOSO\AllUsers      Allow            Read

详细: 已撤销 CONTOSO\DepartedUser 对 Projects 的共享权限
详细: 已移除 NTFS 权限

AccountName          AccessControlType AccessRight
-----------          ----------------- -----------
BUILTIN\Administrators Allow            Full
CONTOSO\ITAdmins      Allow            Full
CONTOSO\ProjectTeam   Allow            Change
CONTOSO\NewUser       Allow            Change
CONTOSO\AllUsers      Allow            Read
```

## 监控共享连接

实时监控谁在访问共享资源，是文件服务器运维的重要需求。

```powershell
function Get-SmbSessionInfo {
    <#
    .SYNOPSIS
    获取当前 SMB 会话和打开的文件
    .PARAMETER ShareName
    按共享名称过滤
    #>
    [CmdletBinding()]
    param(
        [string]$ShareName
    )

    # 获取 SMB 会话
    $sessions = Get-SmbSession -ErrorAction SilentlyContinue

    if ($ShareName) {
        $sessions = $sessions | Where-Object { $_.ShareRelativeName -like "*$ShareName*" }
    }

    Write-Host "===== SMB 会话 =====" -ForegroundColor Cyan
    $sessionInfo = foreach ($session in $sessions) {
        [PSCustomObject]@{
            ClientComputer = $session.ClientComputerName
            UserName       = $session.ClientUserName
            SessionId      = $session.SessionId
            NumOpens       = $session.NumOpens
            Transport      = if ($session.TransportName -match 'SMB2') { 'SMB2/3' } else { 'SMB1' }
        }
    }

    $sessionInfo | Format-Table -AutoSize

    # 获取打开的文件
    $openFiles = Get-SmbOpenFile -ErrorAction SilentlyContinue

    if ($ShareName) {
        $openFiles = $openFiles | Where-Object { $_.ShareRelativeName -like "*$ShareName*" }
    }

    Write-Host "`n===== 打开的文件 =====" -ForegroundColor Cyan
    $fileInfo = foreach ($file in $openFiles) {
        [PSCustomObject]@{
            ClientComputer = $file.ClientComputerName
            UserName       = $file.ClientUserName
            Share          = $file.ShareRelativeName
            Path           = $file.PathRelativeName
            Locks          = $file.Locks
            FileId         = $file.FileId
        }
    }

    $fileInfo | Format-Table -AutoSize

    # 统计汇总
    [PSCustomObject]@{
        TotalSessions = ($sessionInfo | Measure-Object).Count
        TotalOpenFiles = ($fileInfo | Measure-Object).Count
        UniqueClients = @($sessionInfo | Select-Object -ExpandProperty ClientComputer -Unique).Count
    }
}

# 查看所有共享连接
Get-SmbSessionInfo | Format-List
```

执行结果示例：

```text
===== SMB 会话 =====

ClientComputer    UserName           SessionId NumOpens Transport
--------------    ---------           --------- -------- ---------
192.168.1.100     CONTOSO\user1              1        3 SMB2/3
192.168.1.101     CONTOSO\user2              2        1 SMB2/3
192.168.1.102     CONTOSO\admin              3        5 SMB2/3

===== 打开的文件 =====

ClientComputer UserName        Share     Path                       Locks FileId
-------------- ---------        -----     ----                       ----- ------
192.168.1.100  CONTOSO\user1   Projects  \Reports\Q3-Report.xlsx        0 12345
192.168.1.100  CONTOSO\user1   Projects  \Data\inventory.csv             1 12346
192.168.1.102  CONTOSO\admin   Finance   \Budget\2025-Budget.xlsx       0 12347

TotalSessions : 3
TotalOpenFiles : 9
UniqueClients : 3
```

## 强制关闭共享会话

在维护窗口期需要关闭所有共享连接，确保文件不被锁定。

```powershell
function Close-SmbSessionForce {
    <#
    .SYNOPSIS
    强制关闭 SMB 会话和打开的文件
    .PARAMETER ShareName
    目标共享名称
    .PARAMETER ComputerName
    只关闭特定客户端的连接
    .PARAMETER SendNotification
    是否在关闭前发送通知消息
    .PARAMETER GracePeriodSeconds
    通知后的等待时间（秒）
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$ShareName,

        [string]$ComputerName,

        [switch]$SendNotification,

        [int]$GracePeriodSeconds = 30
    )

    # 获取目标会话
    $sessions = Get-SmbSession -ErrorAction SilentlyContinue

    if ($ComputerName) {
        $sessions = $sessions | Where-Object {
            $_.ClientComputerName -eq $ComputerName
        }
    }

    if ($SendNotification) {
        # 发送通知消息
        $targets = $sessions | Select-Object -ExpandProperty ClientComputerName -Unique
        foreach ($target in $targets) {
            $message = "系统维护通知：共享 [$ShareName] 将在 $GracePeriodSeconds 秒后断开连接，请保存您的工作。"
            msg.exe /server:$target * $message 2>$null
            Write-Verbose "已发送通知到：$target"
        }
        Start-Sleep -Seconds $GracePeriodSeconds
    }

    # 关闭打开的文件
    $openFiles = Get-SmbOpenFile -ErrorAction SilentlyContinue |
        Where-Object { $_.ShareRelativeName -like "*$ShareName*" }

    foreach ($file in $openFiles) {
        try {
            Close-SmbOpenFile -FileId $file.FileId -Force -ErrorAction Stop
            Write-Verbose "已关闭文件：$($file.PathRelativeName)"
        } catch {
            Write-Warning "关闭文件失败：$($file.PathRelativeName) - $($_.Exception.Message)"
        }
    }

    # 关闭会话
    $closedCount = 0
    foreach ($session in $sessions) {
        try {
            Close-SmbSession -SessionId $session.SessionId -Force -ErrorAction Stop
            $closedCount++
            Write-Verbose "已关闭会话：$($session.ClientComputerName)"
        } catch {
            Write-Warning "关闭会话失败：$($session.ClientComputerName) - $($_.Exception.Message)"
        }
    }

    [PSCustomObject]@{
        ShareName      = $ShareName
        FilesClosed    = ($openFiles | Measure-Object).Count
        SessionsClosed = $closedCount
        Timestamp      = Get-Date
    }
}

# 关闭 Finance 共享的所有连接（带通知）
$closeResult = Close-SmbSessionForce -ShareName 'Finance' -SendNotification -GracePeriodSeconds 60 -Verbose
$closeResult | Format-List
```

执行结果示例：

```text
详细: 已发送通知到：192.168.1.102
详细: 已关闭文件：\Budget\2025-Budget.xlsx
详细: 已关闭会话：192.168.1.102

ShareName      : Finance
FilesClosed    : 5
SessionsClosed : 2
Timestamp      : 2025/8/22 10:30:45
```

## 审计共享访问

记录谁在何时访问了哪些文件，满足安全合规要求。

```powershell
function Enable-ShareAccessAudit {
    <#
    .SYNOPSIS
    启用共享文件夹的访问审计
    .PARAMETER SharePath
    共享文件夹路径
    .PARAMETER AuditUsers
    要审计的用户或组
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$SharePath,

        [string[]]$AuditUsers = @('Everyone')
    )

    # 启用全局审核策略（需要管理员权限）
    # 确保文件系统审计策略已启用
    $currentAudit = auditpol.exe /get /subcategory:'File System' /r 2>$null
    Write-Verbose "当前文件系统审计策略：$currentAudit"

    # 设置 NTFS 审计规则
    $acl = Get-Acl -Path $SharePath -Audit

    foreach ($user in $AuditUsers) {
        $identity = New-Object System.Security.Principal.NTAccount($user)

        # 审计所有文件访问操作
        $auditFlags = [System.Security.AccessControl.AuditFlags]::Success -bor
                      [System.Security.AccessControl.AuditFlags]::Failure

        $fileSystemRights = [System.Security.AccessControl.FileSystemRights]::ReadData -bor
                            [System.Security.AccessControl.FileSystemRights]::WriteData -bor
                            [System.Security.AccessControl.FileSystemRights]::Delete -bor
                            [System.Security.AccessControl.FileSystemRights]::DeleteSubdirectoriesAndFiles -bor
                            [System.Security.AccessControl.FileSystemRights]::ChangePermissions

        $inheritance = [System.Security.AccessControl.InheritanceFlags]::ContainerInherit -bor
                       [System.Security.AccessControl.InheritanceFlags]::ObjectInherit
        $propagation = [System.Security.AccessControl.PropagationFlags]::None

        $auditRule = New-Object System.Security.AccessControl.FileSystemAuditRule(
            $identity, $fileSystemRights, $inheritance, $propagation, $auditFlags
        )

        $acl.AddAuditRule($auditRule)
    }

    Set-Acl -Path $SharePath -AclObject $acl

    Write-Host "已启用审计：$SharePath" -ForegroundColor Green
    Write-Host "审计对象：$($AuditUsers -join ', ')" -ForegroundColor Cyan

    # 显示当前审计规则
    $auditAcl = Get-Acl -Path $SharePath -Audit
    $auditAcl.Audit | Format-Table IdentityReference, FileSystemRights, AuditFlags -AutoSize
}

function Get-ShareAccessAuditLog {
    <#
    .SYNOPSIS
    查询共享文件夹的访问审计日志
    .PARAMETER SharePath
    共享文件夹路径
    .PARAMETER Hours
    查询最近多少小时的记录
    #>
    [CmdletBinding()]
    param(
        [string]$SharePath,

        [int]$Hours = 24
    )

    $startTime = (Get-Date).AddHours(-$Hours)

    # 查询安全日志中的文件访问事件
    # 事件 ID 4663 = 文件系统对象访问
    $filterHashtable = @{
        LogName   = 'Security'
        Id        = 4663
        StartTime = $startTime
    }

    $events = Get-WinEvent -FilterHashtable $filterHashtable -ErrorAction SilentlyContinue

    if ($SharePath) {
        $events = $events | Where-Object {
            $_.Message -like "*$SharePath*"
        }
    }

    $results = foreach ($event in $events) {
        $xml = [xml]$event.ToXml()
        $data = @{}
        $xml.Event.EventData.Data | ForEach-Object {
            $data[$_.Name] = $_.'#text'
        }

        [PSCustomObject]@{
            TimeCreated = $event.TimeCreated
            SubjectUser = $data['SubjectUserName']
            ObjectName  = $data['ObjectName']
            AccessMask  = $data['AccessMask']
            ProcessName = $data['ProcessName']
        }
    }

    $results | Sort-Object TimeCreated -Descending | Select-Object -First 50
}

# 启用审计
Enable-ShareAccessAudit -SharePath 'D:\Shares\Finance' -AuditUsers @('Everyone') -Verbose

# 查询审计日志
Get-ShareAccessAuditLog -SharePath 'Finance' -Hours 24 |
    Format-Table TimeCreated, SubjectUser, ObjectName -AutoSize
```

执行结果示例：

```text
详细: 当前文件系统审计策略：Success and Failure
已启用审计：D:\Shares\Finance
审计对象：Everyone

IdentityReference FileSystemRights                 AuditFlags
----------------- ----------------                 ----------
Everyone          ReadData, WriteData, Delete, ...  Success, Failure

TimeCreated          SubjectUser       ObjectName
-----------          -----------       ----------
2025/8/22 09:45:12   CONTOSO\user1     D:\Shares\Finance\Report.xlsx
2025/8/22 09:30:05   CONTOSO\admin     D:\Shares\Finance\Budget\2025.xlsx
2025/8/22 08:15:30   CONTOSO\user2     D:\Shares\Finance\Invoice
```

## 注意事项

- **双重权限模型**：Windows 共享存在"共享权限"和"NTFS 权限"两套独立权限体系，最终有效权限取两者的交集（最严格的限制生效）。建议共享权限设为"Everyone 完全控制"，通过 NTFS 权限做精细控制，避免维护两套权限带来的混乱。
- **SMB 版本**：生产环境应禁用 SMBv1 协议（存在永恒之蓝等高危漏洞），仅启用 SMBv2/v3。可通过 `Set-SmbServerConfiguration -EnableSMB1Protocol $false` 全局关闭 SMBv1。
- **SMB 加密**：在传输敏感数据的共享上启用 SMB 加密（`-EncryptData $true`），防止网络抓包窃取文件内容。注意加密会增加 CPU 开销，高吞吐场景需评估性能影响。
- **权限最小化**：遵循最小权限原则，仅授予完成工作所需的最低权限。避免使用"Everyone"的完全控制权限，应为不同部门和角色设置差异化的访问级别。
- **会话管理**：强制关闭 SMB 会话前务必通知用户，避免数据丢失。使用 `msg.exe` 或其他即时通讯工具提前告知，并预留足够的保存时间。
- **审计性能**：启用文件访问审计会产生大量安全日志，在高频访问的共享上可能导致日志文件快速增长。建议配置日志大小限制和定期归档策略，避免系统盘被审计日志占满。
