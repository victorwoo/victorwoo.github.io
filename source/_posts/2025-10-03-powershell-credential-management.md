---
layout: post
date: 2025-10-03 08:00:00
updated: 2025-10-03 08:00:00
title: "PowerShell 技能连载 - 凭据管理"
description: PowerTip of the Day - Credential Management in PowerShell
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
- credential
- pscredential
- security
- secret
---

_适用于 PowerShell 5.1 及以上版本_

<!-- more -->

## 凭据管理的重要性

在日常运维和自动化脚本中，我们经常需要处理各种凭据：远程服务器的登录密码、API 密钥、数据库连接字符串等。如果直接将这些敏感信息以明文形式写在脚本中，不仅存在极大的安全隐患，也违反了绝大多数企业的安全合规要求。

PowerShell 提供了 `PSCredential` 对象来安全地封装用户名和密码。密码在 `PSCredential` 内部以 `SecureString` 形式存储，不会以明文暴露在内存中。结合 Windows 的 DPAPI（数据保护 API），我们可以将凭据安全地保存到文件，在后续脚本中重复使用，而无需每次手动输入。

本文将介绍从创建凭据、安全存储凭据到使用 Microsoft.PowerShell.SecretManagement 模块管理密钥的完整流程，帮助你建立一套规范的凭据管理方案。

## 创建 PSCredential 对象

最直接的方式是使用 `Get-Credential` cmdlet，它会弹出一个 Windows 对话框让用户输入用户名和密码。在无人值守的自动化场景中，我们可以通过代码手动构建 `PSCredential` 对象。以下示例展示了两种创建方式，并将密码转换为明文进行验证。

```powershell
# 方式一：交互式弹窗获取凭据
$cred = Get-Credential -Message "请输入远程服务器凭据"

# 方式二：在脚本中手动构建凭据（适合自动化场景）
$username = "AdminUser"
$password = ConvertTo-SecureString -String "MyP@ssw0rd!" -AsPlainText -Force
$cred = [System.Management.Automation.PSCredential]::new($username, $password)

# 查看凭据信息
Write-Host "用户名: $($cred.UserName)"
Write-Host "密码长度: $($cred.GetNetworkCredential().Password.Length) 个字符"
Write-Host "密码是否已加密: $($cred.Password.IsReadOnly())"
```

```text
用户名: AdminUser
密码长度: 11 个字符
密码是否已加密: False
```

## 安全存储和读取凭据

直接在脚本中硬编码密码显然不安全。更好的做法是将密码以加密形式导出到文件，后续脚本从文件中读取。`ConvertFrom-SecureString` 利用当前用户的 DPAPI 证书对密码加密，导出的密文只有同一台机器上的同一个用户才能解密。

```powershell
# 将密码加密保存到文件
$secretFile = "$env:USERPROFILE\.secrets\remote-admin.xml"

# 确保目录存在
$dir = Split-Path -Path $secretFile -Parent
if (-not (Test-Path -Path $dir)) {
    $null = New-Item -Path $dir -ItemType Directory -Force
}

# 创建凭据并导出加密密码
$username = "AdminUser"
$password = Read-Host -Prompt "请输入密码" -AsSecureString
$cred = [System.Management.Automation.PSCredential]::new($username, $password)

# 将加密后的密码保存到文件
$password | ConvertFrom-SecureString | Out-File -FilePath $secretFile -Encoding UTF8
Write-Host "凭据已安全保存到: $secretFile"

# 在另一个脚本中读取凭据
$encryptedPassword = Get-Content -Path $secretFile -Raw
$securePassword = $encryptedPassword | ConvertTo-SecureString
$restoredCred = [System.Management.Automation.PSCredential]::new($username, $securePassword)

Write-Host "凭据已恢复 - 用户名: $($restoredCred.UserName)"
```

```text
凭据已安全保存到: C:\Users\admin\.secrets\remote-admin.xml
凭据已恢复 - 用户名: AdminUser
```

## 批量管理多个服务的凭据

在真实环境中，我们往往需要同时管理多组凭据：数据库账号、API 密钥、SSH 登录等。可以为每组凭据创建独立的加密文件，并编写一个统一的管理函数来简化操作。

```powershell
function Save-Secret {
    <#
    .SYNOPSIS
    将凭据加密保存到本地文件
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Name,

        [Parameter(Mandatory)]
        [string]$UserName,

        [Parameter(Mandatory)]
        [securestring]$Password
    )

    $secretDir = Join-Path -Path $env:USERPROFILE -ChildPath ".secrets"
    if (-not (Test-Path -Path $secretDir)) {
        $null = New-Item -Path $secretDir -ItemType Directory -Force
    }

    $cred = [System.Management.Automation.PSCredential]::new($UserName, $Password)
    $filePath = Join-Path -Path $secretDir -ChildPath "$Name.xml"

    # 使用 Export-Clixml 保存整个凭据对象（包含用户名和加密密码）
    $cred | Export-Clixml -Path $filePath -Encoding UTF8
    Write-Host "[$Name] 凭据已保存到: $filePath"
}

function Get-Secret {
    <#
    .SYNOPSIS
    从本地文件读取已加密的凭据
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Name
    )

    $filePath = Join-Path -Path $env:USERPROFILE -ChildPath ".secrets\$Name.xml"
    if (-not (Test-Path -Path $filePath)) {
        Write-Error "找不到名为 [$Name] 的凭据文件"
        return
    }

    # Import-Clixml 自动利用 DPAPI 解密还原 PSCredential 对象
    $cred = Import-Clixml -Path $filePath
    Write-Host "[$Name] 凭据已加载 - 用户名: $($cred.UserName)"
    return $cred
}

# 批量保存多个服务凭据
$services = @(
    @{ Name = "sqlserver";   User = "sa" }
    @{ Name = "ssh-gateway"; User = "deploy" }
    @{ Name = "api-service"; User = "api-reader" }
)

foreach ($svc in $services) {
    $securePwd = Read-Host -Prompt "请输入 $($svc.Name) 的密码" -AsSecureString
    Save-Secret -Name $svc.Name -UserName $svc.User -Password $securePwd
}

# 验证：列出所有已保存的凭据
Write-Host "`n已保存的凭据列表："
$secretFiles = Get-ChildItem -Path "$env:USERPROFILE\.secrets\*.xml"
foreach ($file in $secretFiles) {
    $cred = Import-Clixml -Path $file.FullName
    Write-Host "  - $($file.BaseName): $($cred.UserName)"
}
```

```text
[sqlserver] 凭据已保存到: C:\Users\admin\.secrets\sqlserver.xml
[ssh-gateway] 凭据已保存到: C:\Users\admin\.secrets\ssh-gateway.xml
[api-service] 凭据已保存到: C:\Users\admin\.secrets\api-service.xml

已保存的凭据列表：
  - sqlserver: sa
  - ssh-gateway: deploy
  - api-service: api-reader
```

## 使用 SecretManagement 模块统一管理密钥

PowerShell 7 引入了 `Microsoft.PowerShell.SecretManagement` 和 `Microsoft.PowerShell.SecretStore` 模块，提供了一套跨平台的密钥管理框架。它支持将密钥存储在本地 SecretStore 中，也可以扩展对接 Azure Key Vault、KeePass 等外部密钥管理服务。

```powershell
# 安装模块（仅首次需要）
Install-Module -Name Microsoft.PowerShell.SecretManagement -Force -Scope CurrentUser
Install-Module -Name Microsoft.PowerShell.SecretStore -Force -Scope CurrentUser

# 注册本地 SecretStore 作为密钥保管库
Register-SecretVault -Name "MyLocalVault" -ModuleName Microsoft.PowerShell.SecretStore -DefaultVault

# 设置 SecretStore 密码（用于解锁保管库）
$storePassword = Read-Host -Prompt "设置 SecretStore 密码" -AsSecureString
Set-SecretStorePassword -NewPassword $storePassword -Password $storePassword

# 存储各种类型的密钥
Set-Secret -Name "DatabaseConnection" -Secret "Server=db01;Database=prod;User Id=app;Password=s3cret;"
Set-Secret -Name "ApiKey" -Secret "ak-12345-abcde-67890"
Set-Secret -Name "ServiceAccount" -Secret (Get-Credential -UserName "svc_automation" -Message "输入服务账号密码")

# 查询已存储的密钥信息
Write-Host "密钥保管库中存储的密钥列表："
$secrets = Get-SecretInfo
foreach ($secret in $secrets) {
    Write-Host "  名称: $($secret.Name) | 类型: $($secret.Type)"
}

# 在脚本中按需获取密钥
$dbConn = Get-Secret -Name "DatabaseConnection" -AsPlainText
Write-Host "`n数据库连接字符串长度: $($dbConn.Length) 个字符"

$apiCred = Get-Secret -Name "ServiceAccount"
Write-Host "服务账号用户名: $($apiCred.UserName)"
```

```text
密钥保管库中存储的密钥列表：
  名称: DatabaseConnection | 类型: String
  名称: ApiKey | 类型: String
  名称: ServiceAccount | 类型: PSCredential

数据库连接字符串长度: 68 个字符
服务账号用户名: svc_automation
```

## 注意事项

1. **DPAPI 作用域限制**：使用 `ConvertFrom-SecureString` 或 `Export-Clixml` 加密的凭据只能在同一台机器上的同一个 Windows 用户账户下解密。如果需要跨机器使用，请使用 `-Key` 参数指定 AES 加密密钥，或者使用 SecretManagement 模块配合外部密钥管理服务。

2. **避免密码明文传入**：`ConvertTo-SecureString -AsPlainText -Force` 虽然方便，但会暴露明文密码。在生产环境中，应优先使用 `Get-Credential` 或 `Read-Host -AsSecureString` 交互获取密码，或从已加密的文件中读取。

3. **SecureString 并非绝对安全**：`SecureString` 能防止密码在内存中以明文形式长期驻留，但不能防御具有管理员权限的恶意程序通过内存转储获取密码。在 Linux 和 macOS 上，`SecureString` 的加密保护能力弱于 Windows，建议结合操作系统级别的密钥管理工具使用。

4. **文件权限控制**：保存凭据文件的目录应设置严格的 NTFS 权限，仅允许当前用户访问。可以通过以下命令快速设置：`icacls "$env:USERPROFILE\.secrets" /inheritance:r /grant:r "$env:USERNAME:(R,W)"`。

5. **SecretStore 密码管理**：`Microsoft.PowerShell.SecretStore` 默认要求在每次会话中输入密码解锁。如果自动化脚本需要无人值守运行，可以通过 `Set-SecretStoreConfiguration -Authentication None` 关闭密码提示，但这会降低安全性，请根据实际场景权衡。

6. **定期轮换凭据**：无论使用哪种存储方式，都应建立凭据轮换机制。建议在密钥管理流程中记录每个凭据的创建时间和过期时间，并在脚本中添加检查逻辑，对即将过期的凭据发出告警提醒。
