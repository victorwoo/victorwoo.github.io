---
layout: post
date: 2026-03-09 08:00:00
updated: 2026-03-09 08:00:00
title: "PowerShell 技能连载 - WinRM 高级配置与排错"
description: PowerTip of the Day - WinRM Advanced Configuration and Troubleshooting in PowerShell
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
- winrm
- remoting
- troubleshooting
- security
---

_适用于 PowerShell 5.1 及以上版本_

## WinRM 为什么总是连不上？

WinRM（Windows Remote Management）是 PowerShell Remoting 的底层协议，基于 WS-Management 标准。它允许管理员在远程计算机上执行命令、传输文件和管理配置。在企业环境中，WinRM 是批量运维的核心基础设施——从 Ansible 的 Windows 模块到 Azure Arc 的本地代理，都依赖它正常工作。

然而在实际部署中，WinRM 的"能连上"往往需要多个条件同时满足：服务运行、监听器配置正确、防火墙放行、认证协议匹配、权限授予。其中任何一个环节出问题，都会导致连接失败，而错误信息往往晦涩难懂，比如 `Access is denied`、`The WinRM client cannot process the request` 或 `WS-Man could not connect`。

本文将从配置加固、连接排错、受限端点三个方面，系统讲解 WinRM 的高级管理技巧，帮助你快速定位和解决远程管理中的常见故障。

## WinRM 配置与安全加固

在正式使用 WinRM 之前，合理的初始配置至关重要。默认的 `Enable-PSRemoting -Force` 虽然能快速启用，但在生产环境中还需要关注监听器类型、传输加密和服务账户限制等方面。

以下脚本展示了 WinRM 的一次性安全配置流程，包括检查服务状态、配置 HTTPS 监听器以及限制远程访问的服务账户：

```powershell
# 第一步：确保 WinRM 服务运行并设为自动启动
$service = Get-Service -Name WinRM -ErrorAction SilentlyContinue
if ($service.Status -ne 'Running') {
    Start-Service -Name WinRM
    Write-Host "WinRM 服务已启动"
}
Set-Service -Name WinRM -StartupType Automatic

# 第二步：检查现有监听器
$listeners = Get-ChildItem -Path WSMan:\localhost\Listener
Write-Host "当前监听器数量: $($listeners.Count)"

foreach ($listener in $listeners) {
    $protocol = Get-Item -Path "$($listener.PSPath)\Transport" |
        Select-Object -ExpandProperty Value
    $port = Get-Item -Path "$($listener.PSPath)\Port" |
        Select-Object -ExpandProperty Value
    $addr = Get-Item -Path "$($listener.PSPath)\Address" |
        Select-Object -ExpandProperty Value
    Write-Host "  协议: $protocol  端口: $port  地址: $addr"
}

# 第三步：创建 HTTPS 监听器（需要先准备证书）
$cert = Get-ChildItem -Path Cert:\LocalMachine\My |
    Where-Object {
        $_.EnhancedKeyUsageList.FriendlyName -contains 'Server Authentication' -and
        $_.NotAfter -gt (Get-Date)
    } |
    Sort-Object -Property NotAfter -Descending |
    Select-Object -First 1

if ($cert) {
    New-Item -Path WSMan:\localhost\Listener -Transport HTTPS `
        -Address * -CertificateThumbprint $cert.Thumbprint -Force
    Write-Host "HTTPS 监听器已创建，证书指纹: $($cert.Thumbprint)"

    # 配置防火墙规则放行 5986 端口
    $fwRule = Get-NetFirewallRule -DisplayName 'WinRM HTTPS' -ErrorAction SilentlyContinue
    if (-not $fwRule) {
        New-NetFirewallRule -DisplayName 'WinRM HTTPS' `
            -Direction Inbound -Protocol TCP -LocalPort 5986 -Action Allow
        Write-Host "防火墙规则已添加 (TCP 5986)"
    }
} else {
    Write-Warning "未找到有效的服务器认证证书，跳过 HTTPS 监听器创建"
}

# 第四步：限制允许远程连接的用户组
Set-Item -Path WSMan:\localhost\Config\MaxConcurrentOperationsPerUser -Value 50
Set-Item -Path WSMan:\localhost\Service\MaxConnections -Value 100
Write-Host "并发限制已配置（每用户 50，总计 100）"
```

执行结果示例：

```
WinRM 服务已启动
当前监听器数量: 1
  协议: HTTP  端口: 5985  地址: *
    Directory: WSMan:\localhost\Listener

Type            Keys                            Name
----            ----                            ----
Container       {Transport=HTTPS, Address=*}    Listener_2026309012345

HTTPS 监听器已创建，证书指纹: A1B2C3D4E5F6789012345678901234ABCD...
防火墙规则已添加 (TCP 5986)
并发限制已配置（每用户 50，总计 100）
```

## 连接排错工具集

当 WinRM 连接失败时，手动逐项排查非常耗时。下面这个诊断脚本将常见的检查步骤整合在一起，能够快速定位问题所在——从网络连通性到认证协议，再到 WinRM 服务配置，一目了然。

```powershell
function Test-WinRMConnection {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$ComputerName,

        [ValidateSet('HTTP', 'HTTPS')]
        [string]$Transport = 'HTTPS',

        [System.Management.Automation.PSCredential]$Credential
    )

    $port = if ($Transport -eq 'HTTPS') { 5986 } else { 5985 }
    $results = [ordered]@{}

    # 检查 1：DNS 解析
    try {
        $ip = [System.Net.Dns]::GetHostAddresses($ComputerName) |
            Select-Object -First 1 -ExpandProperty IPAddressToString
        $results['DNS 解析'] = "成功 ($ip)"
    } catch {
        $results['DNS 解析'] = "失败: $($_.Exception.Message)"
    }

    # 检查 2：TCP 端口连通性
    $tcp = New-Object System.Net.Sockets.TcpClient
    try {
        $tcp.Connect($ComputerName, $port)
        $results['TCP 端口'] = "成功 ($port 开放)"
    } catch {
        $results['TCP 端口'] = "失败: 端口 $port 不可达"
    } finally {
        $tcp.Close()
    }

    # 检查 3：TrustedHosts 配置
    $trustedHosts = (Get-Item WSMan:\localhost\Client\TrustedHosts).Value
    if ($trustedHosts -eq '*' -or $trustedHosts -split ',' -contains $ComputerName) {
        $results['信任主机'] = "已信任 (当前值: $trustedHosts)"
    } else {
        $results['信任主机'] = "未信任 (当前值: $trustedHosts)"
    }

    # 检查 4：WinRM 测试连接
    $sessionOption = New-PSSessionOption -SkipCACheck -SkipCNCheck
    $testParams = @{
        ComputerName  = $ComputerName
        SessionOption = $sessionOption
        ErrorAction   = 'Stop'
    }
    if ($Transport -eq 'HTTPS') {
        $testParams['UseSSL'] = $true
    }
    if ($Credential) {
        $testParams['Credential'] = $Credential
    }

    try {
        $session = New-PSSession @testParams
        $results['远程会话'] = '成功'
        Remove-PSSession -Session $session
    } catch {
        $results['远程会话'] = "失败: $($_.Exception.Message)"
    }

    # 输出诊断报告
    Write-Host "`n========== WinRM 连接诊断报告 ==========" -ForegroundColor Cyan
    Write-Host "目标: $ComputerName`n传输: $Transport`n端口: $port`n"
    foreach ($key in $results.Keys) {
        $status = $results[$key]
        $icon = if ($status -match '成功|已信任') { '[OK]' } else { '[!!]' }
        $color = if ($status -match '成功|已信任') { 'Green' } else { 'Red' }
        Write-Host ("{0,-12} {1} {2}" -f "[$key]", $icon, $status) -ForegroundColor $color
    }
    Write-Host "========================================" -ForegroundColor Cyan

    return $results
}

# 使用示例
Test-WinRMConnection -ComputerName 'SRV01.contoso.com' -Transport HTTPS
```

执行结果示例：

```
========== WinRM 连接诊断报告 ==========
目标: SRV01.contoso.com
传输: HTTPS
端口: 5986

[DNS 解析]    [OK] 成功 (10.0.1.50)
[TCP 端口]    [OK] 成功 (5986 开放)
[信任主机]    [!!] 未信任 (当前值: )
[远程会话]    [!!] 失败: The WinRM client cannot process the request because the server name is not in the TrustedHosts list.
========================================
```

上面的诊断结果清楚地指出了问题：目标服务器不在 TrustedHosts 列表中。对于非域环境，需要将远程主机名加入信任列表，或者使用 HTTPS 配合正确的证书验证。

常见的错误码及其含义如下：

| 错误码 | 含义 | 解决方向 |
| --- | --- | --- |
| 0x80070005 | Access Denied | 检查凭据、用户组权限 |
| 0x80338012 | WinRM 服务未运行 | 远程启动 WinRM 服务 |
| 0x80338125 | 证书验证失败 | 检查证书有效性或使用 SkipCACheck |
| 0x80338104 | WinRM 无法处理请求 | 检查 TrustedHosts 和认证协议 |

## Constrained Endpoint：受限会话配置

在多人协作的运维团队中，直接给所有成员完整的远程 PowerShell 权限风险很高。Constrained Endpoint（受限端点）允许你创建自定义的会话配置，精确控制远程用户可以执行哪些命令——这既满足了权限最小化原则，又为审计提供了完整的操作日志。

```powershell
# 定义受限会话的角色能力（Role Capability）
$roleCapDir = "$env:ProgramFiles\WindowsPowerShell\RoleCapabilities"
if (-not (Test-Path $roleCapDir)) {
    New-Item -Path $roleCapDir -ItemType Directory -Force
}

# 创建角色能力文件
$roleCapParams = @{
    Path                   = Join-Path $roleCapDir 'Maintenance.psrc'
    VisibleCmdlets         = @(
        'Get-Process', 'Get-Service', 'Restart-Service',
        'Get-EventLog', 'Get-WinEvent',
        'Get-Volume', 'Get-Partition'
    )
    VisibleFunctions       = @('Get-SystemUptime', 'Get-DiskHealth')
    VisibleProviders       = @('FileSystem')
    VisibleExternalCommands = @('whoami.exe', 'hostname.exe')
    ScriptsToProcess       = @()
    AliasDefinitions       = @(
        @{ Name = 'gsv'; Value = 'Get-Service' }
    )
    FunctionDefinitions    = @(
        @{
            Name        = 'Get-SystemUptime'
            ScriptBlock = {
                $os = Get-CimInstance -ClassName Win32_OperatingSystem
                $uptime = (Get-Date) - $os.LastBootUpTime
                [PSCustomObject]@{
                    LastBoot = $os.LastBootUpTime
                    UptimeDays   = [math]::Round($uptime.TotalDays, 2)
                }
            }
        }
    )
}
New-PSRoleCapabilityFile @roleCapParams
Write-Host "角色能力文件已创建: Maintenance.psrc"

# 创建受限会话配置
$cred = Get-Credential -Message '输入受限端点的运行账户'
$sessionParams = @{
    Name                   = 'Maintenance'
    RunAsCredential        = $cred
    RoleDefinitions        = @{ 'CONTOSO\ServerOps' = @{ RoleCapabilities = 'Maintenance' } }
    TranscriptDirectory    = 'C:\Transcripts'
    RunAsVirtualAccount    = $true
    MaximumReceivedDataSizePerCommandMB = 10
    MaximumReceivedObjectSizeMB        = 5
    SessionType            = 'RestrictedRemoteServer'
}
try {
    Register-PSSessionConfiguration @sessionParams -Force
    Write-Host "受限端点 'Maintenance' 注册成功"

    # 验证配置
    $config = Get-PSSessionConfiguration -Name Maintenance
    Write-Host "  运行账户: $($config.RunAsUser)"
    Write-Host "  虚拟账户: $($config.RunAsVirtualAccount)"
    Write-Host "  审计目录: $($config.TranscriptDirectory)"

    # 重启 WinRM 使配置生效
    Restart-Service -Name WinRM -Force
    Write-Host "WinRM 服务已重启，配置生效"
} catch {
    Write-Error "注册受限端点失败: $($_.Exception.Message)"
}
```

执行结果示例：

```
角色能力文件已创建: Maintenance.psrc

   Location: C:\Program Files\WindowsPowerShell\RoleCapabilities

Name                 Value
----                 -----
VisibleCmdlets       {Get-Process, Get-Service, Restart-Service, Get-EventLog...}
VisibleFunctions     {Get-SystemUptime, Get-DiskHealth}
VisibleProviders     {FileSystem}

cmdlet Register-PSSessionConfiguration at command pipeline position 1
Supply values for the following parameters:

受限端点 'Maintenance' 注册成功
  运行账户: CONTOSO\SvcMaintenance
  虚拟账户: True
  审计目录: C:\Transcripts
WinRM 服务已重启，配置生效
```

注册完成后，团队成员可以通过以下方式连接受限端点：

```powershell
Enter-PSSession -ComputerName SRV01 -ConfigurationName Maintenance
```

连接后只能使用预定义的命令集，所有操作都会被记录到 `C:\Transcripts` 目录下的转录文件中，方便事后审计。

## 注意事项

1. **HTTPS 监听器必须有有效证书**。如果使用自签名证书，客户端需要通过 `SkipCACheck` 选项跳过 CA 验证，但这会降低安全性。在生产环境中应使用企业 CA 或公共 CA 签发的证书，确保证书的主题名称（或 SAN）与服务器主机名匹配。

2. **TrustedHosts 是安全风险点**。将 TrustedHosts 设为 `*` 等于信任所有远程主机，仅适用于测试环境。在域环境中应依赖 Kerberos 认证，避免修改 TrustedHosts；在工作组环境中至少明确指定目标主机名。

3. **Constrained Endpoint 使用虚拟账户**。`RunAsVirtualAccount = $true` 会让会话使用临时创建的虚拟账户运行，该账户在会话结束后自动销毁，比直接使用真实服务账户更安全。但虚拟账户无法访问网络资源，如需跨机器操作需配合 gMSA（组托管服务账户）。

4. **防火墙规则需双向检查**。WinRM 使用 HTTP（5985）和 HTTPS（5986）两个端口。确保远程主机的入站规则放行了对应端口，同时检查本地网络出站策略和中间链路的防火墙设备。

5. **转录文件会持续增长**。配置 `TranscriptDirectory` 后，所有远程会话的操作都会被完整记录。建议配合定期归档脚本清理过期的转录文件，避免磁盘空间耗尽。

6. **WinRM 配置修改后需重启服务**。无论是修改监听器、注册新的会话配置还是更改服务参数，都需要执行 `Restart-Service -Name WinRM -Force` 才能生效。注意这会断开所有现有的远程会话，应在维护窗口操作。
