---
layout: post
date: 2024-04-25 08:00:00
title: "PowerShell 技能连载 - 绿色计算与能耗优化"
description: PowerTip of the Day - PowerShell Green Computing and Energy Optimization
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
在当今关注可持续发展的环境中，绿色计算和能耗优化越来越重要。本文将介绍如何使用 PowerShell 实现绿色计算和能耗优化的关键技术。

首先，让我们看看如何监控系统能耗：

```powershell
# 创建能耗监控函数
function Measure-PowerConsumption {
    param(
        [string]$ComputerName = $env:COMPUTERNAME,
        [int]$Duration = 3600,
        [int]$Interval = 60,
        [string]$OutputPath
    )
    
    try {
        $metrics = @()
        $endTime = Get-Date
        $startTime = $endTime.AddSeconds(-$Duration)
        
        while ($startTime -lt $endTime) {
            # 获取 CPU 使用率
            $cpu = Get-Counter '\Processor(_Total)\% Processor Time' -ComputerName $ComputerName
            
            # 获取内存使用率
            $totalMem = (Get-CimInstance -ComputerName $ComputerName -ClassName Win32_ComputerSystem).TotalPhysicalMemory / 1GB
            $availableMem = (Get-CimInstance -ComputerName $ComputerName -ClassName Win32_OperatingSystem).FreePhysicalMemory / 1MB
            $memUsage = (($totalMem - $availableMem) / $totalMem) * 100
            
            # 获取磁盘活动
            $diskRead = Get-Counter '\PhysicalDisk(_Total)\Disk Read Bytes/sec' -ComputerName $ComputerName
            $diskWrite = Get-Counter '\PhysicalDisk(_Total)\Disk Write Bytes/sec' -ComputerName $ComputerName
            
            # 获取网络活动
            $netSent = Get-Counter '\Network Interface(*)\Bytes Sent/sec' -ComputerName $ComputerName
            $netReceived = Get-Counter '\Network Interface(*)\Bytes Received/sec' -ComputerName $ComputerName
            
            # 估算功耗 (模拟计算，实际功耗需要专业工具测量)
            $cpuPower = ($cpu.CounterSamples.CookedValue / 100) * 65 # 假设满载 CPU 为 65W
            $memPower = ($memUsage / 100) * 10 # 假设满载内存为 10W
            $diskPower = (($diskRead.CounterSamples.CookedValue + $diskWrite.CounterSamples.CookedValue) / 1MB) * 0.5 # 假设每 MB I/O 消耗 0.5W
            $netPower = (($netSent.CounterSamples.CookedValue + $netReceived.CounterSamples.CookedValue) / 1MB) * 0.2 # 假设每 MB 网络传输消耗 0.2W
            
            $totalPower = $cpuPower + $memPower + $diskPower + $netPower + 20 # 加上基础功耗约 20W
            
            $metric = [PSCustomObject]@{
                Timestamp = Get-Date
                CPUUsage = $cpu.CounterSamples.CookedValue
                MemoryUsage = $memUsage
                DiskReadBytes = $diskRead.CounterSamples.CookedValue
                DiskWriteBytes = $diskWrite.CounterSamples.CookedValue
                NetworkSentBytes = $netSent.CounterSamples.CookedValue
                NetworkReceivedBytes = $netReceived.CounterSamples.CookedValue
                EstimatedPowerWatts = $totalPower
            }
            
            $metrics += $metric
            
            $startTime = $startTime.AddSeconds($Interval)
            Start-Sleep -Seconds $Interval
        }
        
        if ($OutputPath) {
            $metrics | Export-Csv -Path $OutputPath -NoTypeInformation
            Write-Host "能耗监控结果已保存至：$OutputPath"
        }
        
        $averagePower = ($metrics | Measure-Object -Property EstimatedPowerWatts -Average).Average
        $maxPower = ($metrics | Measure-Object -Property EstimatedPowerWatts -Maximum).Maximum
        
        return [PSCustomObject]@{
            ComputerName = $ComputerName
            Duration = $Duration
            Interval = $Interval
            AveragePowerWatts = $averagePower
            MaximumPowerWatts = $maxPower
            TotalEnergyKWh = ($averagePower * $Duration) / 3600000
            DetailedMetrics = $metrics
        }
    }
    catch {
        Write-Host "能耗监控失败：$_"
    }
}
```

优化电源管理设置：

```powershell
# 创建电源管理优化函数
function Optimize-PowerSettings {
    param(
        [string]$ComputerName = $env:COMPUTERNAME,
        [ValidateSet('Balanced', 'PowerSaver', 'HighPerformance', 'Ultimate')]
        [string]$PowerPlan = 'Balanced',
        [int]$DisplayTimeout = 600,
        [int]$SleepTimeout = 1800,
        [int]$HardDiskTimeout = 1200
    )
    
    try {
        # 获取和激活所选电源计划
        $powerPlans = powercfg /list | Where-Object { $_ -match '([a-z0-9-]{36})' }
        $planGuid = switch ($PowerPlan) {
            'Balanced' { ($powerPlans | Where-Object { $_ -match 'Balanced' } | Select-String -Pattern '([a-z0-9-]{36})').Matches.Value }
            'PowerSaver' { ($powerPlans | Where-Object { $_ -match 'Power saver' } | Select-String -Pattern '([a-z0-9-]{36})').Matches.Value }
            'HighPerformance' { ($powerPlans | Where-Object { $_ -match 'High performance' } | Select-String -Pattern '([a-z0-9-]{36})').Matches.Value }
            'Ultimate' { ($powerPlans | Where-Object { $_ -match 'Ultimate Performance' } | Select-String -Pattern '([a-z0-9-]{36})').Matches.Value }
        }
        
        if ($planGuid) {
            Invoke-Command -ComputerName $ComputerName -ScriptBlock {
                param($guid)
                powercfg /setactive $guid
            } -ArgumentList $planGuid
            
            Write-Host "已激活电源计划：$PowerPlan"
        } else {
            Write-Host "未找到电源计划：$PowerPlan"
        }
        
        # 设置显示器超时
        Invoke-Command -ComputerName $ComputerName -ScriptBlock {
            param($timeout)
            powercfg /change monitor-timeout-ac $timeout
            powercfg /change monitor-timeout-dc $timeout
        } -ArgumentList $DisplayTimeout / 60
        
        # 设置睡眠超时
        Invoke-Command -ComputerName $ComputerName -ScriptBlock {
            param($timeout)
            powercfg /change standby-timeout-ac $timeout
            powercfg /change standby-timeout-dc $timeout
        } -ArgumentList $SleepTimeout / 60
        
        # 设置硬盘超时
        Invoke-Command -ComputerName $ComputerName -ScriptBlock {
            param($timeout)
            powercfg /change disk-timeout-ac $timeout
            powercfg /change disk-timeout-dc $timeout
        } -ArgumentList $HardDiskTimeout / 60
        
        return [PSCustomObject]@{
            ComputerName = $ComputerName
            PowerPlan = $PowerPlan
            DisplayTimeoutMinutes = $DisplayTimeout / 60
            SleepTimeoutMinutes = $SleepTimeout / 60
            HardDiskTimeoutMinutes = $HardDiskTimeout / 60
        }
    }
    catch {
        Write-Host "电源设置优化失败：$_"
    }
}
```

管理非工作时间的自动关机：

```powershell
# 创建非工作时间管理函数
function Schedule-NonWorkHours {
    param(
        [string]$ComputerName = $env:COMPUTERNAME,
        [ValidateSet('Shutdown', 'Hibernate', 'Sleep')]
        [string]$Action = 'Sleep',
        [int]$StartHour = 18,
        [int]$EndHour = 8,
        [switch]$WeekendShutdown,
        [switch]$EnableWakeUp
    )
    
    try {
        # 创建周一至周五的关机任务
        $taskName = "GreenComputing_$Action"
        $actionString = switch ($Action) {
            'Shutdown' { "shutdown /s /f /t 60" }
            'Hibernate' { "rundll32.exe powrprof.dll,SetSuspendState Hibernate" }
            'Sleep' { "rundll32.exe powrprof.dll,SetSuspendState Sleep" }
        }
        
        # 删除已存在的任务
        Invoke-Command -ComputerName $ComputerName -ScriptBlock {
            param($name)
            schtasks /delete /tn $name /f 2>$null
        } -ArgumentList $taskName
        
        # 创建工作日关机任务
        Invoke-Command -ComputerName $ComputerName -ScriptBlock {
            param($name, $action, $hour)
            schtasks /create /tn $name /tr $action /sc weekly /d MON,TUE,WED,THU,FRI /st $('{0:00}' -f $hour):00:00 /f
        } -ArgumentList $taskName, $actionString, $StartHour
        
        # 如果启用周末关机
        if ($WeekendShutdown) {
            $weekendTaskName = "GreenComputing_Weekend_$Action"
            
            # 删除已存在的周末任务
            Invoke-Command -ComputerName $ComputerName -ScriptBlock {
                param($name)
                schtasks /delete /tn $name /f 2>$null
            } -ArgumentList $weekendTaskName
            
            # 创建周末关机任务
            Invoke-Command -ComputerName $ComputerName -ScriptBlock {
                param($name, $action)
                schtasks /create /tn $name /tr $action /sc weekly /d SAT,SUN /st 20:00:00 /f
            } -ArgumentList $weekendTaskName, $actionString
            
            Write-Host "已创建周末$Action任务：$weekendTaskName"
        }
        
        # 如果启用唤醒
        if ($EnableWakeUp) {
            $wakeTaskName = "GreenComputing_WakeUp"
            
            # 删除已存在的唤醒任务
            Invoke-Command -ComputerName $ComputerName -ScriptBlock {
                param($name)
                schtasks /delete /tn $name /f 2>$null
            } -ArgumentList $wakeTaskName
            
            # 创建唤醒任务
            Invoke-Command -ComputerName $ComputerName -ScriptBlock {
                param($name, $hour)
                $wakeupAction = 'powercfg -requestsoverride Process System Awaymode'
                schtasks /create /tn $name /tr $wakeupAction /sc weekly /d MON,TUE,WED,THU,FRI /st $('{0:00}' -f $hour):00:00 /f
            } -ArgumentList $wakeTaskName, $EndHour
            
            Write-Host "已创建唤醒任务：$wakeTaskName"
        }
        
        return [PSCustomObject]@{
            ComputerName = $ComputerName
            ActionScheduled = $Action
            WorkdaysStartHour = $StartHour
            WorkdaysEndHour = $EndHour
            WeekendShutdownEnabled = $WeekendShutdown
            WakeUpEnabled = $EnableWakeUp
        }
    }
    catch {
        Write-Host "非工作时间管理设置失败：$_"
    }
}
```

优化虚拟机整合和资源利用：

```powershell
# 创建虚拟机优化函数
function Optimize-VMConsolidation {
    param(
        [string]$HyperVHost,
        [float]$TargetHostCPUUtilization = 70.0,
        [float]$TargetHostMemoryUtilization = 80.0,
        [switch]$MoveVMs,
        [string]$ReportPath
    )
    
    try {
        # 获取 Hyper-V 主机信息
        $hostInfo = Get-CimInstance -ComputerName $HyperVHost -ClassName Win32_ComputerSystem
        $hostProcessor = Get-CimInstance -ComputerName $HyperVHost -ClassName Win32_Processor
        $hostMemory = $hostInfo.TotalPhysicalMemory / 1GB
        $hostCores = ($hostProcessor | Measure-Object -Property NumberOfCores -Sum).Sum
        
        # 获取主机 CPU 和内存使用率
        $hostCpuUsage = (Get-Counter -ComputerName $HyperVHost -Counter "\Processor(_Total)\% Processor Time").CounterSamples.CookedValue
        $hostMemUsage = 100 - (Get-CimInstance -ComputerName $HyperVHost -ClassName Win32_OperatingSystem).FreePhysicalMemory * 100 / ($hostInfo.TotalPhysicalMemory / 1KB)
        
        # 获取所有 VM
        $vms = Get-VM -ComputerName $HyperVHost
        
        # 计算当前资源分配
        $vmSummary = $vms | ForEach-Object {
            $vmCpuUsage = (Get-Counter -ComputerName $HyperVHost -Counter "\Hyper-V Hypervisor Virtual Processor($($_.Name))\% Guest Run Time").CounterSamples.CookedValue
            $vmAssignedMemory = $_.MemoryAssigned / 1GB
            
            [PSCustomObject]@{
                Name = $_.Name
                Status = $_.State
                CPUCount = $_.ProcessorCount
                AssignedMemoryGB = $vmAssignedMemory
                CPUUsage = $vmCpuUsage
                DynamicMemory = $_.DynamicMemoryEnabled
                MemoryDemandGB = $_.MemoryDemand / 1GB
                IdleTime = if ($_.Uptime) { $_.Uptime.TotalHours } else { 0 }
            }
        }
        
        # 计算理想资源分配
        $optimizedVMs = $vmSummary | Where-Object { $_.Status -eq 'Running' } | ForEach-Object {
            $idealCPUs = [Math]::Max(1, [Math]::Ceiling($_.CPUCount * ($_.CPUUsage / $TargetHostCPUUtilization)))
            $idealMemory = [Math]::Max(0.5, [Math]::Ceiling($_.AssignedMemoryGB * ($_.MemoryDemandGB / $_.AssignedMemoryGB) / ($TargetHostMemoryUtilization / 100)))
            
            $reconfigure = $idealCPUs -ne $_.CPUCount -or $idealMemory -ne $_.AssignedMemoryGB
            
            [PSCustomObject]@{
                Name = $_.Name
                CurrentCPUs = $_.CPUCount
                OptimalCPUs = $idealCPUs
                CurrentMemoryGB = $_.AssignedMemoryGB
                OptimalMemoryGB = $idealMemory
                ShouldReconfigure = $reconfigure
                CPUChangePercent = if ($_.CPUCount -gt 0) { (($idealCPUs - $_.CPUCount) / $_.CPUCount) * 100 } else { 0 }
                MemoryChangePercent = if ($_.AssignedMemoryGB -gt 0) { (($idealMemory - $_.AssignedMemoryGB) / $_.AssignedMemoryGB) * 100 } else { 0 }
                PowerSavings = if ($reconfigure) { "High" } elseif ($idealCPUs -eq $_.CPUCount -and [Math]::Abs($idealMemory - $_.AssignedMemoryGB) < 0.5) { "Low" } else { "Medium" }
            }
        }
        
        # 计算整合后的预期节能效果
        $currentPower = $hostCores * 5 + $hostMemory * 2 # 假设每个核心消耗 5W，每 GB 内存消耗 2W
        $projectedPower = $optimizedVMs | Measure-Object -Property OptimalCPUs -Sum | ForEach-Object { $_.Sum * 5 } 
        $projectedPower += $optimizedVMs | Measure-Object -Property OptimalMemoryGB -Sum | ForEach-Object { $_.Sum * 2 }
        
        $powerSavingEstimate = $currentPower - $projectedPower
        $powerSavingPercentage = if ($currentPower -gt 0) { ($powerSavingEstimate / $currentPower) * 100 } else { 0 }
        
        # 如果启用 VM 移动
        if ($MoveVMs) {
            foreach ($vm in $optimizedVMs | Where-Object { $_.ShouldReconfigure }) {
                if ($vm.OptimalCPUs -ne $vm.CurrentCPUs) {
                    Set-VM -ComputerName $HyperVHost -Name $vm.Name -ProcessorCount $vm.OptimalCPUs
                    Write-Host "已将 $($vm.Name) 的 CPU 数量从 $($vm.CurrentCPUs) 更改为 $($vm.OptimalCPUs)"
                }
                
                if ($vm.OptimalMemoryGB -ne $vm.CurrentMemoryGB) {
                    $memoryBytes = $vm.OptimalMemoryGB * 1GB
                    Set-VMMemory -ComputerName $HyperVHost -VMName $vm.Name -StartupBytes $memoryBytes
                    Write-Host "已将 $($vm.Name) 的内存从 $($vm.CurrentMemoryGB) GB 更改为 $($vm.OptimalMemoryGB) GB"
                }
            }
        }
        
        $report = [PSCustomObject]@{
            HyperVHost = $HyperVHost
            HostCores = $hostCores
            HostMemoryGB = $hostMemory
            CurrentHostCPUUsage = $hostCpuUsage
            CurrentHostMemoryUsage = $hostMemUsage
            RunningVMs = ($vms | Where-Object { $_.State -eq 'Running' }).Count
            TotalVMs = $vms.Count
            OptimizationDetails = $optimizedVMs
            EstimatedPowerSavingsWatts = $powerSavingEstimate
            EstimatedPowerSavingsPercent = $powerSavingPercentage
            ReconfiguredVMs = if ($MoveVMs) { ($optimizedVMs | Where-Object { $_.ShouldReconfigure }).Count } else { 0 }
        }
        
        if ($ReportPath) {
            $report | ConvertTo-Json -Depth 5 | Out-File -FilePath $ReportPath -Encoding UTF8
            Write-Host "虚拟机优化报告已保存至：$ReportPath"
        }
        
        return $report
    }
    catch {
        Write-Host "虚拟机整合优化失败：$_"
    }
}
```

数据中心能效指标计算：

```powershell
# 创建数据中心能效指标函数
function Get-DatacenterEfficiency {
    param(
        [string[]]$Servers,
        [float]$FacilityPowerKW,
        [int]$SamplingInterval = 300,
        [int]$SamplingCount = 12,
        [string]$OutputPath
    )
    
    try {
        $measurements = @()
        
        for ($i = 0; $i -lt $SamplingCount; $i++) {
            $serverPowerUsage = 0
            
            foreach ($server in $Servers) {
                # 这里假设使用前面定义的函数测量服务器功耗
                $powerMeasurement = Measure-PowerConsumption -ComputerName $server -Duration 60 -Interval 10
                $serverPowerUsage += $powerMeasurement.AveragePowerWatts
            }
            
            # 转换为千瓦
            $serverPowerKW = $serverPowerUsage / 1000
            
            # 计算 PUE (Power Usage Effectiveness)
            $pue = if ($serverPowerKW -gt 0) { $FacilityPowerKW / $serverPowerKW } else { 0 }
            
            $measurement = [PSCustomObject]@{
                Timestamp = Get-Date
                ServerPowerKW = $serverPowerKW
                FacilityPowerKW = $FacilityPowerKW
                PUE = $pue
            }
            
            $measurements += $measurement
            
            if ($i -lt $SamplingCount - 1) {
                Start-Sleep -Seconds $SamplingInterval
            }
        }
        
        # 计算平均 PUE
        $averagePUE = ($measurements | Measure-Object -Property PUE -Average).Average
        
        # 计算能效评级
        $efficiencyRating = switch ($averagePUE) {
            { $_ -lt 1.2 } { "Excellent (Tier 4)" }
            { $_ -lt 1.5 } { "Very Good (Tier 3)" }
            { $_ -lt 2.0 } { "Good (Tier 2)" }
            { $_ -lt 2.5 } { "Fair (Tier 1)" }
            default { "Poor" }
        }
        
        $results = [PSCustomObject]@{
            Servers = $Servers
            SamplingInterval = $SamplingInterval
            SamplingCount = $SamplingCount
            AveragePUE = $averagePUE
            EfficiencyRating = $efficiencyRating
            MinimumPUE = ($measurements | Measure-Object -Property PUE -Minimum).Minimum
            MaximumPUE = ($measurements | Measure-Object -Property PUE -Maximum).Maximum
            AverageServerPowerKW = ($measurements | Measure-Object -Property ServerPowerKW -Average).Average
            DetailedMeasurements = $measurements
        }
        
        if ($OutputPath) {
            $results | ConvertTo-Json -Depth 5 | Out-File -FilePath $OutputPath -Encoding UTF8
            Write-Host "数据中心能效报告已保存至：$OutputPath"
        }
        
        return $results
    }
    catch {
        Write-Host "数据中心能效计算失败：$_"
    }
}
```

这些脚本将帮助您实现绿色计算和能耗优化的关键功能。记住，真正的绿色计算不仅是关于降低功耗，还包括延长硬件生命周期、减少电子垃圾和优化资源利用。通过这些 PowerShell 工具，您可以监控、优化和规划您的 IT 基础设施，使其更加环保和可持续。 