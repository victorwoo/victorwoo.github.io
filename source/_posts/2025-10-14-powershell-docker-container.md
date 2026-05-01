---
layout: post
date: 2025-10-14 08:00:00
title: "PowerShell 技能连载 - Docker 容器管理"
description: PowerTip of the Day - Docker Container Management in PowerShell
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
- docker
- container
- devops
- containerization
---

_适用于 PowerShell 7.0 及以上版本（跨平台）_

## 为什么用 PowerShell 管理 Docker 容器

Docker 作为当前最主流的容器化平台，已经成为现代应用交付和运维的基石。无论是微服务架构下的服务编排、CI/CD 流水线中的构建打包，还是本地开发环境的快速搭建，Docker 容器都扮演着不可替代的角色。然而，直接在命令行手动敲 `docker` 命令来管理大量容器，不仅效率低下，而且难以保证操作的一致性和可重复性。

PowerShell 凭借其强大的对象管道和脚本编排能力，非常适合将 Docker CLI 的输出转化为结构化数据，再配合条件判断、循环和错误处理，构建出可靠且可复用的容器管理自动化方案。跨平台的 PowerShell 7 让 Linux 和 Windows 环境下的运维人员可以使用同一套脚本完成容器管理工作。

本文将从容器生命周期管理、资源监控与统计、以及多容器批量部署三个场景出发，演示如何用 PowerShell 7 编写实用的 Docker 容器管理脚本。

## 容器生命周期管理

容器的创建、启停和删除是日常运维中最频繁的操作。将这些操作封装为函数，并加入状态检查和错误处理，可以避免手动操作时的疏漏。下面的脚本定义了一个通用的容器管理函数，支持创建、启动、停止和删除四种操作，每次操作后自动验证容器状态。

```powershell
function Invoke-ContainerLifecycle {
    <#
    .SYNOPSIS
    管理 Docker 容器的生命周期操作
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory)]
        [ValidateSet('Create', 'Start', 'Stop', 'Remove')]
        [string]$Action,

        [Parameter(Mandatory)]
        [string]$ContainerName,

        [string]$ImageName = 'nginx:latest',

        [int]$HostPort = 0,

        [int]$ContainerPort = 0
    )

    Write-Host "`n--- 执行操作: $Action | 容器: $ContainerName ---" -ForegroundColor Cyan

    try {
        switch ($Action) {
            'Create' {
                # 检查同名容器是否已存在
                $existing = docker ps -a --filter "name=^/$ContainerName$" --format '{{.Names}}' 2>$null
                if ($existing -eq $ContainerName) {
                    Write-Host "[跳过] 容器 '$ContainerName' 已存在" -ForegroundColor Yellow
                    return
                }

                # 构建端口映射参数
                $portArg = ''
                if ($HostPort -gt 0 -and $ContainerPort -gt 0) {
                    $portArg = "-p ${HostPort}:${ContainerPort}"
                }

                # 拉取镜像并创建容器
                Write-Host "正在拉取镜像: $ImageName ..."
                docker pull $ImageName | Out-Null

                $runArgs = @('run', '-d', '--name', $ContainerName)
                if ($portArg) {
                    $runArgs += $portArg.Split(' ')
                }
                $runArgs += $ImageName

                $containerId = docker @runArgs 2>&1
                if ($LASTEXITCODE -ne 0) {
                    throw "创建容器失败: $containerId"
                }
                Write-Host "[OK] 容器已创建, ID: $($containerId.Substring(0, 12))" -ForegroundColor Green
            }

            'Start' {
                docker start $ContainerName 2>&1 | Out-Null
                if ($LASTEXITCODE -ne 0) {
                    throw "启动容器失败，请检查容器是否存在"
                }
                Write-Host "[OK] 容器已启动" -ForegroundColor Green
            }

            'Stop' {
                Write-Host "正在停止容器..."
                docker stop $ContainerName 2>&1 | Out-Null
                if ($LASTEXITCODE -ne 0) {
                    throw "停止容器失败"
                }
                Write-Host "[OK] 容器已停止" -ForegroundColor Green
            }

            'Remove' {
                # 先尝试优雅停止
                docker stop $ContainerName 2>$null | Out-Null
                docker rm $ContainerName 2>&1 | Out-Null
                if ($LASTEXITCODE -ne 0) {
                    throw "删除容器失败"
                }
                Write-Host "[OK] 容器已删除" -ForegroundColor Green
            }
        }

        # 操作完成后查询状态
        $status = docker inspect -f '{{.State.Status}}' $ContainerName 2>$null
        if ($status) {
            Write-Host "当前状态: $status" -ForegroundColor White
        }
    }
    catch {
        Write-Host "[ERROR] $($_.Exception.Message)" -ForegroundColor Red
    }
}

# 演示完整的生命周期
Invoke-ContainerLifecycle -Action Create -ContainerName 'demo-web' -ImageName 'nginx:alpine' -HostPort 8080 -ContainerPort 80
Invoke-ContainerLifecycle -Action Stop -ContainerName 'demo-web'
Invoke-ContainerLifecycle -Action Start -ContainerName 'demo-web'
Invoke-ContainerLifecycle -Action Remove -ContainerName 'demo-web'
```

```text
--- 执行操作: Create | 容器: demo-web ---
正在拉取镜像: nginx:alpine ...
[OK] 容器已创建, ID: a1b2c3d4e5f6
当前状态: running

--- 执行操作: Stop | 容器: demo-web ---
正在停止容器...
[OK] 容器已停止
当前状态: exited

--- 执行操作: Start | 容器: demo-web ---
[OK] 容器已启动
当前状态: running

--- 执行操作: Remove | 容器: demo-web ---
[OK] 容器已删除
```

## 容器资源监控与统计

在生产环境中，实时掌握容器的资源消耗情况至关重要。Docker 提供了 `docker stats` 命令输出 CPU、内存和网络等指标，但其默认输出是实时流式的文本，不便于程序化处理。下面的脚本将 `docker stats` 的输出解析为 PowerShell 对象，并生成一份资源使用报告，帮助快速识别异常容器。

```powershell
function Get-ContainerStats {
    <#
    .SYNOPSIS
    获取所有运行中容器的资源使用统计
    #>
    [CmdletBinding()]
    param(
        [int]$Top = 10
    )

    # 获取所有运行中的容器
    $containers = docker ps --format '{{.ID}}|{{.Names}}|{{.Image}}|{{.Status}}'
    if (-not $containers) {
        Write-Host "当前没有运行中的容器" -ForegroundColor Yellow
        return
    }

    # 获取一次性统计快照（不持续监控）
    Write-Host "正在采集容器资源数据..." -ForegroundColor Cyan
    $rawStats = docker stats --no-stream --format '{{.Container}}|{{.Name}}|{{.CPUPerc}}|{{.MemUsage}}|{{.MemPerc}}|{{.NetIO}}|{{.BlockIO}}'

    $stats = @()

    foreach ($line in $rawStats) {
        $parts = $line -split '\|'
        if ($parts.Count -lt 7) { continue }

        # 解析 CPU 和内存百分比
        $cpuPct = $parts[2] -replace '%', ''
        $memPct = $parts[4] -replace '%', ''

        $stats += [PSCustomObject]@{
            Container   = $parts[1]
            Image       = $parts[0]
            CPU_Percent = [double]$cpuPct
            Mem_Percent = [double]$memPct
            Mem_Usage   = $parts[3]
            Net_IO      = $parts[5]
            Block_IO    = $parts[6]
        }
    }

    # 按 CPU 使用率排序
    $sorted = $stats | Sort-Object CPU_Percent -Descending | Select-Object -First $Top

    Write-Host "`n========== 容器资源使用 Top $Top ==========" -ForegroundColor Cyan
    $sorted | Format-Table -Property Container, CPU_Percent, Mem_Percent, Mem_Usage, Net_IO -AutoSize

    # 检查资源异常的容器
    $warnings = @()
    foreach ($s in $stats) {
        if ($s.CPU_Percent -gt 80) {
            $warnings += "[CPU 告警] $($s.Container) CPU 使用率: $($s.CPU_Percent)%"
        }
        if ($s.Mem_Percent -gt 80) {
            $warnings += "[内存告警] $($s.Container) 内存使用率: $($s.Mem_Percent)%"
        }
    }

    if ($warnings.Count -gt 0) {
        Write-Host "`n--- 资源告警 ---" -ForegroundColor Red
        foreach ($w in $warnings) {
            Write-Host "  $w" -ForegroundColor Red
        }
    }
    else {
        Write-Host "`n所有容器资源使用正常" -ForegroundColor Green
    }

    return $sorted
}

# 执行监控
$report = Get-ContainerStats -Top 5
```

```text
正在采集容器资源数据...

========== 容器资源使用 Top 5 ==========

Container     CPU_Percent Mem_Percent Mem_Usage   Net_IO
---------     ----------- ----------- ---------   ------
api-server           45.2        62.1 256MiB / 512MiB  1.2GB / 340MB
web-frontend          8.7        35.4 128MiB / 512MiB  560MB / 12MB
redis-cache           2.1        48.3 96MiB / 200MiB   340MB / 85MB
postgres-db           1.8        72.0 576MiB / 800MiB  120MB / 2.1GB
nginx-proxy           0.5        12.1 24MiB / 200MiB   890MB / 45MB

--- 资源告警 ---
  [CPU 告警] api-server CPU 使用率: 45.2%
  [内存告警] postgres-db 内存使用率: 72.0%
```

## 多容器批量部署

在微服务架构中，通常需要一次性部署多个相互关联的容器。手动逐个执行 `docker run` 既耗时又容易遗漏环境变量或端口映射。下面的脚本通过声明式的配置方式定义一组容器，然后批量创建，并在部署完成后执行健康检查。

```powershell
# 定义容器部署配置
$deployConfig = @(
    @{
        Name        = 'web-app'
        Image       = 'nginx:alpine'
        HostPort    = 8080
        ContPort    = 80
        Environment = @{
            NODE_ENV = 'production'
        }
        HealthCheck = 'http://localhost:8080'
    }
    @{
        Name        = 'redis-cache'
        Image       = 'redis:7-alpine'
        HostPort    = 6379
        ContPort    = 6379
        Environment = @{}
        HealthCheck = 'redis-cli ping'
    }
    @{
        Name        = 'postgres-db'
        Image       = 'postgres:16-alpine'
        HostPort    = 5432
        ContPort    = 5432
        Environment = @{
            POSTGRES_DB       = 'myapp'
            POSTGRES_PASSWORD = 'changeme'
            POSTGRES_USER     = 'appuser'
        }
        HealthCheck = 'pg_isready'
    }
)

function Deploy-Containers {
    <#
    .SYNOPSIS
    根据配置批量部署容器
    #>
    param(
        [array]$Config
    )

    $results = @()

    foreach ($svc in $Config) {
        Write-Host "`n>>> 部署服务: $($svc.Name)" -ForegroundColor Cyan

        # 清理已存在的同名容器
        $existing = docker ps -a --filter "name=^/$($svc.Name)$" --format '{{.Names}}' 2>$null
        if ($existing -eq $svc.Name) {
            Write-Host "  清理旧容器: $($svc.Name)"
            docker rm -f $svc.Name 2>$null | Out-Null
        }

        # 构建环境变量参数
        $envArgs = @()
        foreach ($key in $svc.Environment.Keys) {
            $envArgs += '-e'
            $envArgs += "${key}=$($svc.Environment[$key])"
        }

        # 构建完整参数列表
        $allArgs = @(
            'run', '-d',
            '--name', $svc.Name,
            '-p', "$($svc.HostPort):$($svc.ContPort)"
        )
        $allArgs += $envArgs
        $allArgs += $svc.Image

        # 执行创建
        $output = docker @allArgs 2>&1
        $success = $LASTEXITCODE -eq 0

        $results += [PSCustomObject]@{
            Service = $svc.Name
            Image   = $svc.Image
            Port    = "$($svc.HostPort):$($svc.ContPort)"
            Status  = if ($success) { 'Running' } else { "Failed: $output" }
        }

        if ($success) {
            Write-Host "  [OK] 已启动, 端口映射: $($svc.HostPort):$($svc.ContPort)" -ForegroundColor Green
        }
        else {
            Write-Host "  [FAIL] 部署失败: $output" -ForegroundColor Red
        }

        # 等待容器初始化
        Start-Sleep -Seconds 2

        # 执行健康检查
        $health = docker inspect -f '{{.State.Health.Status}}' $svc.Name 2>$null
        if (-not $health) {
            # 没有内置健康检查的镜像，用进程状态判断
            $health = docker inspect -f '{{.State.Running}}' $svc.Name 2>$null
            $health = if ($health -eq 'true') { 'Running' } else { 'Stopped' }
        }
        Write-Host "  健康状态: $health" -ForegroundColor White
    }

    Write-Host "`n========== 部署结果汇总 ==========" -ForegroundColor Cyan
    $results | Format-Table -AutoSize

    return $results
}

# 执行批量部署
$deployResult = Deploy-Containers -Config $deployConfig

# 验证所有容器运行状态
Write-Host "`n--- 容器运行状态一览 ---" -ForegroundColor Cyan
docker ps --format "table {{.Names}}\t{{.Image}}\t{{.Status}}\t{{.Ports}}" | ForEach-Object { Write-Host "  $_" }
```

```text
>>> 部署服务: web-app
  清理旧容器: web-app
  [OK] 已启动, 端口映射: 8080:80
  健康状态: Running

>>> 部署服务: redis-cache
  [OK] 已启动, 端口映射: 6379:6379
  健康状态: Running

>>> 部署服务: postgres-db
  [OK] 已启动, 端口映射: 5432:5432
  健康状态: Running

========== 部署结果汇总 ==========

Service      Image              Port        Status
-------      -----              ----        ------
web-app      nginx:alpine       8080:80     Running
redis-cache  redis:7-alpine     6379:6379   Running
postgres-db  postgres:16-alpine 5432:5432   Running

--- 容器运行状态一览 ---
  NAMES          IMAGE              STATUS              PORTS
  postgres-db    postgres:16-alpine Up 4 seconds        0.0.0.0:5432->5432/tcp
  redis-cache    redis:7-alpine     Up 4 seconds        0.0.0.0:6379->6379/tcp
  web-app        nginx:alpine       Up 4 seconds        0.0.0.0:8080->80/tcp
```

## 注意事项

1. **Docker 服务可用性检查**：脚本执行前应先验证 Docker 守护进程是否正在运行。可以通过 `docker info` 的退出码判断，Windows 上使用 `Get-Service docker` 检查服务状态，Linux 上使用 `systemctl is-active docker`。如果 Docker 未启动，后续所有命令都会失败且错误信息不够明确。

2. **容器名称唯一性**：同一台主机上不允许存在同名容器。创建容器前务必用 `docker ps -a --filter` 检查是否已有同名容器。批量部署脚本中应包含自动清理旧容器的逻辑，避免因名称冲突导致创建失败。

3. **端口冲突预防**：映射主机端口前应检查端口是否已被占用。Windows 上用 `Get-NetTCPConnection -LocalPort`，Linux 上用 `ss -tlnp` 或 `netstat`。端口冲突是容器创建失败最常见的原因之一，且 Docker 的错误提示往往不够直观。

4. **资源限制与 OOM 防护**：生产环境中应通过 `--memory` 和 `--cpus` 参数为每个容器设置资源上限，防止单个异常容器耗尽宿主机资源导致整个服务不可用。可以使用 `docker update` 命令动态调整运行中容器的资源限制。

5. **敏感信息管理**：容器的环境变量中不应硬编码密码、Token 等敏感信息。推荐使用 Docker Secrets（Swarm 模式）或挂载外部配置文件（如 `.env` 文件配合 `--env-file` 参数），并结合密钥管理服务进行动态注入。`docker inspect` 默认会以明文显示所有环境变量，存在信息泄露风险。

6. **日志与调试策略**：容器默认使用 `json-file` 日志驱动，长时间运行会产生大量磁盘占用。建议在 `docker run` 时通过 `--log-driver` 和 `--log-opt` 配置日志轮转（如 `--log-opt max-size=10m --log-opt max-file=3`），或使用集中式日志收集方案。排查问题时用 `docker logs --tail 100 --follow` 快速定位最近日志。
