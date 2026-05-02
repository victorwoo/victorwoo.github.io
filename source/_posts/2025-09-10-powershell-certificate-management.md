---
layout: post
date: 2025-09-10 08:00:00
updated: 2025-09-10 08:00:00
title: "PowerShell 技能连载 - 证书管理"
description: PowerTip of the Day - Certificate Management in PowerShell
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
- certificate
- pki
- x509
---

_适用于 PowerShell 5.1 及以上版本（Windows）_

在 Windows 环境中，数字证书无处不在——HTTPS 网站加密、代码签名、文档签名、智能卡登录、VPN 认证等都离不开证书。日常运维中，我们经常需要查看证书有效期、导出证书、批量检查即将过期的证书，甚至通过脚本完成证书的申请和续签。

PowerShell 提供了强大的证书管理能力。通过 `Cert:` PSDrive，我们可以像操作文件系统一样浏览和管理 Windows 证书存储区。结合 .NET 的 `System.Security.Cryptography.X509Certificates` 命名空间，PowerShell 能够覆盖几乎所有的证书管理场景。本文将从查看、搜索、导出、续签检查等几个常见场景出发，介绍如何用 PowerShell 高效管理证书。

<!-- more -->

## 浏览和查询证书

Windows 证书存储区采用分层结构：按存储位置（CurrentUser / LocalMachine）和存储名称（My / Root / CA 等）组织。PowerShell 的 `Cert:` 驱动器让我们可以像浏览文件夹一样查看这些证书。

以下代码演示如何列出当前用户个人存储区的所有证书，并筛选出含有私钥的证书：

```powershell
# 列出当前用户个人存储区的证书
$certs = Get-ChildItem -Path Cert:\CurrentUser\My

Write-Host "当前用户共有 $($certs.Count) 张个人证书`n"

foreach ($cert in $certs) {
    $hasPrivateKey = $cert.HasPrivateKey
    $expires = $cert.NotAfter.ToString("yyyy-MM-dd")
    $issuer = $cert.Issuer

    Write-Host "主题: $($cert.Subject)"
    Write-Host "颁发者: $issuer"
    Write-Host "有效期至: $expires"
    Write-Host "含私钥: $hasPrivateKey"
    Write-Host "---"
}
```

```text
当前用户共有 3 张个人证书

主题: CN=Victor Woo, E=victor@example.com
颁发者: CN=Victor Woo
有效期至: 2026-03-15
含私钥: True
---
主题: CN=blog.vichamp.com
颁发者: CN=Let's Encrypt Authority X3
有效期至: 2025-12-01
含私钥: True
---
主题: CN=code-signing.vichamp.com
颁发者: CN=DigiCert SHA2 Assured ID Code Signing CA
有效期至: 2026-06-20
含私钥: False
---
```

通过 `Cert:` 驱动器可以直观地浏览整个证书存储区，也可以使用 `Get-ChildItem -Recurse` 递归遍历所有存储位置。

## 查找即将过期的证书

证书过期会导致服务中断，这是运维中最头疼的问题之一。手动检查每台机器的证书有效期既耗时又容易遗漏。用 PowerShell 可以快速扫描所有存储区，找出指定天数内即将过期的证书。

下面这段脚本会检查本地计算机所有存储区中 30 天内即将过期的证书，并输出详细信息：

```powershell
# 检查即将过期的证书
$warningDays = 30
$cutoffDate = (Get-Date).AddDays($warningDays)

# 扫描本地计算机的所有证书
$allCerts = Get-ChildItem -Path Cert:\LocalMachine -Recurse -CodeSigningCert

$expiringCerts = @()

foreach ($cert in $allCerts) {
    if ($cert.NotAfter -le $cutoffDate -and $cert.NotAfter -ge (Get-Date)) {
        $expiringCerts += [PSCustomObject]@{
            Subject    = $cert.Subject
            Issuer     = $cert.Issuer
            Thumbprint = $cert.Thumbprint
            Expires    = $cert.NotAfter.ToString("yyyy-MM-dd HH:mm:ss")
            DaysLeft   = ($cert.NotAfter - (Get-Date)).Days
            Store      = $cert.PSParentPath -replace ".*\\([^\\]+)$", '$1'
        }
    }
}

# 按剩余天数排序
$expiringCerts = $expiringCerts | Sort-Object -Property DaysLeft

if ($expiringCerts.Count -eq 0) {
    Write-Host "没有在 $warningDays 天内即将过期的证书。"
} else {
    Write-Host "发现 $($expiringCerts.Count) 张证书将在 $warningDays 天内过期：`n"
    $expiringCerts | Format-Table -AutoSize
}
```

```text
发现 2 张证书将在 30 天内过期：

Subject                    Issuer                            Thumbprint                         Expires             DaysLeft Store
-------                    ------                            ----------                         -------             -------- -----
CN=api.vichamp.com         CN=Let's Encrypt Authority X3     A1B2C3D4E5F6...                   2025-09-15 08:30:00        5 My
CN=legacy.vichamp.com      CN=Go Daddy Secure Certificate... F6E5D4C3B2A1...                   2025-10-05 12:00:00       25 My
```

将这段脚本集成到定时任务或监控系统中，就可以在证书过期前收到告警，提前完成续签。

## 导出证书和私钥

有时需要将证书从一台机器迁移到另一台机器，或者备份证书及其私钥。PowerShell 支持将证书导出为各种格式（PFX、CER、PEM 等）。导出含私钥的证书时需要设置密码保护。

下面代码演示如何将指定指纹的证书（含私钥）导出为 PFX 文件，以及如何仅导出公钥为 CER 文件：

```powershell
# 根据指纹查找目标证书
$thumbprint = "A1B2C3D4E5F6A1B2C3D4E5F6A1B2C3D4E5F6A1B2"
$cert = Get-ChildItem -Path Cert:\LocalMachine\My |
    Where-Object { $_.Thumbprint -eq $thumbprint }

if (-not $cert) {
    Write-Host "未找到指纹为 $thumbprint 的证书"
    exit
}

# 导出含私钥的 PFX 文件
$pfxPassword = Read-Host -AsSecureString -Prompt "请输入 PFX 导出密码"
$pfxPath = "C:\Backup\$($cert.Thumbprint).pfx"

$bytes = $cert.Export("PFX", $pfxPassword)
[System.IO.File]::WriteAllBytes($pfxPath, $bytes)
Write-Host "PFX 已导出: $pfxPath"

# 仅导出公钥 CER 文件
$cerPath = "C:\Backup\$($cert.Thumbprint).cer"
$cerBytes = $cert.Export("CERT")
[System.IO.File]::WriteAllBytes($cerPath, $cerBytes)
Write-Host "CER 已导出: $cerPath"
```

```text
PFX 已导出: C:\Backup\A1B2C3D4E5F6A1B2C3D4E5F6A1B2C3D4E5F6A1B2.pfx
CER 已导出: C:\Backup\A1B2C3D4E5F6A1B2C3D4E5F6A1B2C3D4E5F6A1B2.cer
```

PFX 文件包含私钥，务必妥善保管；CER 文件仅包含公钥，可以自由分发。

## 生成自签名证书用于开发测试

开发 HTTPS 服务或测试代码签名时，通常需要自签名证书。PowerShell 5.1 以上版本内置了 `New-SelfSignedCertificate` cmdlet，一条命令即可生成证书。

下面代码创建一张用于 HTTPS 开发的自签名证书，并将其导出以便在浏览器中信任：

```powershell
# 创建自签名 HTTPS 开发证书
$devCert = New-SelfSignedCertificate `
    -Subject "CN=localhost" `
    -FriendlyName "Dev HTTPS Certificate" `
    -NotAfter (Get-Date).AddYears(2) `
    -CertStoreLocation "Cert:\CurrentUser\My" `
    -KeyExportPolicy Exportable `
    -KeyUsage DigitalSignature, KeyEncipherment `
    -KeyLength 2048 `
    -HashAlgorithm SHA256 `
    -TextExtension @("2.5.29.37={text}1.3.6.1.5.5.7.3.1")

Write-Host "自签名证书已创建"
Write-Host "  指纹: $($devCert.Thumbprint)"
Write-Host "  主题: $($devCert.Subject)"
Write-Host "  有效期: $($devCert.NotBefore.ToString('yyyy-MM-dd')) 至 $($devCert.NotAfter.ToString('yyyy-MM-dd'))"

# 将公钥复制到受信任的根证书存储区（仅开发环境使用）
$rootStore = New-Object System.Security.Cryptography.X509Certificates.X509Store("Root", "CurrentUser")
$rootStore.Open("ReadWrite")
$rootStore.Add($devCert)
$rootStore.Close()

Write-Host "已添加到受信任的根证书存储区"
```

```text
自签名证书已创建
  指纹: B7C8D9E0F1A2B3C4D5E6F7A8B9C0D1E2F3A4B5C6
  主题: CN=localhost
  有效期: 2025-09-10 至 2027-09-10
已添加到受信任的根证书存储区
```

注意：将自签名证书添加到受信任根存储区仅适用于开发环境，生产环境应使用受信任 CA 签发的证书。

## 批量统计证书存储区信息

在大规模环境中，管理员可能需要统计各证书存储区的使用情况，以便进行容量规划和清理。以下脚本遍历本地计算机所有存储区并生成汇总报告：

```powershell
# 统计各证书存储区的证书数量和过期情况
$storeNames = @("My", "Root", "CA", "Trust", "TrustedPeople", "TrustedPublisher")
$location = "LocalMachine"
$report = @()

foreach ($storeName in $storeNames) {
    $storePath = "Cert:\$location\$storeName"
    $certs = Get-ChildItem -Path $storePath -ErrorAction SilentlyContinue

    $totalCount = ($certs | Measure-Object).Count
    $expiredCount = ($certs | Where-Object { $_.NotAfter -lt (Get-Date) } | Measure-Object).Count
    $expiringCount = ($certs | Where-Object {
        $_.NotAfter -ge (Get-Date) -and $_.NotAfter -lt (Get-Date).AddDays(90)
    } | Measure-Object).Count

    $report += [PSCustomObject]@{
        Store          = $storeName
        Location       = $location
        TotalCerts     = $totalCount
        Expired        = $expiredCount
        ExpiringSoon   = $expiringCount
        ValidRemaining = $totalCount - $expiredCount - $expiringCount
    }
}

Write-Host "`n证书存储区汇总报告:`n"
$report | Format-Table -AutoSize
```

```text
证书存储区汇总报告:

Store           Location    TotalCerts Expired ExpiringSoon ValidRemaining
-----           --------    ---------- ------- ------------ --------------
My              LocalMachine         5       1            2              2
Root            LocalMachine       120       0            0            120
CA              LocalMachine        85       2            1             82
Trust           LocalMachine         3       0            0              3
TrustedPeople   LocalMachine         1       0            0              1
TrustedPublisher LocalMachine        8       0            1              7
```

通过这种汇总视图，管理员可以快速定位需要关注的存储区，例如上例中 My 存储区有 1 张已过期和 2 张即将过期的证书，需要优先处理。

## 注意事项

1. **权限要求**：访问 `LocalMachine` 证书存储区需要管理员权限。普通用户只能操作 `CurrentUser` 存储区。在脚本开头加上 `#Requires -RunAsAdministrator` 可以避免权限不足导致的运行失败。

2. **私钥安全**：导出 PFX 文件时务必使用强密码保护，并妥善保存密码。私钥一旦泄露，攻击者可以冒充证书持有者进行中间人攻击或伪造签名。

3. **Cert: 驱动器仅限 Windows**：`Cert:` PSDrive 是 Windows 特有的功能，PowerShell 7 在 Linux/macOS 上不可用。跨平台场景下需要使用 .NET 的 `X509Certificate2` 类直接操作。

4. **证书指纹唯一性**：每张证书的指纹（Thumbprint）是 SHA-1 哈希值，全局唯一。在脚本中引用证书时应优先使用指纹而非主题名，因为同一主题名可能存在多张证书。

5. **自签名证书仅用于开发**：自签名证书不受公共 CA 信任，浏览器和操作系统会发出安全警告。生产环境应使用 Let's Encrypt、DigiCert 等受信任 CA 签发的证书。

6. **定期巡检**：建议将证书过期检查脚本配置为 Windows 计划任务或 CI/CD 流水线，每周自动执行一次。结合邮件或即时通讯告警，确保在证书过期前有充足的处理时间。
