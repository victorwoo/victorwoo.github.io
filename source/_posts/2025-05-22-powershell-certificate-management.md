---
layout: post
date: 2025-05-22 08:00:00
title: "PowerShell 技能连载 - 加密与证书管理"
description: PowerTip of the Day - Encryption and Certificate Management in PowerShell
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
- encryption
- certificate
- tls
- security
---

_适用于 PowerShell 5.1 及以上版本（Windows）_

在信息安全日益重要的今天，加密和证书管理已成为运维人员的日常任务。无论是 HTTPS 网站的 TLS 证书续期、代码签名证书的管理、还是敏感数据的加密存储，PowerShell 都提供了完整的支持。Windows 证书存储（Certificate Store）通过 `Cert:` PSDrive 暴露给 PowerShell，使得证书的查询、导入、导出和过期监控都可以脚本化。

本文将讲解证书存储操作、TLS 证书管理、数据加密解密，以及证书过期监控的自动化方案。

## 证书存储操作

Windows 证书存储通过 `Cert:` 驱动器访问，结构类似文件系统：

```powershell
# 查看证书存储结构
Get-ChildItem Cert:\ | Select-Object Name, Location

# 列出当前用户的个人证书
Get-ChildItem Cert:\CurrentUser\My |
    Select-Object FriendlyName, Subject, Thumbprint,
        @{N='颁发者'; E={$_.Issuer -replace 'CN=',''}},
        @{N='过期日期'; E={$_.NotAfter.ToString('yyyy-MM-dd')}},
        @{N='剩余天数'; E={([int]($_.NotAfter - (Get-Date)).TotalDays)}} |
    Format-Table -AutoSize

# 列出本地计算机的证书
Get-ChildItem Cert:\LocalMachine\My |
    Select-Object Subject, Thumbprint,
        @{N='过期日期'; E={$_.NotAfter.ToString('yyyy-MM-dd')}} |
    Format-Table -AutoSize

# 按主题搜索证书
$cert = Get-ChildItem Cert:\CurrentUser\My |
    Where-Object { $_.Subject -match 'blog.vichamp.com' }
if ($cert) {
    Write-Host "找到证书：$($cert.Thumbprint)" -ForegroundColor Green
    Write-Host "主题：$($cert.Subject)"
    Write-Host "过期：$($cert.NotAfter)"
}
```

执行结果示例：

```
Name       Location
----       --------
CurrentUser  CurrentUser
LocalMachine LocalMachine

FriendlyName   Subject              Thumbprint                           颁发者             过期日期 剩余天数
------------   -------              ----------                           ------             -------- --------
blog.vichamp   CN=blog.vichamp.com  A1B2C3D4E5F6789012345678901234...   Let's Encrypt      2025-08-15     85
```

## 导入和导出证书

证书的导入导出是运维中最常见的操作之一：

```powershell
# 导入 PFX 证书（含私钥）到本地计算机
$pfxPath = "C:\Certs\blog.vichamp.com.pfx"
$password = Read-Host "输入 PFX 密码" -AsSecureString

Import-PfxCertificate -FilePath $pfxPath `
    -CertStoreLocation Cert:\LocalMachine\My `
    -Password $password

Write-Host "PFX 证书已导入到 LocalMachine\My" -ForegroundColor Green

# 导入 CER 证书（仅公钥）到受信任根证书
Import-Certificate -FilePath "C:\Certs\myCA.cer" `
    -CertStoreLocation Cert:\LocalMachine\Root

# 导出证书为 CER 格式（公钥）
$cert = Get-ChildItem Cert:\LocalMachine\My |
    Where-Object { $_.Subject -match 'blog.vichamp.com' }

Export-Certificate -Cert $cert -FilePath "C:\Certs\blog.vichamp.com.cer"
Write-Host "公钥已导出" -ForegroundColor Green

# 导出 PFX（含私钥，需要密码保护）
$exportPassword = Read-Host "设置导出密码" -AsSecureString
$cert | Export-PfxCertificate -FilePath "C:\Certs\backup.pfx" -Password $exportPassword
Write-Host "PFX 备份已创建" -ForegroundColor Green
```

执行结果示例：

```
PFX 证书已导入到 LocalMachine\My
公钥已导出
PFX 备份已创建
```

> **注意**：私钥导出仅在证书标记为可导出时才允许。导入 PFX 时使用 `-Exportable` 参数可以允许后续导出。

## 证书过期监控

证书过期是生产事故的常见原因。以下是一个自动化的证书过期监控脚本：

```powershell
function Get-CertificateExpiry {
    <#
    .SYNOPSIS
    检查证书过期情况
    #>
    param(
        [int]$WarningDays = 30,
        [int]$CriticalDays = 7,
        [string[]]$Stores = @('Cert:\LocalMachine\My', 'Cert:\CurrentUser\My')
    )

    $results = @()

    foreach ($store in $Stores) {
        $certs = Get-ChildItem $store -ErrorAction SilentlyContinue

        foreach ($cert in $certs) {
            $daysLeft = [math]::Floor(($cert.NotAfter - (Get-Date)).TotalDays)

            $status = if ($daysLeft -le 0) { 'EXPIRED' }
                      elseif ($daysLeft -le $CriticalDays) { 'CRITICAL' }
                      elseif ($daysLeft -le $WarningDays) { 'WARNING' }
                      else { 'OK' }

            $results += [PSCustomObject]@{
                Store      = $store -replace 'Cert:\\',''
                Subject    = $cert.Subject -replace '^CN=',''
                Issuer     = $cert.Issuer -replace '^CN=',''
                Thumbprint = $cert.Thumbprint
                NotAfter   = $cert.NotAfter.ToString('yyyy-MM-dd')
                DaysLeft   = $daysLeft
                Status     = $status
            }
        }
    }

    $results | Sort-Object DaysLeft |
        Format-Table Subject, Issuer, NotAfter, DaysLeft, Status -AutoSize

    # 汇总统计
    $expired = ($results | Where-Object Status -eq 'EXPIRED').Count
    $critical = ($results | Where-Object Status -eq 'CRITICAL').Count
    $warning = ($results | Where-Object Status -eq 'WARNING').Count
    $ok = ($results | Where-Object Status -eq 'OK').Count

    Write-Host "`n总计：$($results.Count) 个证书" -ForegroundColor Cyan
    Write-Host "  OK: $ok | WARNING: $warning | CRITICAL: $critical | EXPIRED: $expired" -ForegroundColor $(if ($expired -or $critical) { 'Red' } elseif ($warning) { 'Yellow' } else { 'Green' })

    return $results
}

# 检查所有证书，30 天内过期预警
Get-CertificateExpiry -WarningDays 30 -CriticalDays 7
```

执行结果示例：

```
Subject            Issuer          NotAfter   DaysLeft Status
-------            ------          --------   -------- ------
blog.vichamp.com   Let's Encrypt   2025-06-15       24 WARNING
api.internal.com   Contoso CA      2025-05-29        7 CRITICAL
legacy.app.com     Self-Signed     2025-05-20       -2 EXPIRED
intranet.corp.com  Contoso CA      2026-03-15      297 OK

总计：8 个证书
  OK: 5 | WARNING: 1 | CRITICAL: 1 | EXPIRED: 1
```

## 远程检查 TLS 证书

除了本地证书存储，还需要检查远程 HTTPS 站点的证书状态：

```powershell
function Test-TlsCertificate {
    <#
    .SYNOPSIS
    检查远程 HTTPS 站点的 TLS 证书
    #>
    param(
        [Parameter(Mandatory)]
        [string[]]$HostName,

        [int]$Port = 443,

        [int]$WarningDays = 30
    )

    $results = foreach ($host_name in $HostName) {
        try {
            $tcpClient = New-Object System.Net.Sockets.TcpClient($host_name, $Port)
            $sslStream = New-Object System.Net.Security.SslStream($tcpClient.GetStream(), $false, { $true })

            $sslStream.AuthenticateAsClient($host_name, $null, [System.Security.Authentication.SslProtocols]::Tls12, $false)

            $cert = $sslStream.RemoteCertificate
            $x509 = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2($cert)

            $daysLeft = [math]::Floor(($x509.NotAfter - (Get-Date)).TotalDays)

            [PSCustomObject]@{
                HostName    = $host_name
                Subject     = $x509.Subject -replace '^CN=',''
                Issuer      = $x509.Issuer -replace '^CN=',''
                NotBefore   = $x509.NotBefore.ToString('yyyy-MM-dd')
                NotAfter    = $x509.NotAfter.ToString('yyyy-MM-dd')
                DaysLeft    = $daysLeft
                Status      = if ($daysLeft -le 0) { 'EXPIRED' }
                              elseif ($daysLeft -le $WarningDays) { 'WARNING' }
                              else { 'OK' }
                TLSVersion  = $sslStream.SslProtocol
                KeyAlgorithm = $x509.SignatureAlgorithm.FriendlyName
            }

            $sslStream.Close()
            $tcpClient.Close()
        } catch {
            [PSCustomObject]@{
                HostName = $host_name
                Status   = "ERROR: $($_.Exception.Message)"
            }
        }
    }

    $results | Format-Table -AutoSize
}

# 检查多个站点的证书
$sites = @('blog.vichamp.com', 'github.com', 'google.com', 'expired.badssl.com')
Test-TlsCertificate -HostName $sites -WarningDays 30
```

执行结果示例：

```
HostName             Subject              Issuer             NotAfter   DaysLeft Status
--------             -------              ------             --------   -------- ------
blog.vichamp.com     blog.vichamp.com     Let's Encrypt      2025-08-15       85 OK
github.com           github.com           DigiCert           2025-03-15      -68 EXPIRED
google.com           *.google.com         GTS CA 1C3         2025-07-22       61 OK
expired.badssl.com   *.badssl.com         COMODO RSA         2015-09-30    -3509 EXPIRED
```

## 数据加密与解密

PowerShell 支持使用 Windows DPAPI 和 AES 进行数据加密：

```powershell
# 方法一：使用 DPAPI 加密（仅当前用户可解密）
$secret = "MyDatabasePassword123!"
$encrypted = $secret | ConvertTo-SecureString -AsPlainText -Force
$encryptedString = ConvertFrom-SecureString $encrypted
Write-Host "加密后：$($encryptedString.Substring(0, 40))..."

# 解密
$decryptedSecure = ConvertTo-SecureString $encryptedString
$cred = New-Object System.Management.Automation.PSCredential('temp', $decryptedSecure)
Write-Host "解密后：$($cred.GetNetworkCredential().Password)"

# 方法二：使用 AES 加密（跨机器可用）
function Protect-String {
    param([string]$PlainText, [string]$KeyPath)

    # 生成 AES 密钥
    $aes = [System.Security.Cryptography.Aes]::Create()
    $aes.KeySize = 256

    if (-not (Test-Path $KeyPath)) {
        $aes.GenerateKey()
        $aes.GenerateIV()
        $keyData = @{
            Key = [Convert]::ToBase64String($aes.Key)
            IV  = [Convert]::ToBase64String($aes.IV)
        }
        $keyData | ConvertTo-Json | Set-Content $KeyPath
    } else {
        $keyData = Get-Content $KeyPath | ConvertFrom-Json
        $aes.Key = [Convert]::FromBase64String($keyData.Key)
        $aes.IV = [Convert]::FromBase64String($keyData.IV)
    }

    $encryptor = $aes.CreateEncryptor()
    $bytes = [System.Text.Encoding]::UTF8.GetBytes($PlainText)
    $encrypted = $encryptor.TransformFinalBlock($bytes, 0, $bytes.Length)

    return [Convert]::ToBase64String($encrypted)
}

function Unprotect-String {
    param([string]$EncryptedText, [string]$KeyPath)

    $keyData = Get-Content $KeyPath | ConvertFrom-Json
    $aes = [System.Security.Cryptography.Aes]::Create()
    $aes.Key = [Convert]::FromBase64String($keyData.Key)
    $aes.IV = [Convert]::FromBase64String($keyData.IV)

    $decryptor = $aes.CreateDecryptor()
    $bytes = [Convert]::FromBase64String($EncryptedText)
    $decrypted = $decryptor.TransformFinalBlock($bytes, 0, $bytes.Length)

    return [System.Text.Encoding]::UTF8.GetString($decrypted)
}

# 使用 AES 加密
$keyPath = "C:\Config\aes-key.json"
$encrypted = Protect-String -PlainText "SuperSecretPassword" -KeyPath $keyPath
Write-Host "AES 加密：$encrypted"

$decrypted = Unprotect-String -EncryptedText $encrypted -KeyPath $keyPath
Write-Host "AES 解密：$decrypted"
```

执行结果示例：

```
加密后：01000000d08c9ddf0115d1118c7a00c0...
解密后：MyDatabasePassword123!
AES 加密：a2V5QmFzZTY0RW5jcnlwdGVkRGF0YQ==
AES 解密：SuperSecretPassword
```

## 注意事项

1. **DPAPI 限制**：DPAPI 加密的数据只能在同一用户上下文中解密，不适合跨机器场景。跨机器请使用 AES 加密
2. **私钥保护**：导出含私钥的 PFX 时务必使用强密码，不要将密码和 PFX 文件存储在同一位置
3. **证书自动续期**：Let's Encrypt 等免费 CA 支持自动续期，建议使用 win-acme 或 Posh-ACME 自动化续期
4. **TLS 协议版本**：生产环境应禁用 TLS 1.0/1.1，仅启用 TLS 1.2+。使用 `[SslProtocols]::Tls12` 指定
5. **密钥轮换**：AES 密钥应定期轮换，旧密钥安全销毁
6. **审计日志**：证书操作（导入、导出、删除）应记录审计日志，特别是涉及私钥的操作
