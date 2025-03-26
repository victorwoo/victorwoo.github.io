---
layout: post
date: 2024-11-25 08:00:00
title: "PowerShell 技能连载 - 物联网设备管理实践"
description: PowerTip of the Day - PowerShell IoT Device Management
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
在物联网（IoT）时代，设备管理变得越来越重要。本文将介绍如何使用PowerShell来管理和监控物联网设备，包括设备发现、状态监控、固件更新等功能。

## 设备发现与管理

首先，让我们创建一个用于发现和管理物联网设备的函数：

```powershell
function Find-IoTDevices {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$NetworkRange,
        
        [Parameter()]
        [int]$Port = 1883,
        
        [Parameter()]
        [int]$TimeoutSeconds = 5
    )
    
    try {
        $devices = @()
        $ipRange = $NetworkRange -replace '\.\d+$', ''
        
        Write-Host "正在扫描网络 $NetworkRange 中的物联网设备..." -ForegroundColor Yellow
        
        for ($i = 1; $i -le 254; $i++) {
            $ip = "$ipRange.$i"
            $tcpClient = New-Object System.Net.Sockets.TcpClient
            
            try {
                $result = $tcpClient.BeginConnect($ip, $Port, $null, $null)
                $success = $result.AsyncWaitHandle.WaitOne($TimeoutSeconds * 1000)
                
                if ($success) {
                    $tcpClient.EndConnect($result)
                    $device = [PSCustomObject]@{
                        IPAddress = $ip
                        Port = $Port
                        Status = "Online"
                        DiscoveryTime = Get-Date
                    }
                    
                    # 尝试获取设备信息
                    try {
                        $deviceInfo = Get-DeviceInfo -IPAddress $ip
                        $device | Add-Member -NotePropertyName "DeviceType" -NotePropertyValue $deviceInfo.Type
                        $device | Add-Member -NotePropertyName "FirmwareVersion" -NotePropertyValue $deviceInfo.FirmwareVersion
                    }
                    catch {
                        Write-Warning "无法获取设备 $ip 的详细信息：$_"
                    }
                    
                    $devices += $device
                    Write-Host "发现设备：$ip" -ForegroundColor Green
                }
            }
            catch {
                Write-Debug "设备 $ip 未响应：$_"
            }
            finally {
                $tcpClient.Close()
            }
        }
        
        return $devices
    }
    catch {
        Write-Error "设备扫描失败：$_"
        return $null
    }
}

function Get-DeviceInfo {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$IPAddress
    )
    
    try {
        # 这里应该实现与设备的具体通信协议
        # 例如：MQTT、CoAP、HTTP等
        $deviceInfo = [PSCustomObject]@{
            Type = "Unknown"
            FirmwareVersion = "Unknown"
            LastUpdate = Get-Date
        }
        
        return $deviceInfo
    }
    catch {
        Write-Error "获取设备信息失败：$_"
        throw
    }
}
```

## 设备状态监控

接下来，创建一个用于监控物联网设备状态的函数：

```powershell
function Monitor-IoTDevice {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$DeviceIP,
        
        [Parameter()]
        [string[]]$Metrics = @("CPU", "Memory", "Temperature", "Network"),
        
        [Parameter()]
        [int]$IntervalSeconds = 60,
        
        [Parameter()]
        [int]$DurationMinutes = 60,
        
        [Parameter()]
        [string]$LogPath
    )
    
    try {
        $startTime = Get-Date
        $endTime = $startTime.AddMinutes($DurationMinutes)
        $metricsData = @()
        
        Write-Host "开始监控设备 $DeviceIP..." -ForegroundColor Yellow
        
        while ((Get-Date) -lt $endTime) {
            $metricPoint = [PSCustomObject]@{
                Timestamp = Get-Date
            }
            
            foreach ($metric in $Metrics) {
                try {
                    switch ($metric) {
                        "CPU" {
                            $metricPoint.CPUUsage = Get-DeviceCPUUsage -IPAddress $DeviceIP
                        }
                        "Memory" {
                            $metricPoint.MemoryUsage = Get-DeviceMemoryUsage -IPAddress $DeviceIP
                        }
                        "Temperature" {
                            $metricPoint.Temperature = Get-DeviceTemperature -IPAddress $DeviceIP
                        }
                        "Network" {
                            $metricPoint.NetworkStats = Get-DeviceNetworkStats -IPAddress $DeviceIP
                        }
                    }
                }
                catch {
                    Write-Warning "获取指标 $metric 失败：$_"
                }
            }
            
            $metricsData += $metricPoint
            
            if ($LogPath) {
                $metricPoint | ConvertTo-Json | Out-File -FilePath $LogPath -Append
            }
            
            Start-Sleep -Seconds $IntervalSeconds
        }
        
        return $metricsData
    }
    catch {
        Write-Error "设备监控失败：$_"
        return $null
    }
}
```

## 固件更新管理

最后，创建一个用于管理物联网设备固件更新的函数：

```powershell
function Update-DeviceFirmware {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$DeviceIP,
        
        [Parameter(Mandatory = $true)]
        [string]$FirmwarePath,
        
        [Parameter()]
        [switch]$Force,
        
        [Parameter()]
        [int]$TimeoutMinutes = 30
    )
    
    try {
        # 检查设备状态
        $deviceStatus = Get-DeviceStatus -IPAddress $DeviceIP
        if (-not $deviceStatus.IsOnline) {
            throw "设备 $DeviceIP 当前处于离线状态"
        }
        
        # 检查固件版本
        $currentVersion = Get-DeviceFirmwareVersion -IPAddress $DeviceIP
        $newVersion = Get-FirmwareVersion -FirmwarePath $FirmwarePath
        
        if (-not $Force -and $currentVersion -ge $newVersion) {
            throw "当前固件版本 $currentVersion 已是最新版本"
        }
        
        Write-Host "开始更新设备 $DeviceIP 的固件..." -ForegroundColor Yellow
        
        # 备份当前配置
        $backupPath = Backup-DeviceConfig -IPAddress $DeviceIP
        
        # 上传新固件
        $uploadResult = Upload-Firmware -IPAddress $DeviceIP -FirmwarePath $FirmwarePath
        
        # 等待设备重启
        $startTime = Get-Date
        $deviceOnline = $false
        
        while ((Get-Date) -lt $startTime.AddMinutes($TimeoutMinutes)) {
            if (Test-DeviceConnection -IPAddress $DeviceIP) {
                $deviceOnline = $true
                break
            }
            Start-Sleep -Seconds 5
        }
        
        if (-not $deviceOnline) {
            throw "设备在超时时间内未能重新上线"
        }
        
        # 验证更新
        $updateStatus = Test-FirmwareUpdate -IPAddress $DeviceIP -ExpectedVersion $newVersion
        
        return [PSCustomObject]@{
            DeviceIP = $DeviceIP
            OldVersion = $currentVersion
            NewVersion = $newVersion
            UpdateTime = Get-Date
            Status = "Success"
            BackupPath = $backupPath
        }
    }
    catch {
        Write-Error "固件更新失败：$_"
        return $null
    }
}
```

## 使用示例

以下是如何使用这些函数来管理物联网设备的示例：

```powershell
# 发现网络中的物联网设备
$devices = Find-IoTDevices -NetworkRange "192.168.1.0/24" -Port 1883

# 监控特定设备的状态
$metrics = Monitor-IoTDevice -DeviceIP "192.168.1.100" `
    -Metrics @("CPU", "Memory", "Temperature") `
    -IntervalSeconds 30 `
    -DurationMinutes 60 `
    -LogPath "C:\Logs\device_metrics.json"

# 更新设备固件
$updateResult = Update-DeviceFirmware -DeviceIP "192.168.1.100" `
    -FirmwarePath "C:\Firmware\device_v2.0.bin" `
    -Force
```

## 最佳实践

1. 实现设备认证和加密通信
2. 定期备份设备配置
3. 实施固件更新前的兼容性检查
4. 建立设备监控告警机制
5. 记录详细的设备操作日志
6. 实现设备分组管理
7. 制定设备故障恢复计划
8. 定期评估设备安全性 