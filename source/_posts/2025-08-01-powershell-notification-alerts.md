---
layout: post
date: 2025-08-01 08:00:00
updated: 2025-08-01 08:00:00
title: "PowerShell 技能连载 - 通知与告警系统"
description: PowerTip of the Day - Notification and Alerting Systems in PowerShell
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
- tooling
- monitoring
- office
- network
---

_适用于 PowerShell 5.1 及以上版本_

运维自动化的最后一环是通知——部署完成需要告知团队、服务异常需要唤醒值班人员、磁盘满了需要及时处理。PowerShell 可以通过多种渠道发送通知：邮件（SMTP）、Webhook（Slack/Teams/钉钉）、Windows Toast 通知、甚至短信。构建统一的通知系统，让所有脚本复用同一套告警机制，是提升运维响应效率的关键。

本文将讲解 PowerShell 中的各种通知方式和统一的告警系统设计。

<!-- more -->

## 邮件通知

```powershell
function Send-AlertEmail {
    param(
        [Parameter(Mandatory)]
        [string]$Subject,

        [Parameter(Mandatory)]
        [string]$Body,

        [string[]]$To = @("admin@contoso.com"),

        [string]$Priority = "Normal",

        [string]$SmtpServer = "mail.contoso.com",

        [int]$Port = 587
    )

    $params = @{
        From       = "alerts@contoso.com"
        To         = $To
        Subject    = "[PS-Alert] $Subject"
        Body       = $Body
        BodyAsHtml = $true
        SmtpServer = $SmtpServer
        Port       = $Port
        Encoding   = [System.Text.Encoding]::UTF8
        Priority   = $Priority
    }

    if ($env:SMTP_USER -and $env:SMTP_PASS) {
        $secPass = ConvertTo-SecureString $env:SMTP_PASS -AsPlainText -Force
        $params.Credential = New-Object PSCredential($env:SMTP_USER, $secPass)
    }

    try {
        Send-MailMessage @params
        Write-Host "邮件已发送：$Subject" -ForegroundColor Green
    } catch {
        Write-Host "邮件发送失败：$($_.Exception.Message)" -ForegroundColor Red
    }
}

# HTML 格式告警邮件
function Send-HtmlAlert {
    param(
        [string]$Title,
        [string]$Message,
        [ValidateSet("Info", "Warning", "Critical")]
        [string]$Severity = "Info"
    )

    $color = switch ($Severity) {
        "Info"     { "#3498db" }
        "Warning"  { "#f39c12" }
        "Critical" { "#e74c3c" }
    }

    $html = @"
<!DOCTYPE html>
<html><body style="font-family:Arial,sans-serif;padding:20px">
<div style="border-left:4px solid $color;padding:15px;background:#f8f9fa">
<h2 style="color:$color;margin:0">$Title</h2>
<p style="color:#555">$Message</p>
<p style="color:#999;font-size:12px">时间：$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') | 计算机：$($env:COMPUTERNAME)</p>
</div>
</body></html>
"@

    $priority = if ($Severity -eq "Critical") { "High" } else { "Normal" }
    Send-AlertEmail -Subject $Title -Body $html -Priority $priority
}

Send-HtmlAlert -Title "磁盘空间告警" -Message "服务器 SRV01 的 C 盘使用率已达到 92%" -Severity Warning
```

执行结果示例：

```
邮件已发送：磁盘空间告警
```

## Webhook 通知

```powershell
# Slack Webhook
function Send-SlackNotification {
    param(
        [Parameter(Mandatory)][string]$Message,
        [ValidateSet("good", "warning", "danger")]
        [string]$Color = "good",
        [string]$WebhookUrl = $env:SLACK_WEBHOOK_URL
    )

    if (-not $WebhookUrl) {
        Write-Host "未设置 SLACK_WEBHOOK_URL" -ForegroundColor Yellow
        return
    }

    $body = @{
        attachments = @(
            @{
                text  = $Message
                color = $Color
                ts    = [int][double]::Parse((Get-Date -UFormat %s))
                fields = @(
                    @{ title = "Server"; value = $env:COMPUTERNAME; short = $true }
                    @{ title = "Time"; value = (Get-Date -Format 'HH:mm:ss'); short = $true }
                )
            }
        )
    } | ConvertTo-Json -Depth 5

    try {
        Invoke-RestMethod -Uri $WebhookUrl -Method Post -Body $body -ContentType "application/json"
        Write-Host "Slack 通知已发送" -ForegroundColor Green
    } catch {
        Write-Host "Slack 发送失败：$($_.Exception.Message)" -ForegroundColor Red
    }
}

# Microsoft Teams Webhook
function Send-TeamsNotification {
    param(
        [Parameter(Mandatory)][string]$Title,
        [Parameter(Mandatory)][string]$Message,
        [ValidateSet("Info", "Warning", "Error")]
        [string]$Level = "Info",
        [string]$WebhookUrl = $env:TEAMS_WEBHOOK_URL
    )

    if (-not $WebhookUrl) { return }

    $color = switch ($Level) {
        "Info"    { "0078D7" }
        "Warning" { "FFB900" }
        "Error"   { "E81123" }
    }

    $body = @{
        "@type"    = "MessageCard"
        "@context" = "http://schema.org/extensions"
        themeColor = $color
        title      = $Title
        text       = $Message
        sections   = @(
            @{
                facts = @(
                    @{ name = "Computer"; value = $env:COMPUTERNAME },
                    @{ name = "Timestamp"; value = (Get-Date -Format 'yyyy-MM-dd HH:mm:ss') }
                )
            }
        )
    } | ConvertTo-Json -Depth 5

    Invoke-RestMethod -Uri $WebhookUrl -Method Post -Body $body -ContentType "application/json"
    Write-Host "Teams 通知已发送" -ForegroundColor Green
}

# 钉钉 Webhook
function Send-DingTalkNotification {
    param(
        [Parameter(Mandatory)][string]$Message,
        [string]$WebhookUrl = $env:DINGTALK_WEBHOOK_URL
    )

    if (-not $WebhookUrl) { return }

    $body = @{
        msgtype = "text"
        text    = @{ content = "[$($env:COMPUTERNAME)] $Message" }
    } | ConvertTo-Json

    Invoke-RestMethod -Uri $WebhookUrl -Method Post -Body $body -ContentType "application/json; charset=utf-8"
    Write-Host "钉钉通知已发送" -ForegroundColor Green
}

Send-SlackNotification -Message "部署完成：MyApp v2.5.0" -Color "good"
Send-TeamsNotification -Title "服务告警" -Message "CPU 使用率超过 90%" -Level Warning
```

执行结果示例：

```
Slack 通知已发送
Teams 通知已发送
```

## 统一告警系统

```powershell
# 统一告警入口
function Send-Alert {
    param(
        [Parameter(Mandatory)]
        [string]$Title,

        [Parameter(Mandatory)]
        [string]$Message,

        [ValidateSet("Info", "Warning", "Critical")]
        [string]$Severity = "Info",

        [string[]]$Channels = @("Log"),

        [hashtable]$ExtraData
    )

    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $alertId = [guid]::NewGuid().ToString().Substring(0, 8)

    $fullMessage = "[$alertId] [$Severity] $Title`n$Message"
    if ($ExtraData) {
        foreach ($key in $ExtraData.Keys) {
            $fullMessage += "`n  $key : $($ExtraData[$key])"
        }
    }

    # 始终记录日志
    $logDir = "C:\Logs\Alerts"
    New-Item $logDir -ItemType Directory -Force | Out-Null
    $logEntry = "[$timestamp] [$Severity] [$alertId] $Title | $Message"
    Add-Content "$logDir\alerts-$(Get-Date -Format 'yyyyMM').log" -Value $logEntry -Encoding UTF8

    # 根据渠道分发
    foreach ($channel in $Channels) {
        switch ($channel) {
            "Email" {
                Send-HtmlAlert -Title "[$Severity] $Title" -Message $Message -Severity $Severity
            }
            "Slack" {
                $color = switch ($Severity) {
                    "Info"     { "good" }
                    "Warning"  { "warning" }
                    "Critical" { "danger" }
                }
                Send-SlackNotification -Message $fullMessage -Color $color
            }
            "Teams" {
                $level = switch ($Severity) {
                    "Info"     { "Info" }
                    "Warning"  { "Warning" }
                    "Critical" { "Error" }
                }
                Send-TeamsNotification -Title $Title -Message $fullMessage -Level $level
            }
            "DingTalk" {
                Send-DingTalkNotification -Message $fullMessage
            }
            "Log" {
                $color = switch ($Severity) {
                    "Info"     { "Green" }
                    "Warning"  { "Yellow" }
                    "Critical" { "Red" }
                }
                Write-Host $logEntry -ForegroundColor $color
            }
        }
    }
}

# 使用示例
Send-Alert -Title "部署完成" -Message "MyApp v2.5.0 已部署到生产环境" `
    -Severity Info -Channels @("Log", "Slack")

Send-Alert -Title "磁盘空间告警" -Message "SRV01 C盘使用率 95%" `
    -Severity Warning -Channels @("Log", "Email", "Teams") `
    -ExtraData @{ Drive = "C:"; FreeGB = "10.2"; Threshold = "90%" }

Send-Alert -Title "服务宕机" -Message "MyApp 服务无响应" `
    -Severity Critical -Channels @("Log", "Email", "Slack", "Teams", "DingTalk") `
    -ExtraData @{ Server = "SRV01"; LastSeen = "5分钟前" }
```

执行结果示例：

```
[2025-08-01 08:30:15] [Info] [a1b2c3d4] 部署完成 | MyApp v2.5.0 已部署到生产环境
Slack 通知已发送
[2025-08-01 08:30:16] [Warning] [e5f6a7b8] 磁盘空间告警 | SRV01 C盘使用率 95%
邮件已发送：[Warning] 磁盘空间告警
Teams 通知已发送
[2025-08-01 08:30:17] [Critical] [c9d0e1f2] 服务宕机 | MyApp 服务无响应
邮件已发送：[Critical] 服务宕机
Slack 通知已发送
Teams 通知已发送
钉钉通知已发送
```

## Windows Toast 通知

```powershell
# 本地 Windows Toast 通知
function Send-ToastNotification {
    param(
        [Parameter(Mandatory)][string]$Title,
        [Parameter(Mandatory)][string]$Message
    )

    Add-Type -AssemblyName System.Windows.Forms

    $notify = New-Object System.Windows.Forms.NotifyIcon
    $notify.Icon = [System.Drawing.SystemIcons]::Warning
    $notify.BalloonTipTitle = $Title
    $notify.BalloonTipText = $Message
    $notify.Visible = $true
    $notify.ShowBalloonTip(5000)

    Start-Sleep -Seconds 6
    $notify.Dispose()
}

Send-ToastNotification -Title "部署完成" -Message "MyApp v2.5.0 已部署"
```

执行结果示例：

```
# Windows 系统托盘弹出通知气泡
```

## 注意事项

1. **Webhook 安全**：Webhook URL 等同于密码，不要硬编码在脚本中，使用环境变量或密钥管理
2. **告警抑制**：同一告警短时间内重复发送会造成告警疲劳，添加去重和抑制逻辑
3. **告警升级**：Critical 级别告警未被处理时应自动升级，通知更高级别的人员
4. **发送失败处理**：通知发送失败时应有备用方案（如主邮件服务器失败时尝试备用）
5. **告警分级**：合理使用 Info/Warning/Critical，避免所有告警都是最高级别
6. **时区处理**：分布式团队注意时区差异，告警时间使用 UTC 或明确标注时区
