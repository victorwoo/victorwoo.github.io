---
layout: post
date: 2024-08-13 08:00:00
title: "PowerShell 技能连载 - 硬件监控技巧"
description: PowerTip of the Day - PowerShell Hardware Monitoring Tips
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
在IT运维中，硬件监控是确保系统稳定运行的关键任务。本文将介绍如何使用PowerShell实现全面的硬件监控功能。

首先，让我们创建一个基础的系统资源监控函数：

```powershell
# 创建系统资源监控函数
function Get-SystemResourceInfo {
    param(
        [string]$ComputerName = $env:COMPUTERNAME,
        [switch]$IncludeCPU,
        [switch]$IncludeMemory,
        [switch]$IncludeDisk,
        [switch]$IncludeNetwork,
        [switch]$All
    )
    
    if ($All) {
        $IncludeCPU = $IncludeMemory = $IncludeDisk = $IncludeNetwork = $true
    }
    
    $results = [PSCustomObject]@{
        ComputerName = $ComputerName
        Timestamp = Get-Date
    }
    
    try {
        # 获取CPU信息
        if ($IncludeCPU) {
            $cpuInfo = Get-CimInstance -ComputerName $ComputerName -ClassName Win32_Processor
            $cpuUsage = (Get-Counter -ComputerName $ComputerName -Counter "\Processor(_Total)\% Processor Time" -ErrorAction SilentlyContinue).CounterSamples.CookedValue
            
            $cpuDetails = [PSCustomObject]@{
                Name = $cpuInfo.Name
                Cores = $cpuInfo.NumberOfCores
                LogicalProcessors = $cpuInfo.NumberOfLogicalProcessors
                MaxClockSpeed = "$($cpuInfo.MaxClockSpeed) MHz"
                CurrentUsage = "$([Math]::Round($cpuUsage, 2))%"
                LoadPercentage = $cpuInfo.LoadPercentage
                Architecture = $cpuInfo.AddressWidth
                L2CacheSize = "$($cpuInfo.L2CacheSize) KB"
                L3CacheSize = "$($cpuInfo.L3CacheSize) KB"
            }
            
            $results | Add-Member -MemberType NoteProperty -Name "CPU" -Value $cpuDetails
        }
        
        # 获取内存信息
        if ($IncludeMemory) {
            $memoryInfo = Get-CimInstance -ComputerName $ComputerName -ClassName Win32_OperatingSystem
            $physicalMemory = Get-CimInstance -ComputerName $ComputerName -ClassName Win32_PhysicalMemory
            
            $totalMemory = ($physicalMemory | Measure-Object -Property Capacity -Sum).Sum / 1GB
            $freeMemory = $memoryInfo.FreePhysicalMemory / 1MB
            $usedMemory = $totalMemory - ($freeMemory / 1024)
            $memoryUsagePercent = [Math]::Round(($usedMemory / $totalMemory) * 100, 2)
            
            $memoryDetails = [PSCustomObject]@{
                TotalGB = [Math]::Round($totalMemory, 2)
                FreeGB = [Math]::Round($freeMemory / 1024, 2)
                UsedGB = [Math]::Round($usedMemory, 2)
                UsagePercent = "$memoryUsagePercent%"
                Modules = $physicalMemory.Count
                MemoryType = ($physicalMemory | Select-Object -First 1).MemoryType
                Speed = "$($physicalMemory | Select-Object -First 1 -ExpandProperty Speed) MHz"
                PagedPoolMB = [Math]::Round((Get-CimInstance -ComputerName $ComputerName -ClassName Win32_PerfFormattedData_PerfOS_Memory).PoolPagedBytes / 1MB, 2)
                NonPagedPoolMB = [Math]::Round((Get-CimInstance -ComputerName $ComputerName -ClassName Win32_PerfFormattedData_PerfOS_Memory).PoolNonpagedBytes / 1MB, 2)
            }
            
            $results | Add-Member -MemberType NoteProperty -Name "Memory" -Value $memoryDetails
        }
        
        # 获取磁盘信息
        if ($IncludeDisk) {
            $diskInfo = Get-CimInstance -ComputerName $ComputerName -ClassName Win32_LogicalDisk -Filter "DriveType=3"
            $diskCounter = Get-Counter -ComputerName $ComputerName -Counter "\PhysicalDisk(_Total)\Disk Reads/sec", "\PhysicalDisk(_Total)\Disk Writes/sec", "\PhysicalDisk(_Total)\Avg. Disk Queue Length" -ErrorAction SilentlyContinue
            
            $diskReadsSec = $diskCounter.CounterSamples[0].CookedValue
            $diskWritesSec = $diskCounter.CounterSamples[1].CookedValue
            $diskQueueLength = $diskCounter.CounterSamples[2].CookedValue
            
            $diskDetails = $diskInfo | ForEach-Object {
                $freeSpace = $_.FreeSpace / 1GB
                $totalSpace = $_.Size / 1GB
                $usedSpace = $totalSpace - $freeSpace
                $percentFree = [Math]::Round(($freeSpace / $totalSpace) * 100, 2)
                
                [PSCustomObject]@{
                    Drive = $_.DeviceID
                    VolumeLabel = $_.VolumeName
                    TotalGB = [Math]::Round($totalSpace, 2)
                    FreeGB = [Math]::Round($freeSpace, 2)
                    UsedGB = [Math]::Round($usedSpace, 2)
                    PercentFree = "$percentFree%"
                    FileSystem = $_.FileSystem
                }
            }
            
            $diskMetrics = [PSCustomObject]@{
                Drives = $diskDetails
                ReadPerSec = [Math]::Round($diskReadsSec, 2)
                WritesPerSec = [Math]::Round($diskWritesSec, 2)
                QueueLength = [Math]::Round($diskQueueLength, 2)
                AvgTransferTime = [Math]::Round((Get-Counter -ComputerName $ComputerName -Counter "\PhysicalDisk(_Total)\Avg. Disk sec/Transfer" -ErrorAction SilentlyContinue).CounterSamples.CookedValue * 1000, 2)
            }
            
            $results | Add-Member -MemberType NoteProperty -Name "Disk" -Value $diskMetrics
        }
        
        # 获取网络信息
        if ($IncludeNetwork) {
            $networkAdapters = Get-CimInstance -ComputerName $ComputerName -ClassName Win32_NetworkAdapter | Where-Object { $_.PhysicalAdapter -eq $true -and $_.NetEnabled -eq $true }
            $networkConfigs = Get-CimInstance -ComputerName $ComputerName -ClassName Win32_NetworkAdapterConfiguration | Where-Object { $_.IPEnabled -eq $true }
            
            $networkMetrics = $networkAdapters | ForEach-Object {
                $adapterConfig = $networkConfigs | Where-Object { $_.Index -eq $_.Index }
                $bytesReceivedSec = (Get-Counter -ComputerName $ComputerName -Counter "\Network Interface($($_.Name))\Bytes Received/sec" -ErrorAction SilentlyContinue).CounterSamples.CookedValue
                $bytesSentSec = (Get-Counter -ComputerName $ComputerName -Counter "\Network Interface($($_.Name))\Bytes Sent/sec" -ErrorAction SilentlyContinue).CounterSamples.CookedValue
                
                [PSCustomObject]@{
                    Name = $_.Name
                    ConnectionName = $_.NetConnectionID
                    Speed = if ($_.Speed) { "$([Math]::Round($_.Speed / 1000000, 0)) Mbps" } else { "Unknown" }
                    MACAddress = $_.MACAddress
                    IPAddresses = $adapterConfig.IPAddress
                    BytesReceivedSec = [Math]::Round($bytesReceivedSec / 1KB, 2)
                    BytesSentSec = [Math]::Round($bytesSentSec / 1KB, 2)
                    TotalBandwidthKBSec = [Math]::Round(($bytesReceivedSec + $bytesSentSec) / 1KB, 2)
                }
            }
            
            $results | Add-Member -MemberType NoteProperty -Name "Network" -Value $networkMetrics
        }
        
        return $results
    }
    catch {
        Write-Error "获取系统资源信息时出错: $_"
    }
}
```

接下来，让我们创建一个温度监控函数：

```powershell
# 创建温度监控函数
function Get-SystemTemperature {
    param(
        [string]$ComputerName = $env:COMPUTERNAME
    )
    
    try {
        # 使用 WMI 获取温度传感器数据
        $temperatureData = @()
        
        # 获取CPU温度 (使用MSAcpi_ThermalZoneTemperature类)
        $cpuTemp = Get-CimInstance -ComputerName $ComputerName -Namespace "root\WMI" -ClassName MSAcpi_ThermalZoneTemperature -ErrorAction SilentlyContinue
        
        if ($cpuTemp) {
            foreach ($temp in $cpuTemp) {
                # 温度以Kelvin为单位，转换为摄氏度
                $tempC = [Math]::Round($temp.CurrentTemperature / 10 - 273.15, 1)
                
                $temperatureData += [PSCustomObject]@{
                    SensorType = "CPU"
                    Name = $temp.InstanceName
                    TemperatureCelsius = $tempC
                    TemperatureFahrenheit = [Math]::Round(($tempC * 9/5) + 32, 1)
                    Status = if ($tempC -gt 80) { "Critical" } elseif ($tempC -gt 70) { "Warning" } else { "Normal" }
                }
            }
        }
        
        # 如果无法通过MSAcpi_ThermalZoneTemperature获取，尝试其他方法
        if ($temperatureData.Count -eq 0) {
            # 尝试通过Open Hardware Monitor获取（如果已安装）
            $ohm = Get-CimInstance -ComputerName $ComputerName -Namespace "root\OpenHardwareMonitor" -ClassName Sensor -ErrorAction SilentlyContinue | Where-Object { $_.SensorType -eq "Temperature" }
            
            if ($ohm) {
                foreach ($sensor in $ohm) {
                    $temperatureData += [PSCustomObject]@{
                        SensorType = $sensor.Parent
                        Name = $sensor.Name
                        TemperatureCelsius = [Math]::Round($sensor.Value, 1)
                        TemperatureFahrenheit = [Math]::Round(($sensor.Value * 9/5) + 32, 1)
                        Status = if ($sensor.Value -gt 80) { "Critical" } elseif ($sensor.Value -gt 70) { "Warning" } else { "Normal" }
                    }
                }
            }
        }
        
        # 如果仍无法获取温度数据，使用Win32_TemperatureProbe类（较老的系统）
        if ($temperatureData.Count -eq 0) {
            $oldTemp = Get-CimInstance -ComputerName $ComputerName -ClassName Win32_TemperatureProbe -ErrorAction SilentlyContinue
            
            if ($oldTemp) {
                foreach ($probe in $oldTemp) {
                    $tempC = $probe.CurrentReading
                    
                    $temperatureData += [PSCustomObject]@{
                        SensorType = "System"
                        Name = $probe.Description
                        TemperatureCelsius = $tempC
                        TemperatureFahrenheit = [Math]::Round(($tempC * 9/5) + 32, 1)
                        Status = if ($tempC -gt 80) { "Critical" } elseif ($tempC -gt 70) { "Warning" } else { "Normal" }
                    }
                }
            }
        }
        
        # 如果所有方法都失败，返回一个消息
        if ($temperatureData.Count -eq 0) {
            Write-Warning "无法获取温度数据。可能需要安装适当的硬件监控工具，如Open Hardware Monitor。"
        }
        
        return $temperatureData
    }
    catch {
        Write-Error "获取系统温度时出错: $_"
    }
}
```

下面创建一个硬件健康监控函数：

```powershell
# 创建硬件健康监控函数
function Get-HardwareHealth {
    param(
        [string]$ComputerName = $env:COMPUTERNAME,
        [switch]$IncludeSMARTData,
        [int]$WarningDiskSpace = 10, # 磁盘空间警告阈值（百分比）
        [int]$WarningMemory = 80,    # 内存使用警告阈值（百分比）
        [int]$WarningCPU = 90        # CPU使用警告阈值（百分比）
    )
    
    try {
        $health = [PSCustomObject]@{
            ComputerName = $ComputerName
            Timestamp = Get-Date
            Status = "Healthy"
            Warnings = @()
            Errors = @()
        }
        
        # 获取基本系统资源信息
        $resources = Get-SystemResourceInfo -ComputerName $ComputerName -All
        
        # 检查CPU健康状况
        $cpuUsage = [double]($resources.CPU.CurrentUsage -replace '%', '')
        if ($cpuUsage -ge $WarningCPU) {
            $health.Warnings += "CPU使用率 ($cpuUsage%) 超过警告阈值 ($WarningCPU%)"
            $health.Status = "Warning"
        }
        
        # 检查内存健康状况
        $memoryUsage = [double]($resources.Memory.UsagePercent -replace '%', '')
        if ($memoryUsage -ge $WarningMemory) {
            $health.Warnings += "内存使用率 ($memoryUsage%) 超过警告阈值 ($WarningMemory%)"
            $health.Status = "Warning"
        }
        
        # 检查磁盘健康状况
        foreach ($drive in $resources.Disk.Drives) {
            $freePercent = [double]($drive.PercentFree -replace '%', '')
            if ($freePercent -le $WarningDiskSpace) {
                $health.Warnings += "磁盘 $($drive.Drive) 可用空间 ($freePercent%) 低于警告阈值 ($WarningDiskSpace%)"
                $health.Status = "Warning"
            }
        }
        
        # 获取和检查温度数据
        $temps = Get-SystemTemperature -ComputerName $ComputerName
        foreach ($temp in $temps) {
            if ($temp.Status -eq "Critical") {
                $health.Errors += "$($temp.SensorType) 温度 ($($temp.TemperatureCelsius)°C) 处于临界状态"
                $health.Status = "Critical"
            }
            elseif ($temp.Status -eq "Warning") {
                $health.Warnings += "$($temp.SensorType) 温度 ($($temp.TemperatureCelsius)°C) 超过警告阈值"
                if ($health.Status -ne "Critical") {
                    $health.Status = "Warning"
                }
            }
        }
        
        # 收集SMART数据（如果启用）
        if ($IncludeSMARTData) {
            # 这里使用CIM来获取SMART数据（需要WMIC）
            $smartData = @()
            $physicalDisks = Get-CimInstance -ComputerName $ComputerName -ClassName Win32_DiskDrive
            
            foreach ($disk in $physicalDisks) {
                try {
                    # 尝试获取SMART状态
                    $smartStatus = Get-CimInstance -ComputerName $ComputerName -Namespace "root\WMI" -ClassName MSStorageDriver_FailurePredictStatus -ErrorAction SilentlyContinue | 
                        Where-Object { $_.InstanceName -like "*$($disk.PNPDeviceID)*" }
                    
                    # 获取SMART属性
                    $smartAttribs = Get-CimInstance -ComputerName $ComputerName -Namespace "root\WMI" -ClassName MSStorageDriver_FailurePredictData -ErrorAction SilentlyContinue | 
                        Where-Object { $_.InstanceName -like "*$($disk.PNPDeviceID)*" }
                    
                    $diskSmart = [PSCustomObject]@{
                        DiskName = $disk.Caption
                        Model = $disk.Model
                        SerialNumber = $disk.SerialNumber
                        FailurePredicted = if ($smartStatus) { $smartStatus.PredictFailure } else { "Unknown" }
                        SMARTDataAvailable = if ($smartAttribs) { $true } else { $false }
                        SMARTRawData = if ($smartAttribs) { $smartAttribs.VendorSpecific } else { $null }
                    }
                    
                    $smartData += $diskSmart
                    
                    # 如果预测硬盘将要故障，添加错误
                    if ($diskSmart.FailurePredicted) {
                        $health.Errors += "硬盘 $($diskSmart.DiskName) ($($diskSmart.Model)) 预测将故障"
                        $health.Status = "Critical"
                    }
                }
                catch {
                    Write-Warning "无法获取硬盘 $($disk.DeviceID) 的 SMART 数据: $_"
                }
            }
            
            $health | Add-Member -MemberType NoteProperty -Name "SMARTData" -Value $smartData
        }
        
        # 添加基础指标
        $health | Add-Member -MemberType NoteProperty -Name "ResourceMetrics" -Value $resources
        $health | Add-Member -MemberType NoteProperty -Name "TemperatureMetrics" -Value $temps
        
        return $health
    }
    catch {
        Write-Error "获取硬件健康状态时出错: $_"
    }
}
```

现在，让我们创建一个持续监控和报警函数：

```powershell
# 创建持续监控和报警功能
function Start-HardwareMonitoring {
    param(
        [string[]]$ComputerNames = @($env:COMPUTERNAME),
        [int]$Interval = 300, # 间隔时间（秒）
        [string]$LogPath,     # 日志保存路径
        [int]$Duration = 3600, # 持续时间（秒）
        [scriptblock]$AlertAction, # 警报触发时执行的操作
        [switch]$EnableEmailAlerts, # 是否启用电子邮件警报
        [string]$SmtpServer,
        [string]$FromAddress,
        [string[]]$ToAddresses
    )
    
    try {
        $startTime = Get-Date
        $endTime = $startTime.AddSeconds($Duration)
        $currentTime = $startTime
        
        Write-Host "开始硬件监控，将持续到 $($endTime.ToString('yyyy-MM-dd HH:mm:ss'))"
        
        # 创建日志文件
        if ($LogPath) {
            $logFile = Join-Path -Path $LogPath -ChildPath "HardwareMonitoring_$(Get-Date -Format 'yyyyMMdd_HHmmss').csv"
            $logHeaders = "Timestamp,ComputerName,Status,CPUUsage,MemoryUsage,FreeDiskSpace,Temperature,Warnings,Errors"
            $logHeaders | Out-File -FilePath $logFile
        }
        
        while ($currentTime -lt $endTime) {
            foreach ($computer in $ComputerNames) {
                # 获取硬件健康信息
                $healthInfo = Get-HardwareHealth -ComputerName $computer -IncludeSMARTData
                
                # 将结果保存到日志文件
                if ($LogPath) {
                    $cpuUsage = $healthInfo.ResourceMetrics.CPU.CurrentUsage -replace '%', ''
                    $memoryUsage = $healthInfo.ResourceMetrics.Memory.UsagePercent -replace '%', ''
                    $freeDiskSpace = ($healthInfo.ResourceMetrics.Disk.Drives | ForEach-Object { $_.PercentFree -replace '%', '' }) -join '|'
                    $temperature = ($healthInfo.TemperatureMetrics | ForEach-Object { "$($_.SensorType):$($_.TemperatureCelsius)" }) -join '|'
                    $warnings = ($healthInfo.Warnings -join '|').Replace(',', ';')
                    $errors = ($healthInfo.Errors -join '|').Replace(',', ';')
                    
                    $logLine = "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss'),$computer,$($healthInfo.Status),$cpuUsage,$memoryUsage,$freeDiskSpace,$temperature,`"$warnings`",`"$errors`""
                    $logLine | Out-File -FilePath $logFile -Append
                }
                
                # 显示状态
                $statusColor = switch ($healthInfo.Status) {
                    "Healthy" { "Green" }
                    "Warning" { "Yellow" }
                    "Critical" { "Red" }
                    default { "White" }
                }
                
                Write-Host "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') - $computer - 状态: " -NoNewline
                Write-Host $healthInfo.Status -ForegroundColor $statusColor
                
                # 显示警告和错误
                foreach ($warning in $healthInfo.Warnings) {
                    Write-Host "  警告: $warning" -ForegroundColor Yellow
                }
                
                foreach ($error in $healthInfo.Errors) {
                    Write-Host "  错误: $error" -ForegroundColor Red
                }
                
                # 如果状态不是健康，执行警报操作
                if ($healthInfo.Status -ne "Healthy") {
                    # 执行自定义警报动作
                    if ($AlertAction) {
                        & $AlertAction -HealthInfo $healthInfo
                    }
                    
                    # 发送电子邮件警报
                    if ($EnableEmailAlerts -and $SmtpServer -and $FromAddress -and $ToAddresses) {
                        $subject = "硬件监控警报 - $computer - $($healthInfo.Status)"
                        $body = @"
计算机: $computer
状态: $($healthInfo.Status)
时间: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')

警告:
$($healthInfo.Warnings | ForEach-Object { "- $_" } | Out-String)

错误:
$($healthInfo.Errors | ForEach-Object { "- $_" } | Out-String)

系统指标:
- CPU使用率: $($healthInfo.ResourceMetrics.CPU.CurrentUsage)
- 内存使用率: $($healthInfo.ResourceMetrics.Memory.UsagePercent)
- 磁盘使用情况:
$($healthInfo.ResourceMetrics.Disk.Drives | ForEach-Object { "  $($_.Drive): 可用空间 $($_.PercentFree)" } | Out-String)
"@
                        
                        $emailParams = @{
                            SmtpServer = $SmtpServer
                            From = $FromAddress
                            To = $ToAddresses
                            Subject = $subject
                            Body = $body
                        }
                        
                        try {
                            Send-MailMessage @emailParams
                            Write-Host "  已发送电子邮件警报" -ForegroundColor Cyan
                        }
                        catch {
                            Write-Host "  发送电子邮件警报失败: $_" -ForegroundColor Red
                        }
                    }
                }
            }
            
            # 更新当前时间
            $currentTime = Get-Date
            
            # 如果还没有到结束时间，等待到下一个间隔
            if ($currentTime -lt $endTime) {
                $nextCheckTime = $currentTime.AddSeconds($Interval)
                $waitTime = ($nextCheckTime - $currentTime).TotalSeconds
                
                Write-Host "下一次检查将在 $($nextCheckTime.ToString('HH:mm:ss')) 进行 (等待 $([Math]::Round($waitTime, 0)) 秒)" -ForegroundColor Cyan
                Start-Sleep -Seconds ([Math]::Round($waitTime, 0))
            }
        }
        
        Write-Host "硬件监控已完成。监控持续了 $([Math]::Round(((Get-Date) - $startTime).TotalMinutes, 0)) 分钟。"
        
        if ($LogPath) {
            Write-Host "监控日志已保存至: $logFile"
        }
    }
    catch {
        Write-Error "硬件监控过程中出错: $_"
    }
}
```

使用示例：

```powershell
# 获取单次系统资源信息
Get-SystemResourceInfo -All

# 获取系统温度信息
Get-SystemTemperature

# 获取完整的硬件健康状态
Get-HardwareHealth -IncludeSMARTData

# 启动持续监控（每5分钟一次，持续1小时，保存日志到指定路径）
Start-HardwareMonitoring -Interval 300 -Duration 3600 -LogPath "C:\Logs"

# 带邮件警报的持续监控
Start-HardwareMonitoring -Interval 300 -Duration 3600 -LogPath "C:\Logs" -EnableEmailAlerts -SmtpServer "smtp.company.com" -FromAddress "monitoring@company.com" -ToAddresses "admin@company.com"

# 使用自定义警报动作（例如，向Teams发送消息）
$alertAction = {
    param($HealthInfo)
    
    $webhookUrl = "https://company.webhook.office.com/webhookb2/..."
    
    $body = @{
        "@type" = "MessageCard"
        "@context" = "http://schema.org/extensions"
        "themeColor" = if ($HealthInfo.Status -eq "Critical") { "FF0000" } else { "FFA500" }
        "summary" = "硬件监控警报 - $($HealthInfo.ComputerName)"
        "sections" = @(
            @{
                "activityTitle" = "硬件监控警报"
                "activitySubtitle" = "状态: $($HealthInfo.Status)"
                "facts" = @(
                    @{
                        "name" = "计算机"
                        "value" = $HealthInfo.ComputerName
                    },
                    @{
                        "name" = "时间"
                        "value" = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
                    },
                    @{
                        "name" = "问题"
                        "value" = ($HealthInfo.Warnings + $HealthInfo.Errors) -join "; "
                    }
                )
            }
        )
    } | ConvertTo-Json -Depth 4
    
    Invoke-RestMethod -Uri $webhookUrl -Method Post -ContentType 'application/json' -Body $body
}

Start-HardwareMonitoring -AlertAction $alertAction -Interval 300 -Duration 3600 -LogPath "C:\Logs"
```

这些脚本提供了全面的硬件监控功能，可以帮助IT管理员密切关注系统健康状况。对于企业环境，可以考虑将这些功能集成到现有的监控系统中，如SCOM、Nagios或Zabbix。也可以使用Windows任务计划程序来定期运行这些脚本，实现持续监控和长期趋势分析。 