---
layout: post
date: 2025-07-21 08:00:00
title: "PowerShell 技能连载 - 加密与哈希"
description: PowerTip of the Day - Encryption and Hashing in PowerShell
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
- encryption
- hashing
- security
- cryptography
---

_适用于 PowerShell 5.1 及以上版本_

在运维脚本中，加密和哈希操作无处不在——验证文件完整性、保护敏感配置、安全传输数据、存储密码哈希。.NET 的 `System.Security.Cryptography` 命名空间提供了丰富的加密算法，PowerShell 可以直接调用这些类实现各种加密操作。理解哈希（不可逆）和加密（可逆）的区别，以及对称加密和非对称加密的适用场景，是编写安全脚本的基础。

本文将讲解 PowerShell 中的加密与哈希操作，以及实用的安全工具。

## 哈希计算

```powershell
# 计算字符串哈希
function Get-StringHash {
    param(
        [Parameter(Mandatory)][string]$Text,
        [ValidateSet("MD5", "SHA1", "SHA256", "SHA384", "SHA512")]
        [string]$Algorithm = "SHA256"
    )

    $bytes = [System.Text.Encoding]::UTF8.GetBytes($Text)
    $hashAlg = [System.Security.Cryptography.HashAlgorithm]::Create($Algorithm)
    $hashBytes = $hashAlg.ComputeHash($bytes)
    $hashHex = [BitConverter]::ToString($hashBytes) -replace '-', ''

    return $hashHex.ToLower()
}

$password = "MyP@ssw0rd"
Write-Host "原文：$password"
Write-Host "MD5：$(Get-StringHash $password MD5)"
Write-Host "SHA1：$(Get-StringHash $password SHA1)"
Write-Host "SHA256：$(Get-StringHash $password SHA256)"

# 计算文件哈希（验证完整性）
$fileHash = Get-FileHash "C:\Windows\notepad.exe" -Algorithm SHA256
Write-Host "`n文件哈希：" -ForegroundColor Cyan
Write-Host "  文件：$($fileHash.Path)"
Write-Host "  SHA256：$($fileHash.Hash)"

# 批量计算目录文件哈希
function Get-DirectoryHash {
    param([string]$Path = ".")

    Get-ChildItem $Path -File | ForEach-Object {
        $hash = (Get-FileHash $_.FullName -Algorithm SHA256).Hash
        [PSCustomObject]@{
            File   = $_.Name
            Size   = $_.Length
            SHA256 = $hash.Substring(0, 16) + "..."
        }
    } | Format-Table -AutoSize
}

Get-DirectoryHash -Path "C:\Scripts"

# HMAC 哈希（带密钥的哈希，用于消息认证）
function Get-HmacHash {
    param([string]$Message, [string]$Secret)

    $key = [System.Text.Encoding]::UTF8.GetBytes($Secret)
    $hmac = [System.Security.Cryptography.HMACSHA256]::new($key)
    $msgBytes = [System.Text.Encoding]::UTF8.GetBytes($Message)
    $hashBytes = $hmac.ComputeHash($msgBytes)
    return [BitConverter]::ToString($hashBytes) -replace '-', ''
}

$hmac = Get-HmacHash -Message "api call data" -Secret "my-secret-key"
Write-Host "HMAC-SHA256：$($hmac.Substring(0, 16))..."
```

执行结果示例：

```
原文：MyP@ssw0rd
MD5：a3bf2a57d727b47e9c8...
SHA1：482c811da5d5b4bc6d49...
SHA256：a765f9e2a8b7c6d5e4f3...

文件哈希：
  文件：C:\Windows\notepad.exe
  SHA256：A1B2C3D4E5F6...

File             Size SHA256
----             ---- ------
deploy.ps1      10240 a1b2c3d4e5f6...
config.json      2048 d4e5f6a7b8c9...
HMAC-SHA256：e5f6a7b8c9d0...
```

## 对称加密（AES）

```powershell
# AES 对称加密/解密
function Protect-AesString {
    param(
        [Parameter(Mandatory)][string]$PlainText,
        [Parameter(Mandatory)][string]$Key
    )

    # 从密钥生成 256 位 AES 密钥和 IV
    $keyBytes = [System.Security.Cryptography.SHA256]::Create().ComputeHash(
        [System.Text.Encoding]::UTF8.GetBytes($Key)
    )
    $aes = [System.Security.Cryptography.Aes]::Create()
    $aes.Key = $keyBytes
    $aes.GenerateIV()

    $encryptor = $aes.CreateEncryptor()
    $plainBytes = [System.Text.Encoding]::UTF8.GetBytes($PlainText)
    $encryptedBytes = $encryptor.TransformFinalBlock($plainBytes, 0, $plainBytes.Length)

    # IV + 密文合并，Base64 输出
    $result = New-Object byte[] ($aes.IV.Length + $encryptedBytes.Length)
    [System.Array]::Copy($aes.IV, $result, $aes.IV.Length)
    [System.Array]::Copy($encryptedBytes, 0, $result, $aes.IV.Length, $encryptedBytes.Length)

    return [Convert]::ToBase64String($result)
}

function Unprotect-AesString {
    param(
        [Parameter(Mandatory)][string]$EncryptedText,
        [Parameter(Mandatory)][string]$Key
    )

    $keyBytes = [System.Security.Cryptography.SHA256]::Create().ComputeHash(
        [System.Text.Encoding]::UTF8.GetBytes($Key)
    )
    $allBytes = [Convert]::FromBase64String($EncryptedText)

    $aes = [System.Security.Cryptography.Aes]::Create()
    $aes.Key = $keyBytes

    # 提取 IV（前 16 字节）
    $iv = New-Object byte[] $aes.BlockSize.DivRem(8)[0]
    [System.Array]::Copy($allBytes, $iv, $iv.Length)
    $aes.IV = $iv

    # 提取密文
    $cipherBytes = New-Object byte[] ($allBytes.Length - $iv.Length)
    [System.Array]::Copy($allBytes, $iv.Length, $cipherBytes, 0, $cipherBytes.Length)

    $decryptor = $aes.CreateDecryptor()
    $decryptedBytes = $decryptor.TransformFinalBlock($cipherBytes, 0, $cipherBytes.Length)

    return [System.Text.Encoding]::UTF8.GetString($decryptedBytes)
}

# 加密/解密示例
$secret = "数据库连接字符串：Server=prod-db;Password=P@ssw0rd"
$encryptionKey = "MyApp-Encryption-Key-2025"

$encrypted = Protect-AesString -PlainText $secret -Key $encryptionKey
Write-Host "加密后：$($encrypted.Substring(0, 30))..." -ForegroundColor Cyan

$decrypted = Unprotect-AesString -EncryptedText $encrypted -Key $encryptionKey
Write-Host "解密后：$decrypted" -ForegroundColor Green
```

执行结果示例：

```
加密后：a1b2c3d4e5f67890abcdef...
解密后：数据库连接字符串：Server=prod-db;Password=P@ssw0rd
```

## 文件加密

```powershell
# 文件加密/解密
function Protect-File {
    param(
        [Parameter(Mandatory)][string]$Path,
        [Parameter(Mandatory)][string]$Key
    )

    $keyBytes = [System.Security.Cryptography.SHA256]::Create().ComputeHash(
        [System.Text.Encoding]::UTF8.GetBytes($Key)
    )
    $aes = [System.Security.Cryptography.Aes]::Create()
    $aes.Key = $keyBytes
    $aes.GenerateIV()

    $plainBytes = [System.IO.File]::ReadAllBytes($Path)

    $encryptor = $aes.CreateEncryptor()
    $encryptedBytes = $encryptor.TransformFinalBlock($plainBytes, 0, $plainBytes.Length)

    $output = New-Object byte[] ($aes.IV.Length + $encryptedBytes.Length)
    [System.Array]::Copy($aes.IV, $output, $aes.IV.Length)
    [System.Array]::Copy($encryptedBytes, 0, $output, $aes.IV.Length, $encryptedBytes.Length)

    $encPath = $Path + ".enc"
    [System.IO.File]::WriteAllBytes($encPath, $output)
    Write-Host "已加密：$Path => $encPath" -ForegroundColor Green
}

function Unprotect-File {
    param(
        [Parameter(Mandatory)][string]$Path,
        [Parameter(Mandatory)][string]$Key,
        [string]$OutputPath
    )

    $keyBytes = [System.Security.Cryptography.SHA256]::Create().ComputeHash(
        [System.Text.Encoding]::UTF8.GetBytes($Key)
    )
    $allBytes = [System.IO.File]::ReadAllBytes($Path)

    $aes = [System.Security.Cryptography.Aes]::Create()
    $aes.Key = $keyBytes

    $iv = New-Object byte[] ($aes.BlockSize / 8)
    [System.Array]::Copy($allBytes, $iv, $iv.Length)
    $aes.IV = $iv

    $cipherBytes = New-Object byte[] ($allBytes.Length - $iv.Length)
    [System.Array]::Copy($allBytes, $iv.Length, $cipherBytes, 0, $cipherBytes.Length)

    $decryptor = $aes.CreateDecryptor()
    $decryptedBytes = $decryptor.TransformFinalBlock($cipherBytes, 0, $cipherBytes.Length)

    $outPath = if ($OutputPath) { $OutputPath } else { $Path -replace '\.enc$', '' }
    [System.IO.File]::WriteAllBytes($outPath, $decryptedBytes)
    Write-Host "已解密：$Path => $outPath" -ForegroundColor Green
}

# 加密配置文件
Protect-File -Path "C:\MyApp\appsettings.json" -Key "Production-Key-2025"
Unprotect-File -Path "C:\MyApp\appsettings.json.enc" -Key "Production-Key-2025"
```

执行结果示例：

```
已加密：C:\MyApp\appsettings.json => C:\MyApp\appsettings.json.enc
已解密：C:\MyApp\appsettings.json.enc => C:\MyApp\appsettings.json
```

## 密码安全工具

```powershell
# 安全密码哈希（用于存储密码）
function New-PasswordHash {
    param(
        [Parameter(Mandatory)][string]$Password,
        [int]$SaltSize = 16,
        [int]$Iterations = 100000
    )

    $salt = New-Object byte[] $SaltSize
    [System.Security.Cryptography.RandomNumberGenerator]::Create().GetBytes($salt)

    $pbkdf2 = New-Object System.Security.Cryptography.Rfc2898DeriveBytes(
        $Password, $salt, $Iterations, [System.Security.Cryptography.HashAlgorithmName]::SHA256
    )
    $hash = $pbkdf2.GetBytes(32)

    $result = "PBKDF2-SHA256:$Iterations:$([Convert]::ToBase64String($salt)):$([Convert]::ToBase64String($hash))"
    return $result
}

function Test-PasswordHash {
    param(
        [Parameter(Mandatory)][string]$Password,
        [Parameter(Mandatory)][string]$StoredHash
    )

    $parts = $StoredHash -split ':'
    $iterations = [int]$parts[1]
    $salt = [Convert]::FromBase64String($parts[2])
    $storedKey = [Convert]::FromBase64String($parts[3])

    $pbkdf2 = New-Object System.Security.Cryptography.Rfc2898DeriveBytes(
        $Password, $salt, $iterations, [System.Security.Cryptography.HashAlgorithmName]::SHA256
    )
    $testKey = $pbkdf2.GetBytes(32)

    # 常量时间比较防止时序攻击
    $diff = 0
    for ($i = 0; $i -lt $storedKey.Length; $i++) {
        $diff = $diff -bor ($storedKey[$i] -bxor $testKey[$i])
    }
    return ($diff -eq 0)
}

# 创建和验证密码哈希
$hash = New-PasswordHash -Password "MySecureP@ss"
Write-Host "密码哈希：$($hash.Substring(0, 40))..." -ForegroundColor Cyan

$valid = Test-PasswordHash -Password "MySecureP@ss" -StoredHash $hash
Write-Host "正确密码验证：$valid" -ForegroundColor Green

$invalid = Test-PasswordHash -Password "WrongPassword" -StoredHash $hash
Write-Host "错误密码验证：$invalid" -ForegroundColor Red
```

执行结果示例：

```
密码哈希：PBKDF2-SHA256:100000:a1b2c3d4e5f6g7h8...
正确密码验证：True
错误密码验证：False
```

## 注意事项

1. **哈希 vs 加密**：哈希是单向的（用于验证），加密是双向的（用于保护数据）。密码存储用哈希，配置保护用加密
2. **不要用 MD5**：MD5 和 SHA1 已被证明不安全，新项目应使用 SHA256 或更强的算法
3. **密钥管理**：加密的安全性取决于密钥的安全性。密钥不要硬编码在脚本中
4. **IV 唯一性**：AES 加密每次应使用随机 IV，否则相同明文会产生相同密文
5. **密码哈希**：存储密码使用 PBKDF2、bcrypt 或 Argon2，不要用简单的 SHA256
6. **DPAPI**：Windows 环境可以使用 DPAPI（`Protect-CmsMessage`）利用系统级密钥保护数据
