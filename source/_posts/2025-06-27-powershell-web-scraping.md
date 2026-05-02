---
layout: post
date: 2025-06-27 08:00:00
updated: 2025-06-27 08:00:00
title: "PowerShell 技能连载 - Web 数据采集"
description: PowerTip of the Day - Web Data Scraping in PowerShell
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
- web-scraping
- html-parsing
- browser-automation
---

_适用于 PowerShell 5.1 及以上版本_

运维和开发中经常需要从网页获取数据——监控服务状态页、采集系统指标、下载最新版本的工具、从内部管理平台提取报表。PowerShell 内置的 `Invoke-WebRequest` 可以发送 HTTP 请求并解析 HTML，结合正则表达式和 HTML 解析能力，可以高效完成大部分数据采集任务。

本文将讲解 HTTP 请求、HTML 解析、表单提交、会话管理，以及浏览器自动化技术。

<!-- more -->

## HTTP 请求基础

```powershell
# 基本 GET 请求
$response = Invoke-WebRequest -Uri "https://httpbin.org/get" -UseBasicParsing
Write-Host "状态码：$($response.StatusCode)"
Write-Host "内容长度：$($response.Content.Length) bytes"

# 解析 JSON 响应
$json = $response.Content | ConvertFrom-Json
Write-Host "来源 IP：$($json.origin)"
Write-Host "User-Agent：$($json.headers.'User-Agent')"

# 自定义请求头
$headers = @{
    "User-Agent"      = "PowerShell/7.4 (OpsBot)"
    "Accept"          = "application/json"
    "X-Custom-Header" = "monitoring"
}

$response = Invoke-WebRequest -Uri "https://httpbin.org/headers" `
    -Headers $headers -UseBasicParsing
$json = $response.Content | ConvertFrom-Json
$json.headers | Format-Table -AutoSize

# POST 请求（JSON 数据）
$body = @{
    hostname = $env:COMPUTERNAME
    status   = "healthy"
    uptime   = (Get-CimInstance Win32_OperatingSystem).LastBootUpTime.ToString("o")
} | ConvertTo-Json

$response = Invoke-WebRequest -Uri "https://httpbin.org/post" `
    -Method Post `
    -ContentType "application/json; charset=utf-8" `
    -Body ([System.Text.Encoding]::UTF8.GetBytes($body)) `
    -UseBasicParsing

Write-Host "POST 响应：$($response.StatusCode)"
```

执行结果示例：

```
状态码：200
内容长度：356 bytes
来源 IP：203.0.113.42
User-Agent：PowerShell/7.4 (OpsBot)

Host            User-Agent               X-Custom-Header
----            ----------               ---------------
httpbin.org     PowerShell/7.4 (OpsBot)  monitoring

POST 响应：200
```

## HTML 解析

```powershell
# 解析 HTML 页面提取链接
function Get-WebLinks {
    param(
        [Parameter(Mandatory)]
        [string]$Url,
        [string]$Pattern = ".*"
    )

    $response = Invoke-WebRequest -Uri $Url -UseBasicParsing

    # 从 HTML 中提取所有链接
    $links = [regex]::Matches($response.Content, 'href=["''](https?://[^"'']+)["'']') |
        ForEach-Object { $_.Groups[1].Value } |
        Where-Object { $_ -match $Pattern } |
        Sort-Object -Unique

    return $links
}

# 提取页面中的所有下载链接
$downloadLinks = Get-WebLinks -Url "https://example.com/downloads" -Pattern "\.msi$|\.zip$|\.exe$"
$downloadLinks | ForEach-Object { Write-Host "  $_" -ForegroundColor Cyan }

# 使用 HTML 解析提取表格数据
function Get-HtmlTable {
    param(
        [Parameter(Mandatory)]
        [string]$Url,
        [int]$TableIndex = 0
    )

    $response = Invoke-WebRequest -Uri $Url -UseBasicParsing
    $html = $response.Content

    # 提取表格行
    $rows = [regex]::Matches($html, '<tr[^>]*>(.*?)</tr>', [System.Text.RegularExpressions.RegexOptions]::Singleline)

    $tableData = foreach ($row in $rows) {
        $cells = [regex]::Matches($row.Groups[1].Value, '<t[dh][^>]*>(.*?)</t[dh]>', [System.Text.RegularExpressions.RegexOptions]::Singleline)
        $cellValues = $cells | ForEach-Object {
            # 去除 HTML 标签
            $val = $_.Groups[1].Value -replace '<[^>]+>', ''
            $val.Trim()
        }
        if ($cellValues) {
            $cellValues -join '|'
        }
    }

    return $tableData
}

$tableData = Get-HtmlTable -Url "https://example.com/status"
$tableData | ForEach-Object { Write-Host $_ }
```

执行结果示例：

```
  https://example.com/downloads/tool-v3.2.1.msi
  https://example.com/downloads/tool-v3.2.1.zip

服务名|状态|响应时间
Auth-Service|Running|45ms
API-Gateway|Running|23ms
Worker-01|Stopped|N/A
```

## 会话管理与认证

```powershell
# 使用 WebRequestSession 维持会话
$session = [Microsoft.PowerShell.Commands.WebRequestSession]::new()
$session.UserAgent = "PowerShell-OpsBot/1.0"

# 模拟登录（第一步：获取登录页面）
$loginPage = Invoke-WebRequest -Uri "https://example.com/login" `
    -WebSession $session -UseBasicParsing

# 提取 CSRF Token
$csrfToken = if ($loginPage.Content -match 'name="csrf_token"\s+value="([^"]+)"') {
    $Matches[1]
} else {
    ""
}

# 第二步：提交登录表单
$loginBody = @{
    username   = "admin"
    password   = "P@ssw0rd123"
    csrf_token = $csrfToken
}

$loginResponse = Invoke-WebRequest -Uri "https://example.com/login" `
    -Method Post `
    -Body $loginBody `
    -WebSession $session `
    -UseBasicParsing

Write-Host "登录状态：$($loginResponse.StatusCode)"

# 第三步：使用会话访问受保护页面
$dashboard = Invoke-WebRequest -Uri "https://example.com/dashboard" `
    -WebSession $session -UseBasicParsing

Write-Host "仪表板内容长度：$($dashboard.Content.Length) bytes"

# Bearer Token 认证
$token = $env:API_TOKEN
$protectedData = Invoke-RestMethod -Uri "https://api.example.com/v1/status" `
    -Headers @{ "Authorization" = "Bearer $token" }

$protectedData | Format-Table -AutoSize
```

执行结果示例：

```
登录状态：200
仪表板内容长度：45230 bytes

Service          Status    Uptime
-------          ------    ------
auth-service     Running   45d 12h
api-gateway      Running   45d 12h
worker-01        Running   30d 8h
```

## 监控网页状态

```powershell
function Test-WebPageHealth {
    <#
    .SYNOPSIS
    监控网页可用性和关键内容
    #>
    param(
        [Parameter(Mandatory)]
        [string[]]$Urls,

        [string]$ExpectedContent = "",

        [int]$TimeoutSeconds = 10
    )

    $results = foreach ($url in $Urls) {
        $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()

        try {
            $response = Invoke-WebRequest -Uri $url `
                -TimeoutSec $TimeoutSeconds `
                -UseBasicParsing `
                -ErrorAction Stop

            $stopwatch.Stop()

            $contentOk = if ($ExpectedContent) {
                $response.Content -match [regex]::Escape($ExpectedContent)
            } else {
                $true
            }

            [PSCustomObject]@{
                Url          = $url
                Status       = $response.StatusCode
                LatencyMs    = $stopwatch.ElapsedMilliseconds
                ContentMatch = $contentOk
                ContentLen   = $response.Content.Length
                Timestamp    = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
            }
        } catch {
            $stopwatch.Stop()
            [PSCustomObject]@{
                Url          = $url
                Status       = "Error"
                LatencyMs    = $stopwatch.ElapsedMilliseconds
                ContentMatch = $false
                ContentLen   = 0
                Timestamp    = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
            }
        }
    }

    $results | Format-Table -AutoSize

    $failed = $results | Where-Object { $_.Status -ne 200 -or -not $_.ContentMatch }
    if ($failed) {
        Write-Host "`n告警：$($failed.Count) 个页面异常" -ForegroundColor Red
        $failed | ForEach-Object { Write-Host "  $($_.Url) - Status: $($_.Status)" -ForegroundColor Red }
    }
}

# 监控多个服务端点
Test-WebPageHealth -Urls @(
    "https://blog.vichamp.com"
    "https://api.example.com/health"
    "https://portal.example.com"
) -ExpectedContent "OK"
```

执行结果示例：

```
Url                              Status LatencyMs ContentMatch ContentLen Timestamp
---                              ------ --------- ------------ ---------- ---------
https://blog.vichamp.com         200          245         True      52301 2025-06-27 09:15:30
https://api.example.com/health   200          128         True        256 2025-06-27 09:15:31
https://portal.example.com       Error          0        False          0 2025-06-27 09:15:41

告警：1 个页面异常
  https://portal.example.com - Status: Error
```

## 文件下载管理

```powershell
function Start-FileDownload {
    <#
    .SYNOPSIS
    带进度显示的文件下载
    #>
    param(
        [Parameter(Mandatory)]
        [string]$Url,

        [string]$OutputPath = (Join-Path $PWD (Split-Path $Url -Leaf)),

        [int]$TimeoutSeconds = 300
    )

    Write-Host "下载：$Url" -ForegroundColor Cyan
    Write-Host "保存到：$OutputPath"

    try {
        $response = Invoke-WebRequest -Uri $Url -OutFile $OutputPath `
            -TimeoutSec $TimeoutSeconds -UseBasicParsing -PassThru

        $file = Get-Item $OutputPath
        $sizeMB = [math]::Round($file.Length / 1MB, 2)
        Write-Host "下载完成：$sizeMB MB" -ForegroundColor Green

        return $OutputPath
    } catch {
        Write-Host "下载失败：$($_.Exception.Message)" -ForegroundColor Red
        return $null
    }
}

# 批量下载
$files = @(
    @{ Url = "https://example.com/data/report-june.csv"; Name = "report-june.csv" },
    @{ Url = "https://example.com/data/report-may.csv";  Name = "report-may.csv" }
)

$downloadDir = "C:\Downloads\reports"
New-Item $downloadDir -ItemType Directory -Force | Out-Null

foreach ($file in $files) {
    $output = Join-Path $downloadDir $file.Name
    Start-FileDownload -Url $file.Url -OutputPath $output
}
```

执行结果示例：

```
下载：https://example.com/data/report-june.csv
保存到：C:\Downloads\reports\report-june.csv
下载完成：2.35 MB
下载：https://example.com/data/report-may.csv
保存到：C:\Downloads\reports\report-may.csv
下载完成：1.87 MB
```

## 注意事项

1. **遵守 robots.txt**：采集前检查目标网站的 robots.txt 和使用条款，尊重爬取规则
2. **请求频率**：添加合理的 `Start-Sleep` 间隔，避免对目标服务器造成压力
3. **编码处理**：网页编码可能不一致，使用 `-UseBasicParsing` 并手动处理编码
4. **证书验证**：内网自签名证书环境使用 `-SkipCertificateCheck`（PowerShell 7+）
5. **数据敏感**：采集到的数据可能包含敏感信息，注意脱敏和存储安全
6. **User-Agent**：设置合理的 User-Agent，部分网站会屏蔽默认的 PowerShell UA
