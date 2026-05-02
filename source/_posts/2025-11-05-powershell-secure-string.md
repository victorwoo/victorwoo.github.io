---
layout: post
date: 2025-11-05 08:00:00
updated: 2025-11-05 08:00:00
title: "PowerShell 技能连载 - 安全字符串处理"
description: PowerTip of the Day - Secure String Handling in PowerShell
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
- security
---

_适用于 PowerShell 5.1 及以上版本（Windows）_

在自动化脚本中处理密码、API 密钥、连接字符串等敏感信息时，直接将明文写入脚本或配置文件是非常危险的做法。一旦代码仓库泄露或日志被不当收集，这些凭据就会暴露无遗。PowerShell 提供了 `SecureString` 类型，它使用 Windows 数据保护 API（DPAPI）对内存中的字符串进行加密，使得敏感数据不会以明文形式驻留在进程内存中。

虽然 `SecureString` 并非银弹——在 .NET Core 跨平台场景下其保护能力有所减弱——但在 Windows 环境中，结合 DPAPI 的用户/机器级密钥，它仍然是脚本开发中最实用的凭据保护手段之一。本文将系统介绍 `SecureString` 的创建、转换、持久化以及凭据对象的完整使用流程，帮助你在自动化场景中更安全地管理敏感信息。

<!-- more -->

## 创建 SecureString

`SecureString` 有多种创建方式，应根据使用场景选择合适的方法。对于交互式脚本，推荐使用 `Read-Host` 弹出提示让用户输入；对于自动化场景，可以从已加密的文件中还原。

下面的示例展示了三种常见的创建方式：

```powershell
# 方式一：交互式输入（推荐，最安全）
$securePwd = Read-Host -Prompt "请输入密码" -AsSecureString

# 方式二：从明文转换（仅用于测试或临时场景）
$plainText = "MySecretPass123!"
$securePwd = $plainText | ConvertTo-SecureString -AsPlainText -Force

# 方式三：从已加密的字符串还原（适合自动化）
$encryptedString = Get-Content -Path "C:\Vault\pwd.enc.txt" -Raw
$securePwd = $encryptedString | ConvertTo-SecureString
```

执行结果示例：

```text
请输入密码: ************

（使用 -AsSecureString 时，输入内容以星号显示，不会回显明文）
```

注意方式二使用了 `-AsPlainText -Force` 参数，它会将明文字符串直接转换为 `SecureString`。由于明文在转换前会短暂出现在内存中，这种方式仅适合开发测试，不建议在生产环境中使用。

## 持久化加密字符串

在自动化场景中，我们需要将密码保存到文件以便脚本无人值守运行。`ConvertFrom-SecureString` 可以将 `SecureString` 导出为加密后的十六进制字符串。默认情况下使用当前用户的 DPAPI 密钥加密，这意味着只有同一个 Windows 用户账户才能解密。

```powershell
# 将密码安全地保存到文件
$cred = Get-Credential -Message "输入需要持久化的凭据"
$cred.Password | ConvertFrom-SecureString | Set-Content -Path "C:\Vault\encrypted_pwd.txt"

Write-Host "密码已加密保存到 C:\Vault\encrypted_pwd.txt"
```

执行结果示例：

```text
cmdlet Get-Credential at command pipeline position 1
Supply values for the following parameters:
Message: 输入需要持久化的凭据

Windows PowerShell credential request.
输入需要持久化的凭据
User: admin
Password for user admin: ************
密码已加密保存到 C:\Vault\encrypted_pwd.txt
```

保存后的文件内容是一串十六进制字符，例如：

```text
01000000d08c9ddf0115d1118c7a00c04fc297eb01000000...
```

这段密文绑定到当前 Windows 用户的 DPAPI 密钥，其他用户即使拿到文件也无法解密。

## 使用自定义密钥跨机器复用

默认的 DPAPI 加密方式仅限当前用户解密，如果需要在不同机器或不同用户之间共享加密凭据，可以使用自定义密钥（AES-256）进行加密。密钥本身需要通过安全的渠道分发（如密钥管理系统或环境变量），而不是硬编码在脚本中。

```powershell
# 生成 32 字节（256 位）的随机密钥
$key = New-Object byte[] 32
$rng = [System.Security.Cryptography.RandomNumberGenerator]::Create()
$rng.GetBytes($key)

# 使用自定义密钥加密并保存
$plainText = "SuperSecretAPIKey2025!"
$securePwd = $plainText | ConvertTo-SecureString -AsPlainText -Force
$encrypted = $securePwd | ConvertFrom-SecureString -Key $key
$encrypted | Set-Content -Path "C:\Vault\api_key.enc.txt"

# 将密钥安全保存（实际场景中应使用密钥管理服务）
$key | Set-Content -Path "C:\Vault\aes_key.bin" -Encoding Byte

Write-Host "已使用 AES-256 密钥加密并保存"
```

执行结果示例：

```text
已使用 AES-256 密钥加密并保存
```

在目标机器上，只需要加载相同的密钥文件即可还原密码：

```powershell
# 在另一台机器上还原
$key = Get-Content -Path "C:\Vault\aes_key.bin" -Encoding Byte -ReadCount 0
$encrypted = Get-Content -Path "C:\Vault\api_key.enc.txt" -Raw
$securePwd = $encrypted | ConvertTo-SecureString -Key $key

# 还原为明文（仅用于需要明文的 API 调用场景）
$BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($securePwd)
$plainText = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)

Write-Host "还原后的 API 密钥: $($plainText.Substring(0,8))..."
```

执行结果示例：

```text
还原后的 API 密钥: SuperSec...
```

## 构建 PSCredential 对象

在实际工作中，我们很少单独使用 `SecureString`，更多时候需要将它封装为 `PSCredential` 对象。`PSCredential` 是 PowerShell 中标准的凭据类型，几乎所有需要身份验证的 cmdlet（如 `Invoke-Command`、`Enter-PSSession`、`New-SmbMapping`）都接受此类型作为 `-Credential` 参数。

```powershell
# 从持久化的加密文件构建凭据对象
$username = "DOMAIN\ServiceAccount"
$encryptedPwd = Get-Content -Path "C:\Vault\encrypted_pwd.txt" -Raw
$securePwd = $encryptedPwd | ConvertTo-SecureString

$credential = New-Object System.Management.Automation.PSCredential($username, $securePwd)

# 展示凭据信息
Write-Host "用户名: $($credential.UserName)"
Write-Host "密码长度: $($credential.GetNetworkCredential().Password.Length) 个字符"
Write-Host "是否已加密: $($credential.Password.IsReadOnly())"
```

执行结果示例：

```text
用户名: DOMAIN\ServiceAccount
密码长度: 17 个字符
是否已加密: True
```

构建好 `PSCredential` 对象后，就可以直接传递给需要身份验证的命令：

```powershell
# 使用凭据远程执行命令
$session = New-PSSession -ComputerName "SRV01" -Credential $credential
$result = Invoke-Command -Session $session -ScriptBlock {
    Get-Process | Sort-Object -Property WorkingSet64 -Descending | Select-Object -First 5
}
Remove-PSSession -Session $session

# 输出远程进程信息
foreach ($proc in $result) {
    Write-Host "$($proc.Name) - $([math]::Round($proc.WorkingSet64 / 1MB, 2)) MB"
}
```

执行结果示例：

```text
sqlservr - 2456.32 MB
w3wp - 856.71 MB
Microsoft.Exchange - 412.48 MB
MsMpEng - 198.15 MB
System - 45.89 MB
```

## 批量管理多个凭据

在管理多台服务器或多个服务时，往往需要维护多组凭据。可以将凭据信息存储在结构化的配置文件中，通过循环批量加载使用。

```powershell
# 定义服务凭据清单
$services = @(
    @{ Name = "DatabaseServer"; User = "sa"; EncryptedFile = "C:\Vault\db_pwd.txt" }
    @{ Name = "FileShare"; User = "fileadmin"; EncryptedFile = "C:\Vault\fs_pwd.txt" }
    @{ Name = "BackupService"; User = "backup"; EncryptedFile = "C:\Vault\bk_pwd.txt" }
)

# 批量构建凭据对象
$credentials = @{}
foreach ($svc in $services) {
    $encryptedPwd = Get-Content -Path $svc.EncryptedFile -Raw
    if ($encryptedPwd) {
        $securePwd = $encryptedPwd | ConvertTo-SecureString
        $cred = New-Object System.Management.Automation.PSCredential($svc.User, $securePwd)
        $credentials[$svc.Name] = $cred
        Write-Host "[OK] 已加载凭据: $($svc.Name) ($($svc.User))"
    }
    else {
        Write-Host "[WARN] 凭据文件为空: $($svc.EncryptedFile)"
    }
}

Write-Host "`n共加载 $($credentials.Count) 组凭据"
```

执行结果示例：

```text
[OK] 已加载凭据: DatabaseServer (sa)
[OK] 已加载凭据: FileShare (fileadmin)
[OK] 已加载凭据: BackupService (backup)

共加载 3 组凭据
```

通过哈希表存储凭据对象，在后续脚本中可以按服务名称快速查找并使用对应的凭据，既清晰又安全。

## 注意事项

- **DPAPI 绑定用户和机器**：默认的 `ConvertFrom-SecureString` 使用 DPAPI 加密，密文与当前 Windows 用户账户绑定。如果切换用户或在其他机器上运行，将无法解密。跨机器场景请使用自定义密钥模式。
- **避免在代码中硬编码明文**：`ConvertTo-SecureString -AsPlainText -Force` 虽然方便，但明文会在脚本文件和进程内存中暴露。生产环境应使用 `Get-Credential` 或从加密文件加载。
- **自定义密钥的安全分发**：使用 `-Key` 参数时，密钥文件本身需要妥善保管。建议通过环境变量、Azure Key Vault、HashiCorp Vault 等专业密钥管理服务分发，而非将密钥文件提交到代码仓库。
- **及时释放 BSTR 指针**：使用 `[Marshal]::SecureStringToBSTR()` 还原明文后，应调用 `[Marshal]::ZeroFreeBSTR()` 释放内存，避免明文在内存中残留时间过长。
- **跨平台限制**：在 PowerShell 7 的 Linux/macOS 上，`SecureString` 的加密机制不同于 Windows DPAPI，保护效果有限。如果在非 Windows 平台运行，建议使用平台原生的密钥管理工具。
- **日志脱敏**：确保脚本中的 `Write-Host`、`Write-Verbose` 等输出语句不会打印 `SecureString` 的内容。`PSCredential` 对象的 `.Password` 属性在字符串上下文中会显示为 `System.Security.SecureString`，不会泄露明文，但仍需避免调用 `.GetNetworkCredential().Password` 后输出结果。
