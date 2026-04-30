---
layout: post
date: 2025-04-01 08:00:00
title: "PowerShell 技能连载 - Docker 容器管理"
description: PowerTip of the Day - Managing Docker Containers with PowerShell
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
- docker
---
容器化部署已成主流，PowerShell 可以很好地编排 Docker 操作，实现镜像构建、容器生命周期管理、日志收集等自动化流程。

## 检查 Docker 环境

```powershell
function Test-DockerEnvironment {
    $result = @()

    # Docker 是否可用
    try {
        $version = docker version --format "{{.Server.Version}}" 2>$null
        $result += [PSCustomObject]@{
            Check  = "Docker Engine"
            Status = if ($version) { "运行中 v$version" } else { "未运行" }
        }
    }
    catch {
        $result += [PSCustomObject]@{ Check = "Docker Engine"; Status = "未安装" }
    }

    # 磁盘使用
    $diskUsage = docker system df --format "{{.Type}}: {{.Size}}" 2>$null
    $result += [PSCustomObject]@{
        Check  = "磁盘占用"
        Status = ($diskUsage -join "; ")
    }

    # 运行中的容器数
    $running = docker ps -q 2>$null
    $result += [PSCustomObject]@{
        Check  = "运行中容器"
        Status = "$(@($running).Count) 个"
    }

    return $result | Format-Table -AutoSize
}
```

## 容器生命周期管理

```powershell
function New-DockerAppContainer {
    param(
        [Parameter(Mandatory)]
        [string]$Name,

        [Parameter(Mandatory)]
        [string]$Image,

        [hashtable]$PortMappings,
        [hashtable]$EnvVars,
        [string[]]$Volumes,
        [string]$Network = "bridge",
        [string]$RestartPolicy = "unless-stopped"
    )

    $args = @("run", "-d", "--name", $Name, "--restart", $RestartPolicy)

    foreach ($port in $PortMappings.GetEnumerator()) {
        $args += @("-p", "$($port.Key):$($port.Value)")
    }

    foreach ($env in $EnvVars.GetEnumerator()) {
        $args += @("-e", "$($env.Key)=$($env.Value)")
    }

    foreach ($vol in $Volumes) {
        $args += @("-v", $vol)
    }

    $args += @("--network", $Network, $Image)

    $containerId = & docker $args 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host "容器 $Name 已启动: $containerId" -ForegroundColor Green
        return $containerId.Substring(0, 12)
    }
    else {
        Write-Host "启动失败: $containerId" -ForegroundColor Red
    }
}

# 示例：启动一个 Web 应用
New-DockerAppContainer -Name "myapp" `
    -Image "nginx:latest" `
    -PortMappings @{ 8080 = 80; 8443 = 443 } `
    -EnvVars @{ NGINX_HOST = "example.com"; NGINX_PORT = "80" } `
    -Volumes @("C:\data\nginx:/usr/share/nginx/html")
```

## 批量容器巡检

```powershell
function Get-DockerContainerReport {
    param(
        [switch]$All
    )

    $format = "{{.ID}}|{{.Names}}|{{.Image}}|{{.Status}}|{{.Ports}}"
    $filter = if ($All) { "docker ps -a" } else { "docker ps" }

    $containers = Invoke-Expression "$filter --format '$format'" 2>$null

    $report = foreach ($line in $containers) {
        $parts = $line -split '\|'
        $id = $parts[0].Substring(0, [Math]::Min(12, $parts[0].Length))

        # 获取容器资源使用
        $stats = docker stats --no-stream --format "{{.CPUPerc}}|{{.MemUsage}}" $id 2>$null
        $statParts = if ($stats) { $stats -split '\|' } else { @("N/A", "N/A") }

        [PSCustomObject]@{
            Container = $parts[1]
            Image     = $parts[2]
            Status    = $parts[3]
            CPU       = $statParts[0]
            Memory    = $statParts[1]
            Ports     = $parts[4]
        }
    }

    return $report | Format-Table -AutoSize
}
```

## 镜像清理

```powershell
function Remove-DockerDanglingImages {
    # 查找悬空镜像（无标签的中间层）
    $dangling = docker images -f "dangling=true" -q 2>$null

    if ($dangling) {
        $size = docker images -f "dangling=true" --format "{{.Size}}" 2>$null
        $totalSize = ($size | ForEach-Object {
            if ($_ -match '(\d+\.?\d*)\s*(GB|MB)') {
                if ($Matches[2] -eq "GB") { [double]$Matches[1] * 1024 } else { [double]$Matches[1] }
            }
        } | Measure-Object -Sum).Sum

        Write-Host "发现 $($dangling.Count) 个悬空镜像，约 $([math]::Round($totalSize, 0)) MB" -ForegroundColor Yellow
        $confirm = Read-Host "是否清理? (y/n)"

        if ($confirm -eq "y") {
            docker image prune -f 2>$null
            Write-Host "清理完成" -ForegroundColor Green
        }
    }
    else {
        Write-Host "没有悬空镜像" -ForegroundColor Green
    }
}
```

## 容器日志收集

```powershell
function Get-DockerContainerLog {
    param(
        [Parameter(Mandatory)]
        [string]$ContainerName,

        [int]$Tail = 100,

        [datetime]$Since,

        [string]$OutputPath
    )

    $args = @("logs", "--tail", $Tail)

    if ($Since) {
        $args += @("--since", $Since.ToString("yyyy-MM-ddTHH:mm:ss"))
    }

    $args += $ContainerName

    $logs = & docker $args 2>&1

    if ($OutputPath) {
        $logs | Out-File -FilePath $OutputPath -Encoding UTF8
        Write-Host "日志已保存到: $OutputPath"
    }
    else {
        return $logs
    }
}

# 批量收集所有容器日志
function Export-AllContainerLogs {
    param([string]$OutputDir = ".\container_logs")

    New-Item -Path $OutputDir -ItemType Directory -Force | Out-Null

    $containers = docker ps --format "{{.Names}}" 2>$null
    foreach ($name in $containers) {
        $logFile = Join-Path $OutputDir "${name}_$(Get-Date -Format 'yyyyMMdd').log"
        Get-DockerContainerLog -ContainerName $name -Tail 1000 -OutputPath $logFile
    }

    Write-Host "所有容器日志已导出到: $OutputDir"
}
```

管理 Docker 时建议用 `--restart unless-stopped` 保证服务自愈，定期清理悬空镜像和停止的容器释放磁盘空间。
