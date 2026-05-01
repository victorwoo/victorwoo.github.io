---
layout: post
date: 2025-06-20 08:00:00
title: "PowerShell 技能连载 - HTML 报告生成"
description: PowerTip of the Day - HTML Report Generation in PowerShell
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
- html
- reporting
- css
---

_适用于 PowerShell 5.1 及以上版本_

运维报告是沟通技术状态的桥梁——无论是每日健康检查报告、月度容量报告还是安全审计报告，格式清晰、内容直观的 HTML 报告远比纯文本或截图有效。PowerShell 的 `ConvertTo-Html` 命令可以将任何对象集合转为 HTML 表格，结合自定义 CSS 样式和 Here-String 模板，可以快速生成专业级的报告。

本文将讲解 HTML 报告的生成技巧、样式定制、邮件发送，以及实用的报告模板。

## 基础 HTML 报告

```powershell
# 使用 ConvertTo-Html 生成简单报告
$processes = Get-Process | Sort-Object WorkingSet64 -Descending | Select-Object -First 10

$htmlReport = $processes | Select-Object Name, Id,
    @{N='内存MB'; E={[math]::Round($_.WorkingSet64/1MB, 1)}},
    @{N='CPU(s)'; E={[math]::Round($_.CPU, 2)}} |
    ConvertTo-Html -Title "进程报告" -Property Name, Id, '内存MB', 'CPU(s)'

$htmlReport | Set-Content "C:\Reports\processes.html" -Encoding UTF8
Write-Host "报告已生成" -ForegroundColor Green
```

执行结果示例：

```
报告已生成
```

## 带样式的完整报告

```powershell
function New-DailyHealthReport {
    <#
    .SYNOPSIS
    生成每日系统健康 HTML 报告
    #>
    param(
        [string]$OutputPath = "C:\Reports\daily-health.html"
    )

    # 采集数据
    $os = Get-CimInstance Win32_OperatingSystem
    $cpu = Get-CimInstance Win32_Processor | Select-Object -First 1
    $disks = Get-CimInstance Win32_LogicalDisk -Filter "DriveType=3"
    $topProcesses = Get-Process | Sort-Object WorkingSet64 -Descending |
        Select-Object -First 10
    $services = Get-Service | Where-Object {
        $_.StartType -eq 'Automatic' -and $_.Status -ne 'Running'
    }

    # CSS 样式
    $css = @"
<style>
    body { font-family: 'Segoe UI', Arial, sans-serif; margin: 20px; background: #f5f6fa; color: #2d3436; }
    .container { max-width: 1200px; margin: 0 auto; }
    h1 { color: #2d3436; border-bottom: 3px solid #0984e3; padding-bottom: 10px; }
    h2 { color: #636e72; margin-top: 30px; border-left: 4px solid #0984e3; padding-left: 10px; }
    .summary { display: flex; flex-wrap: wrap; gap: 15px; margin: 20px 0; }
    .card { background: white; border-radius: 8px; padding: 20px; box-shadow: 0 2px 8px rgba(0,0,0,0.1); min-width: 200px; flex: 1; }
    .card .label { font-size: 12px; color: #b2bec3; text-transform: uppercase; }
    .card .value { font-size: 28px; font-weight: bold; color: #0984e3; margin-top: 5px; }
    .card.warning .value { color: #fdcb6e; }
    .card.danger .value { color: #d63031; }
    table { width: 100%; border-collapse: collapse; background: white; border-radius: 8px; overflow: hidden;
            box-shadow: 0 2px 8px rgba(0,0,0,0.1); margin: 10px 0; }
    th { background: #0984e3; color: white; padding: 12px 15px; text-align: left; font-size: 13px; }
    td { padding: 10px 15px; border-bottom: 1px solid #dfe6e9; }
    tr:hover { background: #f0f8ff; }
    .bar { height: 8px; background: #dfe6e9; border-radius: 4px; overflow: hidden; min-width: 80px; }
    .bar-fill { height: 100%; border-radius: 4px; }
    .good { background: #00b894; }
    .warning { background: #fdcb6e; }
    .danger { background: #d63031; }
    .footer { text-align: center; color: #b2bec3; margin-top: 30px; font-size: 12px; }
    .status-badge { padding: 3px 10px; border-radius: 12px; font-size: 12px; font-weight: bold; }
    .status-ok { background: #e8f5e9; color: #27ae60; }
    .status-error { background: #ffebee; color: #c0392b; }
</style>
"@

    # 构建报告
    $report = @"
<!DOCTYPE html>
<html lang="zh-CN">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>系统健康报告 - $($os.CSName)</title>
    $css
</head>
<body>
    <div class="container">
        <h1>系统健康报告</h1>
        <p>计算机：<strong>$($os.CSName)</strong> | 操作系统：$($os.Caption) |
           报告时间：$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')</p>

        <div class="summary">
            <div class="card">
                <div class="label">CPU 使用率</div>
                <div class="value">$($cpu.LoadPercentage)%</div>
            </div>
            <div class="card">
                <div class="label">内存使用率</div>
                <div class="value">$([math]::Round(($os.TotalVisibleMemorySize - $os.FreePhysicalMemory) / $os.TotalVisibleMemorySize * 100, 1))%</div>
            </div>
            <div class="card">
                <div class="label">运行时间</div>
                <div class="value">$([math]::Round(((Get-Date) - $os.LastBootUpTime).TotalDays, 1)) 天</div>
            </div>
            <div class="card">
                <div class="label">异常服务</div>
                <div class="value">$($services.Count)</div>
            </div>
        </div>

        <h2>磁盘状态</h2>
        <table>
            <tr><th>驱动器</th><th>文件系统</th><th>总容量</th><th>已使用</th><th>可用</th><th>使用率</th></tr>
"@

    foreach ($disk in $disks) {
        $totalGB = [math]::Round($disk.Size / 1GB, 2)
        $freeGB = [math]::Round($disk.FreeSpace / 1GB, 2)
        $usedGB = [math]::Round(($disk.Size - $disk.FreeSpace) / 1GB, 2)
        $usedPct = [math]::Round(($disk.Size - $disk.FreeSpace) / $disk.Size * 100, 1)
        $barClass = if ($usedPct -gt 90) { 'danger' } elseif ($usedPct -gt 70) { 'warning' } else { 'good' }

        $report += @"
            <tr>
                <td>$($disk.DeviceID)</td>
                <td>$($disk.FileSystem)</td>
                <td>${totalGB} GB</td>
                <td>${usedGB} GB</td>
                <td>${freeGB} GB</td>
                <td>
                    <div class="bar"><div class="bar-fill $barClass" style="width:$usedPct%"></div></div>
                    $usedPct%
                </td>
            </tr>
"@
    }

    $report += @"
        </table>

        <h2>内存占用 Top 10</h2>
        <table>
            <tr><th>进程名</th><th>PID</th><th>内存 (MB)</th><th>CPU (s)</th></tr>
"@

    foreach ($proc in $topProcesses) {
        $memMB = [math]::Round($proc.WorkingSet64 / 1MB, 1)
        $cpuS = [math]::Round($proc.CPU, 2)
        $report += "            <tr><td>$($proc.Name)</td><td>$($proc.Id)</td><td>$memMB</td><td>$cpuS</td></tr>`n"
    }

    $report += @"
        </table>
"@

    if ($services) {
        $report += @"
        <h2>异常自动启动服务</h2>
        <table>
            <tr><th>服务名</th><th>显示名</th><th>状态</th></tr>
"@
        foreach ($svc in $services) {
            $report += "            <tr><td>$($svc.Name)</td><td>$($svc.DisplayName)</td><td><span class=`"status-badge status-error`">$($svc.Status)</span></td></tr>`n"
        }
        $report += "        </table>`n"
    }

    $report += @"
        <div class="footer">
            报告由 PowerShell 自动生成 | $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
        </div>
    </div>
</body>
</html>
"@

    $report | Set-Content $OutputPath -Encoding UTF8
    Write-Host "健康报告已生成：$OutputPath" -ForegroundColor Green
}

New-DailyHealthReport
```

执行结果示例：

```
健康报告已生成：C:\Reports\daily-health.html
```

## 邮件发送报告

```powershell
function Send-HtmlReport {
    param(
        [Parameter(Mandatory)]
        [string]$ReportPath,

        [Parameter(Mandatory)]
        [string[]]$To,

        [string]$Subject = "PowerShell 自动报告 - $(Get-Date -Format 'yyyy-MM-dd')",

        [string]$SmtpServer = "mail.contoso.com",

        [int]$Port = 587,

        [System.Management.Automation.PSCredential]$Credential
    )

    $body = Get-Content $ReportPath -Raw

    $params = @{
        From       = "reports@contoso.com"
        To         = $To
        Subject    = $Subject
        Body       = $body
        BodyAsHtml = $true
        SmtpServer = $SmtpServer
        Port       = $Port
        Encoding   = [System.Text.Encoding]::UTF8
    }

    if ($Credential) {
        $params.Credential = $Credential
    }

    Send-MailMessage @params
    Write-Host "报告已发送给：$($To -join ', ')" -ForegroundColor Green
}

# 发送报告邮件
$cred = Get-Credential -Message "输入邮件发送账户凭据"
Send-HtmlReport -ReportPath "C:\Reports\daily-health.html" `
    -To @("admin@contoso.com", "team@contoso.com") `
    -Subject "每日系统健康报告 - $(Get-Date -Format 'yyyy-MM-dd')" `
    -Credential $cred
```

执行结果示例：

```
报告已发送给：admin@contoso.com, team@contoso.com
```

## 注意事项

1. **UTF-8 编码**：始终使用 UTF-8 编码保存 HTML 文件，并在 `<head>` 中声明 `<meta charset="UTF-8">`
2. **邮件客户端兼容**：邮件中的 CSS 支持有限，避免使用 Flexbox、Grid 等现代布局，使用表格布局更安全
3. **内联 CSS**：邮件中的 CSS 最好内联写在元素上，而不是放在 `<style>` 标签中
4. **图片嵌入**：HTML 报告中的图片可以使用 Base64 内嵌或 CID 附件方式
5. **报告大小**：控制报告文件大小，大量数据应分页或限制展示条数
6. **安全邮件**：生产环境中使用 TLS 加密发送邮件，凭据应存储在密钥库中
