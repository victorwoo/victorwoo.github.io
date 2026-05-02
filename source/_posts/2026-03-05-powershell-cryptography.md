---
layout: post
date: 2026-03-05 08:00:00
updated: 2026-03-05 08:00:00
title: "PowerShell 技能连载 - 加密与数据保护"
description: PowerTip of the Day - Cryptography and Data Protection in PowerShell
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
- cryptography
- encryption
- security
- data-protection
---

_适用于 PowerShell 5.1 及以上版本_

在现代运维和自动化场景中，敏感数据几乎无处不在——数据库连接字符串、API 密钥、用户个人信息、财务记录等。如果这些数据以明文形式存储或传输，一旦系统被入侵或日志泄露，后果将不堪设想。加密（Encryption）是保护数据机密性的最后一道防线。

PowerShell 依托 .NET Framework / .NET 的 `System.Security.Cryptography` 命名空间，提供了从对称加密、非对称加密到哈希校验、数字签名的完整加密工具链。无论是在脚本中保护凭据、验证文件完整性，还是对发布脚本进行代码签名，这些能力都是编写安全自动化脚本的基础。

本文将通过三个实战场景，分别演示如何使用 AES 对称加密保护文件和字符串、利用哈希算法验证数据完整性，以及通过数字证书实现代码签名与验证。

## 对称加密与文件保护

对称加密使用同一把密钥进行加密和解密，适合对大量数据进行快速加解密。AES（Advanced Encryption Standard）是目前最广泛使用的对称加密算法，密钥长度支持 128/192/256 位。以下脚本封装了 AES 加密和解密的核心逻辑，并提供了文件级别的加密保护功能。

```powershell
# AES 对称加密工具函数
function New-AesKey {
    param([int]$KeySize = 256)
    $aes = [System.Security.Cryptography.Aes]::Create()
    $aes.KeySize = $KeySize
    $aes.GenerateKey()
    $aes.GenerateIV()
    return @{
        Key = $aes.Key
        IV  = $aes.IV
    }
}

function Protect-StringWithAes {
    param(
        [Parameter(Mandatory)][string]$PlainText,
        [Parameter(Mandatory)][byte[]]$Key,
        [Parameter(Mandatory)][byte[]]$IV
    )
    $aes = [System.Security.Cryptography.Aes]::Create()
    $aes.Key = $Key
    $aes.IV = $IV
    $encryptor = $aes.CreateEncryptor()
    $plainBytes = [System.Text.Encoding]::UTF8.GetBytes($PlainText)
    $encryptedBytes = $encryptor.TransformFinalBlock($plainBytes, 0, $plainBytes.Length)
    return [Convert]::ToBase64String($encryptedBytes)
}

function Unprotect-StringWithAes {
    param(
        [Parameter(Mandatory)][string]$CipherText,
        [Parameter(Mandatory)][byte[]]$Key,
        [Parameter(Mandatory)][byte[]]$IV
    )
    $aes = [System.Security.Cryptography.Aes]::Create()
    $aes.Key = $Key
    $aes.IV = $IV
    $decryptor = $aes.CreateDecryptor()
    $cipherBytes = [Convert]::FromBase64String($CipherText)
    $decryptedBytes = $decryptor.TransformFinalBlock($cipherBytes, 0, $cipherBytes.Length)
    return [System.Text.Encoding]::UTF8.GetString($decryptedBytes)
}

# 生成密钥对
$keyInfo = New-AesKey -KeySize 256
Write-Host "AES 密钥长度: $($keyInfo.Key.Length * 8) 位"
Write-Host "初始化向量长度: $($keyInfo.IV.Length * 8) 位"

# 加密敏感字符串
$secret = "Server=db.prod.example.com;User=admin;Password=S3cretP@ss!"
$encrypted = Protect-StringWithAes -PlainText $secret -Key $keyInfo.Key -IV $keyInfo.IV
Write-Host "`n加密结果: $encrypted"

# 解密还原
$decrypted = Unprotect-StringWithAes -CipherText $encrypted -Key $keyInfo.Key -IV $keyInfo.IV
Write-Host "解密结果: $decrypted"

# 将密钥安全存储到文件（仅当前用户可访问）
$keyPath = "$env:USERPROFILE\.secrets\aes.key"
$ivPath = "$env:USERPROFILE\.secrets\aes.iv"
New-Item -ItemType Directory -Path (Split-Path $keyPath) -Force | Out-Null
[System.IO.File]::WriteAllBytes($keyPath, $keyInfo.Key)
[System.IO.File]::WriteAllBytes($ivPath, $keyInfo.IV)
Write-Host "`n密钥已保存至 $keyPath"
```

执行结果示例：

```
AES 密钥长度: 256 位
初始化向量长度: 128 位

加密结果: q8Jx3LmN9vT2kR5wY8aBcDeFgHiJkLmNoPqRsTuVwXyZ0123456789abcdefg==

解密结果: Server=db.prod.example.com;User=admin;Password=S3cretP@ss!

密钥已保存至 C:\Users\admin\.secrets\aes.key
```

## 哈希与完整性验证

哈希算法将任意长度的数据映射为固定长度的摘要值，具有单向性和抗碰撞性，广泛用于数据完整性校验和消息认证。SHA-256 和 SHA-512 是目前推荐的哈希算法。HMAC（Hash-based Message Authentication Code）则在此基础上加入密钥，既能验证完整性又能验证消息来源。

```powershell
# 文件哈希计算与完整性校验
function Get-FileHashEx {
    param(
        [Parameter(Mandatory)][string]$Path,
        [ValidateSet('SHA256', 'SHA384', 'SHA512', 'MD5')]
        [string]$Algorithm = 'SHA256'
    )
    if (-not (Test-Path $Path)) {
        throw "文件不存在: $Path"
    }
    $hashAlg = [System.Security.Cryptography.HashAlgorithm]::Create($Algorithm)
    $fileStream = [System.IO.File]::OpenRead((Resolve-Path $Path).Path)
    try {
        $hashBytes = $hashAlg.ComputeHash($fileStream)
        $hashHex = [BitConverter]::ToString($hashBytes) -replace '-', ''
        return @{
            Path      = $Path
            Algorithm = $Algorithm
            Hash      = $hashHex
            Size      = $fileStream.Length
        }
    }
    finally {
        $fileStream.Dispose()
    }
}

# 计算文件哈希
$result = Get-FileHashEx -Path $PSCommandPath -Algorithm SHA256
Write-Host "文件: $($result.Path)"
Write-Host "算法: $($result.Algorithm)"
Write-Host "哈希: $($result.Hash)"
Write-Host "大小: $($result.Size) 字节"

# HMAC 消息认证码
function Get-HmacHash {
    param(
        [Parameter(Mandatory)][string]$Message,
        [Parameter(Mandatory)][string]$Secret
    )
    $keyBytes = [System.Text.Encoding]::UTF8.GetBytes($Secret)
    $messageBytes = [System.Text.Encoding]::UTF8.GetBytes($Message)
    $hmac = New-Object System.Security.Cryptography.HMACSHA256 -ArgumentList @(,$keyBytes)
    $hashBytes = $hmac.ComputeHash($messageBytes)
    return [BitConverter]::ToString($hashBytes) -replace '-', ''
}

# 模拟 API 签名验证场景
$apiPayload = '{"action":"transfer","amount":5000,"to":"account-12345"}'
$apiSecret = "my-api-secret-key-2026"
$signature = Get-HmacHash -Message $apiPayload -Secret $apiSecret
Write-Host "`nAPI 载荷: $apiPayload"
Write-Host "HMAC 签名: $signature"

# 接收方验证签名
$receivedSig = Get-HmacHash -Message $apiPayload -Secret $apiSecret
$isValid = ($signature -eq $receivedSig)
Write-Host "签名验证: $(if ($isValid) { '通过' } else { '失败' })"

# 批量文件完整性基线
$baselineFile = "$env:TEMP\hash-baseline.csv"
$monitorPath = $PWD.Path
$files = Get-ChildItem -Path $monitorPath -Filter "*.ps1" -File
$baseline = foreach ($f in $files) {
    $h = Get-FileHashEx -Path $f.FullName -Algorithm SHA256
    [PSCustomObject]@{
        File      = $f.Name
        SHA256    = $h.Hash
        Timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    }
}
$baseline | Export-Csv -Path $baselineFile -NoTypeInformation -Encoding UTF8
Write-Host "`n已生成 $($baseline.Count) 个文件的完整性基线: $baselineFile"
```

执行结果示例：

```
文件: C:\Scripts\audit.ps1
算法: SHA256
哈希: A1B2C3D4E5F6789012345678901234567890ABCDEF1234567890ABCDEF123456
大小: 4096 字节

API 载荷: {"action":"transfer","amount":5000,"to":"account-12345"}
HMAC 签名: 7F8E9D0C1B2A3948567E6F5D4C3B2A10987654321F0E1D2C3B4A59687012345
签名验证: 通过

已生成 12 个文件的完整性基线: C:\Users\admin\AppData\Local\Temp\hash-baseline.csv
```

## 数字签名与证书操作

数字签名结合了非对称加密和哈希算法，不仅能验证数据的完整性，还能确认数据的来源身份。在 PowerShell 中，代码签名是脚本安全策略的核心环节——只有受信任的发布者签名的脚本才能在受限执行策略下运行。此外，证书操作还广泛用于 TLS/SSL 通信和文档签名。

```powershell
# 查看本机代码签名证书
$codeCerts = Get-ChildItem -Path Cert:\CurrentUser\My -CodeSigningCert
if ($codeCerts) {
    foreach ($cert in $codeCerts) {
        Write-Host "证书主题: $($cert.Subject)"
        Write-Host "指纹: $($cert.Thumbprint)"
        Write-Host "有效期: $($cert.NotBefore) ~ $($cert.NotAfter)"
        Write-Host "颁发者: $($cert.Issuer)"
        Write-Host "---"
    }
}
else {
    Write-Host "未找到代码签名证书，创建自签名证书用于测试..."
    $testCert = New-SelfSignedCertificate `
        -Type CodeSigningCert `
        -Subject "CN=PowerShell Test Signing" `
        -CertStoreLocation "Cert:\CurrentUser\My" `
        -NotAfter (Get-Date).AddYears(1)
    Write-Host "已创建测试证书: $($testCert.Subject)"
    Write-Host "指纹: $($testCert.Thumbprint)"
}

# 对脚本进行数字签名
function Set-ScriptSignature {
    param(
        [Parameter(Mandatory)][string]$ScriptPath,
        [Parameter(Mandatory)][string]$CertThumbprint
    )
    $cert = Get-Item -Path "Cert:\CurrentUser\My\$CertThumbprint"
    if (-not $cert) {
        throw "未找到指纹为 $CertThumbprint 的证书"
    }
    $status = Get-AuthenticodeSignature -FilePath $ScriptPath
    if ($status.Status -eq 'Valid') {
        Write-Host "脚本已签名且签名有效: $ScriptPath"
        return
    }
    Set-AuthenticodeSignature -FilePath $ScriptPath -Certificate $cert | Out-Null
    $newStatus = Get-AuthenticodeSignature -FilePath $ScriptPath
    Write-Host "签名状态: $($newStatus.Status)"
    Write-Host "签名者: $($newStatus.SignerCertificate.Subject)"
}

# 证书链验证
function Test-CertificateChain {
    param([Parameter(Mandatory)][string]$CertThumbprint)
    $cert = Get-Item -Path "Cert:\CurrentUser\My\$CertThumbprint"
    if (-not $cert) {
        throw "未找到证书: $CertThumbprint"
    }
    $chain = New-Object System.Security.Cryptography.X509Certificates.X509Chain
    $chain.ChainPolicy.RevocationMode = [System.Security.Cryptography.X509Certificates.X509RevocationMode]::Online
    $chain.ChainPolicy.RevocationFlag = [System.Security.Cryptography.X509Certificates.X509RevocationFlag]::ExcludeRoot
    $isValid = $chain.Build($cert)
    Write-Host "证书: $($cert.Subject)"
    Write-Host "链验证: $(if ($isValid) { '通过' } else { '失败' })"
    if (-not $isValid) {
        foreach ($element in $chain.ChainElements) {
            Write-Host "  链节点: $($element.Certificate.Subject)"
        }
        foreach ($status in $chain.ChainStatus) {
            Write-Host "  状态: $($status.StatusInformation)"
        }
    }
    return $isValid
}

# 导出证书公钥（用于分发）
$pubCertPath = "$env:TEMP\PowerShellSigning.cer"
if ($testCert) {
    Export-Certificate -Cert $testCert -FilePath $pubCertPath | Out-Null
    Write-Host "`n公钥已导出至: $pubCertPath"
    Write-Host "文件大小: $((Get-Item $pubCertPath).Length) 字节"
}
```

执行结果示例：

```
未找到代码签名证书，创建自签名证书用于测试...
已创建测试证书: CN=PowerShell Test Signing
指纹: A1B2C3D4E5F6789012345678901234567890ABCD

签名状态: Valid
签名者: CN=PowerShell Test Signing

证书: CN=PowerShell Test Signing
链验证: 通过

公钥已导出至: C:\Users\admin\AppData\Local\Temp\PowerShellSigning.cer
文件大小: 814 字节
```

## 注意事项

1. **密钥管理是安全的基石**：再强的加密算法，如果密钥管理不当（如硬编码在脚本中、存储在无权限控制的文件中），整个安全体系形同虚设。生产环境建议使用 Windows DPAPI（`ConvertTo-SecureString`）、Azure Key Vault 或 HashiCorp Vault 等专业密钥管理方案。

2. **优先使用 AES 和 SHA-256 及以上算法**：DES、3DES、MD5、SHA-1 等算法已被证实存在安全弱点，新项目应一律避免使用。AES-256 是对称加密的首选，SHA-256/SHA-512 是哈希的首选。

3. **自签名证书仅用于测试**：生产环境应使用来自受信任 CA（如企业 AD CS、Let's Encrypt、DigiCert 等）颁发的证书。自签名证书无法被其他系统自动信任，且无法提供真正的身份验证保障。

4. **加密数据时要同时保护 IV**：AES 加密中 IV（初始化向量）不需要保密，但必须不可预测且每次加密都不同。如果重复使用相同的 Key 和 IV 加密不同数据，会大幅降低安全性。

5. **HMAC 密钥长度应与哈希输出长度匹配**：HMAC-SHA256 的密钥至少应为 32 字节，HMAC-SHA512 的密钥至少应为 64 字节。过短的密钥会削弱消息认证的安全性。

6. **注意 .NET 版本差异**：部分加密 API 在 .NET Framework 和 .NET（Core）之间行为略有不同。例如 `Aes.Create()` 在两个运行时都可用，但某些过时的算法类（如 `RijndaelManaged`）在 .NET 6+ 中可能已标记为过时。建议始终使用 `Aes`、`SHA256` 等抽象工厂方法创建加密对象。
