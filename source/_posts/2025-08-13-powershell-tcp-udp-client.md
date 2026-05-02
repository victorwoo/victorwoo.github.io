---
layout: post
date: 2025-08-13 08:00:00
updated: 2025-08-13 08:00:00
title: "PowerShell 技能连载 - TCP/UDP 网络客户端"
description: PowerTip of the Day - TCP/UDP Network Client Programming in PowerShell
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
- tcp
- udp
- network
- socket
---

_适用于 PowerShell 5.1 及以上版本_

虽然 `Invoke-WebRequest` 和 `Invoke-RestMethod` 可以处理 HTTP 请求，但很多网络协议不走 HTTP——Redis、MySQL、SMTP、自定义 TCP 协议等。通过 .NET 的 `System.Net.Sockets` 命名空间，PowerShell 可以直接操作 TCP/UDP Socket，实现底层网络通信。这对于端口探测、协议测试、自定义服务监控等场景非常有用。

本文将讲解 PowerShell 中的 TCP/UDP 客户端编程和实用的网络工具。

<!-- more -->

## TCP 客户端

```powershell
# 基本 TCP 连接
function Send-TcpMessage {
    param(
        [Parameter(Mandatory)]
        [string]$Server,

        [Parameter(Mandatory)]
        [int]$Port,

        [string]$Message,

        [int]$TimeoutMs = 5000
    )

    $client = [System.Net.Sockets.TcpClient]::new()
    try {
        $connectTask = $client.ConnectAsync($Server, $Port)
        $connectTask.Wait($TimeoutMs) | Out-Null

        if (-not $client.Connected) {
            throw "连接超时"
        }

        $stream = $client.GetStream()
        $writer = [System.IO.StreamWriter]::new($stream)
        $reader = [System.IO.StreamReader]::new($stream)
        $writer.AutoFlush = $true

        if ($Message) {
            $writer.WriteLine($Message)
        }

        Start-Sleep -Milliseconds 500

        if ($stream.DataAvailable) {
            $response = $reader.ReadToEnd()
            return $response
        }
    } finally {
        $client.Close()
    }
}

# 测试 TCP 端口连通性
function Test-TcpPort {
    param(
        [Parameter(Mandatory)]
        [string]$ComputerName,

        [Parameter(Mandatory)]
        [int]$Port,

        [int]$TimeoutMs = 3000
    )

    $client = [System.Net.Sockets.TcpClient]::new()
    $sw = [System.Diagnostics.Stopwatch]::StartNew()

    try {
        $connectTask = $client.ConnectAsync($ComputerName, $Port)
        $connectTask.Wait($TimeoutMs) | Out-Null

        $sw.Stop()
        $success = $client.Connected

        return [PSCustomObject]@{
            Computer  = $ComputerName
            Port      = $Port
            IsOpen    = $success
            LatencyMs = $sw.ElapsedMilliseconds
        }
    } catch {
        $sw.Stop()
        return [PSCustomObject]@{
            Computer  = $ComputerName
            Port      = $Port
            IsOpen    = $false
            LatencyMs = $sw.ElapsedMilliseconds
        }
    } finally {
        $client.Close()
    }
}

# 批量端口扫描
$targets = @(
    @{ Host = "google.com"; Ports = @(80, 443, 8080) },
    @{ Host = "github.com"; Ports = @(22, 80, 443) }
)

foreach ($target in $targets) {
    Write-Host "$($target.Host)：" -ForegroundColor Cyan
    foreach ($port in $target.Ports) {
        $result = Test-TcpPort -ComputerName $target.Host -Port $port
        $status = if ($result.IsOpen) { "OPEN" } else { "CLOSED" }
        $color = if ($result.IsOpen) { "Green" } else { "Red" }
        Write-Host "  Port $($result.Port) : $status ($($result.LatencyMs)ms)" -ForegroundColor $color
    }
}
```

执行结果示例：

```
google.com：
  Port 80 : OPEN (25ms)
  Port 443 : OPEN (22ms)
  Port 8080 : CLOSED (3003ms)
github.com：
  Port 22 : OPEN (45ms)
  Port 80 : OPEN (30ms)
  Port 443 : OPEN (28ms)
```

## UDP 客户端

```powershell
# UDP 客户端
function Send-UdpMessage {
    param(
        [Parameter(Mandatory)]
        [string]$Server,

        [Parameter(Mandatory)]
        [int]$Port,

        [Parameter(Mandatory)]
        [string]$Message,

        [int]$TimeoutMs = 3000
    )

    $client = [System.Net.Sockets.UdpClient]::new()
    try {
        $client.Connect($Server, $Port)
        $bytes = [System.Text.Encoding]::UTF8.GetBytes($Message)
        $client.Send($bytes, $bytes.Length) | Out-Null

        # 等待响应（UDP 不保证有响应）
        $client.Client.ReceiveTimeout = $TimeoutMs
        $remoteEP = [System.Net.IPEndPoint]::new([System.Net.IPAddress]::Any, 0)
        $response = $client.Receive([ref]$remoteEP)

        return [System.Text.Encoding]::UTF8.GetString($response)
    } catch {
        return $null
    } finally {
        $client.Close()
    }
}

# DNS 查询示例（使用 System.Net）
function Resolve-DnsFast {
    param([Parameter(Mandatory)][string]$Hostname)

    try {
        $addresses = [System.Net.Dns]::GetHostAddresses($Hostname)
        foreach ($addr in $addresses) {
            [PSCustomObject]@{
                Hostname = $Hostname
                Address  = $addr.ToString()
                Family   = $addr.AddressFamily
            }
        }
    } catch {
        Write-Host "解析失败：$Hostname" -ForegroundColor Red
    }
}

Resolve-DnsFast -Hostname "www.microsoft.com" | Format-Table -AutoSize
```

执行结果示例：

```
Hostname         Address           Family
--------         -------           ------
www.microsoft.com 20.190.159.2   InterNetwork
www.microsoft.com 2603:1030:20... InterNetworkV6
```

## 端口监控工具

```powershell
# 服务端口监控
function Test-ServicePorts {
    param(
        [PSCustomObject[]]$Services = @(
            @{ Name = "Web"; Host = "localhost"; Port = 80 },
            @{ Name = "HTTPS"; Host = "localhost"; Port = 443 },
            @{ Name = "SSH"; Host = "localhost"; Port = 22 },
            @{ Name = "MySQL"; Host = "localhost"; Port = 3306 },
            @{ Name = "Redis"; Host = "localhost"; Port = 6379 }
        )
    )

    $results = foreach ($svc in $Services) {
        $test = Test-TcpPort -ComputerName $svc.Host -Port $svc.Port -TimeoutMs 2000
        [PSCustomObject]@{
            Service = $svc.Name
            Host    = $svc.Host
            Port    = $svc.Port
            Status  = if ($test.IsOpen) { "Listening" } else { "Closed" }
            Latency = "$($test.LatencyMs)ms"
        }
    }

    $results | Format-Table -AutoSize

    $closed = $results | Where-Object { $_.Status -eq "Closed" }
    if ($closed) {
        Write-Host "告警：$($closed.Count) 个端口未监听" -ForegroundColor Red
        $closed | ForEach-Object {
            Write-Host "  $($_.Service) ($($_.Host):$($_.Port))" -ForegroundColor Red
        }
    }
}

Test-ServicePorts
```

执行结果示例：

```
Service Host     Port Status    Latency
------- ----     ---- ------    -------
Web     localhost   80 Listening 1ms
HTTPS   localhost  443 Listening 1ms
SSH     localhost   22 Closed    2002ms
MySQL   localhost 3306 Listening 2ms
Redis   localhost 6379 Listening 1ms

告警：1 个端口未监听
  SSH (localhost:22)
```

## SMTP 邮件探测

```powershell
# SMTP 协议探测
function Test-SmtpServer {
    param(
        [Parameter(Mandatory)]
        [string]$Server,

        [int]$Port = 25,

        [int]$TimeoutMs = 10000
    )

    $client = [System.Net.Sockets.TcpClient]::new()
    try {
        $client.Connect($Server, $Port)
        $stream = $client.GetStream()
        $reader = [System.IO.StreamReader]::new($stream)
        $writer = [System.IO.StreamWriter]::new($stream)
        $writer.AutoFlush = $true

        $client.Client.ReceiveTimeout = $TimeoutMs

        # 读取欢迎信息
        $banner = $reader.ReadLine()
        Write-Host "SMTP Banner：$banner" -ForegroundColor Cyan

        # 发送 EHLO
        $writer.WriteLine("EHLO test.local")
        Start-Sleep -Milliseconds 500
        while ($stream.DataAvailable) {
            $line = $reader.ReadLine()
            Write-Host "  $line" -ForegroundColor DarkGray
        }

        # 发送 QUIT
        $writer.WriteLine("QUIT")
        $bye = $reader.ReadLine()
        Write-Host "  $bye" -ForegroundColor DarkGray

        return $true
    } catch {
        Write-Host "SMTP 连接失败：$($_.Exception.Message)" -ForegroundColor Red
        return $false
    } finally {
        $client.Close()
    }
}

Test-SmtpServer -Server "mail.contoso.com" -Port 25
```

执行结果示例：

```
SMTP Banner：220 mail.contoso.com ESMTP Postfix
  250-mail.contoso.com
  250-PIPELINING
  250-SIZE 10240000
  250-STARTTLS
  250-AUTH PLAIN LOGIN
  250 ENHANCEDSTATUSCODES
  221 2.0.0 Bye
```

## 注意事项

1. **防火墙**：TCP/UDP 连接可能被防火墙阻止，超时不代表端口真正关闭
2. **资源释放**：TcpClient 和 UdpClient 必须调用 `Close()` 或使用 `try/finally` 确保释放
3. **超时设置**：默认超时可能很长，显式设置 `ReceiveTimeout` 和 `ConnectTimeout`
4. **UDP 不可靠**：UDP 不保证消息送达和顺序，适合 DNS、SNMP 等简单查询
5. **IPv6**：现代系统可能返回 IPv6 地址，使用 `[System.Net.IPAddress]::Any` 监听所有地址
6. **端口扫描**：批量端口扫描可能触发安全告警，仅在授权环境下使用
