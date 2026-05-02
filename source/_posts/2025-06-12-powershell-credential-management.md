---
layout: post
date: 2025-06-12 08:00:00
updated: 2025-06-12 08:00:00
title: "PowerShell 技能连载 - 凭据管理与安全存储"
description: PowerTip of the Day - Credential Management and Secure Storage in PowerShell
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

_适用于 PowerShell 5.1 及以上版本，SecretManagement 模块需要 PowerShell 7_

脚本中的硬编码密码是安全隐患的头号来源。无论是数据库连接字符串中的密码、API 密钥还是 SSH 私钥，都应该使用安全的存储机制。PowerShell 提供了多层凭据管理方案——从基本的 `PSCredential` 对象到 `SecureString`，再到现代化的 `SecretManagement` 模块，可以满足从单机脚本到企业级自动化的所有需求。

本文将讲解凭据的安全创建、存储、使用，以及 Microsoft.PowerShell.SecretManagement 模块的使用。

<!-- more -->

## PSCredential 基础

`PSCredential` 是 PowerShell 中表示用户名+密码的标准方式：

```powershell
# 交互式创建凭据（弹出对话框）
$cred = Get-Credential -Message "输入数据库管理员凭据"
Write-Host "用户名：$($cred.UserName)"

# 从明文创建 SecureString（仅用于脚本内传递，不要存储）
$plainPassword = "MyPassword123!"
$securePassword = ConvertTo-SecureString $plainPassword -AsPlainText -Force
$cred = New-Object System.Management.Automation.PSCredential("admin", $securePassword)

# 从凭据中提取密码（仅在需要明文密码时使用）
$password = $cred.GetNetworkCredential().Password
Write-Host "密码长度：$($password.Length) 字符"

# 在命令中使用凭据
# Invoke-Command -ComputerName SRV01 -Credential $cred -ScriptBlock { ... }

# 验证凭据是否有效（简单测试）
function Test-Credential {
    param([PSCredential]$Credential)

    try {
        $context = New-Object System.DirectoryServices.DirectoryEntry(
            "", $Credential.UserName, $Credential.GetNetworkCredential().Password
        )
        if ($context.Name) {
            Write-Host "凭据有效：$($Credential.UserName)" -ForegroundColor Green
            return $true
        }
    } catch {
        Write-Host "凭据无效：$($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}
```

执行结果示例：

```
用户名：admin
密码长度：13 字符
凭据有效：CONTOSO\admin
```

## 安全文件存储

```powershell
function Save-CredentialToFile {
    <#
    .SYNOPSIS
    将凭据安全保存到文件（DPAPI 加密）
    #>
    param(
        [Parameter(Mandatory)]
        [string]$Name,

        [Parameter(Mandatory)]
        [PSCredential]$Credential,

        [string]$Path = "$env:USERPROFILE\.creds"
    )

    if (-not (Test-Path $Path)) {
        New-Item -Path $Path -ItemType Directory | Out-Null
    }

    $filePath = Join-Path $Path "$Name.xml"
    $Credential | Export-Clixml -Path $filePath
    Write-Host "凭据已保存到：$filePath" -ForegroundColor Green
}

function Get-CredentialFromFile {
    <#
    .SYNOPSIS
    从文件加载凭据
    #>
    param(
        [Parameter(Mandatory)]
        [string]$Name,

        [string]$Path = "$env:USERPROFILE\.creds"
    )

    $filePath = Join-Path $Path "$Name.xml"
    if (-not (Test-Path $filePath)) {
        Write-Error "凭据文件不存在：$filePath"
        return $null
    }

    Import-Clixml -Path $filePath
}

# 使用示例
$dbCred = Get-Credential -Message "输入数据库凭据"
Save-CredentialToFile -Name "database" -Credential $dbCred

# 后续脚本中加载
$loadedCred = Get-CredentialFromFile -Name "database"
Write-Host "已加载凭据：$($loadedCred.UserName)"
```

执行结果示例：

```
凭据已保存到：C:\Users\admin\.creds\database.xml
已加载凭据：sa
```

> **注意**：`Export-Clixml` 使用 Windows DPAPI 加密，只有当前用户在同一台机器上才能解密。不要将 `.creds` 目录加入版本控制。

## SecretManagement 模块

PowerShell 7 的 `SecretManagement` 模块是微软推荐的现代化凭据管理方案，支持多种后端存储：

```powershell
# 安装模块
Install-Module -Name Microsoft.PowerShell.SecretManagement -Scope CurrentUser -Force
Install-Module -Name Microsoft.PowerShell.SecretStore -Scope CurrentUser -Force

# 注册本地 Secret Store 保管库
Register-SecretVault -Name "LocalVault" -ModuleName Microsoft.PowerShell.SecretStore -DefaultVault

# 设置保管库密码（首次使用）
Set-SecretStorePassword

# 存储凭据
$dbCred = Get-Credential -Message "数据库凭据"
Set-Secret -Name "DBAdmin" -Secret $dbCred -Vault "LocalVault"

# 存储简单字符串（API 密钥）
Set-Secret -Name "GitHubToken" -Secret "ghp_xxxxxxxxxxxx" -Vault "LocalVault"
Set-Secret -Name "OpenAIKey" -Secret "sk-xxxxxxxxxxxx" -Vault "LocalVault"

# 查看已存储的密钥列表
Get-SecretInfo -Vault "LocalVault" |
    Select-Object Name, Type |
    Format-Table -AutoSize

# 获取密钥
$token = Get-Secret -Name "GitHubToken" -AsPlainText
Write-Host "Token 长度：$($token.Length)"

$cred = Get-Secret -Name "DBAdmin"
Write-Host "用户名：$($cred.UserName)"

# 在脚本中使用
function Connect-MyDatabase {
    $dbCred = Get-Secret -Name "DBAdmin"
    $connString = "Server=prod-db;User ID=$($dbCred.UserName);Password=$($dbCred.GetNetworkCredential().Password)"
    # 使用 $connString 连接数据库
}
```

执行结果示例：

```
Name         Type
----         ----
DBAdmin      PSCredential
GitHubToken  String
OpenAIKey    String

Token 长度：40
用户名：sa
```

## Azure Key Vault 集成

对于企业环境，Azure Key Vault 是推荐的集中式密钥管理方案：

```powershell
# 安装 Azure Key Vault 扩展
Install-Module -Name Az.KeyVault -Scope CurrentUser -Force

# 注册 Azure Key Vault 作为 Secret 保管库
Register-SecretVault -Name "AzureKV" -ModuleName Az.KeyVault `
    -VaultParameters @{ AZKVaultName = 'my-company-vault'; SubscriptionId = 'xxx-xxx' }

# 存储密钥到 Azure Key Vault
$apiCred = Get-Credential -Message "API 服务账户"
Set-Secret -Name "ApiServiceAccount" -Secret $apiCred -Vault "AzureKV"

# 从 Azure Key Vault 获取密钥
$apiCred = Get-Secret -Name "ApiServiceAccount" -Vault "AzureKV"
```

执行结果示例：

```
# 首次访问时需要 Azure 认证
```

## 环境变量传递敏感信息

在 CI/CD 和容器化环境中，环境变量是传递凭据的常用方式：

```powershell
# 从环境变量创建凭据
$dbUser = $env:DB_USER
$dbPass = $env:DB_PASSWORD | ConvertTo-SecureString -AsPlainText -Force
$dbCred = New-Object PSCredential($dbUser, $dbPass)

Write-Host "数据库用户：$($dbCred.UserName)"

# 安全地读取 API 密钥
$apiKey = $env:OPENAI_API_KEY
if (-not $apiKey) {
    Write-Error "未设置环境变量 OPENAI_API_KEY"
    exit 1
}
Write-Host "API Key 已加载（长度：$($apiKey.Length)）"

# 检查所有必要的环境变量
$requiredEnvVars = @('DB_USER', 'DB_PASSWORD', 'API_KEY', 'SMTP_SERVER')
$missing = $requiredEnvVars | Where-Object { -not (Get-ChildItem env:$_ -ErrorAction SilentlyContinue) }

if ($missing) {
    Write-Error "缺少环境变量：$($missing -join ', ')"
    exit 1
}
Write-Host "所有环境变量已配置" -ForegroundColor Green
```

执行结果示例：

```
数据库用户：sa
API Key 已加载（长度：48）
所有环境变量已配置
```

## 注意事项

1. **不要硬编码密码**：脚本中永远不应出现明文密码。使用环境变量、密钥库或交互式输入
2. **DPAPI 限制**：`Export-Clixml` 的 DPAPI 加密绑定到当前用户和机器，不能跨机器使用
3. **SecretStore 密码**：忘记 SecretStore 密码后无法恢复已存储的密钥，务必妥善保管
4. **日志脱敏**：脚本输出中不要打印密码和密钥。使用 `****` 替代敏感信息
5. **最小权限原则**：为自动化服务账户仅授予必要的最小权限
6. **定期轮换**：定期轮换 API 密钥和服务账户密码，并在密钥库中同步更新
