---
layout: post
date: 2024-09-11 08:00:00
title: "PowerShell 技能连载 - IoT边缘设备监控"
description: PowerTip of the Day - IoT Edge Device Monitoring
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
在工业物联网场景中，边缘设备监控至关重要。以下脚本实现设备状态采集与异常预警：

```powershell
function Get-IoTDeviceStatus {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string[]]$DeviceIPs,
        
        [ValidateRange(1,100)]
        [int]$SamplingInterval = 30
    )

    $report = [PSCustomObject]@{
        Timestamp     = Get-Date
        OnlineDevices = @()
        OfflineDevices = @()
        HighTempDevices = @()
        LowBatteryDevices = @()
    }

    try {
        # 设备状态轮询
        $DeviceIPs | ForEach-Object -Parallel {
            $response = Test-NetConnection -ComputerName $_ -Port 502 -InformationLevel Quiet
            $telemetry = Invoke-RestMethod -Uri "http://$_/metrics" -TimeoutSec 3

            [PSCustomObject]@{
                IP = $_
                Online = $response
                Temperature = $telemetry.temp
                BatteryLevel = $telemetry.battery
                LastSeen = Get-Date
            }
        } -ThrottleLimit 10

        # 数据分析
        $results | ForEach-Object {
            if(-not $_.Online) {
                $report.OfflineDevices += $_.IP
                continue
            }

            $report.OnlineDevices += $_.IP
            
            if($_.Temperature -gt 85) {
                $report.HighTempDevices += $_.IP
            }

            if($_.BatteryLevel -lt 20) {
                $report.LowBatteryDevices += $_.IP
            }
        }

        # 触发预警
        if($report.HighTempDevices.Count -gt 0) {
            Send-Notification -Type "HighTemp" -Devices $report.HighTempDevices
        }

        if($report.LowBatteryDevices.Count -gt 0) {
            Send-Notification -Type "LowBattery" -Devices $report.LowBatteryDevices
        }
    }
    catch {
        Write-Warning "设备监控异常: $_"
    }

    return $report
}
```

实现原理：
1. 使用并行处理加速多设备状态采集
2. 通过Test-NetConnection验证设备在线状态
3. 调用REST API获取设备遥测数据
4. 设置温度(85°C)和电量(20%)双重预警阈值
5. 自动触发邮件/短信通知机制

使用示例：
```powershell
$devices = '192.168.1.100','192.168.1.101','192.168.1.102'
Get-IoTDeviceStatus -DeviceIPs $devices -SamplingInterval 60
```

最佳实践：
1. 与TSDB时序数据库集成存储历史数据
2. 配置指数退避策略应对网络波动
3. 添加设备白名单安全机制
4. 实现预警静默时段功能

注意事项：
• 需要设备开放502端口和/metrics端点
• 建议使用硬件加密模块保护通信安全
• 监控间隔不宜小于30秒