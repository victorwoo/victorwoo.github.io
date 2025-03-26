---
layout: post
date: 2024-05-06 08:00:00
title: "PowerShell 技能连载 - CIM/WMI 管理技巧"
description: PowerTip of the Day - PowerShell CIM/WMI Management Tips
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
在 PowerShell 中管理 CIM（Common Information Model）和 WMI（Windows Management Instrumentation）是一项重要任务，本文将介绍一些实用的 CIM/WMI 管理技巧。

首先，让我们看看基本的 CIM/WMI 操作：

```powershell
# 创建 CIM/WMI 信息获取函数
function Get-CIMInfo {
    param(
        [string]$ComputerName = $env:COMPUTERNAME,
        [string]$Namespace = "root/cimv2",
        [string]$Class
    )
    
    try {
        $session = New-CimSession -ComputerName $ComputerName
        $instances = Get-CimInstance -CimSession $session -Namespace $Namespace -Class $Class
        
        return [PSCustomObject]@{
            ComputerName = $ComputerName
            Namespace = $Namespace
            Class = $Class
            InstanceCount = $instances.Count
            Properties = $instances[0].PSObject.Properties.Name
            Instances = $instances
        }
    }
    catch {
        Write-Host "获取 CIM 信息失败：$_"
    }
    finally {
        if ($session) {
            Remove-CimSession -CimSession $session
        }
    }
}
```

CIM/WMI 查询优化：

```powershell
# 创建 CIM/WMI 查询优化函数
function Optimize-CIMQuery {
    param(
        [string]$ComputerName = $env:COMPUTERNAME,
        [string]$Namespace = "root/cimv2",
        [string]$Class,
        [hashtable]$Filter,
        [string[]]$Properties,
        [int]$Timeout = 30
    )
    
    try {
        $session = New-CimSession -ComputerName $ComputerName -OperationTimeoutSec $Timeout
        
        $query = "SELECT "
        if ($Properties) {
            $query += $Properties -join ","
        }
        else {
            $query += "*"
        }
        $query += " FROM $Class"
        
        if ($Filter) {
            $query += " WHERE " + ($Filter.GetEnumerator() | ForEach-Object {
                "$($_.Key) = '$($_.Value)'"
            }) -join " AND "
        }
        
        $instances = Get-CimInstance -CimSession $session -Namespace $Namespace -Query $query
        
        return [PSCustomObject]@{
            Query = $query
            InstanceCount = $instances.Count
            ExecutionTime = $instances.PSIsContainer
            Results = $instances
        }
    }
    catch {
        Write-Host "查询优化失败：$_"
    }
    finally {
        if ($session) {
            Remove-CimSession -CimSession $session
        }
    }
}
```

CIM/WMI 方法调用：

```powershell
# 创建 CIM/WMI 方法调用函数
function Invoke-CIMMethod {
    param(
        [string]$ComputerName = $env:COMPUTERNAME,
        [string]$Namespace = "root/cimv2",
        [string]$Class,
        [string]$Method,
        [hashtable]$Parameters,
        [hashtable]$Filter
    )
    
    try {
        $session = New-CimSession -ComputerName $ComputerName
        
        $instance = Get-CimInstance -CimSession $session -Namespace $Namespace -Class $Class -Filter ($Filter.GetEnumerator() | ForEach-Object {
            "$($_.Key) = '$($_.Value)'"
        }) -join " AND "
        
        if ($instance) {
            $result = Invoke-CimMethod -CimInstance $instance -MethodName $Method -Arguments $Parameters
            
            return [PSCustomObject]@{
                Success = $result.ReturnValue -eq 0
                ReturnValue = $result.ReturnValue
                ReturnDescription = $result.ReturnDescription
                Parameters = $Parameters
            }
        }
        else {
            throw "未找到匹配的实例"
        }
    }
    catch {
        Write-Host "方法调用失败：$_"
    }
    finally {
        if ($session) {
            Remove-CimSession -CimSession $session
        }
    }
}
```

CIM/WMI 事件监控：

```powershell
# 创建 CIM/WMI 事件监控函数
function Monitor-CIMEvents {
    param(
        [string]$ComputerName = $env:COMPUTERNAME,
        [string]$Namespace = "root/cimv2",
        [string]$Class,
        [hashtable]$Filter,
        [int]$Duration = 3600,
        [scriptblock]$Action
    )
    
    try {
        $session = New-CimSession -ComputerName $ComputerName
        $query = "SELECT * FROM $Class"
        
        if ($Filter) {
            $query += " WHERE " + ($Filter.GetEnumerator() | ForEach-Object {
                "$($_.Key) = '$($_.Value)'"
            }) -join " AND "
        }
        
        $events = Register-CimIndicationEvent -CimSession $session -Namespace $Namespace -Query $query -Action $Action
        
        Start-Sleep -Seconds $Duration
        
        Unregister-Event -SourceIdentifier $events.Name
        Remove-CimSession -CimSession $session
        
        Write-Host "事件监控完成"
    }
    catch {
        Write-Host "事件监控失败：$_"
    }
    finally {
        if ($session) {
            Remove-CimSession -CimSession $session
        }
    }
}
```

CIM/WMI 性能优化：

```powershell
# 创建 CIM/WMI 性能优化函数
function Optimize-CIMPerformance {
    param(
        [string]$ComputerName = $env:COMPUTERNAME,
        [string]$Namespace = "root/cimv2",
        [string]$Class,
        [int]$BatchSize = 100,
        [int]$MaxThreads = 4
    )
    
    try {
        $session = New-CimSession -ComputerName $ComputerName
        $instances = Get-CimInstance -CimSession $session -Namespace $Namespace -Class $Class
        
        $batches = @()
        for ($i = 0; $i -lt $instances.Count; $i += $BatchSize) {
            $batches += $instances[$i..([math]::Min($i + $BatchSize - 1, $instances.Count - 1))]
        }
        
        $results = @()
        $batches | ForEach-Object -ThrottleLimit $MaxThreads -Parallel {
            $batch = $_
            $session = New-CimSession -ComputerName $using:ComputerName
            
            $batch | ForEach-Object {
                # 在这里添加批处理逻辑
                [PSCustomObject]@{
                    Instance = $_.Name
                    Status = "Processed"
                }
            }
            
            Remove-CimSession -CimSession $session
        }
        
        return [PSCustomObject]@{
            TotalInstances = $instances.Count
            BatchCount = $batches.Count
            Results = $results
        }
    }
    catch {
        Write-Host "性能优化失败：$_"
    }
    finally {
        if ($session) {
            Remove-CimSession -CimSession $session
        }
    }
}
```

这些技巧将帮助您更有效地管理 CIM/WMI。记住，在处理 CIM/WMI 时，始终要注意查询性能和资源使用。同时，建议使用适当的错误处理和会话管理机制来确保操作的可靠性。 