---
layout: post
date: 2026-01-05 08:00:00
title: "PowerShell 技能连载 - 类定义与面向对象编程"
description: PowerTip of the Day - Class Definition and Object-Oriented Programming in PowerShell
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
- class
- oop
- advanced
- types
---

_适用于 PowerShell 5.1 及以上版本_

在 PowerShell 的早期版本中，我们通常使用 `PSCustomObject` 或哈希表来构建自定义数据结构。虽然它们足够灵活，但缺乏类型约束、无法定义方法、也不支持继承，在构建大型自动化项目时显得力不从心。PowerShell 5.0 引入了 `class` 关键字，让我们可以直接在脚本中定义真正的 .NET 类型。

class 不仅仅是语法糖，它带来了完整的面向对象编程能力：类型安全的属性、可重载的构造函数、继承与多态、以及与 .NET 生态的无缝集成。你可以用 class 来建模业务实体、封装复杂逻辑、甚至实现设计模式，让脚本从"一次性工具"进化为可维护的工程化代码。

本文将从基础类定义开始，逐步深入继承与多态，最后通过一个服务器管理框架的实战案例，展示 class 在真实自动化场景中的威力。

## 基础类定义

下面通过一个 `ServerInfo` 类来演示属性、构造函数和方法的定义与使用。这个类用于封装服务器的基本信息，并提供格式化输出和状态检查方法。

```powershell
class ServerInfo {
    # 类型化的属性
    [string]$Name
    [string]$IPAddress
    [int]$Port
    [string]$Environment
    [datetime]$LastChecked

    # 默认构造函数
    ServerInfo() {
        $this.Port = 443
        $this.Environment = 'Development'
        $this.LastChecked = Get-Date
    }

    # 带参数的构造函数
    ServerInfo([string]$Name, [string]$IPAddress, [int]$Port) {
        $this.Name = $Name
        $this.IPAddress = $IPAddress
        $this.Port = $Port
        $this.Environment = 'Production'
        $this.LastChecked = Get-Date
    }

    # 方法：获取连接地址
    [string] GetEndpoint() {
        return "$($this.IPAddress):$($this.Port)"
    }

    # 方法：检查端口是否可达
    [bool] TestConnection() {
        try {
            $tcp = [System.Net.Sockets.TcpClient]::new()
            $connect = $tcp.BeginConnect($this.IPAddress, $this.Port, $null, $null)
            $wait = $connect.AsyncWaitHandle.WaitOne(3000, $false)
            if ($wait) {
                $tcp.EndConnect($connect)
                $this.LastChecked = Get-Date
                return $true
            }
            return $false
        }
        finally {
            $tcp.Dispose()
        }
    }

    # 重写 ToString 方法
    [string] ToString() {
        return "[$($this.Environment)] $($this.Name) ($($this.GetEndpoint()))"
    }
}

# 使用默认构造函数
$devServer = [ServerInfo]::new()
$devServer.Name = 'DEV-WEB-01'
$devServer.IPAddress = '192.168.1.100'
Write-Host $devServer.ToString()

# 使用带参数的构造函数
$prodServer = [ServerInfo]::new('PROD-WEB-01', '10.0.0.50', 8443)
Write-Host "服务器: $($prodServer.Name)"
Write-Host "端点: $($prodServer.GetEndpoint())"
Write-Host "环境: $($prodServer.Environment)"
Write-Host "上次检查: $($prodServer.LastChecked.ToString('yyyy-MM-dd HH:mm:ss'))"
```

执行结果示例：

```
[Development] DEV-WEB-01 (192.168.1.100:443)
服务器: PROD-WEB-01
端点: 10.0.0.50:8443
环境: Production
上次检查: 2026-01-05 08:30:15
```

## 继承与多态

当类之间具有层次关系时，继承可以让子类复用父类的属性和方法，同时添加或重写自己的行为。下面的例子定义了一个通用的部署任务基类，然后派生出两种具体的任务类型。

```powershell
# 基类：部署任务
class DeploymentTask {
    [string]$TaskName
    [string]$TargetServer
    [datetime]$StartTime
    [datetime]$EndTime
    [string]$Status = 'Pending'

    DeploymentTask([string]$TaskName, [string]$TargetServer) {
        $this.TaskName = $TaskName
        $this.TargetServer = $TargetServer
    }

    # 虚方法：执行部署（子类应重写）
    [void] Execute() {
        $this.StartTime = Get-Date
        Write-Host "正在执行任务: $($this.TaskName)"
    }

    # 标记完成
    [void] Complete() {
        $this.EndTime = Get-Date
        $this.Status = 'Completed'
        $duration = ($this.EndTime - $this.StartTime).TotalSeconds
        Write-Host "任务完成: $($this.TaskName) (耗时 $([math]::Round($duration, 2)) 秒)"
    }

    # 标记失败
    [void] Fail([string]$Reason) {
        $this.EndTime = Get-Date
        $this.Status = "Failed: $Reason"
        Write-Host "任务失败: $($this.TaskName) - $Reason"
    }

    # 获取摘要信息
    [hashtable] GetSummary() {
        return @{
            TaskName     = $this.TaskName
            TargetServer = $this.TargetServer
            Status       = $this.Status
            Duration     = if ($this.StartTime -and $this.EndTime) {
                ($this.EndTime - $this.StartTime).TotalSeconds
            } else { 0 }
        }
    }
}

# 子类：Web 应用部署
class WebAppDeployment : DeploymentTask {
    [string]$AppPoolName
    [string]$SiteName
    [string]$PackagePath

    WebAppDeployment(
        [string]$TargetServer,
        [string]$SiteName,
        [string]$PackagePath
    ) : base("Deploy-WebApp-$SiteName", $TargetServer) {
        $this.SiteName = $SiteName
        $this.AppPoolName = "$SiteName-Pool"
        $this.PackagePath = $PackagePath
    }

    # 重写 Execute 方法
    [void] Execute() {
        ([DeploymentTask]$this).Execute()
        Write-Host "  停止应用池: $($this.AppPoolName)"
        Write-Host "  备份当前版本..."
        Write-Host "  解压部署包: $($this.PackagePath)"
        Write-Host "  配置站点: $($this.SiteName)"
        Write-Host "  启动应用池: $($this.AppPoolName)"
        $this.Complete()
    }
}

# 子类：数据库迁移部署
class DatabaseMigration : DeploymentTask {
    [string]$DatabaseName
    [string]$MigrationScript
    [bool]$BackupBeforeMigration = $true

    DatabaseMigration(
        [string]$TargetServer,
        [string]$DatabaseName,
        [string]$MigrationScript
    ) : base("DB-Migration-$DatabaseName", $TargetServer) {
        $this.DatabaseName = $DatabaseName
        $this.MigrationScript = $MigrationScript
    }

    # 重写 Execute 方法
    [void] Execute() {
        ([DeploymentTask]$this).Execute()
        Write-Host "  目标数据库: $($this.DatabaseName)"
        if ($this.BackupBeforeMigration) {
            Write-Host "  正在备份数据库..."
        }
        Write-Host "  执行迁移脚本: $($this.MigrationScript)"
        Write-Host "  验证迁移结果..."
        $this.Complete()
    }
}

# 多态调用：统一执行不同类型的部署任务
$tasks = @(
    [WebAppDeployment]::new('WEB-SVR-01', 'CustomerPortal', 'D:\Packages\v2.5.0.zip')
    [DatabaseMigration]::new('DB-SVR-01', 'CustomerDB', 'v2.5.0_schema_update.sql')
)

foreach ($task in $tasks) {
    Write-Host "`n--- 部署任务 ---"
    $task.Execute()
    $summary = $task.GetSummary()
    Write-Host "摘要: $($summary.Status)"
}
```

执行结果示例：

```
--- 部署任务 ---
正在执行任务: Deploy-WebApp-CustomerPortal
  停止应用池: CustomerPortal-Pool
  备份当前版本...
  解压部署包: D:\Packages\v2.5.0.zip
  配置站点: CustomerPortal
  启动应用池: CustomerPortal-Pool
任务完成: Deploy-WebApp-CustomerPortal (耗时 12.35 秒)
摘要: Completed

--- 部署任务 ---
正在执行任务: DB-Migration-CustomerDB
  目标数据库: CustomerDB
  正在备份数据库...
  执行迁移脚本: v2.5.0_schema_update.sql
  验证迁移结果...
任务完成: DB-Migration-CustomerDB (耗时 8.72 秒)
摘要: Completed
```

## 实战应用：服务器管理框架

在实际运维场景中，我们可以用 class 构建一个完整的服务器管理框架，包含数据验证、JSON 序列化和结构化错误处理。

```powershell
# 验证属性类
class ValidateRangeAttribute : System.Management.Automation.ValidateArgumentsAttribute {
    [int]$MinValue
    [int]$MaxValue

    ValidateRangeAttribute([int]$Min, [int]$Max) {
        $this.MinValue = $Min
        $this.MaxValue = $Max
    }

    [void] Validate([object]$arguments, [System.Management.Automation.EngineIntrinsics]$engineIntrinsics) {
        $val = [int]$arguments
        if ($val -lt $this.MinValue -or $val -gt $this.MaxValue) {
            throw "值 $val 不在允许范围 ($($this.MinValue) - $($this.MaxValue)) 内"
        }
    }
}

# 服务器管理基类
class ManagedServer {
    [ValidateNotNullOrEmpty()][string]$HostName
    [string]$IPAddress
    [string]$Role
    [string]$DataCenter
    [bool]$IsMonitored = $false

    # 静态属性：已注册的服务器列表
    static [System.Collections.Generic.List[ManagedServer]]$Registry =
        [System.Collections.Generic.List[ManagedServer]]::new()

    ManagedServer([string]$HostName, [string]$IPAddress) {
        $this.HostName = $HostName
        $this.IPAddress = $IPAddress
        [ManagedServer]::Registry.Add($this)
    }

    # 转换为 JSON
    [string] ToJson() {
        $ordered = [ordered]@{
            hostName    = $this.HostName
            ipAddress   = $this.IPAddress
            role        = $this.Role
            dataCenter  = $this.DataCenter
            isMonitored = $this.IsMonitored
        }
        return $ordered | ConvertTo-Json -Depth 3
    }

    # 从 JSON 创建实例
    static [ManagedServer] FromJson([string]$Json) {
        $data = $Json | ConvertFrom-Json
        $server = [ManagedServer]::new($data.hostName, $data.ipAddress)
        $server.Role = $data.role
        $server.DataCenter = $data.dataCenter
        $server.IsMonitored = $data.isMonitored
        return $server
    }

    # 获取所有已注册服务器
    static [array] GetRegisteredServers() {
        return [ManagedServer]::Registry.ToArray()
    }
}

# 托管 Web 服务器
class ManagedWebServer : ManagedServer {
    [string[]]$BoundUrls = @()
    [int]$WorkerProcesses = 4
    [string]$RuntimeVersion = '8.0'
    [hashtable]$HealthMetrics = @{}

    ManagedWebServer([string]$HostName, [string]$IPAddress) : base($HostName, $IPAddress) {
        $this.Role = 'WebServer'
    }

    # 健康检查
    [hashtable] CheckHealth() {
        $result = @{
            Server    = $this.HostName
            Timestamp = Get-Date -Format 'o'
            Checks    = @()
        }

        $checks = @(
            @{ Name = 'CPU'; Value = (Get-Random -Min 10 -Max 95); Unit = '%' }
            @{ Name = 'Memory'; Value = (Get-Random -Min 30 -Max 90); Unit = '%' }
            @{ Name = 'Disk'; Value = (Get-Random -Min 20 -Max 85); Unit = '%' }
        )

        foreach ($check in $checks) {
            $status = if ($check.Value -gt 80) { 'Warning' } else { 'OK' }
            $result.Checks += @{
                Name   = $check.Name
                Value  = $check.Value
                Unit   = $check.Unit
                Status = $status
            }
        }

        $this.HealthMetrics = $result
        $this.IsMonitored = $true
        return $result
    }

    # 重写 ToJson 以包含扩展属性
    [string] ToJson() {
        $ordered = [ordered]@{
            hostName        = $this.HostName
            ipAddress       = $this.IPAddress
            role            = $this.Role
            dataCenter      = $this.DataCenter
            isMonitored     = $this.IsMonitored
            boundUrls       = $this.BoundUrls
            workerProcesses = $this.WorkerProcesses
            runtimeVersion  = $this.RuntimeVersion
        }
        return $ordered | ConvertTo-Json -Depth 3
    }
}

# --- 使用示例 ---

# 创建并注册服务器
$web1 = [ManagedWebServer]::new('WEB-PROD-01', '10.1.0.10')
$web1.DataCenter = 'EastAsia'
$web1.BoundUrls = @('https://portal.contoso.com', 'https://api.contoso.com')

$web2 = [ManagedWebServer]::new('WEB-PROD-02', '10.1.0.11')
$web2.DataCenter = 'EastAsia'
$web2.BoundUrls = @('https://portal.contoso.com')
$web2.WorkerProcesses = 8

Write-Host "已注册服务器数量: $([ManagedServer]::Registry.Count)"
Write-Host "`n--- $web1 健康检查 ---"
$health = $web1.CheckHealth()
foreach ($check in $health.Checks) {
    Write-Host ("  {0,-10} {1}{2,-5} [{3}]" -f $check.Name, $check.Value, $check.Unit, $check.Status)
}

Write-Host "`n--- JSON 序列化 ---"
Write-Host $web1.ToJson()
```

执行结果示例：

```
已注册服务器数量: 2

--- WEB-PROD-01 健康检查 ---
  CPU        42%    [OK]
  Memory     67%    [OK]
  Disk       31%    [OK]

--- JSON 序列化 ---
{
    "hostName": "WEB-PROD-01",
    "ipAddress": "10.1.0.10",
    "role": "WebServer",
    "dataCenter": "EastAsia",
    "isMonitored": true,
    "boundUrls": [
      "https://portal.contoso.com",
      "https://api.contoso.com"
    ],
    "workerProcesses": 4,
    "runtimeVersion": "8.0"
  }
```

## 注意事项

1. **PowerShell 版本要求**：`class` 关键字需要 PowerShell 5.0 及以上版本。在 Windows PowerShell 5.1 中功能完整可用，PowerShell 7 进一步增强了与 .NET Core 的兼容性。如果你需要在旧版本中运行脚本，请改用 `PSCustomObject` 或 C# 编译的 cmdlet。

2. **属性初始化时机**：类的属性默认值在类定义时求值，不是在实例化时求值。如果需要动态默认值（如当前时间），应放在构造函数中赋值，而不是在属性声明处直接使用 `Get-Date`。

3. **继承的限制**：PowerShell class 只支持单继承（一个父类），但可以实现多个接口。方法重写时需要使用 `([BaseClass]$this).Method()` 语法调用父类方法，这与 C# 的 `base.Method()` 略有不同。

4. **序列化注意事项**：class 实例默认不能被 `Export-Clixml` 正确序列化和反序列化，反序列化后会变成 `Deserialized.ClassName` 对象，丢失方法。如果需要持久化，建议使用 `ToJson()` / `FromJson()` 模式。

5. **调试与类型检查**：class 中的方法不支持 `Write-Output` 返回值（会被忽略），必须使用 `return` 语句。同时，类方法内的 `Write-Verbose` 等流输出在某些宿主环境中可能不会显示，建议在方法外部进行日志记录。

6. **性能考量**：虽然 class 提供了强类型和结构化的优势，但对于简单的数据传递场景，`PSCustomObject` 仍然更轻量。仅在需要封装逻辑、继承关系或类型约束时使用 class，避免过度设计。
