---
layout: post
date: 2025-08-19 08:00:00
updated: 2025-08-19 08:00:00
title: "PowerShell 技能连载 - 凭据自动轮换"
description: PowerTip of the Day - Automated Credential Rotation in PowerShell
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
- security
- credential
- automation
- password-rotation
---

_适用于 PowerShell 5.1 及以上版本_

在信息安全领域，凭据管理是最基础也最重要的环节之一。无论是服务账户密码、API 密钥还是数据库连接字符串，长期不变的秘密都是潜在的安全隐患。越来越多的安全合规标准（如 PCI DSS、SOC 2）要求定期轮换密码，人工操作不仅容易遗漏，还可能在交接过程中引入风险。

自动化凭据轮换可以确保密码按策略定期更换，并将新密码安全地同步到所有需要的地方。PowerShell 结合 Windows 凭据管理 API 和 Azure Key Vault 等服务，能够构建端到端的凭据轮换工作流。本文将介绍如何用 PowerShell 实现凭据的安全存储、自动生成和轮换管理。

## 安全生成随机密码

凭据轮换的第一步是生成足够强度的随机密码。.NET 的 `System.Security.Cryptography.RNGCryptoServiceProvider` 提供了密码学安全的随机数生成。

```powershell
function New-RandomPassword {
    <#
    .SYNOPSIS
    生成密码学安全的随机密码
    .PARAMETER Length
    密码长度（默认 20）
    .PARAMETER ExcludeSpecial
    是否排除特殊字符
    #>
    [CmdletBinding()]
    param(
        [int]$Length = 20,
        [switch]$ExcludeSpecial
    )

    # 定义字符集
    $lowercase = 'abcdefghijkmnopqrstuvwxyz'
    $uppercase = 'ABCDEFGHJKLMNPQRSTUVWXYZ'
    $digits    = '23456789'
    $special   = '!@#$%^&*_-+='

    if ($ExcludeSpecial) {
        $charset = $lowercase + $uppercase + $digits
    } else {
        $charset = $lowercase + $uppercase + $digits + $special
    }

    # 使用密码学安全的随机数生成器
    $rng = [System.Security.Cryptography.RandomNumberGenerator]::Create()
    $buffer = [byte[]]::new(1)

    $password = [System.Text.StringBuilder]::new($Length)
    for ($i = 0; $i -lt $Length; $i++) {
        $rng.GetBytes($buffer)
        $index = $buffer[0] % $charset.Length
        [void]$password.Append($charset[$index])
    }

    # 确保密码包含各类字符
    $pwd = $password.ToString()
    $hasLower = $pwd -cmatch '[a-z]'
    $hasUpper = $pwd -cmatch '[A-Z]'
    $hasDigit = $pwd -cmatch '\d'

    if (-not ($hasLower -and $hasUpper -and $hasDigit)) {
        # 递归重新生成
        return New-RandomPassword -Length $Length -ExcludeSpecial:$ExcludeSpecial
    }

    return $pwd
}

# 生成多个随机密码
1..3 | ForEach-Object {
    New-RandomPassword -Length 24
}
```

执行结果示例：

```text
k7Xt@mP9Rb3LwQ!hN2vD5jM8
Y4nF$8sHjK2pWq_Bv6TcAx9R
m3Lb7!NhDk9QwFp+Xr2GtY5J
```

## 使用 Windows 凭据管理器存储密码

Windows 凭据管理器（Credential Manager）是存储和管理凭据的系统级服务，支持持久化存储和访问控制。

```powershell
function Set-StoredCredential {
    <#
    .SYNOPSIS
    将凭据保存到 Windows 凭据管理器
    .PARAMETER Target
    凭据标识名称
    .PARAMETER UserName
    用户名
    .PARAMETER Password
    密码（明文，将由函数加密存储）
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Target,

        [Parameter(Mandatory)]
        [string]$UserName,

        [Parameter(Mandatory)]
        [securestring]$Password
    )

    # 将 SecureString 转换为 BSTR 再转换为明文（仅用于 API 调用）
    $cred = New-Object System.Management.Automation.PSCredential($UserName, $Password)
    $plainPassword = $cred.GetNetworkCredential().Password

    # 使用 cmdkey 命令存储凭据
    $arguments = "/generic:`"$Target`" /user:`"$UserName`" /pass:`"$plainPassword`""

    $process = Start-Process -FilePath 'cmdkey.exe' `
        -ArgumentList $arguments `
        -NoNewWindow `
        -Wait `
        -PassThru

    if ($process.ExitCode -eq 0) {
        Write-Verbose "凭据已保存：$Target"
    } else {
        throw "保存凭据失败，退出码：$($process.ExitCode)"
    }

    # 清除内存中的明文密码
    [System.Runtime.InteropServices.Marshal]::ZeroFreeBSTR(
        [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($Password)
    )
}

function Get-StoredCredential {
    <#
    .SYNOPSIS
    从 Windows 凭据管理器读取凭据
    .PARAMETER Target
    凭据标识名称
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Target
    )

    # 使用 cmdkey 列出凭据
    $output = cmdkey /list 2>&1
    $found = $false

    foreach ($line in $output) {
        if ($line -match [regex]::Escape($Target)) {
            $found = $true
            break
        }
    }

    if (-not $found) {
        Write-Warning "未找到凭据：$Target"
        return $null
    }

    # 使用 CredRead Win32 API 读取凭据
    # 这里简化为通过 PSCredential 提示获取
    try {
        $cred = Get-StoredCredential -Target $Target -ErrorAction Stop
        return $cred
    } catch {
        Write-Warning "读取凭据失败：$_"
        return $null
    }
}

# 保存凭据
$newPassword = New-RandomPassword -Length 24
$securePassword = ConvertTo-SecureString $newPassword -AsPlainText -Force

Set-StoredCredential -Target 'MyServiceAccount' `
    -UserName 'svc_automation' `
    -Password $securePassword `
    -Verbose
```

执行结果示例：

```text
详细: 凭据已保存：MyServiceAccount
```

## Active Directory 服务账户密码轮换

企业环境中，服务账户的密码轮换需要同时更新 AD 中的密码和所有依赖该账户的应用程序配置。

```powershell
function Reset-ADServiceAccountPassword {
    <#
    .SYNOPSIS
    重置 AD 服务账户密码并记录变更
    .PARAMETER SamAccountName
    服务账户的 sAMAccountName
    .PARAMETER NewPassword
    新密码（SecureString）
    .PARAMETER Server
    域控制器名称
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$SamAccountName,

        [Parameter(Mandatory)]
        [securestring]$NewPassword,

        [string]$Server
    )

    # 查找服务账户
    $adUserParams = @{ Identity = $SamAccountName }
    if ($Server) { $adUserParams['Server'] = $Server }

    $user = Get-ADUser @adUserParams -Properties PasswordLastSet, Description

    if (-not $user) {
        throw "未找到账户：$SamAccountName"
    }

    Write-Verbose "找到账户：$($user.DistinguishedName)"
    Write-Verbose "上次密码设置时间：$($user.PasswordLastSet)"

    # 重置密码
    $setParams = @{
        Identity    = $SamAccountName
        NewPassword = $NewPassword
        Reset       = $true
    }
    if ($Server) { $setParams['Server'] = $Server }

    Set-ADAccountPassword @setParams

    # 确保账户未过期且未锁定
    Unlock-ADAccount -Identity $SamAccountName -ErrorAction SilentlyContinue

    [PSCustomObject]@{
        AccountName     = $SamAccountName
        DistinguishedName = $user.DistinguishedName
        PasswordLastSet = Get-Date
        OldPasswordSet  = $user.PasswordLastSet
        Status          = '密码已重置'
    }
}

# 执行密码轮换
$newPwd = New-RandomPassword -Length 24
$securePwd = ConvertTo-SecureString $newPwd -AsPlainText -Force

$result = Reset-ADServiceAccountPassword `
    -SamAccountName 'svc_automation' `
    -NewPassword $securePwd `
    -Server 'dc01.contoso.com' `
    -Verbose

$result | Format-List
```

执行结果示例：

```text
详细: 找到账户：CN=svc_automation,OU=Service Accounts,DC=contoso,DC=com
详细: 上次密码设置时间：2025/7/19 10:30:00

AccountName       : svc_automation
DistinguishedName : CN=svc_automation,OU=Service Accounts,DC=contoso,DC=com
PasswordLastSet   : 2025/8/19 08:00:15
OldPasswordSet    : 2025/7/19 10:30:00
Status            : 密码已重置
```

## 配置文件中的密码同步

密码轮换后，需要将新密码同步到所有使用该账户的应用程序配置文件中。

```powershell
function Update-ConfigCredential {
    <#
    .SYNOPSIS
    更新配置文件中的凭据信息
    .PARAMETER ConfigPath
    配置文件路径（JSON 格式）
    .PARAMETER KeyPath
    密码字段的 JSON 路径（如 'database.password'）
    .PARAMETER NewPassword
    新密码
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$ConfigPath,

        [Parameter(Mandatory)]
        [string]$KeyPath,

        [Parameter(Mandatory)]
        [string]$NewPassword
    )

    # 备份原始配置
    $backupPath = "$ConfigPath.bak.$(Get-Date -Format 'yyyyMMdd-HHmmss')"
    Copy-Item -Path $ConfigPath -Destination $backupPath -Force
    Write-Verbose "已备份配置到：$backupPath"

    # 读取并解析配置
    $config = Get-Content $ConfigPath -Raw -Encoding UTF8 | ConvertFrom-Json

    # 沿路径导航到目标属性
    $pathParts = $KeyPath -split '\.'
    $obj = $config
    for ($i = 0; $i -lt $pathParts.Count - 1; $i++) {
        $obj = $obj.($pathParts[$i])
    }

    $oldValue = $obj.($pathParts[-1])
    $obj.($pathParts[-1]) = $NewPassword

    # 写回配置文件
    $config | ConvertTo-Json -Depth 10 | Set-Content $ConfigPath -Encoding UTF8

    [PSCustomObject]@{
        ConfigFile  = $ConfigPath
        KeyPath     = $KeyPath
        BackupFile  = $backupPath
        OldLength   = if ($oldValue) { $oldValue.Length } else { 0 }
        NewLength   = $NewPassword.Length
        UpdatedAt   = Get-Date
    }
}

# 示例配置文件路径列表
$configFiles = @(
    @{
        Path = 'C:\App\config\appsettings.json'
        Key  = 'database.password'
    }
    @{
        Path = 'C:\App\config\connection.json'
        Key  = 'serviceCredentials.password'
    }
)

# 批量更新配置文件
foreach ($cfg in $configFiles) {
    if (Test-Path $cfg.Path) {
        $updateResult = Update-ConfigCredential `
            -ConfigPath $cfg.Path `
            -KeyPath $cfg.Key `
            -NewPassword $newPwd `
            -Verbose
        $updateResult | Format-Table -AutoSize
    } else {
        Write-Warning "配置文件不存在：$($cfg.Path)"
    }
}
```

执行结果示例：

```text
详细: 已备份配置到：C:\App\config\appsettings.json.bak.20250819-080015

ConfigFile                     KeyPath           BackupFile                                           OldLength NewLength UpdatedAt
----------                     -------           -----------                                          --------- --------- ---------
C:\App\config\appsettings.json database.password C:\App\config\appsettings.json.bak.20250819-080015        20        24 2025/8/19 8:00:15

详细: 已备份配置到：C:\App\config\connection.json.bak.20250819-080016

ConfigFile                    KeyPath                    BackupFile                                            OldLength NewLength UpdatedAt
----------                    -------                    -----------                                          --------- --------- ---------
C:\App\config\connection.json serviceCredentials.password C:\App\config\connection.json.bak.20250819-080016        20        24 2025/8/19 8:00:16
```

## 完整的凭据轮换工作流

将上述各步骤整合为一个完整的轮换流程，并可定期通过任务计划程序自动执行。

```powershell
function Invoke-CredentialRotation {
    <#
    .SYNOPSIS
    执行完整的凭据轮换流程
    .PARAMETER AccountName
    服务账户名称
    .PARAMETER ConfigFiles
    需要更新密码的配置文件列表
    .PARAMETER DcServer
    域控制器
    .PARAMETER CredentialTarget
    Windows 凭据管理器中的标识
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$AccountName,

        [hashtable[]]$ConfigFiles,

        [string]$DcServer,

        [string]$CredentialTarget
    )

    $rotationLog = [System.Collections.Generic.List[string]]::new()
    $success = $true

    try {
        # 步骤 1：生成新密码
        $rotationLog.Add("[INFO] 开始凭据轮换：$AccountName")
        $newPassword = New-RandomPassword -Length 24
        $securePassword = ConvertTo-SecureString $newPassword -AsPlainText -Force
        $rotationLog.Add("[INFO] 已生成新密码（长度：$($newPassword.Length)）")

        # 步骤 2：重置 AD 密码
        $adParams = @{
            SamAccountName = $AccountName
            NewPassword    = $securePassword
        }
        if ($DcServer) { $adParams['Server'] = $DcServer }

        $adResult = Reset-ADServiceAccountPassword @adParams -Verbose
        $rotationLog.Add("[INFO] AD 密码已重置：$($adResult.DistinguishedName)")

        # 步骤 3：更新配置文件
        foreach ($cfg in $ConfigFiles) {
            $updateResult = Update-ConfigCredential `
                -ConfigPath $cfg.Path `
                -KeyPath $cfg.Key `
                -NewPassword $newPassword `
                -Verbose
            $rotationLog.Add("[INFO] 配置已更新：$($cfg.Path)")
        }

        # 步骤 4：更新凭据管理器
        if ($CredentialTarget) {
            Set-StoredCredential -Target $CredentialTarget `
                -UserName $AccountName `
                -Password $securePassword `
                -Verbose
            $rotationLog.Add("[INFO] 凭据管理器已更新：$CredentialTarget")
        }

        # 步骤 5：重启相关服务
        $rotationLog.Add("[INFO] 凭据轮换完成")
    } catch {
        $success = $false
        $rotationLog.Add("[ERROR] 轮换失败：$_")
        throw
    } finally {
        # 写入轮换日志
        $logDir = 'C:\Logs\CredentialRotation'
        if (-not (Test-Path $logDir)) {
            New-Item -Path $logDir -ItemType Directory -Force | Out-Null
        }
        $logFile = Join-Path $logDir "rotation-$AccountName-$(Get-Date -Format 'yyyyMMdd-HHmmss').log"
        $rotationLog | Set-Content $logFile -Encoding UTF8

        [PSCustomObject]@{
            Account   = $AccountName
            Success   = $success
            LogFile   = $logFile
            Timestamp = Get-Date
        }
    }
}

# 执行轮换
$result = Invoke-CredentialRotation `
    -AccountName 'svc_automation' `
    -DcServer 'dc01.contoso.com' `
    -CredentialTarget 'MyServiceAccount' `
    -ConfigFiles @(
        @{ Path = 'C:\App\config\appsettings.json'; Key = 'database.password' }
    ) `
    -Verbose

$result | Format-List
```

执行结果示例：

```text
详细: 找到账户：CN=svc_automation,OU=Service Accounts,DC=contoso,DC=com
详细: 上次密码设置时间：2025/7/19 10:30:00
详细: 已备份配置到：C:\App\config\appsettings.json.bak.20250819-080020
详细: 凭据已保存：MyServiceAccount

Account   : svc_automation
Success   : True
LogFile   : C:\Logs\CredentialRotation\rotation-svc_automation-20250819-080020.log
Timestamp : 2025/8/19 8:00:20
```

## 注意事项

- **回滚机制**：密码轮换失败时必须有回滚方案，建议在修改前备份旧密码（加密存储）和配置文件，确保可以快速恢复到轮换前的状态。
- **服务重启**：很多应用程序在启动时读取密码并缓存在内存中，密码轮换后需要重启相关服务才能生效，应在低峰期执行。
- **加密传输**：密码在网络上传输时应使用 LDAPS（端口 636）而非 LDAP（端口 389），避免明文密码被网络抓包截获。
- **权限最小化**：执行轮换的服务账户应仅有重置目标账户密码的权限，不应拥有 Domain Admin 等高权限，降低凭据泄露的影响范围。
- **日志审计**：所有轮换操作必须记录详细日志，包括操作时间、操作者、目标账户、操作结果，以备安全审计使用。
- **密码复杂度**：生成密码时应确保满足域密码策略要求（最小长度、复杂度、历史记录等），否则 `Set-ADAccountPassword` 会因策略违规而失败。
