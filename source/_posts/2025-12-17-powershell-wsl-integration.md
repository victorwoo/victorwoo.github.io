---
layout: post
date: 2025-12-17 08:00:00
updated: 2025-12-17 08:00:00
title: "PowerShell 技能连载 - WSL 集成与互操作"
description: PowerTip of the Day - WSL Integration and Interop in PowerShell
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
- scripting
---

_适用于 PowerShell 7.0 及以上版本_

Windows Subsystem for Linux (WSL) 已经从一个实验性的兼容层发展为成熟的 Linux 运行环境。WSL2 基于真正的 Linux 内核，支持 systemd、Docker 以及绝大多数原生 Linux 应用。对于日常在 Windows 上工作的运维工程师和开发者来说，WSL 提供了一条低成本的 Linux 工具链接入路径——无需双系统，无需虚拟机管理程序的开销。

PowerShell 与 WSL 的互操作不仅限于简单的命令转发。借助 `wsl` 命令行工具、`\\wsl$` 网络路径以及双向的进程调用机制，可以在一个脚本中自由混合 Windows 和 Linux 工具。例如，用 PowerShell 采集 Windows 事件日志，再通过管道传给 WSL 中的 `awk` 做文本分析；或者反过来，在 WSL 中编译项目后调用 PowerShell 部署到 Windows 服务。这种混合工作流在 DevOps 和跨平台自动化场景中尤为实用。

本文将从实例管理、跨平台数据交换和自动化部署三个维度，展示 PowerShell 与 WSL 深度集成的实战技巧。

<!-- more -->

## 管理 WSL 实例生命周期

日常工作中，我们经常需要创建、备份、迁移 WSL 实例。PowerShell 可以把 `wsl.exe` 的能力封装成可复用的管理函数，实现实例的批量运维。

```powershell
# 定义 WSL 实例管理工具集
function Get-WslInstance {
    <# 获取所有 WSL 发行版的详细信息 #>
    $raw = wsl --list --verbose 2>&1
    $lines = $raw | Select-Object -Skip 2 | Where-Object { $_ -match '\S' }

    foreach ($line in $lines) {
        $parts = $line.Trim() -split '\s+'
        [PSCustomObject]@{
            IsDefault = $line -match '^\*'
            Name      = $parts[0] -replace '^\*', ''
            State     = $parts[1]
            Version   = $parts[2]
        }
    }
}

function Export-WslInstance {
    <# 将 WSL 实例导出为 tar 文件，用于备份或迁移 #>
    param(
        [Parameter(Mandatory)][string]$Name,
        [Parameter(Mandatory)][string]$OutputPath
    )

    if (-not (Test-Path (Split-Path $OutputPath -Parent))) {
        New-Item -ItemType Directory -Path (Split-Path $OutputPath -Parent) -Force |
            Out-Null
    }

    Write-Host "正在导出 $Name ..." -ForegroundColor Cyan
    wsl --export $Name $OutputPath

    $size = [math]::Round((Get-Item $OutputPath).Length / 1GB, 2)
    Write-Host "导出完成：$OutputPath (${size} GB)" -ForegroundColor Green
}

function Import-WslInstance {
    <# 从 tar 文件导入为新的 WSL 实例 #>
    param(
        [Parameter(Mandatory)][string]$Name,
        [Parameter(Mandatory)][string]$InstallPath,
        [Parameter(Mandatory)][string]$SourceFile
    )

    if (-not (Test-Path $InstallPath)) {
        New-Item -ItemType Directory -Path $InstallPath -Force | Out-Null
    }

    Write-Host "正在导入 $Name ..." -ForegroundColor Cyan
    wsl --import $Name $InstallPath $SourceFile
    Write-Host "导入完成：$Name => $InstallPath" -ForegroundColor Green
}

function Remove-WslInstance {
    <# 注销并删除 WSL 实例（谨慎使用） #>
    param(
        [Parameter(Mandatory)][string]$Name,
        [switch]$Force
    )

    if (-not $Force) {
        $confirm = Read-Host "确认要删除 WSL 实例 '$Name' 吗？(yes/no)"
        if ($confirm -ne 'yes') {
            Write-Host "已取消" -ForegroundColor Yellow
            return
        }
    }

    wsl --unregister $Name
    Write-Host "已删除 WSL 实例：$Name" -ForegroundColor Red
}

# 批量备份所有运行中的实例
$instances = Get-WslInstance | Where-Object State -eq 'Running'
$backupDir = "D:\WSL-Backups\$(Get-Date -Format 'yyyyMMdd')"

foreach ($inst in $instances) {
    $tar = Join-Path $backupDir "$($inst.Name).tar"
    Export-WslInstance -Name $inst.Name -OutputPath $tar
}
```

执行结果示例：

```
正在导出 Ubuntu-24.04 ...
导出完成：D:\WSL-Backups\20251217\Ubuntu-24.04.tar (1.85 GB)
正在导出 Debian ...
导出完成：D:\WSL-Backups\20251217\Debian.tar (0.92 GB)
```

## 跨平台命令调用与数据交换

PowerShell 与 WSL 之间的数据交换是互操作的核心。下面展示几种常见模式：结构化数据传递、环境变量共享，以及双向脚本编排。

```powershell
# 封装一个通用的 WSL 命令执行器
function Invoke-WslCommand {
    param(
        [Parameter(Mandatory)][string]$Command,
        [string]$Distribution,
        [switch]$AsJson
    )

    $args = @()
    if ($Distribution) { $args += '-d', $Distribution }
    $args += '--', 'bash', '-c', $Command

    $result = & wsl @args 2>&1
    $result = $result | Out-String

    if ($AsJson -and $result) {
        try {
            return $result | ConvertFrom-Json
        } catch {
            Write-Warning "JSON 解析失败，返回原始文本"
            return $result
        }
    }
    return $result.Trim()
}

# 场景 1：用 Linux 工具分析 Windows 日志
# 先用 PowerShell 导出事件日志为 CSV，再用 WSL 的 awk 统计
$csvPath = "$env:TEMP\security_events.csv"
Get-WinEvent -LogName Security -MaxEvents 500 |
    Select-Object TimeCreated, Id, LevelDisplayName, Message |
    Export-Csv $csvPath -NoTypeInformation -Encoding UTF8

# 将 Windows 路径转为 WSL 可访问的路径
$wslCsv = ($csvPath -replace '^([A-Z]):', { '/mnt/' + $_.Groups[1].Value.ToLower() } `
    -replace '\\', '/')

$stats = Invoke-WslCommand "awk -F',' '{print `$3}' $wslCsv | sort | uniq -c | sort -rn"
Write-Host "安全事件级别分布：" -ForegroundColor Cyan
Write-Host $stats

# 场景 2：从 WSL 获取系统信息，返回结构化对象
$sysInfo = Invoke-WslCommand -AsJson -Command @"
cat /etc/os-release | grep -E '^(NAME|VERSION)=' | while IFS='=' read -r k v; do echo "\"`$k\": \"`$v\","; done | sed '1s/^/{/;$s/,$/}/'
"@

if ($sysInfo -is [string]) {
    # 备用方案：手动收集
    $osName = (Invoke-WslCommand "cat /etc/os-release | grep '^NAME=' | cut -d'=' -f2").Trim('"')
    $osVer = (Invoke-WslCommand "cat /etc/os-release | grep '^VERSION=' | cut -d'=' -f2").Trim('"')
    $sysInfo = [PSCustomObject]@{ NAME = $osName; VERSION = $osVer }
}

Write-Host "`nWSL 系统信息：" -ForegroundColor Cyan
Write-Host "  发行版：$($sysInfo.NAME)"
Write-Host "  版本：$($sysInfo.VERSION)"

# 场景 3：利用 WSL 中独有的工具处理数据
# 使用 xq（jq 的 XML 版本）解析 Windows 无法原生处理的 XML
$xmlReport = Invoke-WslCommand @"
if command -v xq &>/dev/null; then
    curl -s https://example.com/feed.xml | xq '.rss.channel.item[] | .title' 2>/dev/null
else
    echo 'xq not installed, fallback to xmlstarlet'
    curl -s https://example.com/feed.xml | xmlstarlet sel -t -m '//item/title' -v '.' -n 2>/dev/null
fi
"@

Write-Host "`nRSS 标题提取：" -ForegroundColor Cyan
Write-Host $xmlReport
```

执行结果示例：

```
安全事件级别分布：
    420 信息
     45 审核
     28 警告
      7 错误

WSL 系统信息：
  发行版：Ubuntu
  版本：24.04.1 LTS (Noble Numbat)

RSS 标题提取：
PowerShell 7.5 发布：新特性一览
.NET 9 正式可用
Azure 新增多云管理功能
```

## 自动化部署场景：混合 Windows/Linux 工具链

在实际的 CI/CD 和运维自动化中，经常需要将 Windows 原生工具与 Linux 工具链串联起来。下面的示例展示了一个完整的混合部署脚本：在 WSL 中编译 Node.js 项目，然后在 Windows 上完成 IIS 部署。

```powershell
# 混合平台部署脚本
function Invoke-HybridDeploy {
    param(
        [string]$ProjectName = "webapp",
        [string]$WslProjectPath = "/home/user/projects/$ProjectName",
        [string]$WinDeployPath = "C:\inetpub\wwwroot\$ProjectName",
        [string]$Distribution = "Ubuntu-24.04"
    )

    # 阶段 1：在 WSL 中拉取代码并构建
    Write-Host "`n[1/4] 在 WSL 中拉取最新代码..." -ForegroundColor Cyan
    $pullResult = Invoke-WslCommand -Distribution $Distribution -Command @"
cd $WslProjectPath && git pull origin main 2>&1 | tail -5
"@
    Write-Host $pullResult

    # 阶段 2：在 WSL 中执行 npm 构建
    Write-Host "`n[2/4] 在 WSL 中执行构建..." -ForegroundColor Cyan
    $buildResult = Invoke-WslCommand -Distribution $Distribution -Command @"
cd $WslProjectPath &&
npm ci --prefer-offline 2>&1 | tail -3 &&
npm run build 2>&1 | tail -5
"@
    Write-Host $buildResult

    # 阶段 3：将构建产物从 WSL 文件系统复制到 Windows
    Write-Host "`n[3/4] 复制构建产物到 Windows..." -ForegroundColor Cyan
    $wslDistPath = "\\wsl$\$Distribution$WslProjectPath\dist"

    if (Test-Path $WinDeployPath) {
        $backup = "$WinDeployPath.bak.$(Get-Date -Format 'yyyyMMdd_HHmmss')"
        Move-Item $WinDeployPath $backup -Force
        Write-Host "已备份旧版本到 $backup" -ForegroundColor Yellow
    }

    Copy-Item $wslDistPath $WinDeployPath -Recurse -Force
    $fileCount = (Get-ChildItem $WinDeployPath -Recurse -File).Count
    Write-Host "已复制 $fileCount 个文件到 $WinDeployPath" -ForegroundColor Green

    # 阶段 4：用 PowerShell 进行 Windows 端配置
    Write-Host "`n[4/4] 更新 IIS 配置..." -ForegroundColor Cyan

    # 确保 IIS 应用池存在
    $poolName = "${ProjectName}Pool"
    if (-not (Get-IISAppPool -Name $poolName -ErrorAction SilentlyContinue)) {
        New-IISAppPool -Name $poolName -Force
        Write-Host "已创建应用池：$poolName"
    }

    # 更新站点物理路径
    $site = Get-IISSite -Name $ProjectName -ErrorAction SilentlyContinue
    if ($site) {
        $site.Applications["/"].VirtualDirectories["/"].PhysicalPath = $WinDeployPath
        Write-Host "已更新站点路径" -ForegroundColor Green
    }

    # 验证部署结果
    $indexPath = Join-Path $WinDeployPath "index.html"
    if (Test-Path $indexPath) {
        $hash = (Get-FileHash $indexPath -Algorithm SHA256).Hash.Substring(0, 16)
        Write-Host "`n部署成功！index.html 校验：$hash" -ForegroundColor Green
    }

    # 阶段 5：健康检查（用 WSL 中的 curl）
    Write-Host "`n健康检查..." -ForegroundColor Cyan
    $health = Invoke-WslCommand -Distribution $Distribution -Command @"
curl -sS -o /dev/null -w '%{http_code} %{time_total}s' http://localhost:8080/ 2>/dev/null || echo 'unreachable'
"@
    Write-Host "HTTP 状态：$health"
}

# 执行部署
Invoke-HybridDeploy -ProjectName "webapp"
```

执行结果示例：

```
[1/4] 在 WSL 中拉取最新代码...
Already up to date.
Updating 3f2a1b0..7c8d9e0
Fast-forward
 src/App.js | 12 ++++++------
 2 files changed, 6 insertions(+), 6 deletions(-)

[2/4] 在 WSL 中执行构建...
added 245 packages in 3.2s
> webapp@1.0.0 build
> vite build
✓ built in 4.21s

[3/4] 复制构建产物到 Windows...
已备份旧版本到 C:\inetpub\wwwroot\webapp.bak.20251217_083000
已复制 42 个文件到 C:\inetpub\wwwroot\webapp

[4/4] 更新 IIS 配置...
已更新站点路径

部署成功！index.html 校验：A3F8B2C1D4E5F607

健康检查...
HTTP 状态：200 0.032s
```

## 注意事项

1. **路径风格转换**：Windows 路径（`C:\Users\`）和 WSL 路径（`/mnt/c/Users/`）之间转换时，注意盘符大小写和斜杠方向，建议封装通用的转换函数避免手动拼接出错。
2. **`\\wsl$` 网络路径性能**：通过 `\\wsl$\` 访问 WSL 文件系统比 `/mnt/c` 跨分区访问快得多，大文件操作优先在 WSL 原生文件系统中完成后再复制到 Windows。
3. **环境变量隔离**：Windows 和 WSL 的环境变量相互独立，`$env:PATH` 不会自动共享。如果需要传递变量，使用 `WSLENV` 配置共享映射规则。
4. **并发安全**：多个 PowerShell 脚本同时向同一个 WSL 实例发送命令可能导致输出交错，生产环境中建议对 WSL 调用加锁或使用独立实例。
5. **退出码传递**：`wsl -- command` 的 `$LASTEXITCODE` 返回的是 Linux 进程的退出码，但经过 PowerShell 管道处理后可能丢失，关键操作建议显式检查输出内容而非仅依赖退出码。
6. **换行符陷阱**：WSL 输出是 LF 换行，Windows 文件默认 CRLF。跨系统写入文本文件时注意使用统一的编码和换行符，否则可能导致配置文件解析失败。
