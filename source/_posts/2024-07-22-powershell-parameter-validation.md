---
layout: post
date: 2024-07-22 08:00:00
title: "PowerShell 技能连载 - 参数验证机制"
description: PowerTip of the Day - PowerShell Parameter Validation
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---

## 参数验证基础

PowerShell 提供多种参数验证属性来确保输入合规性：

```powershell
function Get-UserInfo {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [ValidatePattern("^[a-zA-Z]\\w{3,20}$")]
        [string]$UserName,

        [ValidateSet('Active','Disabled','Archived')]
        [string]$Status = 'Active',

        [ValidateRange(18,120)]
        [int]$Age
    )
    # 函数逻辑...
}
```

## 验证类型详解

1. **Mandatory验证**：
```powershell
[Parameter(Mandatory=$true, HelpMessage="请输入用户ID")]
[string]$UserID
```

2. **正则表达式验证**：
```powershell
[ValidatePattern("^\\d{4}-\\d{2}-\\d{2}$")]
[string]$BirthDate
```

3. **脚本块验证**：
```powershell
[ValidateScript({
    if ($_ -notmatch "^CN=") { 
        throw "必须使用LDAP格式"
    }
    $true
})]
[string]$DistinguishedName
```

## 最佳实践
1. 组合使用多个验证属性
2. 为复杂验证添加帮助信息
3. 在验证失败时提供友好提示
4. 优先使用内置验证属性

```powershell
function Register-Device {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [ValidateScript({
            if (-not (Test-Path $_)) {
                throw "证书文件不存在"
            }
            $true
        })]
        [string]$CertPath
    )
    # 注册逻辑...
}
```