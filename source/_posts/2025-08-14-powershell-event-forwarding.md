---
layout: post
date: 2025-08-14 08:00:00
updated: 2025-08-14 08:00:00
title: "PowerShell 技能连载 - Windows 事件转发"
description: PowerTip of the Day - Windows Event Forwarding in PowerShell
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
- event-log
- wef
- centralized-logging
---

_适用于 PowerShell 5.1 及以上版本（Windows），需要管理员权限_

在企业环境中，每台 Windows 服务器都在本地记录事件日志。当需要排查跨服务器的问题时，逐台登录查看日志效率极低。Windows 事件转发（WEF，Windows Event Forwarding）可以将多台服务器的事件日志集中转发到收集器服务器，实现集中化日志管理。结合 PowerShell 的日志查询能力，可以构建强大的安全监控和故障排查平台。

本文将讲解如何使用 PowerShell 配置和管理 Windows 事件转发。

<!-- more -->

## 事件日志查询

```powershell
# 查询本地事件日志
$events = Get-WinEvent -LogName "Application" -MaxEvents 10 -ErrorAction SilentlyContinue
$events | Select-Object TimeCreated, LevelDisplayName, ProviderName,
    @{N='Message'; E={if ($_.Message.Length -gt 80) { $_.Message.Substring(0, 80) + "..." } else { $_.Message }}} |
    Format-Table -AutoSize -Wrap

# 按条件筛选事件
$errors = Get-WinEvent -FilterHashtable @{
    LogName   = "Application"
    Level     = 2  # Error
    StartTime = (Get-Date).AddHours(-24)
} -ErrorAction SilentlyContinue

Write-Host "过去 24 小时应用错误：$($errors.Count) 条" -ForegroundColor Red

# 查询安全日志（需要管理员权限）
$logons = Get-WinEvent -FilterHashtable @{
    LogName   = "Security"
    Id        = 4624  # 登录成功
    StartTime = (Get-Date).AddHours(-1)
} -MaxEvents 10 -ErrorAction SilentlyContinue

if ($logons) {
    $logonDetails = foreach ($event in $logons) {
        $xml = [xml]$event.ToXml()
        $targetUser = ($xml.Event.EventData.Data | Where-Object { $_.Name -eq 'TargetUserName' }).'#text'
        $logonType = ($xml.Event.EventData.Data | Where-Object { $_.Name -eq 'LogonType' }).'#text'
        $sourceIP = ($xml.Event.EventData.Data | Where-Object { $_.Name -eq 'IpAddress' }).'#text'

        [PSCustomObject]@{
            Time     = $event.TimeCreated.ToString('HH:mm:ss')
            User     = $targetUser
            Type     = $logonType
            SourceIP = $sourceIP
        }
    }
    $logonDetails | Format-Table -AutoSize
}

# 查询系统启动事件
$boots = Get-WinEvent -FilterHashtable @{
    LogName = "System"
    Id      = 12  # 系统启动
} -MaxEvents 5 -ErrorAction SilentlyContinue

Write-Host "`n最近系统启动：" -ForegroundColor Cyan
$boots | ForEach-Object { Write-Host "  $($_.TimeCreated.ToString('yyyy-MM-dd HH:mm:ss'))" }
```

执行结果示例：

```
过去 24 小时应用错误：12 条

Time     User     Type SourceIP
----     ----     ---- --------
08:15:30 admin    2    192.168.1.100
08:20:45 svc_app  3    127.0.0.1
08:35:10 admin    10   10.0.1.50

最近系统启动：
  2025-08-14 06:00:00
  2025-08-07 06:00:00
  2025-08-01 02:30:00
```

## 事件转发配置

```powershell
# 配置事件收集器服务器
function Initialize-EventCollector {
    <#
    .SYNOPSIS
    初始化 Windows 事件转发收集器
    #>

    # 启用 Windows 事件收集器服务
    $wecSvc = Get-Service -Name "Wecsvc" -ErrorAction SilentlyContinue
    if ($wecSvc.Status -ne 'Running') {
        Start-Service -Name "Wecsvc"
        Set-Service -Name "Wecsvc" -StartupType Automatic
        Write-Host "Windows 事件收集器服务已启动" -ForegroundColor Green
    }

    # 创建事件订阅
    $subscriptionXml = @"
<Subscription xmlns="http://schemas.microsoft.com/2006/03/windows/events/subscription">
  <SubscriptionId>SecurityEvents</SubscriptionId>
  <SubscriptionType>SourceInitiated</SubscriptionType>
  <Description>安全事件集中收集</Description>
  <Enabled>true</Enabled>
  <Uri>http://schemas.microsoft.com/wbem/wsman/1/windows/EventLog</Uri>
  <ConfigurationMode>Custom</ConfigurationMode>
  <Delivery Mode="Push">
    <Batching>
      <MaxItems>20</MaxItems>
      <MaxLatencyTime>300000</MaxLatencyTime>
    </Batching>
    <PushSettings>
      <Heartbeat Interval="3600000"/>
    </PushSettings>
  </Delivery>
  <ContentFormat>
    <RenderedText/>
  </ContentFormat>
  <LogFile>ForwardedEvents</LogFile>
  <Query>
    <![CDATA[
      <QueryList>
        <Query Path="Security">
          <Select>*[System[(EventID=4624 or EventID=4625 or EventID=4648 or EventID=4672)]]</Select>
        </Query>
        <Query Path="System">
          <Select>*[System[Level=1 or Level=2 or Level=3]]</Select>
        </Query>
      </QueryList>
    ]]>
  </Query>
  <ReadExistingEvents>false</ReadExistingEvents>
</Subscription>
"@

    $configPath = "$env:TEMP\SecurityEvents.xml"
    $subscriptionXml | Set-Content $configPath -Encoding UTF8

    # 创建订阅
    try {
        wecutil cs $configPath 2>&1
        Write-Host "安全事件订阅已创建" -ForegroundColor Green
    } catch {
        Write-Host "创建订阅失败：$($_.Exception.Message)" -ForegroundColor Red
    }
}

# Initialize-EventCollector

# 查询转发的事件
function Get-ForwardedEvents {
    param(
        [int]$Hours = 1,
        [int]$MaxEvents = 50
    )

    $events = Get-WinEvent -FilterHashtable @{
        LogName   = "ForwardedEvents"
        StartTime = (Get-Date).AddHours(-$Hours)
    } -MaxEvents $MaxEvents -ErrorAction SilentlyContinue

    if (-not $events) {
        Write-Host "无转发事件" -ForegroundColor Yellow
        return
    }

    $summary = $events | Group-Object ProviderName | Sort-Object Count -Descending
    Write-Host "转发事件概览（过去 $Hours 小时）：" -ForegroundColor Cyan
    $summary | Select-Object Count, Name | Format-Table -AutoSize

    return $events
}

Get-ForwardedEvents -Hours 4 -MaxEvents 100
```

执行结果示例：

```
安全事件订阅已创建
转发事件概览（过去 4 小时）：
Count Name
----- ----
   45 Microsoft-Windows-Security-Auditing
   23 Service Control Manager
   12 Microsoft-Windows-Kernel-General
```

## 安全事件分析

```powershell
# 分析登录失败事件
function Get-FailedLogonReport {
    param([int]$Hours = 24)

    $failedLogons = Get-WinEvent -FilterHashtable @{
        LogName   = "ForwardedEvents"
        Id        = 4625
        StartTime = (Get-Date).AddHours(-$Hours)
    } -ErrorAction SilentlyContinue

    if (-not $failedLogons) {
        Write-Host "无登录失败事件" -ForegroundColor Green
        return
    }

    $report = foreach ($event in $failedLogons) {
        $xml = [xml]$event.ToXml()
        $data = @{}
        $xml.Event.EventData.Data | ForEach-Object { $data[$_.Name] = $_.'#text' }

        [PSCustomObject]@{
            Time     = $event.TimeCreated.ToString('yyyy-MM-dd HH:mm:ss')
            Computer = $event.MachineName
            Target   = $data['TargetUserName']
            SourceIP = $data['IpAddress']
            LogonType = $data['LogonType']
            Failure  = $data['SubStatus']
        }
    }

    Write-Host "登录失败报告（过去 $Hours 小时）：" -ForegroundColor Red
    Write-Host "总计：$($report.Count) 次失败" -ForegroundColor Yellow

    # 按来源 IP 聚合
    $byIP = $report | Group-Object SourceIP | Sort-Object Count -Descending | Select-Object -First 10
    Write-Host "`n按来源 IP 聚合：" -ForegroundColor Cyan
    $byIP | Select-Object Count, Name | Format-Table -AutoSize

    # 按目标用户聚合
    $byUser = $report | Group-Object Target | Sort-Object Count -Descending | Select-Object -First 5
    Write-Host "按目标用户聚合：" -ForegroundColor Cyan
    $byUser | Select-Object Count, Name | Format-Table -AutoSize
}

Get-FailedLogonReport -Hours 24
```

执行结果示例：

```
登录失败报告（过去 24 小时）：
总计：45 次失败

按来源 IP 聚合：
Count Name
----- ----
   23 192.168.1.100
   12 10.0.1.50
    5 203.0.113.42
    3 172.16.0.5
    2 192.168.1.200

按目标用户聚合：
Count Name
----- ----
   30 administrator
    8 admin
    5 root
    2 sa
```

## 注意事项

1. **WinRM 依赖**：WEF 依赖 WinRM 服务，确保源计算机已启用 WinRM
2. **防火墙规则**：源计算机需要允许 WinRM 出站连接（默认端口 5985/5986）
3. **订阅类型**：SourceInitiated（源发起）适合大规模部署，CollectorInitiated（收集器发起）适合少量服务器
4. **事件量控制**：大量服务器的事件转发可能产生海量数据，使用精确的 XPath 查询过滤
5. **存储规划**：收集器服务器需要足够的磁盘空间存储转发的事件
6. **GPO 部署**：企业环境中通过组策略配置 WEF，比手动配置更高效一致
