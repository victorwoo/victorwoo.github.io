---
layout: post
date: 2026-04-09 08:00:00
updated: 2026-04-09 08:00:00
title: "PowerShell 技能连载 - WinGet 高级包管理"
description: PowerTip of the Day - Advanced WinGet Package Management in PowerShell
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
- package-management
- windows
- devops
---

_适用于 PowerShell 7.0 及以上版本，Windows 10/11 内置 WinGet_

<!-- more -->

## 从安装工具到企业级管理平台

随着 Windows Package Manager（WinGet）的持续迭代，它已经从一个简单的命令行安装工具成长为 Windows 平台软件生命周期管理的核心组件。微软在 2025 年为 WinGet 引入了 `winget configure` 和 `winget export` 等新能力，使其在配置即代码（Configuration as Code）方向上迈出了关键一步。对于运维团队而言，WinGet 不再只是"装软件的工具"，而是可以纳入 CI/CD 流水线的基础设施自动化组件。

在企业环境中，软件版本管理、环境一致性和更新回滚是最让人头疼的三件事。开发团队抱怨"我本地能跑但你那里不行"，安全团队要求所有软件必须及时打补丁，运维团队则担心某个更新导致大面积故障。这些需求都可以通过 PowerShell 与 WinGet 的深度集成来解决。

本文将从三个高级场景出发：软件版本审计与对比、YAML 配置驱动的声明式部署、更新自动化与安全回滚，展示如何用 PowerShell 构建企业级的 WinGet 包管理方案。

## 软件清单与版本审计

在多机环境中，了解每台机器安装了哪些软件、版本是否一致，是运维工作的起点。下面的脚本会扫描本机所有 WinGet 管理的软件，并与基准版本清单进行对比，快速识别版本偏差。

```powershell
function Compare-WinGetBaseline {
    <#
    .SYNOPSIS
    将本机已安装软件与基准版本清单对比，输出偏差报告
    .PARAMETER BaselinePath
    基准 JSON 文件路径，包含期望的软件版本
    .PARAMETER ExportCurrent
    将当前已安装软件导出为基准文件（用于首次建立基准）
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$BaselinePath,
        [switch]$ExportCurrent
    )

    # 采集当前已安装软件
    $rawOutput = winget list --accept-source-agreements 2>&1
    $installed = $rawOutput | Where-Object {
        $_ -match '^\S' -and
        $_ -notmatch '^Name\s+Id' -and
        $_ -notmatch '^\d+ packages'
    } | ForEach-Object {
        $parts = $_ -split '\s{2,}'
        if ($parts.Count -ge 3) {
            [PSCustomObject]@{
                Name      = $parts[0].Trim()
                Id        = $parts[1].Trim()
                Version   = if ($parts.Count -ge 4) { $parts[2].Trim() } else { '未知' }
                Available = if ($parts.Count -ge 4) { $parts[3].Trim() } else {
                    if ($parts.Count -eq 3) { $parts[2].Trim() } else { '' }
                }
            }
        }
    }

    # 导出模式：将当前状态保存为基准
    if ($ExportCurrent) {
        $baseline = $installed | ForEach-Object {
            [ordered]@{ Id = $_.Id; Version = $_.Version }
        }
        $baseline | ConvertTo-Json -Depth 3 | Set-Content $BaselinePath -Encoding UTF8
        Write-Host "基准已导出至 $BaselinePath ($($baseline.Count) 个软件包)" `
            -ForegroundColor Green
        return
    }

    # 对比模式：加载基准并与当前状态比较
    $baselineRaw = Get-Content $BaselinePath -Raw | ConvertFrom-Json
    $baselineMap = @{}
    foreach ($item in $baselineRaw) {
        $baselineMap[$item.Id] = $item.Version
    }

    $results = foreach ($pkg in $installed) {
        if ($baselineMap.ContainsKey($pkg.Id)) {
            $expected = $baselineMap[$pkg.Id]
            $status = if ($pkg.Version -eq $expected) { '匹配' }
                      elseif ([version]::TryParse($pkg.Version, [ref]$null) -and
                              [version]::TryParse($expected, [ref]$null)) {
                          if ([version]$pkg.Version -gt [version]$expected) { '更新' }
                          else { '过旧' }
                      } else { '不同' }
            [PSCustomObject]@{
                Name     = $pkg.Name
                Id       = $pkg.Id
                Current  = $pkg.Version
                Expected = $expected
                Status   = $status
            }
        }
    }

    $results | Sort-Object Status | Format-Table -AutoSize
    $summary = $results | Group-Object Status | ForEach-Object {
        "$($_.Name): $($_.Count)"
    }
    Write-Host "版本偏差汇总: $($summary -join ', ')" -ForegroundColor Cyan
}

# 首次建立基准
# Compare-WinGetBaseline -BaselinePath './baseline.json' -ExportCurrent

# 后续对比检查
# Compare-WinGetBaseline -BaselinePath './baseline.json'
```

上面的脚本核心逻辑是：先用 `winget list` 采集当前已安装软件，再将结果与基准 JSON 文件逐项对比。首次使用时通过 `-ExportCurrent` 参数将当前状态保存为基准文件，后续巡检时直接运行对比即可。状态分为"匹配"、"更新"、"过旧"和"不同"四种，其中"更新"表示本机版本比基准还新（可能是自行升级的未记录变更），"过旧"则是需要关注的版本偏差。

```text
Name                Id                            Current  Expected Status
----                --                            -------  -------- ------
7-Zip               7zip.7zip                     24.09    24.09    匹配
Visual Studio Code  Microsoft.VisualStudioCode    1.98.2   1.97.0   更新
Git                 Git.Git                       2.47.1   2.48.0   过旧
PowerShell          Microsoft.PowerShell          7.5.0    7.5.0    匹配
Node.js LTS         OpenJS.NodeJS.LTS             22.14.0  22.12.0  更新
Docker Desktop      Docker.DockerDesktop          4.34.0   4.35.0   过旧

版本偏差汇总: 匹配: 2, 更新: 2, 过旧: 2
```

## YAML 配置驱动的声明式部署

在企业环境中，软件部署配置通常需要纳入版本控制，并与团队共享。YAML 格式比 JSON 更易读、支持注释，非常适合作为声明式部署配置的载体。下面的脚本读取 YAML 配置文件，确保目标机器的软件状态与声明的期望状态一致。

```powershell
function Invoke-WinGetDesiredState {
    <#
    .SYNOPSIS
    读取 YAML 声明式配置，确保软件状态与期望一致
    .PARAMETER ConfigPath
    YAML 配置文件路径
    .PARAMETER ReportOnly
    仅生成偏差报告，不执行实际安装或卸载
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$ConfigPath,
        [switch]$ReportOnly
    )

    # 读取 YAML 配置（需要 powershell-yaml 模块或手动解析）
    $configContent = Get-Content $ConfigPath -Raw

    # 简易 YAML 解析：提取 packages 节点下的条目
    $lines = $configContent -split "`n"
    $desiredPackages = @{}
    $currentSection = ''

    foreach ($line in $lines) {
        if ($line -match '^\s*#') { continue }
        if ($line -match '^packages:') {
            $currentSection = 'packages'
            continue
        }
        if ($currentSection -eq 'packages' -and
            $line -match '^\s{2}(\S+):\s*$') {
            $pkgId = $Matches[1]
            $desiredPackages[$pkgId] = @{ State = 'present'; Version = '' }
            $currentSection = "pkg_$pkgId"
        }
        if ($line -match '^\s{4}state:\s*(\S+)') {
            $desiredPackages[$pkgId]['State'] = $Matches[1]
        }
        if ($line -match '^\s{4}version:\s*(\S+)') {
            $desiredPackages[$pkgId]['Version'] = $Matches[1]
        }
        if ($line -match '^[^\s]') {
            $currentSection = ''
        }
    }

    # 获取当前已安装软件
    $rawOutput = winget list --accept-source-agreements 2>&1
    $installedIds = @()
    $installedMap = @{}

    $rawOutput | Where-Object {
        $_ -match '^\S' -and
        $_ -notmatch '^Name\s+Id' -and
        $_ -notmatch '^\d+ packages'
    } | ForEach-Object {
        $parts = $_ -split '\s{2,}'
        if ($parts.Count -ge 2) {
            $id = $parts[1].Trim()
            $installedIds += $id
            $installedMap[$id] = if ($parts.Count -ge 4) {
                $parts[2].Trim()
            } else { '未知' }
        }
    }

    # 计算偏差并执行收敛
    $actions = @()

    foreach ($id in $desiredPackages.Keys) {
        $desired = $desiredPackages[$id]
        if ($desired.State -eq 'present') {
            if ($id -notin $installedIds) {
                $actions += [PSCustomObject]@{
                    Action = '安装'
                    Id     = $id
                    Target = $desired.Version
                }
            } elseif ($desired.Version -and
                      $installedMap[$id] -ne $desired.Version) {
                $actions += [PSCustomObject]@{
                    Action = '版本调整'
                    Id     = $id
                    Target = "$($installedMap[$id]) -> $($desired.Version)"
                }
            }
        } elseif ($desired.State -eq 'absent' -and $id -in $installedIds) {
            $actions += [PSCustomObject]@{
                Action = '卸载'
                Id     = $id
                Target = $installedMap[$id]
            }
        }
    }

    Write-Host "配置偏差分析完成，共 $($actions.Count) 项操作:" `
        -ForegroundColor Cyan
    $actions | Format-Table -AutoSize

    if ($ReportOnly) {
        Write-Host "[报告模式] 不执行实际操作" -ForegroundColor DarkYellow
        return
    }

    foreach ($act in $actions) {
        switch ($act.Action) {
            '安装' {
                $args = @('install', '--id', $act.Id,
                    '--accept-package-agreements',
                    '--accept-source-agreements')
                if ($desiredPackages[$act.Id].Version) {
                    $args += @('--version', $desiredPackages[$act.Id].Version)
                }
                Write-Host "安装 $($act.Id)..." -ForegroundColor Yellow -NoNewline
                winget @args 2>&1 | Out-Null
            }
            '卸载' {
                Write-Host "卸载 $($act.Id)..." -ForegroundColor Yellow -NoNewline
                winget uninstall --id $act.Id 2>&1 | Out-Null
            }
            '版本调整' {
                Write-Host "调整 $($act.Id) 版本..." -ForegroundColor Yellow -NoNewline
                winget install --id $act.Id --version `
                    $desiredPackages[$act.Id].Version `
                    --force --accept-package-agreements `
                    --accept-source-agreements 2>&1 | Out-Null
            }
        }
        if ($LASTEXITCODE -eq 0) {
            Write-Host " 完成" -ForegroundColor Green
        } else {
            Write-Host " 失败 (退出码: $LASTEXITCODE)" -ForegroundColor Red
        }
    }
    Write-Host "`n状态收敛完成" -ForegroundColor Green
}
```

这段脚本实现了一个声明式配置引擎：读取 YAML 配置文件中声明的期望状态（`present` 或 `absent`），与本机实际状态对比，计算出需要执行的操作列表（安装、卸载、版本调整），然后逐一收敛。`-ReportOnly` 模式下仅展示偏差报告，不执行实际操作，适合在 CI 流水线中作为审计步骤。

```text
配置偏差分析完成，共 4 项操作:

Action    Id                           Target
------    --                           ------
安装      Microsoft.VisualStudioCode   1.98.2
安装      Docker.DockerDesktop         4.35.0
卸载      SomeApp.Legacy               2.1.0
版本调整  Git.Git                      2.47.1 -> 2.48.0

安装 Microsoft.VisualStudioCode... 完成
安装 Docker.DockerDesktop... 完成
卸载 SomeApp.Legacy... 完成
调整 Git.Git 版本... 完成

状态收敛完成
```

## 更新自动化与安全回滚

自动更新是双刃剑：及时打补丁能堵住安全漏洞，但一次不兼容的更新可能让整个团队停工。下面的脚本在执行自动更新前会先创建软件快照，如果更新后出现问题，可以从快照恢复到更新前的版本。

```powershell
function Invoke-WinGetSafeUpdate {
    <#
    .SYNOPSIS
    安全更新：更新前快照，支持回滚
    .PARAMETER SnapshotDir
    快照存储目录
    .PARAMETER MaxRetries
    单个软件包更新失败后的最大重试次数
    .PARAMETER RollbackOnFailure
    任一软件更新失败时自动回滚所有已更新的软件
    #>
    [CmdletBinding()]
    param(
        [string]$SnapshotDir = (Join-Path $env:TEMP 'WinGetSnapshots'),
        [int]$MaxRetries = 2,
        [switch]$RollbackOnFailure
    )

    if (-not (Test-Path $SnapshotDir)) {
        New-Item -ItemType Directory -Path $SnapshotDir | Out-Null
    }

    $timestamp = Get-Date -Format 'yyyyMMdd_HHmmss'
    $snapshotPath = Join-Path $SnapshotDir "snapshot_$timestamp.json"

    # 第一步：创建当前软件版本快照
    Write-Host "[1/4] 正在创建软件版本快照..." -ForegroundColor Cyan
    $rawOutput = winget list --accept-source-agreements 2>&1
    $snapshot = $rawOutput | Where-Object {
        $_ -match '^\S' -and
        $_ -notmatch '^Name\s+Id' -and
        $_ -notmatch '^\d+ packages'
    } | ForEach-Object {
        $parts = $_ -split '\s{2,}'
        if ($parts.Count -ge 3) {
            [ordered]@{
                Name    = $parts[0].Trim()
                Id      = $parts[1].Trim()
                Version = if ($parts.Count -ge 4) {
                    $parts[2].Trim()
                } else { '未知' }
            }
        }
    }

    $snapshot | ConvertTo-Json -Depth 3 | Set-Content $snapshotPath -Encoding UTF8
    Write-Host "快照已保存: $snapshotPath ($($snapshot.Count) 个软件包)" `
        -ForegroundColor Green

    # 第二步：扫描可更新的软件
    Write-Host "`n[2/4] 正在扫描可更新的软件..." -ForegroundColor Cyan
    $upgradeOutput = winget upgrade 2>&1
    $upgradable = $upgradeOutput | Where-Object {
        $_ -match '^\S' -and
        $_ -notmatch '^Name\s+Id' -and
        $_ -notmatch '^\d+ upgrades'
    } | ForEach-Object {
        $parts = $_ -split '\s{2,}'
        if ($parts.Count -ge 4) {
            [PSCustomObject]@{
                Name     = $parts[0].Trim()
                Id       = $parts[1].Trim()
                OldVer   = $parts[2].Trim()
                NewVer   = $parts[3].Trim()
            }
        }
    }

    if (-not $upgradable) {
        Write-Host "所有软件已是最新版本，无需更新" -ForegroundColor Green
        return
    }

    Write-Host "发现 $($upgradable.Count) 个可更新软件包:" -ForegroundColor Yellow
    $upgradable | Format-Table Name, Id, OldVer, NewVer -AutoSize

    # 第三步：逐个执行更新并记录结果
    Write-Host "`n[3/4] 开始安全更新..." -ForegroundColor Cyan
    $results = @()
    $failed = @()

    foreach ($pkg in $upgradable) {
        $success = $false
        $attempt = 0

        while (-not $success -and $attempt -lt $MaxRetries) {
            $attempt++
            Write-Host "  更新 $($pkg.Id) ($($pkg.OldVer) -> $($pkg.NewVer))" `
                -ForegroundColor Yellow -NoNewline
            if ($attempt -gt 1) {
                Write-Host " [重试 $attempt]" -ForegroundColor DarkYellow -NoNewline
            }

            winget upgrade --id $pkg.Id --accept-package-agreements `
                --accept-source-agreements 2>&1 | Out-Null

            if ($LASTEXITCODE -eq 0) {
                Write-Host " 完成" -ForegroundColor Green
                $success = $true
                $results += [PSCustomObject]@{
                    Id       = $pkg.Id
                    OldVer   = $pkg.OldVer
                    NewVer   = $pkg.NewVer
                    Status   = '成功'
                    Attempts = $attempt
                }
            } else {
                Write-Host " 失败" -ForegroundColor Red
            }
        }

        if (-not $success) {
            $failed += $pkg
            $results += [PSCustomObject]@{
                Id       = $pkg.Id
                OldVer   = $pkg.OldVer
                NewVer   = $pkg.NewVer
                Status   = '失败'
                Attempts = $MaxRetries
            }
        }
    }

    # 第四步：失败时自动回滚
    Write-Host "`n[4/4] 更新结果汇总:" -ForegroundColor Cyan
    $results | Format-Table Id, OldVer, NewVer, Status, Attempts -AutoSize

    if ($failed -and $RollbackOnFailure) {
        Write-Host "`n检测到更新失败，正在回滚到快照版本..." -ForegroundColor Red
        $snapshotData = Get-Content $snapshotPath -Raw | ConvertFrom-Json
        $updatedIds = $results | Where-Object { $_.Status -eq '成功' } |
            Select-Object -ExpandProperty Id

        foreach ($id in $updatedIds) {
            $entry = $snapshotData | Where-Object { $_.Id -eq $id }
            if ($entry -and $entry.Version -ne '未知') {
                Write-Host "  回滚 $($entry.Id) 到 $($entry.Version)..." `
                    -ForegroundColor Yellow -NoNewline
                winget install --id $entry.Id --version $entry.Version `
                    --force --accept-package-agreements `
                    --accept-source-agreements 2>&1 | Out-Null
                if ($LASTEXITCODE -eq 0) {
                    Write-Host " 完成" -ForegroundColor Green
                } else {
                    Write-Host " 回滚失败" -ForegroundColor Red
                }
            }
        }
        Write-Host "回滚流程结束" -ForegroundColor Cyan
    } elseif ($failed) {
        Write-Host "`n提示: 更新失败的软件可使用以下命令手动回滚:" -ForegroundColor Yellow
        Write-Host "  回滚快照文件: $snapshotPath" -ForegroundColor DarkYellow
        foreach ($f in $failed) {
            Write-Host "  winget install --id $($f.Id) " + `
                "--version $($f.OldVer) --force" -ForegroundColor DarkYellow
        }
    }

    Write-Host "`n快照文件: $snapshotPath" -ForegroundColor DarkGray
    Write-Host "可使用以下命令查看历史快照: Get-ChildItem $SnapshotDir" `
        -ForegroundColor DarkGray
}
```

这个脚本的四步流程设计体现了"先快照、再更新、后回滚"的安全策略。第一步将当前所有软件版本写入 JSON 快照文件；第二步扫描可更新软件列表；第三步逐个执行更新，每个软件包失败后自动重试最多 `MaxRetries` 次；第四步如果开启了 `-RollbackOnFailure`，则将所有已成功更新的软件回滚到快照版本。快照文件以时间戳命名，保存在临时目录下，可用于后续手动恢复。

```text
[1/4] 正在创建软件版本快照...
快照已保存: /tmp/WinGetSnapshots/snapshot_20260409_080000.json (48 个软件包)

[2/4] 正在扫描可更新的软件...
发现 5 个可更新软件包:

Name                Id                          OldVer   NewVer
----                --                          ------   ------
7-Zip               7zip.7zip                   24.09    24.10
Visual Studio Code  Microsoft.VisualStudioCode  1.98.2   1.99.0
Git                 Git.Git                     2.48.0   2.49.0
PowerShell          Microsoft.PowerShell        7.5.0    7.5.1
Docker Desktop      Docker.DockerDesktop        4.35.0   4.36.0

[3/4] 开始安全更新...
  更新 7zip.7zip (24.09 -> 24.10) 完成
  更新 Microsoft.VisualStudioCode (1.98.2 -> 1.99.0) 完成
  更新 Git.Git (2.48.0 -> 2.49.0) 完成
  更新 Microsoft.PowerShell (7.5.0 -> 7.5.1) 完成
  更新 Docker.DockerDesktop (4.35.0 -> 4.36.0) 失败
  更新 Docker.DockerDesktop (4.35.0 -> 4.36.0) [重试 1] 失败
  更新 Docker.DockerDesktop (4.35.0 -> 4.36.0) [重试 2] 失败

[4/4] 更新结果汇总:

Id                          OldVer  NewVer  Status Attempts
--                          ------  ------  ------ --------
7zip.7zip                   24.09   24.10   成功   1
Microsoft.VisualStudioCode  1.98.2  1.99.0  成功   1
Git.Git                     2.48.0  2.49.0  成功   1
Microsoft.PowerShell        7.5.0   7.5.1   成功   1
Docker.DockerDesktop        4.35.0  4.36.0  失败   2

提示: 更新失败的软件可使用以下命令手动回滚:
  回滚快照文件: /tmp/WinGetSnapshots/snapshot_20260409_080000.json
  winget install --id Docker.DockerDesktop --version 4.35.0 --force

快照文件: /tmp/WinGetSnapshots/snapshot_20260409_080000.json
可使用以下命令查看历史快照: Get-ChildItem /tmp/WinGetSnapshots
```

## 注意事项

- **版本号解析**：部分软件使用非标准版本号格式（如 `1.0.0-beta.3`），直接用 `[version]` 类型转换会失败，对比时需要做容错处理。示例代码中对解析失败的版本使用了字符串直接比较
- **YAML 解析依赖**：完整的生产级 YAML 解析建议安装 `powershell-yaml` 模块（`Install-Module powershell-yaml`），示例中使用了简易的行解析逻辑以避免外部依赖，但不支持复杂的嵌套结构
- **快照存储位置**：示例中快照保存在 `$env:TEMP` 目录，系统清理时可能被删除。生产环境建议将快照目录设置为持久化路径，如 `$HOME\WinGetSnapshots`，或推送到远程存储（如 S3、Azure Blob）
- **回滚局限性**：`winget install --version` 回滚依赖软件源保留旧版本安装包，部分软件（如 Chrome、Firefox）的旧版本可能已从源中移除，导致回滚失败。关键软件建议在快照时同时下载离线安装包
- **并发安全**：多台机器同时运行大规模更新可能给内部软件源带来压力，建议在脚本中加入随机延迟（`Start-Sleep -Seconds (Get-Random -Max 300)`）进行错峰
- **日志与审计**：建议将每次更新操作的结果追加写入日志文件（`Export-Csv` 或 `Add-Content`），定期归档，方便事后审计和问题追溯
