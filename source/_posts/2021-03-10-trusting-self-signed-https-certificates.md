---
layout: post
date: 2021-03-10 00:00:00
title: "PowerShell 技能连载 - 信任自签名的 HTTPS 证书"
description: PowerTip of the Day - Trusting Self-Signed HTTPS Certificates
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
如果您需要访问使用自签名测试证书或已过期或不可信的证书的 HTTPS 网站，PowerShell 将拒绝连接。在大多数情况下，这是正确的选择，但有时您知道目标服务器是安全的。

这是一段通过重写证书策略来信任所有 HTTPS 证书的 PowerShell 代码。新的证书策略始终返回 `$true` 并完全信任任何证书：

```powershell
class TrustAll : System.Net.ICertificatePolicy
{
  [bool]CheckValidationResult([System.Net.ServicePoint]$sp, [System.Security.Cryptography.X509Certificates.X509Certificate]$cert, [System.Net.WebRequest]$request, [int]$problem)
  {
    return $true
  }
}

[System.Net.ServicePointManager]::CertificatePolicy = [TrustAll]::new()
```

<!--本文国际来源：[Trusting Self-Signed HTTPS Certificates](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/trusting-self-signed-https-certificates)-->

