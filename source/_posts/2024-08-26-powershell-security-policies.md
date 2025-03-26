---
layout: post
date: 2024-08-26 08:00:00
title: "PowerShell 技能连载 - 安全策略配置指南"
description: "掌握PowerShell执行策略与安全防护的核心配置"
categories:
- powershell
- security
tags:
- powershell
- security
- policies
---

PowerShell执行策略是脚本安全的第一道防线，通过灵活配置平衡功能与安全。

```powershell
# 查看当前执行策略
Get-ExecutionPolicy -List

# 设置远程签名策略
Set-ExecutionPolicy RemoteSigned -Scope CurrentUser
```

### 脚本签名验证
1. 创建代码签名证书：
```powershell
$certParams = @{
    Subject = 'CN=PowerShell Scripts'
    Type = 'CodeSigning'
    KeyUsage = 'DigitalSignature'
    KeyLength = 2048
}
$cert = New-SelfSignedCertificate @certParams
```

2. 签名脚本文件：
```powershell
$signParams = @{
    Certificate = $cert
    FilePath = 'script.ps1'
    TimestampServer = 'http://timestamp.digicert.com'
}
Set-AuthenticodeSignature @signParams
```

### 安全日志分析
```powershell
# 查询脚本块日志
Get-WinEvent -FilterHashtable @{
    LogName = 'Microsoft-Windows-PowerShell/Operational'
    Id = 4104
} | Where-Object {
    $_.Message -match '可疑命令'
}
```

最佳实践：
- 使用AllSigned策略生产环境
- 定期轮换签名证书
- 启用脚本块日志记录
- 结合AppLocker增强控制