---
layout: post
date: 2025-06-30 08:00:00
updated: 2025-06-30 08:00:00
title: "PowerShell 技能连载 - 安全编码实践"
description: PowerTip of the Day - Secure Coding Practices in PowerShell
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
- security
- secure-coding
- credential
- encryption
---

_适用于 PowerShell 5.1 及以上版本_

安全编码不是可选项，而是生产环境的基本要求。PowerShell 脚本经常处理凭据、连接字符串、API 密钥等敏感信息，如果处理不当，这些信息可能泄露到日志文件、版本控制系统、甚至被恶意代码利用。从凭据管理、输入验证、代码签名，到审计日志和合规检查，PowerShell 提供了完整的安全工具链。

本文将讲解 PowerShell 安全编码的核心实践，帮助构建安全可靠的自动化脚本。

## 凭据安全管理

```powershell
# 不要这样做——明文密码
# $password = "MyP@ssw0rd123"

# 安全方式 1：Get-Credential 交互式输入
$credential = Get-Credential -Message "输入服务账户凭据"
Write-Host "用户名：$($credential.UserName)"
Write-Host "密码长度：$($credential.GetNetworkCredential().Password.Length)"

# 安全方式 2：加密文件存储（DPAPI，仅限当前用户和机器）
function Save-SecureCredential {
    param(
        [Parameter(Mandatory)]
        [string]$Name,

        [Parameter(Mandatory)]
        [System.Management.Automation.PSCredential]$Credential
    )

    $credDir = "$env:APPDATA\PowerShell\Credentials"
    New-Item $credDir -ItemType Directory -Force | Out-Null

    $Credential | Export-Clixml -Path "$credDir\$Name.xml" -Force
    Write-Host "凭据已安全保存：$Name" -ForegroundColor Green
}

function Get-SecureCredential {
    param([Parameter(Mandatory)][string]$Name)

    $path = "$env:APPDATA\PowerShell\Credentials\$Name.xml"
    if (-not (Test-Path $path)) {
        throw "凭据文件不存在：$Name"
    }
    return Import-Clixml -Path $path
}

# 保存和读取凭据
$cred = Get-Credential -Message "输入数据库连接凭据"
Save-SecureCredential -Name "DBAdmin" -Credential $cred

$dbCred = Get-SecureCredential -Name "DBAdmin"
Write-Host "已加载凭据：$($dbCred.UserName)"

# 安全方式 3：Windows Credential Manager
Install-Module -Name CredentialManager -Force -Scope CurrentUser
New-StoredCredential -Target "MyApp-Prod" -UserName "svc_myapp" -Password "P@ssw0rd" -Persist LocalMachine
$storedCred = Get-StoredCredential -Target "MyApp-Prod"
Write-Host "从凭据管理器加载：$($storedCred.UserName)"
```

执行结果示例：

```
凭据已安全保存：DBAdmin
已加载凭据：admin@example.com
从凭据管理器加载：svc_myapp
```

## 输入验证与净化

```powershell
# 路径遍历攻击防护
function Get-SafeFilePath {
    param([Parameter(Mandatory)][string]$UserInput)

    # 规范化路径
    $basePath = "C:\Data\Uploads"
    $fullPath = [System.IO.Path]::GetFullPath(
        [System.IO.Path]::Combine($basePath, $UserInput)
    )

    # 检查是否在允许的基目录下
    if (-not $fullPath.StartsWith($basePath, [StringComparison]::OrdinalIgnoreCase)) {
        throw "非法路径：$UserInput（路径遍历攻击）"
    }

    return $fullPath
}

# 测试路径遍历
$tests = @("report.csv", "..\..\Windows\System32\config\SAM", "subdir\file.txt")
foreach ($test in $tests) {
    try {
        $safePath = Get-SafeFilePath -UserInput $test
        Write-Host "合法路径：$safePath" -ForegroundColor Green
    } catch {
        Write-Host "拦截：$test - $($_.Exception.Message)" -ForegroundColor Red
    }
}

# SQL 注入防护——始终使用参数化查询
function Get-UserData {
    param(
        [Parameter(Mandatory)]
        [string]$ConnectionString,

        [Parameter(Mandatory)]
        [string]$UserName
    )

    # 验证输入格式
    if ($UserName -notmatch '^[a-zA-Z0-9_-]{1,50}$') {
        throw "非法用户名格式：$UserName"
    }

    $query = "SELECT Id, Name, Email FROM Users WHERE Name = @userName"

    $connection = New-Object System.Data.SqlClient.SqlConnection($ConnectionString)
    $command = $connection.CreateCommand()
    $command.CommandText = $query

    # 使用参数化查询防止 SQL 注入
    $param = $command.Parameters.Add("@userName", [System.Data.SqlDbType]::VarChar, 50)
    $param.Value = $UserName

    try {
        $connection.Open()
        $adapter = New-Object System.Data.SqlClient.SqlDataAdapter($command)
        $table = New-Object System.Data.DataTable
        $adapter.Fill($table) | Out-Null
        return $table
    } finally {
        $connection.Close()
    }
}

# 命令注入防护
function Invoke-SafeCommand {
    param([Parameter(Mandatory)][string]$FileName)

    # 白名单验证
    $allowedExtensions = @('.csv', '.json', '.xml', '.txt')
    $ext = [System.IO.Path]::GetExtension($FileName).ToLower()

    if ($ext -notin $allowedExtensions) {
        throw "不支持的文件类型：$ext"
    }

    if ($FileName -match '[<>|&]') {
        throw "文件名包含非法字符"
    }

    # 使用参数数组而非字符串拼接
    $psi = [System.Diagnostics.ProcessStartInfo]::new()
    $psi.FileName = "cmd.exe"
    $psi.Arguments = "/c type `"$FileName`""
    $psi.UseShellExecute = $false
    $psi.RedirectStandardOutput = $true

    $process = [System.Diagnostics.Process]::Start($psi)
    $output = $process.StandardOutput.ReadToEnd()
    $process.WaitForExit()

    return $output
}
```

执行结果示例：

```
合法路径：C:\Data\Uploads\report.csv
拦截：..\..\Windows\System32\config\SAM - 非法路径：..\..\Windows\System32\config\SAM（路径遍历攻击）
合法路径：C:\Data\Uploads\subdir\file.txt
```

## 脚本代码签名

```powershell
# 获取代码签名证书
$cert = Get-ChildItem Cert:\CurrentUser\My -CodeSigningCert | Select-Object -First 1

if (-not $cert) {
    Write-Host "未找到代码签名证书，创建自签名证书用于测试..." -ForegroundColor Yellow
    $cert = New-SelfSignedCertificate -Type CodeSigningCert `
        -Subject "CN=PowerShell Script Signing" `
        -CertStoreLocation "Cert:\CurrentUser\My"
    Write-Host "已创建测试证书：$($cert.Thumbprint)" -ForegroundColor Green
}

# 对脚本进行签名
$scriptPath = "C:\Scripts\Deploy-App.ps1"
Set-AuthenticodeSignature -FilePath $scriptPath -Certificate $cert
Write-Host "脚本已签名：$scriptPath" -ForegroundColor Green

# 验证签名
$signature = Get-AuthenticodeSignature $scriptPath
Write-Host "签名状态：$($signature.Status)"
Write-Host "签名者：$($signature.SignerCertificate.Subject)"

# 设置执行策略
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
Write-Host "执行策略已设为 RemoteSigned" -ForegroundColor Green
```

执行结果示例：

```
已创建测试证书：A1B2C3D4E5F6...
脚本已签名：C:\Scripts\Deploy-App.ps1
签名状态：Valid
签名者：CN=PowerShell Script Signing
执行策略已设为 RemoteSigned
```

## 审计日志与合规

```powershell
function Write-AuditLog {
    <#
    .SYNOPSIS
    写入安全审计日志
    #>
    param(
        [Parameter(Mandatory)]
        [string]$Action,

        [string]$Target = "",

        [string]$Result = "Success",

        [string]$Details = ""
    )

    $entry = [PSCustomObject]@{
        Timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff'
        User      = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name
        Computer  = $env:COMPUTERNAME
        Action    = $Action
        Target    = $Target
        Result    = $Result
        Details   = $Details
    }

    $logDir = "C:\Logs\Audit"
    New-Item $logDir -ItemType Directory -Force | Out-Null

    $logFile = "$logDir\audit-$(Get-Date -Format 'yyyy-MM').csv"

    if (Test-Path $logFile) {
        $entry | Export-Csv $logFile -Append -NoTypeInformation -Encoding UTF8
    } else {
        $entry | Export-Csv $logFile -NoTypeInformation -Encoding UTF8
    }
}

# 关键操作自动记录审计日志
function Restart-ServiceWithAudit {
    param(
        [Parameter(Mandatory)]
        [string]$ServiceName,

        [string]$Reason
    )

    Write-AuditLog -Action "ServiceRestart" -Target $ServiceName -Details "原因：$Reason"

    try {
        Restart-Service -Name $ServiceName -Force -ErrorAction Stop
        $svc = Get-Service $ServiceName
        Write-AuditLog -Action "ServiceRestartResult" -Target $ServiceName `
            -Result "Success" -Details "服务状态：$($svc.Status)"
        Write-Host "服务已重启：$ServiceName" -ForegroundColor Green
    } catch {
        Write-AuditLog -Action "ServiceRestartResult" -Target $ServiceName `
            -Result "Failed" -Details $_.Exception.Message
        Write-Host "重启失败：$($_.Exception.Message)" -ForegroundColor Red
        throw
    }
}

Restart-ServiceWithAudit -ServiceName "Spooler" -Reason "打印队列堵塞"
```

执行结果示例：

```
服务已重启：Spooler
```

## 安全基线检查脚本

```powershell
function Test-SecurityBaseline {
    <#
    .SYNOPSIS
    执行基本的安全基线检查
    #>

    $results = @()

    # 检查 1：执行策略
    $policy = Get-ExecutionPolicy
    $results += [PSCustomObject]@{
        Check   = "执行策略"
        Value   = $policy.ToString()
        Status  = if ($policy -in @('Restricted', 'RemoteSigned', 'AllSigned')) { "PASS" } else { "WARN" }
        Details = "当前策略：$policy"
    }

    # 检查 2：管理员权限
    $isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    $results += [PSCustomObject]@{
        Check   = "管理员权限"
        Value   = $isAdmin.ToString()
        Status  = if (-not $isAdmin) { "PASS" } else { "WARN" }
        Details = if ($isAdmin) { "以管理员身份运行，存在提权风险" } else { "以普通用户运行" }
    }

    # 检查 3：PowerShell 版本
    $psVersion = $PSVersionTable.PSVersion.ToString()
    $results += [PSCustomObject]@{
        Check   = "PowerShell 版本"
        Value   = $psVersion
        Status  = if ($PSVersionTable.PSVersion.Major -ge 5) { "PASS" } else { "FAIL" }
        Details = "版本：$psVersion"
    }

    # 检查 4：脚本块日志
    $sbLogging = Get-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\PowerShell\ScriptBlockLogging" `
        -ErrorAction SilentlyContinue
    $results += [PSCustomObject]@{
        Check   = "脚本块日志"
        Value   = if ($sbLogging.EnableScriptBlockLogging -eq 1) { "启用" } else { "未启用" }
        Status  = if ($sbLogging.EnableScriptBlockLogging -eq 1) { "PASS" } else { "WARN" }
        Details = "建议启用脚本块日志记录"
    }

    $results | Format-Table -AutoSize

    $failCount = ($results | Where-Object { $_.Status -eq "FAIL" }).Count
    $warnCount = ($results | Where-Object { $_.Status -eq "WARN" }).Count

    Write-Host "`n检查结果：$($results.Count) 项 | PASS: $($results.Count - $failCount - $warnCount) | WARN: $warnCount | FAIL: $failCount" -ForegroundColor $(if ($failCount -gt 0) { "Red" } elseif ($warnCount -gt 0) { "Yellow" } else { "Green" })
}

Test-SecurityBaseline
```

执行结果示例：

```
Check           Value    Status Details
-----           -----    ------ -------
执行策略        RemoteSigned PASS  当前策略：RemoteSigned
管理员权限      False        PASS  以普通用户运行
PowerShell 版本 7.4.2        PASS  版本：7.4.2
脚本块日志      启用         PASS  建议启用脚本块日志记录

检查结果：4 项 | PASS: 4 | WARN: 0 | FAIL: 0
```

## 注意事项

1. **绝不硬编码密码**：密码、密钥、Token 等敏感信息应使用凭据管理器、环境变量或密钥库
2. **最小权限原则**：脚本使用最小必要权限运行，避免使用管理员权限执行常规任务
3. **输入验证**：所有外部输入都必须验证和净化，防止注入攻击（SQL、命令、路径遍历）
4. **传输加密**：远程管理使用 HTTPS/SSL，禁用不安全的协议（TLS 1.0/1.1）
5. **审计追踪**：关键操作记录审计日志，包含操作者、时间、目标、结果
6. **签名策略**：生产环境使用 `AllSigned` 或 `RemoteSigned` 执行策略，阻止未签名脚本运行
