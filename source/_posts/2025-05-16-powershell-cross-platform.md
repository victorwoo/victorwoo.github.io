---
layout: post
date: 2025-05-16 08:00:00
updated: 2025-05-16 08:00:00
title: "PowerShell 技能连载 - 跨平台 PowerShell 实践"
description: PowerTip of the Day - Cross-Platform PowerShell Practices
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
- cross-platform
- linux
- macos
---

_适用于 PowerShell 7.0 及以上版本（跨平台）_

PowerShell 7 的跨平台能力是一个里程碑式的变化——同一套脚本语言可以在 Windows、Linux 和 macOS 上运行。对于管理混合环境的运维团队来说，这意味着只需学习一种语言就能管理所有平台。但跨平台并非"写一次到处运行"那么简单，不同操作系统的路径格式、包管理器、服务管理和服务发现机制都有差异。

本文将讲解跨平台 PowerShell 脚本的最佳实践，包括平台检测、路径处理、包管理适配和实用案例。

<!-- more -->

## 安装 PowerShell 7

在 Linux 上安装 PowerShell 7 比较简单，各主流发行版都有官方包：

```powershell
# 检查当前平台信息
$PSVersionTable
Write-Host "操作系统：$( [System.Runtime.InteropServices.RuntimeInformation]::OSDescription )"
Write-Host "平台架构：$( [System.Runtime.InteropServices.RuntimeInformation]::OSArchitecture )"

# 平台检测变量
Write-Host "`n内置平台变量："
Write-Host "  `$IsWindows : $IsWindows"
Write-Host "  `$IsLinux   : $IsLinux"
Write-Host "  `$IsMacOS   : $IsMacOS"

# Ubuntu/Debian 安装命令（在 Bash 中运行）
# wget https://packages.microsoft.com/config/ubuntu/22.04/packages-microsoft-prod.deb
# sudo dpkg -i packages-microsoft-prod.deb
# sudo apt-get update && sudo apt-get install -y powershell

# CentOS/RHEL 安装
# sudo yum install -y https://packages.microsoft.com/config/rhel/8/packages-microsoft-prod.rpm
# sudo yum install -y powershell

# macOS 安装
# brew install --cask powershell
```

执行结果示例：

```
Name                           Value
----                           -----
PSVersion                      7.4.2
PSEdition                      Core
Platform                       Unix
OS                             Ubuntu 22.04.4 LTS

操作系统：Linux 5.15.0-101-generic #111-Ubuntu SMP
平台架构：X64

内置平台变量：
  $IsWindows : False
  $IsLinux   : True
  $IsMacOS   : False
```

## 跨平台路径处理

路径分隔符是跨平台脚本最常见的陷阱。Windows 使用反斜杠 `\`，Linux/macOS 使用正斜杠 `/`。PowerShell 7 推荐使用 `Join-Path` 和 `Split-Path` 来处理路径：

```powershell
# 错误做法：硬编码路径分隔符
# $path = "C:\Users\admin\Documents"   # Windows only
# $path = "/home/admin/documents"     # Linux only

# 正确做法：使用 Join-Path
$configDir = Join-Path $HOME "config"
$dataFile = Join-Path $configDir "data.json"
Write-Host "配置文件路径：$dataFile"

# 跨平台常用路径映射
function Get-PlatformPath {
    param([string]$Segment)

    $basePaths = @{
        Config   = if ($IsWindows) { Join-Path $env:APPDATA "MyApp" }
                   elseif ($IsMacOS) { Join-Path $HOME "Library" "Application Support" "MyApp" }
                   else { Join-Path $HOME ".config" "myapp" }
        Data     = if ($IsWindows) { Join-Path $env:LOCALAPPDATA "MyApp" }
                   elseif ($IsMacOS) { Join-Path $HOME "Library" "Application Support" "MyApp" "Data" }
                   else { Join-Path $HOME ".local" "share" "myapp" }
        Temp     = if ($IsWindows) { $env:TEMP }
                   else { "/tmp" }
        Log      = if ($IsWindows) { Join-Path $env:LOCALAPPDATA "MyApp" "Logs" }
                   else { Join-Path "/var" "log" "myapp" }
    }

    return $basePaths[$Segment]
}

foreach ($type in @('Config', 'Data', 'Temp', 'Log')) {
    $path = Get-PlatformPath -Segment $type
    Write-Host "$type => $path"
}
```

执行结果示例：

```
配置文件路径：/home/admin/config/data.json

Config => /home/admin/.config/myapp
Data => /home/admin/.local/share/myapp
Temp => /tmp
Log => /var/log/myapp
```

> **注意**：在 PowerShell 7 中，即使 Windows 上也可以使用正斜杠 `/` 作为路径分隔符。但为了代码清晰，始终使用 `Join-Path` 是最佳实践。

## 跨平台服务管理

不同平台使用不同的服务管理器。以下是统一的跨平台服务管理函数：

```powershell
function Get-ServiceStatus {
    <#
    .SYNOPSIS
    跨平台获取服务状态
    #>
    param(
        [Parameter(Mandatory)]
        [string]$ServiceName
    )

    if ($IsWindows) {
        $svc = Get-Service -Name $ServiceName -ErrorAction SilentlyContinue
        if ($svc) {
            return [PSCustomObject]@{
                Name   = $svc.Name
                Status = $svc.Status.ToString()
                StartType = $svc.StartType.ToString()
            }
        }
    } else {
        # Linux/macOS 使用 systemctl 或 launchctl
        if (Get-Command systemctl -ErrorAction SilentlyContinue) {
            $output = systemctl is-active $ServiceName 2>$null
            $enabled = systemctl is-enabled $ServiceName 2>$null
            return [PSCustomObject]@{
                Name     = $ServiceName
                Status   = if ($output -eq 'active') { 'Running' } else { 'Stopped' }
                StartType = if ($enabled -eq 'enabled') { 'Automatic' } else { 'Manual' }
            }
        } elseif ($IsMacOS -and (Get-Command launchctl -ErrorAction SilentlyContinue)) {
            $output = launchctl list 2>$null | Select-String $ServiceName
            return [PSCustomObject]@{
                Name   = $ServiceName
                Status = if ($output) { 'Running' } else { 'Stopped' }
                StartType = 'Unknown'
            }
        }
    }
}

# 跨平台重启服务
function Restart-PlatformService {
    param([string]$ServiceName)

    if ($IsWindows) {
        Restart-Service -Name $ServiceName -Force
    } elseif (Get-Command systemctl -ErrorAction SilentlyContinue) {
        sudo systemctl restart $ServiceName
    } elseif ($IsMacOS) {
        sudo launchctl stop "com.$ServiceName"
        sudo launchctl start "com.$ServiceName"
    }
    Write-Host "已重启服务：$ServiceName" -ForegroundColor Green
}

# 示例
Get-ServiceStatus -ServiceName 'ssh'
Get-ServiceStatus -ServiceName 'nginx'
```

执行结果示例：

```
Name Status StartType
---- ------ ---------
ssh  Running Automatic

Name  Status StartType
----  ------ ---------
nginx Running Automatic
```

## 跨平台系统信息采集

统一的系统信息采集函数，适配三个平台：

```powershell
function Get-CrossPlatformSystemInfo {
    <#
    .SYNOPSIS
    跨平台采集系统信息
    #>

    $info = [ordered]@{}

    # 基础平台信息
    $info['主机名'] = $env:COMPUTERNAME ?? hostname
    $info['平台'] = if ($IsWindows) { 'Windows' } elseif ($IsMacOS) { 'macOS' } else { 'Linux' }
    $info['PowerShell版本'] = $PSVersionTable.PSVersion.ToString()

    if ($IsWindows) {
        $os = Get-CimInstance Win32_OperatingSystem
        $info['操作系统'] = $os.Caption
        $info['版本'] = $os.Version
        $info['总内存GB'] = [math]::Round($os.TotalVisibleMemorySize / 1MB, 2)
        $info['可用内存GB'] = [math]::Round($os.FreePhysicalMemory / 1MB, 2)
        $info['运行时间'] = ((Get-Date) - $os.LastBootUpTime).ToString('dd\天\ hh\:mm\:ss')

        $cpu = Get-CimInstance Win32_Processor | Select-Object -First 1
        $info['CPU'] = $cpu.Name
        $info['CPU核心'] = $cpu.NumberOfLogicalProcessors
    } else {
        # Linux/macOS 系统信息
        if ($IsLinux) {
            $info['操作系统'] = (Get-Content /etc/os-release | Select-String '^PRETTY_NAME=') -replace 'PRETTY_NAME="?(.+)"?','$1'
        } else {
            $info['操作系统'] = sw_vers -productName
            $info['版本'] = sw_vers -productVersion
        }

        # 内存信息
        if ($IsLinux) {
            $memInfo = Get-Content /proc/meminfo
            $totalKB = ($memInfo | Select-String 'MemTotal:') -replace '\D',''
            $freeKB = ($memInfo | Select-String 'MemAvailable:') -replace '\D',''
            $info['总内存GB'] = [math]::Round($totalKB / 1MB, 2)
            $info['可用内存GB'] = [math]::Round($freeKB / 1MB, 2)
        }

        # CPU 信息
        if ($IsLinux) {
            $cpuModel = (Get-Content /proc/cpuinfo | Select-String 'model name' | Select-Object -First 1) -replace 'model name\s+:\s+',''
            $cpuCores = (Get-Content /proc/cpuinfo | Select-String 'processor' | Measure-Object).Count
            $info['CPU'] = $cpuModel
            $info['CPU核心'] = $cpuCores
        }

        # 运行时间
        $uptimeOutput = uptime -p 2>$null
        $info['运行时间'] = $uptimeOutput ?? "unknown"
    }

    # 磁盘信息（跨平台）
    $info['磁盘'] = if ($IsWindows) {
        Get-CimInstance Win32_LogicalDisk -Filter "DriveType=3" |
            ForEach-Object {
                [PSCustomObject]@{
                    驱动器 = $_.DeviceID
                    总GB   = [math]::Round($_.Size / 1GB, 2)
                    可用GB = [math]::Round($_.FreeSpace / 1GB, 2)
                }
            }
    } else {
        df -h 2>/dev/null | Select-String '^/dev/' | ForEach-Object {
            $parts = $_.ToString() -split '\s+'
            [PSCustomObject]@{
                驱动器 = $parts[5]
                总GB   = $parts[1] -replace '[A-Z]',''
                可用GB = $parts[3] -replace '[A-Z]',''
            }
        }
    }

    return [PSCustomObject]$info
}

Get-CrossPlatformSystemInfo | Format-List
```

执行结果示例：

```
主机名        : ubuntu-server01
平台          : Linux
PowerShell版本 : 7.4.2
操作系统       : Ubuntu 22.04.4 LTS
总内存GB      : 15.57
可用内存GB    : 8.23
CPU           : Intel(R) Xeon(R) CPU E5-2680 v4 @ 2.40GHz
CPU核心       : 4
运行时间      : up 42 days, 3 hours, 17 minutes
```

## 跨平台包管理

不同平台有不同的包管理器。PowerShell 7 支持统一的 `Install-Package` 接口，但实际操作中往往需要调用原生包管理器：

```powershell
function Install-CrossPlatformPackage {
    <#
    .SYNOPSIS
    跨平台安装软件包
    #>
    param(
        [Parameter(Mandatory)]
        [string]$Package,

        [ValidateSet('apt','yum','brew','winget','auto')]
        [string]$Manager = 'auto'
    )

    if ($Manager -eq 'auto') {
        if ($IsWindows) {
            $Manager = 'winget'
        } elseif (Get-Command apt-get -ErrorAction SilentlyContinue) {
            $Manager = 'apt'
        } elseif (Get-Command yum -ErrorAction SilentlyContinue) {
            $Manager = 'yum'
        } elseif (Get-Command brew -ErrorAction SilentlyContinue) {
            $Manager = 'brew'
        }
    }

    switch ($Manager) {
        'apt'    { sudo apt-get update; sudo apt-get install -y $Package }
        'yum'    { sudo yum install -y $Package }
        'brew'   { brew install $Package }
        'winget' { winget install --id $Package --accept-source-agreements }
    }

    Write-Host "已通过 $Manager 安装：$Package" -ForegroundColor Green
}

# 批量安装常用工具
$commonTools = @('git', 'curl', 'wget')
foreach ($tool in $commonTools) {
    Install-CrossPlatformPackage -Package $tool
}
```

执行结果示例：

```
已通过 apt 安装：git
已通过 apt 安装：curl
已通过 apt 安装：wget
```

## 注意事项

1. **使用 `Join-Path`**：永远不要手动拼接路径，使用 `Join-Path`、`Split-Path`、`Test-Path` 等命令确保跨平台兼容
2. **平台检测使用内置变量**：`$IsWindows`、`$IsLinux`、`$IsMacOS` 是最可靠的检测方式，在 PowerShell 5.1 中需要手动检测 `$env:OS`
3. **换行符差异**：Windows 使用 CRLF（`\r\n`），Linux/macOS 使用 LF（`\n`）。处理文本文件时注意统一换行符
4. **文件权限**：Linux/macOS 使用 POSIX 权限模型（`chmod`），Windows 使用 ACL。跨平台脚本应分别处理
5. **环境变量大小写**：Windows 环境变量不区分大小写，Linux/macOS 区分大小写
6. **测试覆盖**：跨平台脚本应在所有目标平台上测试，不要假设"在 Linux 上能跑就行"
