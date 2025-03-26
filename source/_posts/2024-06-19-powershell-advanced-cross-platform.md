---
layout: post
date: 2024-06-19 08:00:00
title: "PowerShell 技能连载 - 高级跨平台功能实现"
description: PowerTip of the Day - PowerShell Advanced Cross-Platform Features
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
在PowerShell Core的支持下，我们可以实现更高级的跨平台功能。本文将介绍如何在Windows、Linux和macOS上实现GUI开发、数据库操作、网络编程、文件系统监控和日志管理等高级功能。

## 跨平台GUI开发

使用.NET Core的跨平台GUI框架，我们可以创建在多个平台上运行的图形界面：

```powershell
function New-CrossPlatformGUI {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Title,
        
        [Parameter()]
        [int]$Width = 800,
        
        [Parameter()]
        [int]$Height = 600,
        
        [Parameter()]
        [scriptblock]$OnLoad,
        
        [Parameter()]
        [scriptblock]$OnClose
    )
    
    try {
        # 检查是否安装了必要的模块
        if (-not (Get-Module -ListAvailable -Name "Avalonia")) {
            Write-Host "正在安装Avalonia模块..."
            Install-Module -Name "Avalonia" -Scope CurrentUser -Force
        }
        
        # 创建主窗口
        $window = New-Object Avalonia.Window
        $window.Title = $Title
        $window.Width = $Width
        $window.Height = $Height
        
        # 创建主布局
        $grid = New-Object Avalonia.Controls.Grid
        $grid.RowDefinitions.Add("Auto")
        $grid.RowDefinitions.Add("*")
        
        # 创建标题栏
        $titleBar = New-Object Avalonia.Controls.TextBlock
        $titleBar.Text = $Title
        $titleBar.FontSize = 16
        $titleBar.Margin = "10"
        $grid.Children.Add($titleBar)
        
        # 创建内容区域
        $content = New-Object Avalonia.Controls.StackPanel
        $grid.Children.Add($content)
        
        # 设置窗口内容
        $window.Content = $grid
        
        # 注册事件处理程序
        if ($OnLoad) {
            $window.Loaded += $OnLoad
        }
        
        if ($OnClose) {
            $window.Closing += $OnClose
        }
        
        # 显示窗口
        $window.Show()
        
        return $window
    }
    catch {
        Write-Error "创建GUI失败：$_"
        return $null
    }
}

# 示例：创建一个简单的跨平台GUI应用
$window = New-CrossPlatformGUI -Title "跨平台PowerShell应用" `
    -Width 400 `
    -Height 300 `
    -OnLoad {
        Write-Host "窗口已加载"
    } `
    -OnClose {
        Write-Host "窗口已关闭"
    }
```

## 跨平台数据库操作

使用.NET Core的数据库提供程序，我们可以实现跨平台的数据库操作：

```powershell
function Connect-CrossPlatformDatabase {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateSet("SQLite", "PostgreSQL", "MySQL", "MongoDB")]
        [string]$DatabaseType,
        
        [Parameter(Mandatory = $true)]
        [string]$ConnectionString,
        
        [Parameter()]
        [switch]$UseConnectionPooling
    )
    
    try {
        $connection = $null
        
        switch ($DatabaseType) {
            "SQLite" {
                $connection = New-Object Microsoft.Data.Sqlite.SqliteConnection($ConnectionString)
            }
            "PostgreSQL" {
                $connection = New-Object Npgsql.NpgsqlConnection($ConnectionString)
            }
            "MySQL" {
                $connection = New-Object MySql.Data.MySqlClient.MySqlConnection($ConnectionString)
            }
            "MongoDB" {
                $connection = New-Object MongoDB.Driver.MongoClient($ConnectionString)
            }
        }
        
        if ($UseConnectionPooling) {
            $connection.ConnectionString += ";Pooling=true"
        }
        
        $connection.Open()
        Write-Host "成功连接到 $DatabaseType 数据库" -ForegroundColor Green
        
        return $connection
    }
    catch {
        Write-Error "数据库连接失败：$_"
        return $null
    }
}

function Invoke-CrossPlatformQuery {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        $Connection,
        
        [Parameter(Mandatory = $true)]
        [string]$Query,
        
        [Parameter()]
        [hashtable]$Parameters
    )
    
    try {
        $command = $Connection.CreateCommand()
        $command.CommandText = $Query
        
        if ($Parameters) {
            foreach ($param in $Parameters.GetEnumerator()) {
                $dbParam = $command.CreateParameter()
                $dbParam.ParameterName = $param.Key
                $dbParam.Value = $param.Value
                $command.Parameters.Add($dbParam)
            }
        }
        
        $result = $command.ExecuteReader()
        $dataTable = New-Object System.Data.DataTable
        $dataTable.Load($result)
        
        return $dataTable
    }
    catch {
        Write-Error "查询执行失败：$_"
        return $null
    }
}

# 示例：使用SQLite数据库
$connection = Connect-CrossPlatformDatabase -DatabaseType "SQLite" `
    -ConnectionString "Data Source=test.db" `
    -UseConnectionPooling

$result = Invoke-CrossPlatformQuery -Connection $connection `
    -Query "SELECT * FROM Users WHERE Age > @Age" `
    -Parameters @{
        "Age" = 18
    }
```

## 跨平台网络编程

使用.NET Core的网络库，我们可以实现跨平台的网络通信：

```powershell
function New-CrossPlatformWebServer {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Url,
        
        [Parameter()]
        [scriptblock]$RequestHandler,
        
        [Parameter()]
        [int]$MaxConnections = 100
    )
    
    try {
        $listener = New-Object System.Net.HttpListener
        $listener.Prefixes.Add($Url)
        $listener.Start()
        
        Write-Host "Web服务器已启动，监听地址：$Url" -ForegroundColor Green
        
        while ($true) {
            $context = $listener.GetContext()
            $request = $context.Request
            $response = $context.Response
            
            # 处理请求
            if ($RequestHandler) {
                $RequestHandler.Invoke($request, $response)
            }
            else {
                $response.StatusCode = 200
                $response.ContentType = "text/plain"
                $responseString = "Hello from PowerShell Web Server!"
                $buffer = [System.Text.Encoding]::UTF8.GetBytes($responseString)
                $response.ContentLength64 = $buffer.Length
                $response.OutputStream.Write($buffer, 0, $buffer.Length)
            }
            
            $response.Close()
        }
    }
    catch {
        Write-Error "Web服务器启动失败：$_"
        return $null
    }
}

function Send-CrossPlatformHttpRequest {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Url,
        
        [Parameter()]
        [ValidateSet("GET", "POST", "PUT", "DELETE")]
        [string]$Method = "GET",
        
        [Parameter()]
        [hashtable]$Headers,
        
        [Parameter()]
        [string]$Body
    )
    
    try {
        $client = New-Object System.Net.Http.HttpClient
        
        if ($Headers) {
            foreach ($header in $Headers.GetEnumerator()) {
                $client.DefaultRequestHeaders.Add($header.Key, $header.Value)
            }
        }
        
        $request = New-Object System.Net.Http.HttpRequestMessage($Method, $Url)
        
        if ($Body) {
            $request.Content = New-Object System.Net.Http.StringContent($Body)
        }
        
        $response = $client.SendAsync($request).Result
        $responseContent = $response.Content.ReadAsStringAsync().Result
        
        return [PSCustomObject]@{
            StatusCode = $response.StatusCode
            Content = $responseContent
            Headers = $response.Headers
        }
    }
    catch {
        Write-Error "HTTP请求失败：$_"
        return $null
    }
}

# 示例：创建Web服务器并发送请求
$server = Start-Job -ScriptBlock {
    New-CrossPlatformWebServer -Url "http://localhost:8080/" `
        -RequestHandler {
            param($request, $response)
            $responseString = "收到请求：$($request.Url)"
            $buffer = [System.Text.Encoding]::UTF8.GetBytes($responseString)
            $response.ContentLength64 = $buffer.Length
            $response.OutputStream.Write($buffer, 0, $buffer.Length)
        }
}

Start-Sleep -Seconds 2

$result = Send-CrossPlatformHttpRequest -Url "http://localhost:8080/" `
    -Method "GET" `
    -Headers @{
        "User-Agent" = "PowerShell Client"
    }
```

## 跨平台文件系统监控

使用.NET Core的文件系统监控功能，我们可以实现跨平台的文件系统事件监控：

```powershell
function Start-CrossPlatformFileWatcher {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path,
        
        [Parameter()]
        [ValidateSet("Created", "Changed", "Deleted", "Renamed", "All")]
        [string[]]$Events = @("All"),
        
        [Parameter()]
        [string]$Filter = "*.*",
        
        [Parameter()]
        [switch]$IncludeSubdirectories,
        
        [Parameter()]
        [scriptblock]$OnEvent
    )
    
    try {
        $watcher = New-Object System.IO.FileSystemWatcher
        $watcher.Path = $Path
        $watcher.Filter = $Filter
        $watcher.IncludeSubdirectories = $IncludeSubdirectories
        $watcher.EnableRaisingEvents = $true
        
        # 注册事件处理程序
        if ($Events -contains "All" -or $Events -contains "Created") {
            $watcher.Created += {
                if ($OnEvent) {
                    $OnEvent.Invoke("Created", $EventArgs)
                }
            }
        }
        
        if ($Events -contains "All" -or $Events -contains "Changed") {
            $watcher.Changed += {
                if ($OnEvent) {
                    $OnEvent.Invoke("Changed", $EventArgs)
                }
            }
        }
        
        if ($Events -contains "All" -or $Events -contains "Deleted") {
            $watcher.Deleted += {
                if ($OnEvent) {
                    $OnEvent.Invoke("Deleted", $EventArgs)
                }
            }
        }
        
        if ($Events -contains "All" -or $Events -contains "Renamed") {
            $watcher.Renamed += {
                if ($OnEvent) {
                    $OnEvent.Invoke("Renamed", $EventArgs)
                }
            }
        }
        
        Write-Host "文件系统监控已启动，监控路径：$Path" -ForegroundColor Green
        
        return $watcher
    }
    catch {
        Write-Error "文件系统监控启动失败：$_"
        return $null
    }
}

# 示例：监控文件系统变化
$watcher = Start-CrossPlatformFileWatcher -Path "C:\Temp" `
    -Events @("Created", "Changed", "Deleted") `
    -Filter "*.txt" `
    -IncludeSubdirectories `
    -OnEvent {
        param($eventType, $eventArgs)
        Write-Host "检测到文件系统事件：$eventType" -ForegroundColor Yellow
        Write-Host "文件路径：$($eventArgs.FullPath)" -ForegroundColor Cyan
    }
```

## 跨平台日志管理

使用.NET Core的日志框架，我们可以实现跨平台的日志管理：

```powershell
function New-CrossPlatformLogger {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$LogPath,
        
        [Parameter()]
        [ValidateSet("Debug", "Info", "Warning", "Error", "Critical")]
        [string]$LogLevel = "Info",
        
        [Parameter()]
        [switch]$EnableConsoleOutput,
        
        [Parameter()]
        [switch]$EnableFileOutput,
        
        [Parameter()]
        [switch]$EnableJsonFormat
    )
    
    try {
        $logger = [PSCustomObject]@{
            LogPath = $LogPath
            LogLevel = $LogLevel
            EnableConsoleOutput = $EnableConsoleOutput
            EnableFileOutput = $EnableFileOutput
            EnableJsonFormat = $EnableJsonFormat
            LogLevels = @{
                "Debug" = 0
                "Info" = 1
                "Warning" = 2
                "Error" = 3
                "Critical" = 4
            }
        }
        
        # 创建日志目录
        if ($EnableFileOutput) {
            $logDir = Split-Path -Parent $LogPath
            if (-not (Test-Path $logDir)) {
                New-Item -ItemType Directory -Path $logDir -Force | Out-Null
            }
        }
        
        # 添加日志方法
        $logger | Add-Member -MemberType ScriptMethod -Name "Log" -Value {
            param(
                [string]$Level,
                [string]$Message,
                [hashtable]$Properties
            )
            
            if ($this.LogLevels[$Level] -ge $this.LogLevels[$this.LogLevel]) {
                $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss.fff"
                $logEntry = [PSCustomObject]@{
                    Timestamp = $timestamp
                    Level = $Level
                    Message = $Message
                    Properties = $Properties
                }
                
                if ($this.EnableJsonFormat) {
                    $logString = $logEntry | ConvertTo-Json
                }
                else {
                    $logString = "[$timestamp] [$Level] $Message"
                    if ($Properties) {
                        $logString += " | " + ($Properties.GetEnumerator() | ForEach-Object { "$($_.Key)=$($_.Value)" }) -join " "
                    }
                }
                
                if ($this.EnableConsoleOutput) {
                    switch ($Level) {
                        "Debug" { Write-Debug $logString }
                        "Info" { Write-Host $logString -ForegroundColor White }
                        "Warning" { Write-Host $logString -ForegroundColor Yellow }
                        "Error" { Write-Host $logString -ForegroundColor Red }
                        "Critical" { Write-Host $logString -ForegroundColor DarkRed }
                    }
                }
                
                if ($this.EnableFileOutput) {
                    $logString | Out-File -FilePath $this.LogPath -Append
                }
            }
        }
        
        return $logger
    }
    catch {
        Write-Error "创建日志记录器失败：$_"
        return $null
    }
}

# 示例：使用日志记录器
$logger = New-CrossPlatformLogger -LogPath "C:\Logs\app.log" `
    -LogLevel "Info" `
    -EnableConsoleOutput `
    -EnableFileOutput `
    -EnableJsonFormat

$logger.Log("Info", "应用程序启动", @{
    "Version" = "1.0.0"
    "Platform" = $PSVersionTable.Platform
})

$logger.Log("Warning", "磁盘空间不足", @{
    "Drive" = "C:"
    "FreeSpace" = "1.2GB"
})
```

## 最佳实践

1. 使用.NET Core的跨平台API而不是平台特定API
2. 实现优雅的错误处理和日志记录
3. 使用连接池和资源管理
4. 实现适当的超时和重试机制
5. 使用异步操作提高性能
6. 实现适当的清理和资源释放
7. 使用配置文件管理设置
8. 实现适当的权限检查 