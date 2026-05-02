---
layout: post
date: 2025-07-23 08:00:00
updated: 2025-07-23 08:00:00
title: "PowerShell 技能连载 - REST API 设计与实现"
description: PowerTip of the Day - REST API Design and Implementation in PowerShell
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
- rest-api
- http
- web-server
- api
---

_适用于 PowerShell 7.0 及以上版本_

PowerShell 不仅能调用 API，还能**创建** API。`Polaris`、`Pode` 等模块让 PowerShell 可以快速搭建 Web 服务器，处理 HTTP 请求。虽然不建议用 PowerShell 替代专业的 Web 框架，但在内网工具、运维自动化接口、轻量级中间服务等场景中，PowerShell API 服务器非常实用——快速实现一个健康检查接口、暴露系统信息给监控平台、提供配置查询 API。

本文将讲解如何使用 PowerShell 构建轻量级 REST API 服务。

<!-- more -->

## 使用 Pode 搭建 API

```powershell
# 安装 Pode 模块
Install-Module -Name Pode -Force -Scope CurrentUser

# 创建 API 服务器脚本
$startApi = {
    Start-PodeServer {
        Add-PodeEndpoint -Address localhost -Port 8080 -Protocol Http

        # 日志中间件
        Add-PodeMiddleware -Name 'Logger' -ScriptBlock {
            $timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
            $method = $WebEvent.Method
            $path = $WebEvent.Path
            Write-PodeHost "[$timestamp] $method $path"
        }

        # GET /api/health —— 健康检查
        Add-PodeRoute -Method Get -Path '/api/health' -ScriptBlock {
            $os = Get-CimInstance Win32_OperatingSystem
            $cpu = Get-CimInstance Win32_Processor | Select-Object -First 1
            $uptime = [math]::Round(((Get-Date) - $os.LastBootUpTime).TotalDays, 1)

            Write-PodeJsonResponse -Value @{
                status    = 'healthy'
                timestamp = (Get-Date).ToString('yyyy-MM-ddTHH:mm:ss')
                computer  = $env:COMPUTERNAME
                uptime    = "$uptime 天"
                cpuUsage  = "$($cpu.LoadPercentage)%"
                memoryUsage = "$([math]::Round(($os.TotalVisibleMemorySize - $os.FreePhysicalMemory) / $os.TotalVisibleMemorySize * 100, 1))%"
            }
        }

        # GET /api/processes —— 进程列表
        Add-PodeRoute -Method Get -Path '/api/processes' -ScriptBlock {
            $top = if ($WebEvent.Query['top']) { [int]$WebEvent.Query['top'] } else { 10 }
            $sortBy = if ($WebEvent.Query['sort']) { $WebEvent.Query['sort'] } else { 'Memory' }

            $processes = Get-Process | Sort-Object WorkingSet64 -Descending |
                Select-Object -First $top |
                ForEach-Object {
                    @{
                        name     = $_.Name
                        pid      = $_.Id
                        memoryMB = [math]::Round($_.WorkingSet64 / 1MB, 1)
                        cpu      = [math]::Round($_.CPU, 2)
                    }
                }

            Write-PodeJsonResponse -Value @{
                count = $processes.Count
                data  = $processes
            }
        }

        # GET /api/disks —— 磁盘信息
        Add-PodeRoute -Method Get -Path '/api/disks' -ScriptBlock {
            $disks = Get-CimInstance Win32_LogicalDisk -Filter "DriveType=3" |
                ForEach-Object {
                    $totalGB = [math]::Round($_.Size / 1GB, 2)
                    $freeGB = [math]::Round($_.FreeSpace / 1GB, 2)
                    @{
                        drive     = $_.DeviceID
                        totalGB   = $totalGB
                        freeGB    = $freeGB
                        usagePct  = [math]::Round(($_.Size - $_.FreeSpace) / $_.Size * 100, 1)
                    }
                }

            Write-PodeJsonResponse -Value @{ data = $disks }
        }
    }
}

Write-Host "API 服务器启动中..." -ForegroundColor Cyan
Write-Host "端点：" -ForegroundColor Yellow
Write-Host "  GET http://localhost:8080/api/health" -ForegroundColor Green
Write-Host "  GET http://localhost:8080/api/processes?top=5" -ForegroundColor Green
Write-Host "  GET http://localhost:8080/api/disks" -ForegroundColor Green
```

执行结果示例：

```
API 服务器启动中...
端点：
  GET http://localhost:8080/api/health
  GET http://localhost:8080/api/processes?top=5
  GET http://localhost:8080/api/disks
[2025-07-23 08:30:15] GET /api/health
```

## POST 接口与请求处理

```powershell
# 在同一 Pode 服务器中添加 POST 接口
$apiWithPost = {
    Start-PodeServer {
        Add-PodeEndpoint -Address localhost -Port 8081 -Protocol Http

        # POST /api/execute —— 执行命令（需要认证）
        Add-PodeRoute -Method Post -Path '/api/execute' -ScriptBlock {
            $body = $WebEvent.Data

            if (-not $body.command) {
                Set-PodeResponseStatus -Code 400
                Write-PodeJsonResponse -Value @{ error = '缺少 command 参数' }
                return
            }

            # 安全限制：只允许特定命令
            $allowed = @('Get-Process', 'Get-Service', 'Get-EventLog', 'Get-CimInstance')
            $cmdName = ($body.command -split '\s+')[0]
            if ($cmdName -notin $allowed) {
                Set-PodeResponseStatus -Code 403
                Write-PodeJsonResponse -Value @{ error = "命令不允许：$cmdName" }
                return
            }

            try {
                $result = Invoke-Expression $body.command -ErrorAction Stop
                $jsonResult = $result | ConvertTo-Json -Depth 3 -Compress

                Write-PodeJsonResponse -Value @{
                    success = $true
                    command = $body.command
                    result  = $result
                }
            } catch {
                Set-PodeResponseStatus -Code 500
                Write-PodeJsonResponse -Value @{
                    success = $false
                    error   = $_.Exception.Message
                }
            }
        }

        # POST /api/alert —— 接收告警
        Add-PodeRoute -Method Post -Path '/api/alert' -ScriptBlock {
            $body = $WebEvent.Data

            $alertInfo = @{
                timestamp  = (Get-Date).ToString('yyyy-MM-ddTHH:mm:ss')
                source     = $body.source
                level      = $body.level
                message    = $body.message
                hostname   = $body.hostname
                receivedAt = Get-Date -Format 'HH:mm:ss'
            }

            # 记录到文件
            $alertInfo | ConvertTo-Json | Add-Content "C:\Logs\alerts.json" -Encoding UTF8

            Write-PodeJsonResponse -Value @{
                received = $true
                id       = [guid]::NewGuid().ToString()
            }
        }

        # GET /api/alerts —— 查询告警
        Add-PodeRoute -Method Get -Path '/api/alerts' -ScriptBlock {
            $count = if ($WebEvent.Query['count']) { [int]$WebEvent.Query['count'] } else { 10 }
            $level = $WebEvent.Query['level']

            if (Test-Path "C:\Logs\alerts.json") {
                $alerts = Get-Content "C:\Logs\alerts.json" -Tail $count |
                    ConvertFrom-Json |
                    Where-Object { if ($level) { $_.level -eq $level } else { $true } }

                Write-PodeJsonResponse -Value @{
                    count = $alerts.Count
                    data  = $alerts
                }
            } else {
                Write-PodeJsonResponse -Value @{ count = 0; data = @() }
            }
        }
    }
}
```

执行结果示例：

```
# 调用 POST 接口
$body = @{ command = "Get-Process | Select-Object -First 3 Name,Id" } | ConvertTo-Json
Invoke-RestMethod -Uri "http://localhost:8081/api/execute" -Method Post -Body $body -ContentType "application/json"

# 发送告警
$alert = @{
    source   = "monitor"
    level    = "ERROR"
    message  = "磁盘空间不足"
    hostname = "SRV01"
} | ConvertTo-Json
Invoke-RestMethod -Uri "http://localhost:8081/api/alert" -Method Post -Body $alert -ContentType "application/json"
```

## API 客户端封装

```powershell
# 封装为可复用的 API 客户端函数
function Get-ServerHealth {
    param([string]$ServerUrl = "http://localhost:8080")

    try {
        $response = Invoke-RestMethod -Uri "$ServerUrl/api/health" -TimeoutSec 5
        return $response
    } catch {
        Write-Host "健康检查失败：$($_.Exception.Message)" -ForegroundColor Red
        return $null
    }
}

function Get-ServerProcesses {
    param(
        [string]$ServerUrl = "http://localhost:8080",
        [int]$Top = 10
    )

    return Invoke-RestMethod -Uri "$ServerUrl/api/processes?top=$Top" -TimeoutSec 10
}

# 批量检查多台服务器
$servers = @(
    "http://web-01:8080",
    "http://web-02:8080",
    "http://db-01:8080"
)

Write-Host "集群健康检查：" -ForegroundColor Cyan
foreach ($server in $servers) {
    $health = Get-ServerHealth -ServerUrl $server
    if ($health) {
        $status = $health.status
        $color = if ($status -eq "healthy") { "Green" } else { "Red" }
        Write-Host "  $server : $status (CPU: $($health.cpuUsage), MEM: $($health.memoryUsage))" -ForegroundColor $color
    } else {
        Write-Host "  $server : 不可达" -ForegroundColor Red
    }
}
```

执行结果示例：

```
集群健康检查：
  http://web-01:8080 : healthy (CPU: 35%, MEM: 72.4%)
  http://web-02:8080 : healthy (CPU: 28%, MEM: 65.1%)
  http://db-01:8080 : healthy (CPU: 42%, MEM: 85.3%)
```

## 注意事项

1. **安全风险**：暴露命令执行接口极度危险，生产环境必须加认证、限白名单、审计日志
2. **性能限制**：PowerShell HTTP 服务器性能有限，不适合高并发场景（建议使用反向代理）
3. **认证**：生产 API 必须添加认证（API Key、JWT、Basic Auth），Pode 内置认证中间件
4. **HTTPS**：生产环境使用 HTTPS，Pode 支持自签名证书和 Let's Encrypt
5. **服务化**：长期运行的 API 应注册为 Windows 服务，使用 `nssm` 或 `Register-PodeService`
6. **错误处理**：API 接口必须有完善的错误处理和统一的错误响应格式
