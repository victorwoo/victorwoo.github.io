---
layout: post
date: 2025-04-30 08:00:00
title: "PowerShell 技能连载 - 脚本签名与执行策略"
description: PowerTip of the Day - Script Signing and Execution Policy in PowerShell
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
- security
- code-signing
- execution-policy
---

_适用于 PowerShell 5.1 及以上版本（Windows）_

在企业环境中，PowerShell 是双刃剑：它既是运维人员最强大的自动化工具，也是攻击者最常滥用的攻击载体。从 Mimikatz 到勒索软件，大量恶意行为都依赖 PowerShell 执行。因此，微软提供了两层防护机制——**执行策略（Execution Policy）** 和 **代码签名（Code Signing）**，帮助组织控制哪些脚本可以运行、哪些脚本应该被拦截。

本文将系统讲解执行策略的各个级别与作用域、如何获取和使用代码签名证书对脚本进行签名、如何验证签名有效性，以及如何在团队中建立可落地的签名工作流。

## 执行策略详解

执行策略（Execution Policy）并不是安全边界，而是一种"防误触"机制——它的目的是防止用户无意中运行未信任的脚本。PowerShell 定义了多个策略级别，从最宽松到最严格依次为：

- **Unrestricted**：不限制，运行任何脚本（仅对来自互联网的文件提示确认）
- **RemoteSigned**：本地脚本可直接运行，远程下载的脚本必须经过签名
- **AllSigned**：所有脚本都必须有受信任的签名才能运行
- **Restricted**：不允许运行任何脚本（Windows 客户端默认值）
- **Default**：客户端为 Restricted，服务器为 RemoteSigned
- **Bypass**：不阻止任何脚本，也不提示警告（常用于 CI/CD 流水线）

执行策略还支持多个作用域，优先级从高到低为：MachinePolicy > UserPolicy > Process > CurrentUser > LocalMachine。这意味着组策略设置的优先级最高，无法通过命令行覆盖。

下面的代码展示了如何查看当前各作用域的执行策略设置：

```powershell
# 查看所有作用域的执行策略
Get-ExecutionPolicy -List

# 查看当前生效的执行策略
Get-ExecutionPolicy

# 为当前用户设置执行策略（不需要管理员权限）
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser

# 为本地计算机设置执行策略（需要管理员权限）
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope LocalMachine
```

执行结果示例：

```
Scope                 ExecutionPolicy
-----                 ---------------
MachinePolicy               Undefined
UserPolicy                  Undefined
Process                     Undefined
CurrentUser           RemoteSigned
LocalMachine          RemoteSigned

RemoteSigned
```

> **注意**：`Set-ExecutionPolicy` 修改的是注册表项，在 PowerShell 7 中默认作用于 CurrentUser 作用域。如果使用 `-Scope Process`，则仅对当前会话生效，关闭窗口后恢复原值。

## 代码签名证书获取

在 AllSigned 策略下，脚本必须经过受信任的代码签名证书签名后才能执行。代码签名证书可以从以下途径获取：

1. **企业内部 CA**：大多数企业已部署 Active Directory Certificate Services（AD CS），可以直接申请代码签名证书
2. **公共 CA**：如 DigiCert、Sectigo 等商业 CA 提供的代码签名证书
3. **自签名证书**：仅适用于测试环境，不会被其他机器信任

下面的代码演示如何使用企业 CA 或自签名方式获取代码签名证书：

```powershell
# 方法一：从企业 CA 申请代码签名证书
# 需要企业管理员预先配置证书模板
$cert = Get-ChildItem -Path Cert:\CurrentUser\My -CodeSigningCert |
    Where-Object { $_.Issuer -match 'YourCompany-CA' } |
    Select-Object -First 1

if ($cert) {
    Write-Host "找到企业 CA 颁发的代码签名证书：$($cert.Subject)" -ForegroundColor Green
} else {
    Write-Host "未找到企业 CA 证书，正在创建自签名测试证书..." -ForegroundColor Yellow

    # 方法二：创建自签名代码签名证书（仅用于测试）
    $testCert = New-SelfSignedCertificate `
        -Type CodeSigningCert `
        -Subject "CN=PowerShell Test Signing" `
        -KeyAlgorithm RSA `
        -KeyLength 2048 `
        -HashAlgorithm SHA256 `
        -CertStoreLocation "Cert:\CurrentUser\My"

    Write-Host "已创建自签名证书：$($testCert.Subject)" -ForegroundColor Green
    Write-Host "指纹：$($testCert.Thumbprint)" -ForegroundColor Cyan
}
```

执行结果示例：

```
未找到企业 CA 证书，正在创建自签名测试证书...
已创建自签名证书：CN=PowerShell Test Signing
指纹：A1B2C3D4E5F6789012345678901234567890ABCD
```

> **注意**：自签名证书默认不在"受信任的根证书颁发机构"中，需要手动将其导出并导入到 `TrustedPublisher` 和 `Root` 存储区，其他机器才能信任该签名。

## 对脚本进行签名

获取证书后，使用 `Set-AuthenticodeSignature` 对 `.ps1` 脚本文件进行签名。签名时推荐同时指定时间戳服务器（Timestamp Server），这样即使证书过期，在证书有效期内签名的脚本仍然可以被验证为可信。

下面是一个完整的签名示例，包含签名和时间戳设置：

```powershell
# 选择代码签名证书
$cert = Get-ChildItem -Path Cert:\CurrentUser\My -CodeSigningCert |
    Where-Object { $_.Subject -match 'PowerShell Test Signing' } |
    Select-Object -First 1

# 定义要签名的脚本路径
$scriptPath = "D:\Scripts\Deploy-Application.ps1"

# 使用时间戳服务器签名（推荐）
# 时间戳服务器确保证书过期后签名仍然有效
Set-AuthenticodeSignature -FilePath $scriptPath -Certificate $cert `
    -TimestampServer "http://timestamp.digicert.com"

# 验证签名结果
$signature = Get-AuthenticodeSignature -FilePath $scriptPath
Write-Host "签名状态：$($signature.Status)"
Write-Host "签名者：$($signature.SignerCertificate.Subject)"
Write-Host "时间戳：$($signature.TimeStamperCertificate.NotBefore)"
```

执行结果示例：

```
签名状态：Valid
签名者：CN=PowerShell Test Signing
时间戳：04/30/2025 00:00:00
```

签名完成后，脚本文件末尾会自动追加一段以 `# SIG # Begin signature block` 开头的 Base64 编码签名数据。这段数据不要手动修改，否则签名会失效。

## 验证签名有效性

在生产环境中运行脚本之前，应该先验证其签名状态。`Get-AuthenticodeSignature` 返回的 `Status` 属性包含以下可能值：

| 状态值 | 含义 |
| ------ | ---- |
| Valid | 签名有效且受信任 |
| NotSigned | 脚本未签名 |
| HashMismatch | 文件内容被篡改，哈希不匹配 |
| UnknownError | 签名无法验证（如证书链不完整） |
| NotTrusted | 签名有效但证书不受信任 |

下面编写一个函数，用于批量检查目录下所有脚本的签名状态：

```powershell
function Test-ScriptSignature {
    <#
    .SYNOPSIS
    批量检查 PowerShell 脚本的签名状态
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Path,

        [ValidateSet('Valid','NotSigned','HashMismatch','NotTrusted','All')]
        [string]$Filter = 'All'
    )

    $scripts = Get-ChildItem -Path $Path -Filter *.ps1 -Recurse

    foreach ($script in $scripts) {
        $sig = Get-AuthenticodeSignature -FilePath $script.FullName

        $result = [PSCustomObject]@{
            File        = $script.FullName
            Status      = $sig.Status
            Signer      = if ($sig.SignerCertificate) { $sig.SignerCertificate.Subject } else { 'N/A' }
            Timestamp   = if ($sig.TimeStamperCertificate) {
                $sig.TimeStamperCertificate.NotBefore.ToString('yyyy-MM-dd')
            } else {
                'N/A'
            }
        }

        if ($Filter -eq 'All' -or $result.Status -eq $Filter) {
            $result
        }
    }
}

# 检查 D:\Scripts 下所有脚本，仅显示未签名的
Test-ScriptSignature -Path "D:\Scripts" -Filter NotSigned
```

执行结果示例：

```
File                                   Status    Signer Timestamp
----                                   ------    ------ ---------
D:\Scripts\Cleanup-Temp.ps1            NotSigned N/A    N/A
D:\Scripts\Update-Modules.ps1          NotSigned N/A    N/A
D:\Scripts\Restart-Services.ps1        NotSigned N/A    N/A
```

当发现 `HashMismatch` 状态时，说明脚本内容在签名后被修改过，这可能是恶意篡改的信号，应当立即排查。

## 批量签名脚本

在 CI/CD 流水线或发布流程中，通常需要对整个目录的脚本进行批量签名。下面是一个实用的批量签名函数，支持排除指定文件、记录日志，并在签名失败时抛出异常：

```powershell
function Protect-ScriptDirectory {
    <#
    .SYNOPSIS
    批量对目录中的 PowerShell 脚本进行代码签名
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Path,

        [Parameter(Mandatory)]
        [string]$CertSubject,

        [string]$TimestampServer = "http://timestamp.digicert.com",

        [string[]]$ExcludePattern,

        [string]$LogPath = "D:\Logs\SigningLog.csv"
    )

    # 查找证书
    $cert = Get-ChildItem -Path Cert:\CurrentUser\My -CodeSigningCert |
        Where-Object { $_.Subject -match $CertSubject } |
        Select-Object -First 1

    if (-not $cert) {
        throw "未找到匹配的代码签名证书：$CertSubject"
    }

    # 获取脚本列表
    $scripts = Get-ChildItem -Path $Path -Filter *.ps1 -Recurse

    # 应用排除规则
    if ($ExcludePattern) {
        $scripts = $scripts | Where-Object {
            $file = $_
            -not ($ExcludePattern | Where-Object { $file.Name -match $_ })
        }
    }

    $results = foreach ($script in $scripts) {
        $sig = Set-AuthenticodeSignature -FilePath $script.FullName `
            -Certificate $cert `
            -TimestampServer $TimestampServer

        [PSCustomObject]@{
            Time   = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
            File   = $script.FullName
            Status = $sig.Status
        }
    }

    # 输出日志
    $results | Export-Csv -Path $LogPath -NoTypeInformation -Append
    $results | Format-Table -AutoSize

    # 检查是否有失败
    $failed = $results | Where-Object { $_.Status -ne 'Valid' }
    if ($failed) {
        Write-Warning "以下脚本签名失败："
        $failed | ForEach-Object { Write-Warning "  $($_.File) - $($_.Status)" }
    } else {
        Write-Host "全部 $($scripts.Count) 个脚本签名成功" -ForegroundColor Green
    }
}

# 批量签名，排除测试脚本
Protect-ScriptDirectory `
    -Path "D:\Scripts" `
    -CertSubject "YourCompany Code Signing" `
    -ExcludePattern "Test","Demo","Example" `
    -LogPath "D:\Logs\SigningLog_20250430.csv"
```

执行结果示例：

```
Time                 File                               Status
----                 ----                               ------
2025-04-30 10:15:32  D:\Scripts\Deploy-Application.ps1  Valid
2025-04-30 10:15:32  D:\Scripts\Cleanup-Temp.ps1        Valid
2025-04-30 10:15:33  D:\Scripts\Update-Modules.ps1      Valid
2025-04-30 10:15:33  D:\Scripts\Restart-Services.ps1    Valid
全部 4 个脚本签名成功
```

## 团队签名工作流

在企业团队中，代码签名不应依赖个人手动操作，而应建立标准化流程。以下是一个推荐的团队签名工作流：

1. **开发阶段**：开发者使用 `RemoteSigned` 策略，本地脚本无需签名即可运行
2. **代码审查**：通过 Pull Request 审查脚本内容，确保无恶意代码
3. **CI/CD 签名**：合并到主分支后，流水线使用专用签名证书自动签名
4. **发布部署**：仅签名后的脚本被推送到生产环境，生产环境使用 `AllSigned` 策略

下面展示一个可在 Azure DevOps 或 GitHub Actions 中使用的签名步骤：

```powershell
# CI/CD 流水线中的签名步骤
# 证书从安全变量或 Key Vault 中加载
param(
    [string]$CertThumbprint,
    [string]$ScriptsPath = "./src/scripts",
    [string]$TimestampServer = "http://timestamp.digicert.com"
)

# 从证书存储区加载签名证书
$cert = Get-ChildItem -Path Cert:\LocalMachine\My |
    Where-Object { $_.Thumbprint -eq $CertThumbprint }

if (-not $cert) {
    Write-Error "未找到指纹为 $CertThumbprint 的证书"
    exit 1
}

# 签名所有 .ps1 文件
$scripts = Get-ChildItem -Path $ScriptsPath -Filter *.ps1 -Recurse
$successCount = 0
$failCount = 0

foreach ($script in $scripts) {
    $sig = Set-AuthenticodeSignature `
        -FilePath $script.FullName `
        -Certificate $cert `
        -TimestampServer $TimestampServer

    if ($sig.Status -eq 'Valid') {
        $successCount++
    } else {
        $failCount++
        Write-Error "签名失败：$($script.FullName) - 状态：$($sig.Status)"
    }
}

Write-Host "签名完成：成功 $successCount 个，失败 $failCount 个"

if ($failCount -gt 0) {
    exit 1
}
```

执行结果示例：

```
签名完成：成功 12 个，失败 0 个
```

此外，还建议通过组策略（Group Policy）统一管理执行策略，确保所有终端的设置一致：

```powershell
# 查看组策略设置的执行策略
# 组策略优先级高于 Set-ExecutionPolicy
Get-ExecutionPolicy -List | Where-Object {
    $_.Scope -match 'MachinePolicy|UserPolicy'
}
```

执行结果示例：

```
Scope                 ExecutionPolicy
-----                 ---------------
MachinePolicy                 AllSigned
UserPolicy                    Undefined
```

当 `MachinePolicy` 设置为 `AllSigned` 时，即使本地执行策略为 `RemoteSigned`，组策略也会强制要求所有脚本必须经过签名。

## 注意事项

1. **执行策略不是安全边界**：用户可以通过 `-ExecutionPolicy Bypass` 参数轻松绕过，真正的安全应依赖 AppLocker 或 WDAC（Windows Defender Application Control）
2. **时间戳服务器必不可少**：没有时间戳的签名在证书过期后立即失效，所有已签名的脚本都会变成"不受信任"状态
3. **保护签名私钥**：代码签名证书的私钥应存储在 HSM（硬件安全模块）或 Azure Key Vault 中，避免泄露
4. **自签名证书仅限测试**：生产环境必须使用受信任 CA 颁发的证书，否则在其他机器上签名无法通过验证
5. **签名后勿修改脚本**：任何对脚本内容的修改（包括空格和注释）都会导致签名哈希不匹配，状态变为 `HashMismatch`
6. **组策略优先级最高**：在域环境中，始终通过组策略统一管控执行策略，避免依赖本地配置
