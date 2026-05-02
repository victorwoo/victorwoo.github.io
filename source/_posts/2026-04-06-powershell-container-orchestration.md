---
layout: post
date: 2026-04-06 08:00:00
updated: 2026-04-06 08:00:00
title: "PowerShell 技能连载 - 容器编排自动化"
description: PowerTip of the Day - Container Orchestration Automation in PowerShell
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
- orchestration
---

_适用于 PowerShell 7.0 及以上版本，需要 Docker Desktop 或 Podman_

在现代 DevOps 工作流中，容器已经成为应用部署的标准载体。无论是微服务架构、CI/CD 流水线，还是本地开发环境，容器的使用无处不在。然而，当容器数量从几个增长到几十个甚至上百个时，手动管理就变得既低效又容易出错。如何用脚本化的方式编排和管理这些容器，就成了每个运维工程师必须面对的课题。

PowerShell 凭借其强大的对象管道、丰富的模块生态以及与 .NET 的深度集成，为容器编排提供了一种独特的自动化思路。与 Bash 脚本相比，PowerShell 能够直接操作结构化数据（如 JSON、YAML），将 Docker CLI 的文本输出转化为可查询的对象，从而实现更精细、更可靠的容器生命周期管理。

本文将围绕三个典型场景展开：使用 PowerShell 动态生成 Docker Compose 配置并管理多服务生命周期；构建容器健康检查与自动恢复机制；以及实现多环境批量容器部署工具，支持蓝绿部署和快速回滚。

<!-- more -->

## Docker Compose 管理

在日常开发中，我们经常需要根据不同的环境（开发、测试、生产）生成不同的 Compose 配置。手动维护多份 YAML 文件不仅繁琐，还容易导致配置漂移。下面的脚本展示了如何用 PowerShell 动态生成 Docker Compose 文件，并统一管理服务的启动、停止和状态查询。

```powershell
function New-DockerComposeConfig {
    param(
        [Parameter(Mandatory)]
        [ValidateSet('dev', 'staging', 'prod')]
        [string]$Environment,

        [int]$ReplicaCount = 1,
        [int]$MemoryLimitMb = 512
    )

    $envConfig = @{
        dev     = @{ HostPort = 8080; Tag = 'latest';  LogLevel = 'Debug' }
        staging = @{ HostPort = 8081; Tag = 'rc';      LogLevel = 'Information' }
        prod    = @{ HostPort = 80;   Tag = 'stable';  LogLevel = 'Warning' }
    }

    $cfg = $envConfig[$Environment]

    $compose = @{
        version = '3.8'
        services = @{
            webapp = @{
                image            = "myapp/webapp:$($cfg.Tag)"
                ports            = @("$($cfg.HostPort):80")
                environment      = @(
                    "ASPNETCORE_ENVIRONMENT=$Environment"
                    "LOG_LEVEL=$($cfg.LogLevel)"
                )
                deploy           = @{
                    replicas    = $ReplicaCount
                    resources   = @{
                        limits   = @{ memory = "${MemoryLimitMb}M" }
                        reservations = @{ memory = "$([Math]::Floor($MemoryLimitMb / 2))M" }
                    }
                    restart_policy = @{
                        condition   = 'on-failure'
                        max_attempts = 3
                    }
                }
                healthcheck      = @{
                    test     = @('CMD', 'curl', '-f', 'http://localhost/health')
                    interval = '30s'
                    timeout  = '10s'
                    retries  = 3
                }
                volumes          = @('./data:/app/data')
                networks         = @('app-network')
            }
            redis = @{
                image       = 'redis:7-alpine'
                ports       = @('6379:6379')
                volumes     = @('redis-data:/data')
                networks    = @('app-network')
                healthcheck = @{
                    test     = @('CMD', 'redis-cli', 'ping')
                    interval = '15s'
                    timeout  = '5s'
                    retries  = 3
                }
            }
        }
        networks = @{
            'app-network' = @{ driver = 'bridge' }
        }
        volumes  = @{
            'redis-data' = @{}
        }
    }

    $compose | ConvertTo-Yaml | Set-Content "docker-compose.$Environment.yml"
    Write-Host "已生成 docker-compose.$Environment.yml" -ForegroundColor Green
    return "docker-compose.$Environment.yml"
}

function Invoke-DockerComposeLifecycle {
    param(
        [Parameter(Mandatory)]
        [string]$ComposeFile,
        [ValidateSet('up', 'down', 'status')]
        [string]$Action = 'up'
    )

    switch ($Action) {
        'up' {
            Write-Host "启动服务: $ComposeFile" -ForegroundColor Cyan
            docker compose -f $ComposeFile up -d --remove-orphans
            Write-Host "服务已启动，等待健康检查..." -ForegroundColor Green
            Start-Sleep -Seconds 5
            docker compose -f $ComposeFile ps
        }
        'down' {
            Write-Host "停止服务: $ComposeFile" -ForegroundColor Yellow
            docker compose -f $ComposeFile down --volumes --remove-orphans
            Write-Host "服务已停止并清理" -ForegroundColor Green
        }
        'status' {
            docker compose -f $ComposeFile ps
            Write-Host "`n--- 资源使用 ---" -ForegroundColor Cyan
            docker stats --no-stream --format 'table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}'
        }
    }
}

# 使用示例：生成开发环境配置并启动
$composeFile = New-DockerComposeConfig -Environment dev -ReplicaCount 2 -MemoryLimitMb 256
Invoke-DockerComposeLifecycle -ComposeFile $composeFile -Action up
```

执行结果示例：

```text
已生成 docker-compose.dev.yml
启动服务: docker-compose.dev.yml
[+] Running 3/3
 ✔ Network dev_app-network  Created
 ✔ Container dev-redis-1    Started
 ✔ Container dev-webapp-1   Started
 ✔ Container dev-webapp-2   Started
服务已启动，等待健康检查...
NAME             IMAGE                  STATUS          PORTS
dev-webapp-1     myapp/webapp:latest    Up 5 seconds    0.0.0.0:8080->80/tcp
dev-webapp-2     myapp/webapp:latest    Up 5 seconds    0.0.0.0:8080->80/tcp
dev-redis-1      redis:7-alpine         Up 5 seconds    0.0.0.0:6379->6379/tcp
```

## 容器健康检查与自动恢复

在生产环境中，容器可能会因为内存溢出、依赖服务不可用或网络抖动等原因意外退出。如果缺乏自动化的监控和恢复机制，服务中断往往会持续到人工介入才得以解决。下面的脚本实现了一套轻量级的容器健康巡检系统，能够自动检测异常容器、触发重启，并在资源使用接近阈值时发出告警。

```powershell
function Get-ContainerHealthReport {
    param(
        [string]$Filter = '',
        [int]$CpuThreshold = 80,
        [int]$MemoryThresholdPercent = 85
    )

    $containers = docker ps -a --format '{{.ID}}|{{.Names}}|{{.Status}}|{{.Image}}' |
        ForEach-Object {
            $parts = $_ -split '\|'
            [PSCustomObject]@{
                Id     = $parts[0]
                Name   = $parts[1]
                Status = $parts[2]
                Image  = $parts[3]
            }
        }

    if ($Filter) {
        $containers = $containers | Where-Object { $_.Name -match $Filter }
    }

    foreach ($c in $containers) {
        $inspect = docker inspect $c.Id | ConvertFrom-Json
        $state   = $inspect.State
        $health  = $state.Health

        $report = [PSCustomObject]@{
            Name       = $c.Name
            Image      = $c.Image
            Running    = $state.Running
            Health     = if ($health) { $health.Status } else { 'N/A' }
            Restarting = $state.Restarting
            ExitCode   = $state.ExitCode
            StartedAt  = $state.StartedAt
        }

        # 获取资源使用情况
        $stats = docker stats --no-stream --format '{{.CPUPerc}}|{{.MemUsage}}|{{.MemPerc}}' $c.Id
        if ($stats) {
            $statParts = $stats -split '\|'
            $report | Add-Member -NotePropertyName 'CpuPct' `
                -NotePropertyValue ($statParts[0] -replace '%', '').Trim()
            $report | Add-Member -NotePropertyName 'MemPct' `
                -NotePropertyValue ($statParts[2] -replace '%', '').Trim()
        }

        $report
    }
}

function Repair-UnhealthyContainers {
    param(
        [int]$MaxRestartAttempts = 3,
        [int]$CooldownSeconds = 30,
        [switch]$DryRun
    )

    $report = Get-ContainerHealthReport
    $unhealthy = $report | Where-Object {
        -not $_.Running -or $_.Health -eq 'unhealthy'
    }

    if (-not $unhealthy) {
        Write-Host "所有容器状态正常" -ForegroundColor Green
        return
    }

    foreach ($c in $unhealthy) {
        $action = if (-not $c.Running) { '启动' } else { '重启' }

        if ($DryRun) {
            Write-Host "[模拟] 将$action 容器: $($c.Name) (状态: $($c.Status))" `
                -ForegroundColor Yellow
            continue
        }

        Write-Host "$action 容器: $($c.Name)..." -ForegroundColor Cyan
        docker restart $c.Name

        Start-Sleep -Seconds $CooldownSeconds

        $newState = docker inspect $c.Name --format '{{.State.Running}}'
        if ($newState -eq 'true') {
            Write-Host "  容器 $($c.Name) 已恢复运行" -ForegroundColor Green
        } else {
            Write-Host "  容器 $($c.Name) 恢复失败，需要人工介入" -ForegroundColor Red
        }
    }
}

# 使用示例：巡检并自动恢复
Get-ContainerHealthReport | Format-Table -AutoSize
Repair-UnhealthyContainers -DryRun
```

执行结果示例：

```text
Name          Image              Running Health     Restarting ExitCode CpuPct MemPct
----          -----              ------- ------     ---------- -------- ------ ------
dev-webapp-1  myapp/webapp:latest True    healthy   False      0        2.3%   15.2%
dev-webapp-2  myapp/webapp:latest True    healthy   False      0        1.8%   14.7%
dev-redis-1   redis:7-alpine      True    healthy   False      0        0.5%   8.1%
test-api-1    myapp/api:rc        False   unhealthy False      137      N/A    N/A

[模拟] 将重启 容器: test-api-1 (状态: Exited (137) 2 minutes ago)
```

## 批量容器部署工具

蓝绿部署是一种经典的零停机发布策略，它通过维护两套完全相同的生产环境（蓝和绿），在发布新版本时将流量从旧环境切换到新环境，从而实现无缝升级。结合 PowerShell 的参数化能力，我们可以构建一个支持多环境配置、蓝绿部署和一键回滚的批量部署工具。

```powershell
class ContainerDeployment {
    [string]$ProjectName
    [string]$Environment
    [hashtable]$Services = @{}

    ContainerDeployment([string]$ProjectName, [string]$Environment) {
        $this.ProjectName = $ProjectName
        $this.Environment = $Environment
    }

    [void] AddService([string]$Name, [string]$Image, [string[]]$Ports) {
        $this.Services[$Name] = @{
            Image = $Image
            Ports = $Ports
            CreatedAt = (Get-Date).ToString('o')
        }
    }

    [string] Deploy([string]$Slot) {
        $slotPrefix = "$($this.ProjectName)-$Slot"
        Write-Host "部署到 $Slot 槽位: $slotPrefix" -ForegroundColor Cyan

        foreach ($svc in $this.Services.GetEnumerator()) {
            $containerName = "$slotPrefix-$($svc.Key)"
            $portMap = ($svc.Value.Ports | ForEach-Object { '-p'; $_ }) -join ' '

            # 拉取最新镜像
            Write-Host "  拉取镜像: $($svc.Value.Image)" -ForegroundColor Gray
            docker pull $svc.Value.Image | Out-Null

            # 停止并移除旧容器
            $existing = docker ps -aq -f "name=$containerName"
            if ($existing) {
                docker stop $existing | Out-Null
                docker rm $existing | Out-Null
            }

            # 启动新容器
            $runCmd = "docker run -d --name $containerName $portMap $($svc.Value.Image)"
            $containerId = Invoke-Expression $runCmd
            Write-Host "  已启动: $containerName ($($containerId.Substring(0,12)))" `
                -ForegroundColor Green
        }

        return $slotPrefix
    }

    [void] SwitchTraffic([string]$NewSlot) {
        $oldSlot = if ($NewSlot -eq 'blue') { 'green' } else { 'blue' }
        $oldPrefix = "$($this.ProjectName)-$oldSlot"
        $newPrefix = "$($this.ProjectName)-$NewSlot"

        Write-Host "`n切换流量: $oldSlot -> $NewSlot" -ForegroundColor Yellow

        # 验证新槽位容器健康
        $newContainers = docker ps -f "name=$newPrefix" --format '{{.Names}}'
        foreach ($name in $newContainers) {
            $health = docker inspect $name --format '{{.State.Health.Status}}'
            if ($health -ne 'healthy') {
                Write-Host "  容器 $name 状态为 $health，中止切换" -ForegroundColor Red
                return
            }
        }

        # 停止旧槽位容器（保持数据卷）
        $oldContainers = docker ps -f "name=$oldPrefix" --format '{{.Names}}'
        foreach ($name in $oldContainers) {
            Write-Host "  停止旧容器: $name" -ForegroundColor Gray
            docker stop $name | Out-Null
        }

        Write-Host "流量已切换到 $NewSlot 槽位" -ForegroundColor Green
    }

    [void] Rollback() {
        $activeSlot = $this.GetActiveSlot()
        $targetSlot = if ($activeSlot -eq 'blue') { 'green' } else { 'blue' }

        Write-Host "回滚到 $targetSlot 槽位..." -ForegroundColor Yellow

        # 启动目标槽位的容器
        $stopped = docker ps -aq -f "status=exited" -f "name=$($this.ProjectName)-$targetSlot"
        foreach ($id in $stopped) {
            docker start $id | Out-Null
            $name = docker inspect $id --format '{{.Name}}' | ForEach-Object { $_ -replace '^/', '' }
            Write-Host "  已恢复: $name" -ForegroundColor Green
        }

        # 停止当前槽位
        $active = docker ps -f "name=$($this.ProjectName)-$activeSlot" --format '{{.Names}}'
        foreach ($name in $active) {
            docker stop $name | Out-Null
        }

        Write-Host "回滚完成，活跃槽位: $targetSlot" -ForegroundColor Green
    }

    hidden [string] GetActiveSlot() {
        $blue = docker ps -q -f "name=$($this.ProjectName)-blue" 2>$null
        $green = docker ps -q -f "name=$($this.ProjectName)-green" 2>$null
        if ($blue) { return 'blue' }
        if ($green) { return 'green' }
        return 'none'
    }
}

# 使用示例
$deploy = [ContainerDeployment]::new('myapp', 'prod')
$deploy.AddService('web', 'myapp/web:stable', @('80:80'))
$deploy.AddService('api', 'myapp/api:stable', @('8080:8080'))
$deploy.AddService('worker', 'myapp/worker:stable', @())

$deploy.Deploy('blue')
$deploy.SwitchTraffic('blue')
```

执行结果示例：

```text
部署到 blue 槽位: myapp-blue
  拉取镜像: myapp/web:stable
  已启动: myapp-blue-web (a1b2c3d4e5f6)
  拉取镜像: myapp/api:stable
  已启动: myapp-blue-api (f6e5d4c3b2a1)
  拉取镜像: myapp/worker:stable
  已启动: myapp-blue-worker (1a2b3c4d5e6f)

切换流量: green -> blue
  停止旧容器: myapp-green-web
  停止旧容器: myapp-green-api
  停止旧容器: myapp-green-worker
流量已切换到 blue 槽位
```

## 注意事项

- **Docker 权限**：在 Linux 上运行时，确保当前用户已加入 `docker` 用户组，否则需要在命令前加 `sudo`。生产环境建议使用 Rootless Docker 以降低安全风险。

- **ConvertTo-Yaml 模块**：生成 Compose 文件依赖 `powershell-yaml` 模块，可通过 `Install-Module -Name powershell-yaml -Scope CurrentUser` 安装。如果无法安装，也可以用 `ConvertTo-Json` 生成 JSON 格式的配置。

- **健康检查延迟**：容器启动后需要一定时间才能通过健康检查，`Start-Sleep` 的等待时间应根据应用的启动速度调整，避免误判。建议在脚本中加入轮询逻辑，而不是简单的固定等待。

- **蓝绿部署数据一致性**：蓝绿切换时数据库迁移是一个常见陷阱。如果新版本包含破坏性的数据库变更，需要确保迁移脚本兼容新旧版本，否则回滚将变得不可行。建议将数据库迁移与容器部署解耦。

- **资源限制**：Docker Desktop 在 macOS 和 Windows 上的资源配额受虚拟机限制，脚本中设置的 `memory` 限制不能超过 Docker Desktop 分配的总内存。可通过 Docker Desktop 设置面板调整。

- **日志与监控**：脚本中的 `docker stats` 只能获取实时快照数据。如需长期监控和历史数据查询，建议集成 Prometheus + Grafana 或 Docker 原生的 `docker logs --since` 进行日志聚合分析。
