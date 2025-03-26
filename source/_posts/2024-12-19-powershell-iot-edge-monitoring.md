---
layout: post
date: 2024-12-19 08:00:00
title: "PowerShell 技能连载 - 边缘计算环境中的IoT设备监控"
description: "实现工业物联网设备的自动化状态采集与异常预警"
categories:
- powershell
- iot
- automation
tags:
- edge-computing
- device-monitoring
- industrial-iot
---

```powershell
function Get-IoTEdgeDeviceStatus {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$DeviceIPRange,
        
        [ValidateRange(1,65535)]
        [int]$PollingInterval = 300
    )

    $deviceReport = [PSCustomObject]@{
        Timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
        OnlineDevices = @()
        OfflineDevices = @()
        AbnormalMetrics = @()
    }

    # 执行Ping扫描发现设备
    $discoveredDevices = Test-Connection -ComputerName $DeviceIPRange -Count 1 -AsJob |
        Wait-Job | Receive-Job |
        Where-Object { $_.StatusCode -eq 0 } |
        Select-Object Address,ResponseTime

    # 获取设备遥测数据
    $discoveredDevices | ForEach-Object {
        try {
            $metrics = Invoke-RestMethod -Uri "http://$($_.Address)/metrics" -TimeoutSec 5
            
            $deviceReport.OnlineDevices += [PSCustomObject]@{
                IPAddress = $_.Address
                Latency = $_.ResponseTime
                CPUUsage = $metrics.cpu_usage
                MemoryUsage = $metrics.memory_usage
            }

            if($metrics.cpu_usage -gt 90 -or $metrics.memory_usage -gt 85) {
                $deviceReport.AbnormalMetrics += [PSCustomObject]@{
                    IPAddress = $_.Address
                    Metric = ($metrics | ConvertTo-Json)
                    Threshold = "CPU >90% 或 Memory >85%"
                }
            }
        }
        catch {
            $deviceReport.OfflineDevices += $_.Address
        }
    }

    # 生成HTML报告
    $reportPath = "$env:TEMP/IoTEdgeReport_$(Get-Date -Format yyyyMMdd).html"
    $deviceReport | ConvertTo-Html -Title "IoT设备健康报告" | Out-File $reportPath
    return $deviceReport
}
```

**核心功能**：
1. 工业设备自动发现与状态采集
2. 设备资源使用率实时监控
3. 异常阈值自动预警
4. HTML格式可视化报告

**应用场景**：
- 智能制造设备监控
- 能源行业传感器网络
- 智慧城市基础设施
- 远程设备维护预警