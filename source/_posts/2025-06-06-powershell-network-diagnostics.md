---
layout: post
date: 2025-06-06 08:00:00
updated: 2025-06-06 08:00:00
title: "PowerShell 技能连载 - 网络诊断与排查"
description: PowerTip of the Day - Network Diagnostics and Troubleshooting in PowerShell
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
- network
- diagnostics
- tcp
- dns
---

_适用于 PowerShell 5.1 及以上版本_

网络故障是运维工作中最常见的排障场景——"连不上数据库"、"网站打不开"、"文件共享超时"。PowerShell 内置了丰富的网络诊断命令，从基本的 ping、端口检测到 DNS 解析、路由追踪和 TCP 连接测试，可以快速定位网络问题的层级（物理层、链路层、网络层、传输层、应用层）。

本文将讲解 PowerShell 网络诊断的系统化方法，以及如何构建一键式排障脚本。

## 基础连通性测试

```powershell
# Test-Connection（PowerShell 的 ping）
Test-Connection -ComputerName google.com -Count 4 |
    Select-Object Address, @{N='延迟ms'; E={$_.ResponseTime}}, Status |
    Format-Table -AutoSize

# Test-NetConnection（更强大的网络测试）
Test-NetConnection -ComputerName blog.vichamp.com -Port 443 |
    Select-Object ComputerName, RemoteAddress, RemotePort, TcpTestSucceeded, PingSucceeded |
    Format-List

# 批量测试多台服务器的连通性
$servers = @('web-01.internal', 'db-01.internal', 'api-01.internal', 'redis-01.internal')

$results = foreach ($server in $servers) {
    $test = Test-NetConnection -ComputerName $server -WarningAction SilentlyContinue
    [PSCustomObject]@{
        Server  = $server
        IP      = $test.RemoteAddress
        Ping    = $test.PingSucceeded
        Port    = if ($test.TcpTestSucceeded) { 'Open' } else { 'Closed/Filtered' }
    }
}

$results | Format-Table -AutoSize
```

执行结果示例：

```
Address   延迟ms Status
-------   ------ ------
google.com      12 True
google.com      15 True
google.com      11 True
google.com      14 True

ComputerName      : blog.vichamp.com
RemoteAddress     : 185.199.108.153
RemotePort        : 443
TcpTestSucceeded  : True
PingSucceeded     : True

Server            IP              Ping    Port
------            --              ----    ----
web-01.internal   192.168.1.101   True    Open
db-01.internal    192.168.1.201   True    Open
api-01.internal   192.168.1.102   True    Open
redis-01.internal 192.168.1.202   False   Closed/Filtered
```

## DNS 诊断

DNS 解析问题是网络故障的高发区：

```powershell
# DNS 解析
Resolve-DnsName -Name blog.vichamp.com | Format-Table -AutoSize

# 查看所有 DNS 记录类型
Resolve-DnsName -Name contoso.com -Type ANY |
    Select-Object Name, Type, Section, Data |
    Format-Table -AutoSize

# 查看当前 DNS 服务器配置
Get-DnsClientServerAddress -AddressFamily IPv4 |
    Where-Object { $_.InterfaceAlias -notmatch 'Loopback' } |
    Select-Object InterfaceAlias, ServerAddresses |
    Format-Table -AutoSize

# 刷新 DNS 缓存
Clear-DnsClientCache
Write-Host "DNS 缓存已清除" -ForegroundColor Green

# DNS 解析对比（用不同 DNS 服务器）
function Compare-DnsResolution {
    param([string]$Domain)

    $servers = @{
        '默认'   = $null
        'Google' = '8.8.8.8'
        'Cloudflare' = '1.1.1.1'
        'AliDNS' = '223.5.5.5'
    }

    foreach ($name in $servers.Keys) {
        try {
            $params = @{ Name = $Domain }
            if ($servers[$name]) { $params.Server = $servers[$name] }

            $result = Resolve-DnsName @params -ErrorAction Stop |
                Select-Object -First 1

            [PSCustomObject]@{
                DNS服务器 = $name
                IP地址    = $result.IPAddress
                类型      = $result.Type
                TTL       = $result.TTL
            }
        } catch {
            [PSCustomObject]@{
                DNS服务器 = $name
                IP地址    = "解析失败: $($_.Exception.Message)"
            }
        }
    }
}

Compare-DnsResolution -Domain "blog.vichamp.com" | Format-Table -AutoSize
```

执行结果示例：

```
Name             Type  Section Data
----             ----  ------- ----
blog.vichamp.com CNAME Name    victorwoo.github.io

InterfaceAlias   ServerAddresses
--------------   ---------------
以太网           {192.168.1.1}

DNS服务器   IP地址          类型  TTL
---------   ------          ----  ---
默认        185.199.108.153 CNAME 3600
Google      185.199.108.153 CNAME 3600
Cloudflare  185.199.108.153 CNAME 3600
AliDNS      185.199.108.153 CNAME 3600
```

## TCP 端口扫描

```powershell
function Test-TcpPort {
    <#
    .SYNOPSIS
    测试目标主机的 TCP 端口连通性
    #>
    param(
        [Parameter(Mandatory)]
        [string]$ComputerName,

        [int[]]$Ports = @(22, 80, 443, 3389, 5985, 5986, 8080, 1433, 3306, 6379),

        [int]$TimeoutMs = 3000
    )

    $results = foreach ($port in $Ports) {
        $tcpClient = New-Object System.Net.Sockets.TcpClient
        $asyncResult = $tcpClient.BeginConnect($ComputerName, $port, $null, $null)
        $waited = $asyncResult.AsyncWaitHandle.WaitOne($TimeoutMs, $false)

        $isOpen = $false
        if ($waited) {
            try {
                $tcpClient.EndConnect($asyncResult)
                $isOpen = $true
            } catch {
                $isOpen = $false
            }
        }

        $tcpClient.Close()

        $serviceName = switch ($port) {
            22    { 'SSH' }
            80    { 'HTTP' }
            443   { 'HTTPS' }
            3389  { 'RDP' }
            5985  { 'WinRM-HTTP' }
            5986  { 'WinRM-HTTPS' }
            8080  { 'HTTP-Alt' }
            1433  { 'MSSQL' }
            3306  { 'MySQL' }
            6379  { 'Redis' }
            default { 'Unknown' }
        }

        [PSCustomObject]@{
            Port   = $port
            Service = $serviceName
            Status = if ($isOpen) { 'Open' } else { 'Closed' }
        }
    }

    $results | Format-Table -AutoSize
}

# 扫描目标服务器的常用端口
Test-TcpPort -ComputerName "192.168.1.100" -Ports @(22, 80, 443, 3389, 5985, 1433, 6379)
```

执行结果示例：

```
Port Service     Status
---- -------     ------
  22 SSH         Closed
  80 HTTP        Open
 443 HTTPS       Open
3389 RDP         Open
5985 WinRM-HTTP  Open
1433 MSSQL       Open
6379 Redis       Closed
```

## 构建一键式排障脚本

```powershell
function Invoke-NetworkTroubleshooter {
    <#
    .SYNOPSIS
    一键式网络排障脚本
    #>
    param(
        [Parameter(Mandatory)]
        [string]$Target,

        [int]$Port = 443
    )

    Write-Host "========== 网络排障：$Target ==========" -ForegroundColor Cyan

    # Step 1: DNS 解析
    Write-Host "`n[1/5] DNS 解析" -ForegroundColor Yellow
    try {
        $dns = Resolve-DnsName -Name $Target -ErrorAction Stop
        $ip = ($dns | Where-Object { $_.Type -eq 'A' } | Select-Object -First 1).IPAddress
        if (-not $ip) {
            $ip = ($dns | Select-Object -First 1).IPAddress
        }
        Write-Host "  解析结果：$Target => $ip" -ForegroundColor Green
    } catch {
        Write-Host "  DNS 解析失败：$($_.Exception.Message)" -ForegroundColor Red
        Write-Host "  建议：检查 DNS 配置或尝试使用其他 DNS 服务器" -ForegroundColor Yellow
        return
    }

    # Step 2: ICMP Ping
    Write-Host "`n[2/5] Ping 测试" -ForegroundColor Yellow
    $ping = Test-Connection -ComputerName $ip -Count 3 -Quiet
    if ($ping) {
        $latency = (Test-Connection -ComputerName $ip -Count 1).ResponseTime
        Write-Host "  Ping 成功，延迟：${latency}ms" -ForegroundColor Green
    } else {
        Write-Host "  Ping 失败（可能被防火墙阻止）" -ForegroundColor Yellow
    }

    # Step 3: TCP 端口测试
    Write-Host "`n[3/5] TCP 端口测试 ($Port)" -ForegroundColor Yellow
    $tcp = Test-NetConnection -ComputerName $ip -Port $Port -WarningAction SilentlyContinue
    if ($tcp.TcpTestSucceeded) {
        Write-Host "  端口 $Port 连接成功" -ForegroundColor Green
    } else {
        Write-Host "  端口 $Port 连接失败" -ForegroundColor Red
        Write-Host "  建议：检查防火墙规则或目标服务是否运行" -ForegroundColor Yellow
    }

    # Step 4: 路由追踪
    Write-Host "`n[4/5] 路由追踪 (tracert)" -ForegroundColor Yellow
    $trace = tracert -d -h 15 -w 1000 $ip 2>$null
    $trace | Select-Object -First 15 | ForEach-Object { Write-Host "  $_" }

    # Step 5: HTTP 测试（如果是 Web 服务）
    if ($Port -in @(80, 443, 8080, 8443)) {
        Write-Host "`n[5/5] HTTP 测试" -ForegroundColor Yellow
        $protocol = if ($Port -in @(443, 8443)) { 'https' } else { 'http' }
        try {
            $response = Invoke-WebRequest -Uri "${protocol}://${Target}" `
                -TimeoutSec 10 -UseBasicParsing -MaximumRedirection 0 -ErrorAction Stop
            Write-Host "  HTTP $($response.StatusCode) - $($response.StatusDescription)" -ForegroundColor Green
        } catch {
            $statusCode = $_.Exception.Response.StatusCode
            if ($statusCode) {
                Write-Host "  HTTP $([int]$statusCode) - $($statusCode)" -ForegroundColor Yellow
            } else {
                Write-Host "  HTTP 请求失败：$($_.Exception.Message)" -ForegroundColor Red
            }
        }
    }

    Write-Host "`n========== 排障完成 ==========" -ForegroundColor Cyan
}

# 一键排查网络问题
Invoke-NetworkTroubleshooter -Target "blog.vichamp.com" -Port 443
```

执行结果示例：

```
========== 网络排障：blog.vichamp.com ==========

[1/5] DNS 解析
  解析结果：blog.vichamp.com => 185.199.108.153

[2/5] Ping 测试
  Ping 成功，延迟：45ms

[3/5] TCP 端口测试 (443)
  端口 443 连接成功

[4/5] 路由追踪 (tracert)
  1    <1 ms    <1 ms    <1 ms  192.168.1.1
  2     5 ms     3 ms     3 ms  10.0.0.1
  ...

[5/5] HTTP 测试
  HTTP 200 - OK

========== 排障完成 ==========
```

## 注意事项

1. **防火墙影响**：ICMP ping 被阻止不代表服务不可用，始终结合 TCP 端口测试判断
2. **DNS 缓存**：排查 DNS 问题时先执行 `Clear-DnsClientCache` 清除缓存
3. **超时设置**：给网络测试设置合理的超时，避免脚本无限等待
4. **IPv4/IPv6**：某些环境可能有 IPv6 相关问题，使用 `-AddressFamily IPv4` 强制使用 IPv4
5. **权限要求**：部分网络诊断命令（如路由追踪）需要管理员权限
6. **安全合规**：端口扫描功能仅用于授权的网络诊断和安全审计，不得用于未授权的扫描
