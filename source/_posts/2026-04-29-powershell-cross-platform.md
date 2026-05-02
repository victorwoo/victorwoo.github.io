---
layout: post
date: 2026-04-29 08:00:00
updated: 2026-04-29 08:00:00
title: "PowerShell 技能连载 - 跨平台脚本开发"
description: PowerTip of the Day - Cross-Platform Script Development in PowerShell
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
- best-practices
---

_适用于 PowerShell 7.0 及以上版本（Windows / Linux / macOS）_

PowerShell 7 是微软推出的跨平台版本，基于 .NET 构建，可以在 Windows、Linux 和 macOS 三个操作系统上运行。这为运维工程师带来了一个统一脚本语言的可能性——同一套 PowerShell 脚本理论上可以在不同平台上执行，减少了学习成本和维护负担。但现实中的跨平台开发远比"能跑起来"复杂得多。

不同操作系统在文件系统结构、路径规范、大小写敏感性、权限模型、包管理方式等方面存在显著差异。如果不做适配，一个在 Windows 上完美运行的脚本放到 Linux 上可能处处报错。比如路径分隔符的差异（`\` vs `/`）、环境变量的读取方式、甚至某些 cmdlet 的可用性都会因平台而异。

本文将从平台检测与条件分支、路径与文件系统差异处理、跨平台工具函数库三个维度，介绍如何编写真正能在三大平台上稳定运行的 PowerShell 脚本。掌握这些技巧后，你可以将运维自动化脚本打包成跨平台模块，在混合环境中统一管理。

<!-- more -->

## 平台检测与条件分支

PowerShell 7 提供了三个内置布尔变量来标识当前运行平台：`$IsWindows`、`$IsLinux` 和 `$IsMacOS`。利用它们可以在脚本中实现条件分支，根据不同平台执行不同的逻辑。下面这个函数封装了平台检测逻辑，返回统一的结构化信息，方便在脚本的任何位置引用。

```powershell
function Get-PlatformInfo {
    [CmdletBinding()]
    param()

    $result = [ordered]@{
        Platform     = 'Unknown'
        IsWindows    = $false
        IsLinux      = $false
        IsMacOS      = $false
        Architecture = [System.Runtime.InteropServices.RuntimeInformation]::OSArchitecture.ToString()
        OSVersion    = ''
        ShellName    = $PSVersionTable.ShellId
        PSVersion    = $PSVersionTable.PSVersion.ToString()
    }

    if ($IsWindows) {
        $result.Platform  = 'Windows'
        $result.IsWindows = $true
        $result.OSVersion = [System.Environment]::OSVersion.VersionString
    }
    elseif ($IsLinux) {
        $result.Platform = 'Linux'
        $result.IsLinux  = $true
        if (Test-Path /etc/os-release) {
            $osRelease = Get-Content /etc/os-release -ErrorAction SilentlyContinue
            $prettyName = $osRelease | Where-Object { $_ -match '^PRETTY_NAME=' }
            if ($prettyName) {
                $result.OSVersion = ($prettyName -split '=', 2)[1].Trim('"')
            }
        }
    }
    elseif ($IsMacOS) {
        $result.Platform = 'macOS'
        $result.IsMacOS  = $true
        $result.OSVersion = sw_vers -productVersion 2>$null
        if ($result.OSVersion) {
            $result.OSVersion = "macOS $($result.OSVersion)"
        }
    }

    return [PSCustomObject]$result
}

# 使用示例：根据平台选择不同的包安装方式
$platform = Get-PlatformInfo
Write-Host "当前平台: $($platform.Platform) ($($platform.Architecture))"
Write-Host "操作系统: $($platform.OSVersion)"
Write-Host "PowerShell 版本: $($platform.PSVersion)"
```

在 Windows 上运行的输出大致如下：

```
当前平台: Windows (X64)
操作系统: Microsoft Windows 10.0.26100
PowerShell 版本: 7.5.0
```

在 Linux (Ubuntu) 上运行的输出大致如下：

```
当前平台: Linux (X64)
操作系统: Ubuntu 24.04.2 LTS
PowerShell 版本: 7.5.0
```

## 路径与文件系统差异处理

路径处理是跨平台脚本开发中最容易踩坑的地方。Windows 使用反斜杠 `\` 作为路径分隔符，而 Linux 和 macOS 使用正斜杠 `/`。此外，Linux 的文件系统区分大小写，Windows 的 NTFS 默认不区分。下面这个函数库封装了常见的路径操作，确保在所有平台上行为一致。

```powershell
function Join-PlatformPath {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Base,

        [Parameter(Mandatory)]
        [string]$Relative
    )

    # 统一使用 [System.IO.Path] 处理，自动适配当前平台
    return [System.IO.Path]::Combine($Base, $Relative)
}

function Get-PlatformTempPath {
    [CmdletBinding()]
    param()

    if ($IsWindows) {
        return $env:TEMP
    }
    elseif ($IsMacOS -or $IsLinux) {
        $tmpDir = $env:TMPDIR
        if (-not $tmpDir) { $tmpDir = $env:XDG_RUNTIME_DIR }
        if (-not $tmpDir) { $tmpDir = '/tmp' }
        return $tmpDir
    }
    return '/tmp'
}

function Get-PlatformHomePath {
    [CmdletBinding()]
    param()

    if ($IsWindows) {
        return $env:USERPROFILE
    }
    return $env:HOME
}

function Resolve-PlatformCase {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Path
    )

    # 在区分大小写的文件系统上，验证路径的实际大小写
    if ($IsLinux) {
        if (-not (Test-Path $Path)) {
            Write-Warning "路径不存在: $Path"
            return $Path
        }
        $item = Get-Item $Path -ErrorAction SilentlyContinue
        if ($item) {
            return $item.FullName
        }
    }
    return (Resolve-Path $Path -ErrorAction SilentlyContinue).Path
}

# 使用示例：构建跨平台的配置文件路径
$homePath   = Get-PlatformHomePath
$configDir  = Join-PlatformPath $homePath '.myapp'
$configFile = Join-PlatformPath $configDir 'config.json'
$tempDir    = Get-PlatformTempPath

Write-Host "主目录: $homePath"
Write-Host "配置目录: $configDir"
Write-Host "配置文件: $configFile"
Write-Host "临时目录: $tempDir"

# 确保配置目录存在（跨平台方式）
if (-not (Test-Path $configDir)) {
    New-Item -ItemType Directory -Path $configDir -Force | Out-Null
    Write-Host "已创建配置目录: $configDir"
}
```

在 Windows 上的输出：

```
主目录: C:\Users\admin
配置目录: C:\Users\admin\.myapp
配置文件: C:\Users\admin\.myapp\config.json
临时目录: C:\Users\admin\AppData\Local\Temp
已创建配置目录: C:\Users\admin\.myapp
```

在 Linux 上的输出：

```
主目录: /home/admin
配置目录: /home/admin/.myapp
配置文件: /home/admin/.myapp/config.json
临时目录: /tmp
已创建配置目录: /home/admin/.myapp
```

## 跨平台工具函数库

在实际运维中，最常见的需求包括软件包管理、服务管理和用户管理。不同平台使用的底层命令各不相同：Windows 用 `winget`/`choco`，Linux 用 `apt`/`yum`/`dnf`，macOS 用 `brew`；服务管理在 Windows 上是 `Get-Service`，Linux 上是 `systemctl`，macOS 上是 `launchctl`。下面这个函数库将这些差异封装为统一的 PowerShell 接口。

```powershell
#region 包管理器抽象

function Install-PlatformPackage {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory)]
        [string]$Name,

        [Parameter()]
        [switch]$Update
    )

    if ($IsWindows) {
        # 优先使用 winget，回退到 choco
        $winget = Get-Command winget -ErrorAction SilentlyContinue
        if ($winget) {
            $args = @('install', '--id', $Name, '--accept-package-agreements', '--accept-source-agreements')
            if ($Update) { $args += '--upgrade' }
            if ($PSCmdlet.ShouldProcess($Name, 'Install via winget')) {
                & winget @args
            }
        }
        else {
            $choco = Get-Command choco -ErrorAction SilentlyContinue
            if ($choco) {
                if ($PSCmdlet.ShouldProcess($Name, 'Install via chocolatey')) {
                    & choco install $Name -y
                }
            }
            else {
                Write-Error "未找到可用的包管理器（winget 或 chocolatey）"
            }
        }
    }
    elseif ($IsMacOS) {
        if ($PSCmdlet.ShouldProcess($Name, 'Install via brew')) {
            if ($Update) {
                & brew upgrade $Name
            }
            else {
                & brew install $Name
            }
        }
    }
    elseif ($IsLinux) {
        $pkgMgr = Get-LinuxPackageManager
        if ($PSCmdlet.ShouldProcess($Name, "Install via $pkgMgr")) {
            switch ($pkgMgr) {
                'apt'   { & sudo apt-get install -y $Name }
                'dnf'   { & sudo dnf install -y $Name }
                'yum'   { & sudo yum install -y $Name }
                'pacman' { & sudo pacman -S --noconfirm $Name }
                default { Write-Error "不支持的包管理器: $pkgMgr" }
            }
        }
    }
}

function Get-LinuxPackageManager {
    [CmdletBinding()]
    param()

    if (Get-Command apt-get -ErrorAction SilentlyContinue) { return 'apt' }
    if (Get-Command dnf -ErrorAction SilentlyContinue)     { return 'dnf' }
    if (Get-Command yum -ErrorAction SilentlyContinue)     { return 'yum' }
    if (Get-Command pacman -ErrorAction SilentlyContinue)  { return 'pacman' }
    return $null
}

#endregion

#region 服务管理抽象

function Get-PlatformService {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Name
    )

    if ($IsWindows) {
        return Get-Service -Name $Name -ErrorAction SilentlyContinue
    }
    elseif ($IsLinux) {
        $status = systemctl is-active $Name 2>$null
        $enabled = systemctl is-enabled $Name 2>$null
        return [PSCustomObject]@{
            Name    = $Name
            Status  = if ($status -eq 'active') { 'Running' } else { 'Stopped' }
            Enabled = ($enabled -eq 'enabled')
        }
    }
    elseif ($IsMacOS) {
        $loaded = launchctl list $Name 2>$null
        return [PSCustomObject]@{
            Name    = $Name
            Status  = if ($loaded) { 'Running' } else { 'Stopped' }
            Enabled = [bool]$loaded
        }
    }
}

#endregion

#region 用户管理抽象

function Get-PlatformUser {
    [CmdletBinding()]
    param(
        [Parameter()]
        [string]$UserName = $env:USER
    )

    if ($IsWindows) {
        $adsi = [ADSI]"WinNT://$env:COMPUTERNAME"
        $user = $adsi.Children | Where-Object {
            $_.SchemaClassName -eq 'User' -and $_.Name -eq $UserName
        }
        if ($user) {
            return [PSCustomObject]@{
                Name        = $user.Name[0]
                FullName    = $user.FullName[0]
                Description = $user.Description[0]
                HomeDir     = Join-PlatformPath $env:USERPROFILE $user.Name[0]
                Platform    = 'Windows'
            }
        }
    }
    else {
        $passwd = getent passwd $UserName 2>$null
        if ($passwd) {
            $fields = $passwd -split ':'
            return [PSCustomObject]@{
                Name        = $fields[0]
                FullName    = ($fields[4] -split ',', 2)[0]
                Description = ''
                HomeDir     = $fields[5]
                Shell       = $fields[6]
                Platform    = if ($IsMacOS) { 'macOS' } else { 'Linux' }
            }
        }
    }
}

#endregion

# 使用示例
$platform = Get-PlatformInfo
Write-Host "`n===== 跨平台工具函数演示 ====="
Write-Host "平台: $($platform.Platform)"

$currentUser = Get-PlatformUser
Write-Host "当前用户: $($currentUser.Name)"
Write-Host "主目录: $($currentUser.HomeDir)"

$tempPath = Get-PlatformTempPath
Write-Host "临时目录: $tempPath"
```

在 Windows 上运行的输出：

```
===== 跨平台工具函数演示 =====
平台: Windows
当前用户: admin
主目录: C:\Users\admin\admin
临时目录: C:\Users\admin\AppData\Local\Temp
```

在 Linux 上运行的输出：

```
===== 跨平台工具函数演示 =====
平台: Linux
当前用户: admin
主目录: /home/admin
临时目录: /tmp
```

## 注意事项

1. **始终使用 `[System.IO.Path]` 类处理路径拼接**：不要手动拼接路径分隔符。`[System.IO.Path]::Combine()` 会自动根据当前平台选择正确的分隔符，从根本上避免路径格式错误。

2. **利用 `$PSVersionTable` 做版本检查**：跨平台脚本开头建议加上版本守卫，确保运行环境是 PowerShell 7+。例如 `if ($PSVersionTable.PSVersion.Major -lt 7) { throw '此脚本需要 PowerShell 7.0 或更高版本' }`。

3. **注意 cmdlet 的平台差异**：并非所有 cmdlet 在所有平台上都可用。例如 `Get-Service` 只在 Windows 上可用，`Set-Clipboard` 在 Linux 上需要 `xclip` 依赖。编写脚本前用 `Get-Command` 检查目标 cmdlet 的可用性。

4. **文件权限模型不同**：Windows 使用 ACL（访问控制列表），Linux/macOS 使用 POSIX 权限（rwx）。如果脚本涉及权限设置，需要根据平台分别调用 `icacls`（Windows）或 `chmod`/`chown`（Linux/macOS）。

5. **环境变量大小写敏感**：Windows 的环境变量名不区分大小写，而 Linux/macOS 区分。`$env:PATH` 在所有平台上都能工作，但自定义环境变量如 `$env:MyApp_Home` 在 Linux 上必须与设置时完全一致（包括大小写）。

6. **测试覆盖三大平台**：推荐使用 Docker（Linux）、WSL（Linux 交叉测试）和本地 macOS 环境进行实际验证。仅靠阅读代码很难发现所有平台特定问题，自动化测试是最好的保障。有条件的话可以使用 GitHub Actions 的多平台矩阵（`os: [windows-latest, ubuntu-latest, macos-latest]`）实现 CI 级别的跨平台验证。
