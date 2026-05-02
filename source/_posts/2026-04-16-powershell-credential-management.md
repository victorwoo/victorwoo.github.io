---
layout: post
date: 2026-04-16 08:00:00
updated: 2026-04-16 08:00:00
title: "PowerShell 技能连载 - 凭据安全管理"
description: PowerTip of the Day - Secure Credential Management in PowerShell
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
- security
- identity
---

_适用于 PowerShell 7.0 及以上版本_

在自动化脚本中硬编码密码是最常见也最危险的安全隐患之一。一段包含明文密码的脚本一旦被提交到版本控制系统，就会永久留在 Git 历史中，即使后续删除也无济于事。据统计，GitHub 上每天有数千个包含泄露凭据的提交被安全研究员发现。对于企业运维团队来说，一个泄露的服务账号密码可能意味着整个基础设施面临风险。

PowerShell 提供了完善的凭据安全管理机制。从传统的 `PSCredential` + `SecureString` 方案，到现代化的 `SecretManagement` 模块生态，再到凭据轮换与审计的完整生命周期管理，PowerShell 生态已经覆盖了凭据安全的各个环节。合理运用这些工具，可以确保密码永远不会以明文形式出现在脚本、日志或配置文件中。

本文将从三个维度展开：使用 `PSCredential` 和安全字符串进行本地凭据保护；通过 `SecretManagement` 模块实现跨平台密钥管理；以及构建凭据轮换与审计机制，形成完整的凭据安全闭环。

<!-- more -->

## PSCredential 与安全字符串

`PSCredential` 是 PowerShell 中封装用户名和密码的标准对象，密码在内部以 `SecureString` 形式存储，不会以明文暴露在内存中。结合 Windows 的 DPAPI（数据保护 API），可以将凭据安全地序列化到文件，供后续脚本复用。

```powershell
# 方式一：交互式创建凭据（适合手动执行场景）
$cred = Get-Credential -Message '请输入服务账号凭据'

# 方式二：通过代码创建凭据（适合自动化场景）
$plainPassword = 'My$ecureP@ssw0rd!2026'
$securePassword = $plainPassword | ConvertTo-SecureString -AsPlainText -Force
$cred = [System.Management.Automation.PSCredential]::new('svcautomation', $securePassword)

# 将凭据安全导出到文件（DPAPI 加密，仅当前用户可解密）
$cred | Export-Clixml -Path './svcautomation.cred.xml'

# 从文件导入凭据
$loadedCred = Import-Clixml -Path './svcautomation.cred.xml'

# 使用 SecureString 的 DPAPI 加密/解密
$encrypted = $plainPassword | ConvertTo-SecureString -AsPlainText -Force |
    ConvertFrom-SecureString

# 将加密字符串保存到文件
$encrypted | Set-Content -Path './encrypted-password.txt'

# 在另一台机器或用户上下文中解密（需配合 Key 参数使用 AES 对称加密）
$key = (1..16 | ForEach-Object { Get-Random -Minimum 0 -Maximum 255 })
$encryptedWithKey = $plainPassword | ConvertTo-SecureString -AsPlainText -Force |
    ConvertFrom-SecureString -Key $key

Write-Host "用户名: $($loadedCred.UserName)"
Write-Host "密码长度: $($loadedCred.GetNetworkCredential().Password.Length) 个字符"
Write-Host "加密字符串前 40 字符: $($encrypted.Substring(0, 40))..."
```

执行结果示例：

```
用户名: svcautomation
密码长度: 20 个字符
加密字符串前 40 字符: 01000000d08c9ddf0115d1118c7a00c04f...
```

需要注意的是，不带 `-Key` 参数的 `ConvertFrom-SecureString` 使用 Windows DPAPI 加密，加密后的数据只能在同一台机器的同一用户账户下解密。如果需要跨机器传输，必须使用 `-Key` 参数指定 AES 密钥。

## SecretManagement 模块

`Microsoft.PowerShell.SecretManagement` 是微软官方推出的密钥管理框架，采用"核心模块 + 扩展保管库"的架构。核心模块提供统一的读写接口，而实际的密钥存储由扩展库实现，支持 Windows Credential Manager、Azure Key Vault、KeePass、HashiCorp Vault 等多种后端。脚本代码面向统一 API 编写，不必关心底层存储细节。

```powershell
# 安装核心模块和扩展保管库
Install-Module -Name Microsoft.PowerShell.SecretManagement -Force -Scope CurrentUser
Install-Module -Name Microsoft.PowerShell.SecretStore -Force -Scope CurrentUser

# 注册本地 SecretStore 保管库
Register-SecretVault -Name 'LocalDevVault' -ModuleName Microsoft.PowerShell.SecretStore

# 配置保管库策略（需要密码才能访问）
Set-SecretStoreConfiguration -Authentication Password -Interaction None

# 存储各种类型的密钥
Set-Secret -Name 'DatabaseConnection' -Secret 'Server=db01;User=app;Password=S3cure!;' -Vault LocalDevVault
Set-Secret -Name 'ApiKey' -Secret 'sk-proj-abc123def456ghi789' -Vault LocalDevVault
Set-Secret -Name 'ServiceAccount' -Secret (
    [System.Management.Automation.PSCredential]::new(
        'DOMAIN\svcautomation',
        ('P@ssw0rd!' | ConvertTo-SecureString -AsPlainText -Force)
    )
) -Vault LocalDevVault

# 读取密钥
$dbConn = Get-Secret -Name 'DatabaseConnection' -Vault LocalDevVault
$apiKey = Get-Secret -Name 'ApiKey' -Vault LocalDevVault
$svcCred = Get-Secret -Name 'ServiceAccount' -Vault LocalDevVault

# 列出所有密钥名称（不暴露值）
Get-SecretInfo -Vault LocalDevVault | Format-Table Name, Type

# 删除不需要的密钥
Remove-Secret -Name 'ApiKey' -Vault LocalDevVault

# 查看已注册的保管库信息
Get-SecretVault | Format-Table Name, ModuleName, IsDefault
```

执行结果示例：

```
Name                Type
----                ----
DatabaseConnection  SecureString
ApiKey              SecureString
ServiceAccount      PSCredential

Name           ModuleName                          IsDefault
----           ----------                          ---------
LocalDevVault  Microsoft.PowerShell.SecretStore       False
```

SecretManagement 的优势在于扩展性。如果未来需要从本地文件迁移到 Azure Key Vault 或 HashiCorp Vault，只需注册新的保管库并迁移数据，业务脚本中的 `Get-Secret` 调用完全不需要修改。

## 凭据轮换与审计

凭据安全不止于安全存储，还需要定期轮换密码、记录使用日志并设置过期告警。以下代码构建了一个简易的凭据生命周期管理系统，可以自动生成强密码、更新保管库中的密钥，并记录完整的审计日志。

```powershell
# 凭据轮换与审计管理系统

# 生成强随机密码
function New-RandomPassword {
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [int]$Length = 24,
        [int]$NonAlphaNumeric = 6
    )
    $assembly = [System.Reflection.Assembly]::LoadWithPartialName('System.Web')
    $password = [System.Web.Security.Membership]::GeneratePassword($Length, $NonAlphaNumeric)
    return $password
}

# 凭据审计日志（追加式 JSON 日志）
function Write-CredentialAuditLog {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$SecretName,
        [Parameter(Mandatory)]
        [ValidateSet('Create', 'Read', 'Rotate', 'Delete')]
        [string]$Action,
        [string]$VaultName = 'LocalDevVault',
        [string]$Operator = $env:USERNAME
    )
    $logEntry = [ordered]@{
        Timestamp  = Get-Date -Format 'yyyy-MM-ddTHH:mm:ss.fffZ'
        Action     = $Action
        SecretName = $SecretName
        VaultName  = $VaultName
        Operator   = $Operator
        Machine    = $env:COMPUTERNAME
    }
    $logPath = './credential-audit.json'
    $existing = @()
    if (Test-Path $logPath) {
        $existing = Get-Content $logPath -Raw | ConvertFrom-Json
        if ($existing -isnot [array]) { $existing = @($existing) }
    }
    $existing += $logEntry
    $existing | ConvertTo-Json -Depth 5 | Set-Content $logPath -Encoding UTF8
}

# 凭据轮换：生成新密码并更新保管库
function Invoke-CredentialRotation {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$SecretName,
        [string]$VaultName = 'LocalDevVault'
    )
    $newPassword = New-RandomPassword -Length 32 -NonAlphaNumeric 8
    $secureNew = $newPassword | ConvertTo-SecureString -AsPlainText -Force
    Set-Secret -Name $SecretName -Secret $secureNew -Vault $VaultName
    Write-CredentialAuditLog -SecretName $SecretName -Action Rotate -VaultName $VaultName
    Write-Host "[$SecretName] 密码已轮换，新密码长度: $($newPassword.Length) 字符"
}

# 检查凭据是否即将过期（基于审计日志中的最后轮换时间）
function Test-CredentialExpiry {
    [CmdletBinding()]
    param(
        [int]$ExpireDays = 90
    )
    $logPath = './credential-audit.json'
    if (-not (Test-Path $logPath)) {
        Write-Warning '审计日志文件不存在，无法检查凭据过期状态'
        return
    }
    $logs = Get-Content $logPath -Raw | ConvertFrom-Json
    $rotateLogs = $logs | Where-Object { $_.Action -eq 'Rotate' }
    $latestRotations = $rotateLogs | Group-Object SecretName | ForEach-Object {
        $latest = ($_.Group | Sort-Object Timestamp -Descending | Select-Object -First 1)
        [PSCustomObject]@{
            SecretName    = $_.Name
            LastRotated   = [datetime]$latest.Timestamp
            DaysSince     = [math]::Floor((Get-Date) - [datetime]$latest.Timestamp)
            ShouldRotate  = ((Get-Date) - [datetime]$latest.Timestamp).TotalDays -gt $ExpireDays
        }
    }
    $latestRotations | Format-Table SecretName, LastRotated, DaysSince, ShouldRotate
    $expired = $latestRotations | Where-Object { $_.ShouldRotate }
    if ($expired) {
        Write-Warning "以下凭据已超过 $ExpireDays 天未轮换：$($expired.SecretName -join ', ')"
    }
}

# 执行轮换并记录审计日志
Invoke-CredentialRotation -SecretName 'DatabaseConnection' -VaultName LocalDevVault
Invoke-CredentialRotation -SecretName 'ServiceAccount' -VaultName LocalDevVault

# 检查凭据过期状态
Test-CredentialExpiry -ExpireDays 90
```

执行结果示例：

```
[DatabaseConnection] 密码已轮换，新密码长度: 32 字符
[ServiceAccount] 密码已轮换，新密码长度: 32 字符

SecretName          LastRotated              DaysSince ShouldRotate
----------          ------------               --------- ------------
DatabaseConnection  2026-04-16T10:30:00.000Z          0        False
ServiceAccount      2026-04-16T10:30:01.000Z          0        False
```

## 注意事项

- **绝不硬编码密码**：脚本中出现的任何明文密码都是安全隐患，应始终通过 `PSCredential`、`SecureString` 或 `SecretManagement` 模块来管理凭据。
- **DPAPI 加密的局限性**：不带 `-Key` 参数的 `ConvertFrom-SecureString` 使用 Windows DPAPI，加密数据绑定于当前机器和用户账户，无法跨机器解密。跨机器场景请使用 `-Key` 参数配合 AES 对称加密。
- **SecretStore 密码保护**：生产环境中务必将 SecretStore 配置为需要密码访问（`Set-SecretStoreConfiguration -Authentication Password`），不要使用 None 模式，否则任何能登录的用户都能读取密钥。
- **审计日志的存储安全**：凭据审计日志本身也包含敏感操作记录，应存放在受保护的位置，并设置适当的 NTFS 权限或文件加密，防止未授权访问。
- **定期轮换密码**：建议建立密码轮换策略，至少每 90 天轮换一次服务账号密码。轮换后确保所有依赖该凭据的自动化任务都使用更新后的密钥。
- **密钥传输安全**：在 CI/CD 管线中使用密钥时，应通过安全的管线变量或环境变量传递，避免将密钥写入磁盘文件或打印到控制台输出中。
