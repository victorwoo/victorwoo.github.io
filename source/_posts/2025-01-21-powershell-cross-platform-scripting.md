---
layout: post
date: 2025-01-21 08:00:00
title: "PowerShell 技能连载 - 跨平台脚本编写技巧"
description: PowerTip of the Day - PowerShell Cross-Platform Scripting Tips
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
随着PowerShell Core的发展，PowerShell已经成为真正的跨平台自动化工具。本文将介绍如何编写在Windows、Linux和macOS上都能正常运行的PowerShell脚本。

## 检测操作系统平台

首先，让我们学习如何检测脚本运行的操作系统平台：

```powershell
function Get-CurrentPlatform {
    if ($IsWindows -or ($PSVersionTable.PSVersion.Major -lt 6 -and $env:OS -eq "Windows_NT")) {
        return "Windows"
    }
    elseif ($IsLinux) {
        return "Linux"
    }
    elseif ($IsMacOS) {
        return "macOS"
    }
    else {
        return "Unknown"
    }
}

$platform = Get-CurrentPlatform
Write-Host "当前运行平台: $platform"
```

## 处理文件路径

在不同操作系统上，文件路径的格式和分隔符有所不同。使用PowerShell提供的内置方法可以解决这个问题：

```powershell
function Get-CrossPlatformPath {
    param(
        [string]$Path
    )
    
    # 使用Join-Path确保路径分隔符正确
    $normalizedPath = $Path
    
    # 处理根路径
    if ($IsWindows -or ($PSVersionTable.PSVersion.Major -lt 6 -and $env:OS -eq "Windows_NT")) {
        # 在Windows上，确保使用正确的驱动器表示法
        if (-not $normalizedPath.Contains(':') -and $normalizedPath.StartsWith('/')) {
            $normalizedPath = "C:$normalizedPath"
        }
    }
    else {
        # 在Linux/macOS上，将Windows路径转换为Unix风格
        if ($normalizedPath -match '^[A-Za-z]:') {
            $normalizedPath = $normalizedPath -replace '^[A-Za-z]:', ''
            $normalizedPath = $normalizedPath -replace '\\', '/'
            $normalizedPath = "/$normalizedPath"
        }
    }
    
    # 确保所有分隔符都是平台适用的
    $normalizedPath = $normalizedPath -replace '[/\\]', [System.IO.Path]::DirectorySeparatorChar
    
    return $normalizedPath
}

# 示例
$path = "/temp/test.txt"
$platformPath = Get-CrossPlatformPath -Path $path
Write-Host "跨平台路径: $platformPath"
```

## 执行平台特定命令

有时候，我们需要根据不同的平台执行不同的命令：

```powershell
function Invoke-PlatformCommand {
    param(
        [string]$WindowsCommand,
        [string]$LinuxCommand,
        [string]$MacOSCommand
    )
    
    $platform = Get-CurrentPlatform
    
    switch ($platform) {
        "Windows" {
            Write-Host "执行Windows命令: $WindowsCommand" -ForegroundColor Cyan
            Invoke-Expression -Command $WindowsCommand
        }
        "Linux" {
            Write-Host "执行Linux命令: $LinuxCommand" -ForegroundColor Green
            Invoke-Expression -Command $LinuxCommand
        }
        "macOS" {
            Write-Host "执行macOS命令: $MacOSCommand" -ForegroundColor Magenta
            Invoke-Expression -Command $MacOSCommand
        }
        default {
            Write-Error "不支持的平台: $platform"
        }
    }
}

# 示例：获取系统信息
Invoke-PlatformCommand -WindowsCommand "Get-ComputerInfo | Select-Object WindowsProductName, OsVersion" `
                      -LinuxCommand "uname -a" `
                      -MacOSCommand "system_profiler SPSoftwareDataType | grep 'System Version'"
```

## 创建跨平台服务管理函数

下面是一个管理服务的跨平台函数示例：

```powershell
function Manage-CrossPlatformService {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ServiceName,
        
        [Parameter(Mandatory = $true)]
        [ValidateSet("Start", "Stop", "Restart", "Status")]
        [string]$Action
    )
    
    $platform = Get-CurrentPlatform
    
    switch ($platform) {
        "Windows" {
            switch ($Action) {
                "Start" { 
                    Start-Service -Name $ServiceName
                    Write-Host "已启动Windows服务 $ServiceName" -ForegroundColor Green 
                }
                "Stop" { 
                    Stop-Service -Name $ServiceName
                    Write-Host "已停止Windows服务 $ServiceName" -ForegroundColor Yellow 
                }
                "Restart" { 
                    Restart-Service -Name $ServiceName
                    Write-Host "已重启Windows服务 $ServiceName" -ForegroundColor Cyan 
                }
                "Status" { 
                    Get-Service -Name $ServiceName
                }
            }
        }
        "Linux" {
            switch ($Action) {
                "Start" { 
                    sudo systemctl start $ServiceName
                    Write-Host "已启动Linux服务 $ServiceName" -ForegroundColor Green 
                }
                "Stop" { 
                    sudo systemctl stop $ServiceName
                    Write-Host "已停止Linux服务 $ServiceName" -ForegroundColor Yellow 
                }
                "Restart" { 
                    sudo systemctl restart $ServiceName
                    Write-Host "已重启Linux服务 $ServiceName" -ForegroundColor Cyan 
                }
                "Status" { 
                    sudo systemctl status $ServiceName
                }
            }
        }
        "macOS" {
            switch ($Action) {
                "Start" { 
                    sudo launchctl load /Library/LaunchDaemons/$ServiceName.plist
                    Write-Host "已启动macOS服务 $ServiceName" -ForegroundColor Green 
                }
                "Stop" { 
                    sudo launchctl unload /Library/LaunchDaemons/$ServiceName.plist
                    Write-Host "已停止macOS服务 $ServiceName" -ForegroundColor Yellow 
                }
                "Restart" { 
                    sudo launchctl unload /Library/LaunchDaemons/$ServiceName.plist
                    sudo launchctl load /Library/LaunchDaemons/$ServiceName.plist
                    Write-Host "已重启macOS服务 $ServiceName" -ForegroundColor Cyan 
                }
                "Status" { 
                    sudo launchctl list | grep $ServiceName
                }
            }
        }
        default {
            Write-Error "不支持的平台: $platform"
        }
    }
}

# 示例：服务管理
# Manage-CrossPlatformService -ServiceName "spooler" -Action "Status"
```

## 创建跨平台进程管理函数

下面是一个管理进程的跨平台函数：

```powershell
function Get-CrossPlatformProcess {
    param(
        [string]$Name = ""
    )
    
    $platform = Get-CurrentPlatform
    
    switch ($platform) {
        "Windows" {
            if ($Name) {
                Get-Process -Name $Name -ErrorAction SilentlyContinue
            }
            else {
                Get-Process
            }
        }
        { $_ -in "Linux", "macOS" } {
            if ($Name) {
                $processInfo = Invoke-Expression "ps -ef | grep $Name | grep -v grep"
                if ($processInfo) {
                    $processInfo
                }
                else {
                    Write-Host "未找到名称包含 '$Name' 的进程。" -ForegroundColor Yellow
                }
            }
            else {
                Invoke-Expression "ps -ef"
            }
        }
        default {
            Write-Error "不支持的平台: $platform"
        }
    }
}

# 示例：查找进程
# Get-CrossPlatformProcess -Name "pwsh"
```

## 跨平台环境变量处理

不同操作系统的环境变量处理方式有所不同，下面是一个统一的方法：

```powershell
function Get-CrossPlatformEnvironmentVariable {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Name
    )
    
    $platform = Get-CurrentPlatform
    
    switch ($platform) {
        "Windows" {
            return [System.Environment]::GetEnvironmentVariable($Name)
        }
        { $_ -in "Linux", "macOS" } {
            $value = Invoke-Expression "echo `$${Name}"
            return $value
        }
        default {
            Write-Error "不支持的平台: $platform"
            return $null
        }
    }
}

function Set-CrossPlatformEnvironmentVariable {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Name,
        
        [Parameter(Mandatory = $true)]
        [string]$Value,
        
        [ValidateSet("Process", "User", "Machine")]
        [string]$Scope = "Process"
    )
    
    $platform = Get-CurrentPlatform
    
    switch ($platform) {
        "Windows" {
            [System.Environment]::SetEnvironmentVariable($Name, $Value, $Scope)
            Write-Host "已设置Windows环境变量 $Name=$Value (作用域: $Scope)" -ForegroundColor Green
        }
        { $_ -in "Linux", "macOS" } {
            # Linux/macOS只支持进程级别的即时设置
            Invoke-Expression "`$env:$Name = `"$Value`""
            
            # 如果需要永久设置，需要写入配置文件
            if ($Scope -ne "Process") {
                Write-Host "在Linux/macOS上永久设置环境变量，需要添加到配置文件中:" -ForegroundColor Yellow
                if ($Scope -eq "User") {
                    Write-Host "添加 'export $Name=$Value' 到 ~/.profile 或 ~/.bash_profile" -ForegroundColor Cyan
                }
                elseif ($Scope -eq "Machine") {
                    Write-Host "添加 'export $Name=$Value' 到 /etc/profile 或 /etc/environment" -ForegroundColor Cyan
                }
            }
            else {
                Write-Host "已设置Linux/macOS环境变量 $Name=$Value (仅当前进程有效)" -ForegroundColor Green
            }
        }
        default {
            Write-Error "不支持的平台: $platform"
        }
    }
}

# 示例：获取和设置环境变量
# $path = Get-CrossPlatformEnvironmentVariable -Name "PATH"
# Set-CrossPlatformEnvironmentVariable -Name "TEST_VAR" -Value "TestValue" -Scope "Process"
```

## 创建跨平台文件系统监控函数

下面是一个监控文件系统变化的跨平台函数：

```powershell
function Start-CrossPlatformFileWatcher {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path,
        
        [string]$Filter = "*.*",
        
        [switch]$IncludeSubdirectories
    )
    
    $platform = Get-CurrentPlatform
    
    # 确保路径适合当前平台
    $Path = Get-CrossPlatformPath -Path $Path
    
    # 创建FileSystemWatcher对象（适用于所有平台）
    $watcher = New-Object System.IO.FileSystemWatcher
    $watcher.Path = $Path
    $watcher.Filter = $Filter
    $watcher.IncludeSubdirectories = $IncludeSubdirectories
    
    # 定义事件处理程序
    $action = {
        $event = $Event.SourceEventArgs
        $name = $event.Name
        $changeType = $event.ChangeType
        $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        
        Write-Host "[$timestamp] 文件 $name 已$changeType" -ForegroundColor Green
    }
    
    # 注册事件
    $handlers = @()
    $handlers += Register-ObjectEvent -InputObject $watcher -EventName Created -Action $action
    $handlers += Register-ObjectEvent -InputObject $watcher -EventName Changed -Action $action
    $handlers += Register-ObjectEvent -InputObject $watcher -EventName Deleted -Action $action
    $handlers += Register-ObjectEvent -InputObject $watcher -EventName Renamed -Action $action
    
    # 启用监控
    $watcher.EnableRaisingEvents = $true
    
    Write-Host "开始监控文件夹: $Path" -ForegroundColor Cyan
    Write-Host "按Ctrl+C停止监控..." -ForegroundColor Yellow
    
    try {
        # 保持脚本运行
        while ($true) { Start-Sleep -Seconds 1 }
    }
    finally {
        # 清理
        $watcher.EnableRaisingEvents = $false
        $handlers | ForEach-Object { Unregister-Event -SubscriptionId $_.Id }
        $watcher.Dispose()
        Write-Host "已停止监控." -ForegroundColor Cyan
    }
}

# 示例：监控目录变化
# Start-CrossPlatformFileWatcher -Path "/tmp" -Filter "*.txt" -IncludeSubdirectories
```

## 实用的跨平台脚本模板

下面是一个通用的跨平台脚本模板，您可以作为基础进行扩展：

```powershell
#!/usr/bin/env pwsh
<#
.SYNOPSIS
    跨平台PowerShell脚本模板。
.DESCRIPTION
    这是一个在Windows、Linux和macOS上都能正常运行的PowerShell脚本模板。
.PARAMETER Action
    要执行的操作。
.EXAMPLE
    ./cross-platform-script.ps1 -Action "CheckSystem"
#>

param(
    [Parameter(Mandatory = $true)]
    [ValidateSet("CheckSystem", "ListFiles", "GetProcesses")]
    [string]$Action
)

# 平台检测
function Get-CurrentPlatform {
    if ($IsWindows -or ($PSVersionTable.PSVersion.Major -lt 6 -and $env:OS -eq "Windows_NT")) {
        return "Windows"
    }
    elseif ($IsLinux) {
        return "Linux"
    }
    elseif ($IsMacOS) {
        return "macOS"
    }
    else {
        return "Unknown"
    }
}

# 平台特定命令执行
function Invoke-PlatformCommand {
    param(
        [string]$WindowsCommand,
        [string]$LinuxCommand,
        [string]$MacOSCommand
    )
    
    $platform = Get-CurrentPlatform
    
    switch ($platform) {
        "Windows" {
            if ($WindowsCommand) {
                return Invoke-Expression -Command $WindowsCommand
            }
        }
        "Linux" {
            if ($LinuxCommand) {
                return Invoke-Expression -Command $LinuxCommand
            }
        }
        "macOS" {
            if ($MacOSCommand) {
                return Invoke-Expression -Command $MacOSCommand
            }
        }
        default {
            Write-Error "不支持的平台: $platform"
            return $null
        }
    }
}

# 主函数
function Main {
    $platform = Get-CurrentPlatform
    Write-Host "当前平台: $platform" -ForegroundColor Cyan
    
    switch ($Action) {
        "CheckSystem" {
            Write-Host "系统信息:" -ForegroundColor Green
            switch ($platform) {
                "Windows" { Get-ComputerInfo | Select-Object WindowsProductName, OsVersion, CsName }
                "Linux" { 
                    $osInfo = Invoke-Expression "cat /etc/os-release"
                    $hostname = Invoke-Expression "hostname"
                    Write-Host "主机名: $hostname"
                    Write-Host $osInfo
                }
                "macOS" { 
                    $osInfo = Invoke-Expression "sw_vers"
                    $hostname = Invoke-Expression "hostname"
                    Write-Host "主机名: $hostname"
                    Write-Host $osInfo
                }
            }
        }
        "ListFiles" {
            $currentDir = Get-Location
            Write-Host "当前目录 ($currentDir) 的文件:" -ForegroundColor Green
            Get-ChildItem | Select-Object Name, Length, LastWriteTime
        }
        "GetProcesses" {
            Write-Host "运行中的进程:" -ForegroundColor Green
            switch ($platform) {
                "Windows" { Get-Process | Sort-Object -Property CPU -Descending | Select-Object -First 10 Name, CPU, WorkingSet }
                { $_ -in "Linux", "macOS" } { 
                    Invoke-Expression "ps -eo pid,ppid,cmd,%cpu,%mem --sort=-%cpu | head -11"
                }
            }
        }
    }
}

# 执行主函数
Main
```

## 最佳实践总结

1. **始终检测平台**：使用`$IsWindows`、`$IsLinux`和`$IsMacOS`变量确定当前平台。
2. **使用内置路径处理**：利用`Join-Path`、`Split-Path`和`[System.IO.Path]`类处理跨平台路径。
3. **避免硬编码路径分隔符**：使用`[System.IO.Path]::DirectorySeparatorChar`代替硬编码的`\`或`/`。
4. **利用条件逻辑**：为不同平台编写特定的代码分支。
5. **使用.NET Core的跨平台API**：尽可能使用.NET Core提供的跨平台API而不是平台特定命令。
6. **测试、测试再测试**：在所有目标平台上测试您的脚本。

通过遵循这些技巧和最佳实践，您可以编写出在所有主要操作系统上都能无缝运行的PowerShell脚本，充分发挥PowerShell跨平台能力的优势。 