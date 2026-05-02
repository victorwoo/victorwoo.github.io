---
layout: post
date: 2025-07-25 08:00:00
updated: 2025-07-25 08:00:00
title: "PowerShell 技能连载 - WSL 集成操作"
description: PowerTip of the Day - WSL Integration in PowerShell
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
- wsl
- linux
- cross-platform
---

_适用于 PowerShell 5.1 及以上版本（Windows），需要安装 WSL_

Windows Subsystem for Linux (WSL) 让 Windows 和 Linux 无缝协作——在 Windows 上运行 Linux 工具链，同时享受 Windows 的图形界面和生态。PowerShell 可以通过 `wsl` 命令与 WSL 交互，调用 Linux 命令、管理 WSL 发行版、在两个环境之间传递数据。这种能力让运维人员可以在一个终端中同时使用 PowerShell 和 Bash 的优势。

本文将讲解 PowerShell 与 WSL 的集成操作技巧。

<!-- more -->

## WSL 基本管理

```powershell
# 查看已安装的 WSL 发行版
wsl --list --verbose

# 安装新的发行版
# wsl --install -d Ubuntu-24.04

# 设置默认发行版
wsl --set-default Ubuntu-24.04

# 管理 WSL 实例
function Get-WslDistributions {
    $output = wsl --list --verbose 2>&1
    # 解析输出（跳过标题行）
    $lines = $output | Select-Object -Skip 2 | Where-Object { $_.Trim() }

    foreach ($line in $lines) {
        $parts = $line.Trim() -split '\s+'
        if ($parts.Count -ge 3) {
            $isDefault = $line -match '^\*'
            [PSCustomObject]@{
                IsDefault  = $isDefault
                Name       = $parts[0] -replace '^\*', ''
                State      = $parts[1]
                Version    = $parts[2]
            }
        }
    }
}

Get-WslDistributions | Format-Table -AutoSize

# 启动/停止 WSL
function Start-WslInstance {
    param([string]$Distribution = "Ubuntu-24.04")

    Write-Host "启动 WSL：$Distribution" -ForegroundColor Cyan
    wsl -d $Distribution -- echo "WSL $Distribution 已启动"
}

function Stop-WslInstance {
    param([string]$Distribution)

    if ($Distribution) {
        wsl -t $Distribution
        Write-Host "已停止 WSL：$Distribution" -ForegroundColor Yellow
    } else {
        wsl --shutdown
        Write-Host "已停止所有 WSL 实例" -ForegroundColor Yellow
    }
}

# 查看 WSL 资源使用
function Get-WslResourceUsage {
    $output = wsl -- bash -c "free -h && echo '---' && df -h / && echo '---' && nproc"
    Write-Host $output
}

Get-WslResourceUsage
```

执行结果示例：

```
  NAME            STATE       VERSION
* Ubuntu-24.04    Running     2
  Debian          Stopped     2

IsDefault Name         State   Version
--------- ----         -----   -------
     True Ubuntu-24.04 Running 2
    False Debian       Stopped 2

启动 WSL：Ubuntu-24.04
WSL Ubuntu-24.04 已启动

              total        used        free
Mem:           15Gi       4.2Gi        11Gi
Swap:         4.0Gi          0B       4.0Gi
---
Filesystem      Size  Used Avail Use% Mounted on
/dev/sdb        250G   45G  205G  18% /
---
8
```

## 跨系统命令调用

```powershell
# 从 PowerShell 调用 Linux 命令
function Invoke-WslCommand {
    param(
        [Parameter(Mandatory)]
        [string]$Command,

        [string]$Distribution = "Ubuntu-24.04"
    )

    $result = wsl -d $Distribution -- bash -c $Command 2>&1
    return $result
}

# 使用 Linux 工具处理数据
# 用 grep 过滤日志
$nginxErrors = Invoke-WslCommand "grep -c 'ERROR' /var/log/nginx/error.log 2>/dev/null || echo 0"
Write-Host "Nginx 错误数：$nginxErrors"

# 用 awk 处理 CSV
$awkResult = Invoke-WslCommand @"
awk -F',' '{sum += $3; count++} END {print "Average:", sum/count}' /tmp/data.csv
"@
Write-Host "AWK 结果：$awkResult"

# 用 jq 处理 JSON
$jsonResult = Invoke-WslCommand "echo '{\"name\":\"test\",\"value\":42}' | jq '.value'"
Write-Host "JSON 处理：$jsonResult"

# 用 find 查找文件
$found = Invoke-WslCommand "find /home -name '*.sh' -mtime -7 2>/dev/null | head -10"
Write-Host "最近修改的脚本：`n$found"

# 从 WSL 调用 PowerShell（反向调用）
$psResult = wsl -- powershell.exe -Command "Get-Date -Format 'yyyy-MM-dd HH:mm:ss'"
Write-Host "从 WSL 调用 PowerShell：$psResult"

# 混合管道：PowerShell 采集数据，Linux 处理
$processes = Get-Process | Select-Object Name, CPU,
    @{N='MemMB'; E={[math]::Round($_.WorkingSet64/1MB,1)}} |
    ConvertTo-Csv -NoTypeInformation

# 通过管道传给 Linux sort
$sorted = $processes | wsl -- sort -t',' -k3 -rn | wsl -- head -5
Write-Host "`n内存排序 Top 5（Linux sort）：" -ForegroundColor Cyan
Write-Host $sorted
```

执行结果示例：

```
Nginx 错误数：23
JSON 处理：42

最近修改的脚本：
/home/user/scripts/backup.sh
/home/user/scripts/deploy.sh

从 WSL 调用 PowerShell：2025-07-25 08:30:15

内存排序 Top 5（Linux sort）：
"chrome",1250.34,512.5
"vscode",234.56,345.2
"node",456.78,256.3
"msedge",345.12,198.7
"powershell",123.45,85.6
```

## 文件系统互操作

```powershell
# 从 Windows 访问 WSL 文件
# WSL 文件系统在 \\wsl$\<发行版名>\ 下
$wslHome = "\\wsl$\Ubuntu-24.04\home"
Write-Host "WSL Home 目录内容：" -ForegroundColor Cyan
Get-ChildItem $wslHome | Select-Object Name, Length, LastWriteTime |
    Format-Table -AutoSize

# 从 WSL 访问 Windows 文件
# Windows 的 C 盘在 WSL 中是 /mnt/c/
Invoke-WslCommand "ls /mnt/c/Users/$env:USERNAME/Desktop | head -5"

# 双向文件复制
function Copy-WslFile {
    param(
        [Parameter(Mandatory)][string]$Source,
        [Parameter(Mandatory)][string]$Destination,
        [ValidateSet("WindowsToWsl", "WslToWindows")]
        [string]$Direction = "WindowsToWsl"
    )

    if ($Direction -eq "WindowsToWsl") {
        # Windows 路径转 WSL 路径
        $wslSource = $Source -replace '^([A-Z]):', '/mnt/$1' -replace '\\', '/'
        $wslDest = $Destination
        wsl -- cp -r $wslSource $wslDest
        Write-Host "已复制（Win->WSL）：$Source => $Destination" -ForegroundColor Green
    } else {
        $wslSource = $Source
        $winDest = $Destination
        wsl -- cp -r $wslSource "/mnt/c/$($winDest -replace '^([A-Z]):\\' , { $_.Groups[1].Value.ToLower() + '/' } -replace '\\', '/')"
        Write-Host "已复制（WSL->Win）：$Source => $Destination" -ForegroundColor Green
    }
}

# 同步项目目录到 WSL
$projectDir = "C:\Projects\MyApp"
$wslDest = "/home/user/projects/"
Copy-WslFile -Source $projectDir -Destination $wslDest -Direction WindowsToWsl

# 在 WSL 中执行构建
Invoke-WslCommand "cd /home/user/projects/MyApp && make build"
```

执行结果示例：

```
WSL Home 目录内容：
Name       Length LastWriteTime
----       ------ -------------
user            0 2025-07-25 08:00:00
projects        0 2025-07-25 08:00:00
scripts         0 2025-07-25 08:00:00

Desktop
Documents
Downloads
已复制（Win->WSL）：C:\Projects\MyApp => /home/user/projects/
Build complete.
```

## 开发环境管理

```powershell
# 在 WSL 中管理开发环境
function Enter-WslDev {
    param(
        [string]$Distribution = "Ubuntu-24.04",
        [string]$ProjectPath = "/home/user/projects"
    )

    Write-Host "进入 WSL 开发环境..." -ForegroundColor Cyan
    wsl -d $Distribution -- cd $ProjectPath '&&' bash -l
}

# 检查 WSL 中的开发工具
function Test-WslDevTools {
    $tools = @(
        @{ Name = "git";    Command = "git --version" },
        @{ Name = "node";   Command = "node --version" },
        @{ Name = "python"; Command = "python3 --version" },
        @{ Name = "docker"; Command = "docker --version" },
        @{ Name = "make";   Command = "make --version | head -1" }
    )

    Write-Host "WSL 开发工具检查：" -ForegroundColor Cyan

    foreach ($tool in $tools) {
        try {
            $version = (Invoke-WslCommand $tool.Command 2>&1) | Select-Object -First 1
            if ($LASTEXITCODE -eq 0 -or $version) {
                Write-Host "  $($tool.Name)：$version" -ForegroundColor Green
            } else {
                Write-Host "  $($tool.Name)：未安装" -ForegroundColor Yellow
            }
        } catch {
            Write-Host "  $($tool.Name)：未安装" -ForegroundColor Yellow
        }
    }
}

Test-WslDevTools

# 在 WSL 中运行 Docker
function Invoke-WslDocker {
    param(
        [Parameter(Mandatory)]
        [string]$Image,

        [string]$Command = "echo 'Container running'"
    )

    $dockerCmd = "docker run --rm $Image bash -c '$Command'"
    $result = Invoke-WslCommand $dockerCmd
    Write-Host $result
}

# 快速启动 MySQL 测试容器
Invoke-WslDocker -Image "mysql:8.0" -Command "mysql --version"
```

执行结果示例：

```
WSL 开发工具检查：
  git：git version 2.45.1
  node：v20.14.0
  python：Python 3.12.4
  docker：Docker version 26.1.3
  make：GNU Make 4.3

mysql  Ver 8.0.38 for Linux on x86_64 (MySQL Community Server - GPL)
```

## 注意事项

1. **路径转换**：Windows 使用反斜杠和盘符（`C:\`），WSL 使用正斜杠和 `/mnt/c/`，注意转换
2. **性能差异**：跨文件系统（`/mnt/c/`）的 IO 性能远低于 WSL 原生文件系统（`~/`）
3. **换行符**：Windows 用 `\r\n`，Linux 用 `\n`，跨系统处理文本时注意换行符转换
4. **网络访问**：WSL2 有独立的虚拟网络，从 WSL 访问 Windows 服务使用 `$(hostname).local`
5. **systemd 支持**：WSL2 支持 systemd，需要在 `/etc/wsl.conf` 中启用
6. **内存限制**：WSL2 默认使用系统一半内存，可通过 `.wslconfig` 文件配置
