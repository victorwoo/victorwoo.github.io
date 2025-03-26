---
layout: post
date: 2024-10-23 08:00:00
title: "PowerShell 技能连载 - 物联网设备状态监控实战"
description: "通过MQTT协议实现边缘计算设备自动化管理"
categories:
- powershell
- iot
- automation
tags:
- edge-computing
- mqtt
- device-management
---

```powershell
function Start-EdgeDeviceMonitor {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$BrokerUrl,
        
        [Parameter(Mandatory=$true)]
        [string[]]$DeviceTopics
    )

    Add-Type -Path "MQTTnet.dll"
    $factory = [MQTTnet.MqttFactory]::new()
    $client = $factory.CreateMqttClient()

    $report = [PSCustomObject]@{
        Timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
        ConnectedDevices = @()
        HealthStatus = @()
    }

    $clientOptions = [MQTTnet.Client.MqttClientOptionsBuilder]::new()
        .WithTcpServer($BrokerUrl)
        .Build()

    $client.ConnectAsync($clientOptions).Wait()

    $DeviceTopics | ForEach-Object {
        $client.SubscribeAsync([MQTTnet.MqttTopicFilterBuilder]::new()
            .WithTopic($_)
            .Build()).Wait()

        $client.ApplicationMessageReceivedHandler = [MQTTnet.MqttApplicationMessageReceivedHandler]{
            param($e)
            $payload = [System.Text.Encoding]::UTF8.GetString($e.ApplicationMessage.Payload)
            
            $report.ConnectedDevices += [PSCustomObject]@{
                DeviceID = $e.ApplicationMessage.Topic.Split('/')[-1]
                LastSeen = Get-Date
                Telemetry = $payload | ConvertFrom-Json
            }

            if ($payload -match '"status":"error"') {
                $report.HealthStatus += [PSCustomObject]@{
                    DeviceID = $e.ApplicationMessage.Topic.Split('/')[-1]
                    ErrorCode = ($payload | ConvertFrom-Json).errorCode
                    Recommendation = "检查设备固件版本并重启服务"
                }
            }
        }
    }

    Register-ObjectEvent -InputObject $client -EventName ApplicationMessageReceived -Action {
        $global:report = $eventArgs | ForEach-Object { $_.UserEventArgs }
    }

    $report | Export-Csv -Path "$env:TEMP/EdgeDeviceReport_$(Get-Date -Format yyyyMMdd).csv"
    return $report
}
```

**核心功能**：
1. MQTT协议设备状态实时订阅
2. 边缘计算设备健康状态分析
3. 异常事件自动化预警
4. CSV报告持续输出

**典型应用场景**：
- 智能制造产线监控
- 智慧城市基础设施管理
- 农业物联网传感器网络
- 能源设备远程诊断