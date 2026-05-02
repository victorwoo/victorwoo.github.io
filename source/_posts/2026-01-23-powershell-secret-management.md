---
layout: post
date: 2026-01-23 08:00:00
updated: 2026-01-23 08:00:00
title: "PowerShell 技能连载 - 密钥管理与安全存储"
description: PowerTip of the Day - Secret Management and Secure Storage in PowerShell
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
- secrets
- security
- credentials
- vault
---

_适用于 PowerShell 7.0 及以上版本_

在日常运维和自动化脚本编写中，硬编码密码、API Key 和数据库连接字符串是最常见的安全隐患之一。一旦脚本被误提交到公开仓库或在日志中泄露，敏感信息就会直接暴露。传统的做法是用 `Read-Host -AsSecureString` 手动输入，但这在自动化场景中并不适用。

PowerShell SecretManagement 模块的出现改变了这一局面。它提供了一套统一的密钥管理接口，通过扩展库机制支持多种后端存储：Windows Credential Manager、本地加密文件、Azure Key Vault、KeePass、HashiCorp Vault 等。脚本代码只需面向标准 API 编写，不必关心底层密钥存储在哪里。

本文将从基础安装配置讲起，逐步展示如何构建多保管库策略，以及在 CI/CD 和自动化场景中安全使用密钥的最佳实践。

## SecretManagement 基础：注册保管库与存取密钥

SecretManagement 模块采用"核心模块 + 扩展库"的架构设计。核心模块 `Microsoft.PowerShell.SecretManagement` 提供统一的读写接口，而具体的存储后端由扩展库实现。我们首先安装核心模块和一个常用的本地扩展库。

```powershell
# 安装核心模块和本地加密存储扩展库
Install-Module -Name Microsoft.PowerShell.SecretManagement -Force -Scope CurrentUser
Install-Module -Name Microsoft.PowerShell.SecretStore -Force -Scope CurrentUser

# 注册一个本地加密保管库（SecretStore）
Register-SecretVault -Name 'LocalDev' -ModuleName Microsoft.PowerShell.SecretStore -DefaultVault

# 查看已注册的所有保管库
Get-SecretVault | Format-Table Name, ModuleName, IsDefault

# 存储不同类型的密钥
Set-Secret -Name 'ApiKey' -Secret 'sk-abc123def456ghi789'
Set-Secret -Name 'DbPassword' -Secret (ConvertTo-SecureString 'P@ssw0rd!2026' -AsPlainText -Force)
Set-Secret -Name 'ServiceAccount' -Secret (
    [System.Management.Automation.PSCredential]::new(
        'svc_automation',
        (ConvertTo-SecureString 'SvcP@ss2026!' -AsPlainText -Force)
    )
)

# 枚举保管库中的所有密钥名称
Get-SecretInfo -Vault 'LocalDev'

# 读取密钥并使用
$apiKey = Get-Secret -Name 'ApiKey' -AsPlainText
Write-Output "API Key 前缀: $($apiKey.Substring(0, 8))..."

$dbCred = Get-Secret -Name 'ServiceAccount'
Write-Output "用户名: $($dbCred.UserName)"
```

```text
Name     ModuleName                          IsDefault
----     ----------                          ---------
LocalDev Microsoft.PowerShell.SecretStore         True

Name            Type         Vault
----            ----         -----
ApiKey          String       LocalDev
DbPassword      SecureString LocalDev
ServiceAccount  PSCredential LocalDev

API Key 前缀: sk-abc12...
用户名: svc_automation
```

可以看到 SecretManagement 支持三种密钥类型：普通字符串（String）、安全字符串（SecureString）和凭据对象（PSCredential）。注册保管库时使用 `-DefaultVault` 参数可以省略后续操作中反复指定保管库名称的麻烦。`Get-SecretInfo` 只返回元数据（名称和类型），不会解密实际内容，适合在脚本中做前置检查。

## 多保管库策略：本地开发与生产环境分离

在实际项目中，开发环境和生产环境通常使用不同的密钥存储方案。开发阶段可以用本地加密存储方便调试，而生产环境则需要对接企业级密钥管理服务。SecretManagement 的多保管库机制天然支持这种场景。

```powershell
# 安装 Azure Key Vault 扩展库
Install-Module -Name Az.KeyVault -Force -Scope CurrentUser

# 注册 Azure Key Vault 作为生产保管库
Register-SecretVault -Name 'ProdKeyVault' -ModuleName Az.KeyVault -VaultParameters @{
    AZKVaultName = 'prod-secrets-2026'
    SubscriptionId = 'xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx'
}

# 注册 Windows Credential Manager 扩展库（适合本地开发）
Install-Module -Name SecretManagement.JustinGrote.CredMan -Force -Scope CurrentUser
Register-SecretVault -Name 'CredMan' -ModuleName SecretManagement.JustinGrote.CredMan

# 查看所有保管库的配置
Get-SecretVault | Format-Table Name, ModuleName, IsDefault

# 根据环境变量自动选择保管库
$envName = $env:PSENV ?? 'development'

$vaultName = switch ($envName) {
    'production'  { 'ProdKeyVault' }
    'staging'     { 'CredMan' }
    default       { 'LocalDev' }
}

Write-Output "当前环境: $envName, 使用保管库: $vaultName"

# 写入环境专属密钥
Set-Secret -Name "DbConnection-$envName" -Secret "Server=prod-db;Database=app;" -Vault $vaultName

# 统一读取接口（无需关心底层存储）
$connection = Get-Secret -Name "DbConnection-$envName" -Vault $vaultName -AsPlainText
Write-Output "连接字符串已获取，长度: $($connection.Length) 字符"

# 设置保管库访问密码策略（仅限 SecretStore）
Set-SecretStorePassword -Interaction None -PasswordTimeout 3600
```

```text
Name          ModuleName                                  IsDefault
----          ----------                                  ---------
LocalDev      Microsoft.PowerShell.SecretStore                 True
ProdKeyVault  Az.KeyVault                                    False
CredMan       SecretManagement.JustinGrote.CredMan            False

当前环境: development, 使用保管库: LocalDev
连接字符串已获取，长度: 32 字符
```

多保管库策略的核心价值在于"代码不变，后端可换"。脚本中使用统一的 `Get-Secret` / `Set-Secret` 接口，只需要通过保管库名称区分环境。`Set-SecretStorePassword` 的 `-PasswordTimeout` 参数可以设置密码缓存时长，避免在批量操作中频繁弹出密码提示。

## 自动化脚本中的密钥安全使用

在 CI/CD 流水线和服务自动化场景中，密钥管理面临更多挑战：不能弹出交互式提示、需要支持密钥轮换、还要做好审计追踪。以下示例展示如何在自动化环境中安全地集成 SecretManagement。

```powershell
# --- 文件: Invoke-SecureAutomation.ps1 ---
# 自动化脚本密钥使用模板

# 1. 非交互式初始化（适用于 CI/CD）
$secretStoreConfig = @{
    Authentication  = 'Password'
    PasswordTimeout = 0       # 不缓存密码
    Interaction     = 'None'  # 禁止交互式提示
}
Set-SecretStoreConfiguration @secretStoreConfig -Force

# 2. 用环境变量提供的密码解锁保管库
$vaultPassword = ConvertTo-SecureString $env:VAULT_PASSWORD -AsPlainText -Force
Unlock-SecretStore -Password $vaultPassword

# 3. 定义密钥轮换辅助函数
function Invoke-SecretRotation {
    param(
        [string]$SecretName,
        [string]$VaultName = 'LocalDev',
        [int]$Length = 32
    )

    # 生成随机新密钥
    $chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#$%'
    $rng = [System.Security.Cryptography.RandomNumberGenerator]::Create()
    $bytes = [byte[]]::new($Length)
    $rng.GetBytes($bytes)
    $newSecret = -join ($bytes | ForEach-Object { $chars[$_ % $chars.Length] })

    # 备份旧值（带时间戳）
    $oldValue = Get-Secret -Name $SecretName -Vault $VaultName -AsPlainText -ErrorAction SilentlyContinue
    if ($oldValue) {
        Set-Secret -Name "${SecretName}.backup.$(Get-Date -Format 'yyyyMMdd')" `
            -Secret $oldValue -Vault $VaultName
    }

    # 写入新值
    Set-Secret -Name $SecretName -Secret $newSecret -Vault $VaultName
    Write-Output "[$(Get-Date -Format 'HH:mm:ss')] 密钥 '$SecretName' 已轮换"
}

# 4. 批量获取多个服务的连接凭据
$serviceSecrets = @{
    'DatabaseServer' = 'Svc_Database'
    'MessageQueue'   = 'Svc_MQ'
    'StorageAccount' = 'Svc_Storage'
}

$credentials = foreach ($entry in $serviceSecrets.GetEnumerator()) {
    $cred = Get-Secret -Name $entry.Value -Vault 'LocalDev' -ErrorAction Stop
    [PSCustomObject]@{
        Service   = $entry.Key
        UserName  = if ($cred -is [pscredential]) { $cred.UserName } else { 'N/A' }
        HasSecret = $true
    }
}

$credentials | Format-Table -AutoSize

# 5. 记录密钥访问审计日志
$accessLog = @{
    Timestamp  = Get-Date -Format 'o'
    ScriptName = $MyInvocation.MyCommand.Name
    User       = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name
    Secrets    = $serviceSecrets.Values -join ', '
}
$accessLog | ConvertTo-Json | Out-File -FilePath "./audit-$(Get-Date -Format 'yyyyMMdd').log" -Append
Write-Output "审计日志已记录"
```

```text
[14:30:22] 密钥 'Svc_Database' 已轮换
[14:30:22] 密钥 'Svc_MQ' 已轮换
[14:30:22] 密钥 'Svc_Storage' 已轮换

Service        UserName     HasSecret
-------        --------     ---------
DatabaseServer svc_db          True
MessageQueue   svc_mq          True
StorageAccount svc_storage     True

审计日志已记录
```

这个模板展示了自动化场景的几个关键设计：通过 `Unlock-SecretStore` 用环境变量解锁保管库，避免交互式密码输入；`Invoke-SecretRotation` 函数在轮换密钥时自动备份旧值，方便紧急回滚；审计日志记录了谁在什么时候访问了哪些密钥，满足合规要求。

## 注意事项

1. **必须保护保管库密码**：SecretStore 的加密密码是整个安全链的起点。在 CI/CD 中应使用平台原生机制（如 GitHub Secrets、Azure Pipeline Variables）注入 `VAULT_PASSWORD` 环境变量，绝不能硬编码在脚本中。

2. **区分密钥类型**：`Set-Secret` 会根据传入值的类型自动推断。字符串会以 String 类型存储（`Get-Secret -AsPlainText` 直接可读），SecureString 和 PSCredential 则提供更高的安全等级。建议对高敏感度密钥使用 SecureString 或 PSCredential 类型。

3. **扩展库的选择**：SecretStore 扩展库适合个人开发和小团队，密钥以 AES-256 加密存储在本地文件中。企业环境应优先对接 Azure Key Vault 或 HashiCorp Vault，利用其访问控制、审计日志和自动轮换等高级功能。

4. **密钥命名规范**：建议使用 `{项目}/{环境}/{用途}` 的命名约定（如 `MyApp/Prod/DbPassword`），避免命名冲突，也方便批量查询和管理。

5. **密钥轮换策略**：定期轮换密钥是安全最佳实践。轮换时应先备份旧值、写入新值、验证新值可用后再删除备份。切勿在新值未验证通过时删除旧密钥。

6. **模块版本兼容性**：SecretManagement 的扩展库接口在 1.x 版本中保持稳定，但建议在 `requirements.psd1` 或 `modules.json` 中锁定版本号，避免自动化流水线中因模块自动更新引入兼容性问题。
