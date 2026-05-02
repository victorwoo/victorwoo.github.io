---
layout: post
date: 2025-07-22 08:00:00
updated: 2025-07-22 08:00:00
title: "PowerShell 技能连载 - 进程管理进阶"
description: PowerTip of the Day - Advanced Process Management in PowerShell
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
- system-management
- monitoring
- performance
---

_适用于 PowerShell 5.1 及以上版本（Windows）_

进程管理是系统运维的基本功——排查 CPU 飙高、清理僵尸进程、监控关键服务、控制进程资源占用。虽然任务管理器能做基本的进程管理，但 PowerShell 可以实现更精细的控制：批量操作、历史趋势分析、自动告警、进程树追踪。掌握进程管理的高级技巧，是高效排查系统问题的关键。

本文将讲解进程的查询、监控、控制，以及自动化的进程管理方案。

<!-- more -->

## 进程查询与筛选

```powershell
# 按条件筛选进程
Write-Host "=== CPU 占用 Top 10 ===" -ForegroundColor Cyan
Get-Process | Sort-Object CPU -Descending | Select-Object -First 10 |
    Select-Object Name, Id,
        @{N='CPU(s)'; E={[math]::Round($_.CPU, 2)}},
        @{N='内存MB'; E={[math]::Round($_.WorkingSet64 / 1MB, 1)}} |
    Format-Table -AutoSize

Write-Host "`n=== 内存占用 Top 10 ===" -ForegroundColor Cyan
Get-Process | Sort-Object WorkingSet64 -Descending | Select-Object -First 10 |
    Select-Object Name, Id,
        @{N='内存MB'; E={[math]::Round($_.WorkingSet64 / 1MB, 1)}},
        @{N='CPU(s)'; E={[math]::Round($_.CPU, 2)}} |
    Format-Table -AutoSize

# 查找特定进程的所有实例
$nodeProcesses = Get-Process -Name "node" -ErrorAction SilentlyContinue
if ($nodeProcesses) {
    Write-Host "`nNode.js 进程（$($nodeProcesses.Count) 个）：" -ForegroundColor Cyan
    $nodeProcesses | Format-Table Id, CPU,
        @{N='内存MB'; E={[math]::Round($_.WorkingSet64 / 1MB, 1)}},
        StartTime -AutoSize
}

# 按用户筛选进程
function Get-ProcessByUser {
    param([string]$UserName)

    Get-CimInstance Win32_Process |
        ForEach-Object {
            $owner = Invoke-CimMethod -InputObject $_ -MethodName GetOwner -ErrorAction SilentlyContinue
            if ($owner.User -eq $UserName) {
                [PSCustomObject]@{
                    PID      = $_.ProcessId
                    Name     = $_.Name
                    User     = $owner.User
                    MemoryMB = [math]::Round($_.WorkingSetSize / 1MB, 1)
                    CmdLine  = if ($_.CommandLine.Length -gt 80) { $_.CommandLine.Substring(0, 80) + "..." } else { $_.CommandLine }
                }
            }
        } | Sort-Object MemoryMB -Descending
}

Get-ProcessByUser -UserName "admin" | Format-Table -AutoSize
```

执行结果示例：

```
=== CPU 占用 Top 10 ===
Name           Id CPU(s) 内存MB
----           -- ------ ------
chrome       12345 1250.3  512.5
node         12346  456.7  256.3
msedge       12347  345.2  198.7
vscode       12348  234.5  345.2
powershell   12349  123.4   85.6

=== 内存占用 Top 10 ===
Name           Id 内存MB CPU(s)
----           -- ------ ------
chrome       12345  512.5 1250.3
vscode       12348  345.2  234.5
node         12346  256.3  456.7

Node.js 进程（3 个）：
 Id   CPU 内存MB StartTime
 --   --- ------ ---------
12346 456.7  256.3 2025-07-22 06:00:00
12350  12.3   64.1 2025-07-22 07:30:00
12351   5.6   32.5 2025-07-22 08:15:00
```

## 进程监控与告警

```powershell
# 监控关键进程资源使用
function Watch-CriticalProcesses {
    param(
        [string[]]$ProcessNames = @("sqlservr", "w3wp", "MyApp"),
        [double]$MemoryThresholdMB = 1024,
        [double]$CPUThreshold = 80,
        [int]$IntervalSeconds = 60
    )

    while ($true) {
        $timestamp = Get-Date -Format "HH:mm:ss"
        Write-Host "`n[$timestamp] 进程监控" -ForegroundColor Cyan

        foreach ($name in $ProcessNames) {
            $procs = Get-Process -Name $name -ErrorAction SilentlyContinue

            if (-not $procs) {
                Write-Host "  $name : 未运行" -ForegroundColor Red
                continue
            }

            foreach ($proc in $procs) {
                $memMB = [math]::Round($proc.WorkingSet64 / 1MB, 1)
                $cpuS = [math]::Round($proc.CPU, 2)

                $memAlert = $memMB -gt $MemoryThresholdMB
                $status = if ($memAlert) { "ALERT" } else { "OK" }
                $color = if ($memAlert) { "Red" } else { "Green" }

                Write-Host "  $name (PID:$($proc.Id)) : 内存 ${memMB}MB CPU ${cpuS}s [$status]" -ForegroundColor $color
            }
        }

        Start-Sleep -Seconds $IntervalSeconds
    }
}

# 启动监控（Ctrl+C 停止）
# Watch-CriticalProcesses -MemoryThresholdMB 512

# 一次性检查并告警
function Test-ProcessHealth {
    $alerts = @()

    # 检查关键服务进程
    $critical = @(
        @{ Name = "Winmgmt"; DisplayName = "WMI 服务" },
        @{ Name = "svchost"; DisplayName = "系统服务" },
        @{ Name = "lsass"; DisplayName = "安全认证" }
    )

    foreach ($svc in $critical) {
        $proc = Get-Process -Name $svc.Name -ErrorAction SilentlyContinue
        if (-not $proc) {
            $alerts += "[$($svc.DisplayName)] 进程未找到"
        }
    }

    # 检查内存压力
    $os = Get-CimInstance Win32_OperatingSystem
    $memPct = [math]::Round(($os.TotalVisibleMemorySize - $os.FreePhysicalMemory) / $os.TotalVisibleMemorySize * 100, 1)
    if ($memPct -gt 85) {
        $alerts += "系统内存使用率 ${memPct}%，超过 85% 阈值"
    }

    # 检查僵尸进程
    $zombies = Get-Process | Where-Object { $_.Responding -eq $false }
    if ($zombies) {
        $alerts += "$($zombies.Count) 个无响应进程：$($zombies.Name -join ', ')"
    }

    if ($alerts) {
        Write-Host "健康检查发现 $($alerts.Count) 个问题：" -ForegroundColor Red
        $alerts | ForEach-Object { Write-Host "  ! $_" -ForegroundColor Red }
    } else {
        Write-Host "所有进程健康" -ForegroundColor Green
    }
}

Test-ProcessHealth
```

执行结果示例：

```
[08:30:15] 进程监控
  sqlservr (PID:2048) : 内存 1024.5MB CPU 345.2s [OK]
  w3wp (PID:3072) : 内存 512.3MB CPU 123.4s [OK]
  MyApp (PID:4096) : 内存 1536.7MB CPU 567.8s [ALERT]

所有进程健康
```

## 进程树与命令行

```powershell
# 获取进程树（父子关系）
function Get-ProcessTree {
    param([int]$ParentPid = $PID)

    $allProcesses = Get-CimInstance Win32_Process

    function Build-Tree {
        param([int]$Pid, [int]$Indent = 0)

        $proc = $allProcesses | Where-Object { $_.ProcessId -eq $Pid }
        if ($proc) {
            $prefix = "  " * $Indent + "+--"
            $memMB = [math]::Round($proc.WorkingSetSize / 1MB, 1)
            Write-Host "$prefix $($proc.Name) (PID:$Pid, ${memMB}MB)" -ForegroundColor $(if ($Indent -eq 0) { "Cyan" } else { "White" })

            $children = $allProcesses | Where-Object { $_.ParentProcessId -eq $Pid }
            foreach ($child in $children) {
                Build-Tree -Pid $child.ProcessId -Indent ($Indent + 1)
            }
        }
    }

    Build-Tree -Pid $ParentPid
}

Write-Host "当前 PowerShell 进程树：" -ForegroundColor Cyan
Get-ProcessTree -ParentPid $PID

# 获取进程的完整命令行
function Get-ProcessCommandLine {
    param([Parameter(Mandatory)][int[]]$ProcessId)

    foreach ($pid in $ProcessId) {
        $proc = Get-CimInstance Win32_Process -Filter "ProcessId = $pid"
        if ($proc) {
            [PSCustomObject]@{
                PID     = $proc.ProcessId
                Name    = $proc.Name
                CmdLine = $proc.CommandLine
                ExePath = $proc.ExecutablePath
            }
        }
    }
}

# 查看所有 Web 服务器进程的命令行
$webProcs = Get-Process -Name "w3wp" -ErrorAction SilentlyContinue
if ($webProcs) {
    Get-ProcessCommandLine -ProcessId $webProcs.Id |
        Select-Object PID, Name, CmdLine |
        Format-List
}
```

执行结果示例：

```
当前 PowerShell 进程树：
+-- pwsh (PID:5120, 85.6MB)
  +-- node (PID:5234, 32.1MB)
  +-- node (PID:5456, 16.5MB)

PID     : 3072
Name    : w3wp.exe
CmdLine : c:\windows\system32\inetsrv\w3wp.exe -ap "MyAppPool" -v "v4.0" ...
ExePath : c:\windows\system32\inetsrv\w3wp.exe
```

## 安全终止进程

```powershell
# 安全的进程终止函数
function Stop-ProcessSafe {
    param(
        [Parameter(Mandatory)]
        [string]$Name,

        [int]$GracePeriodSeconds = 10,

        [switch]$Force
    )

    $processes = Get-Process -Name $Name -ErrorAction SilentlyContinue
    if (-not $processes) {
        Write-Host "未找到进程：$Name" -ForegroundColor Yellow
        return
    }

    foreach ($proc in $processes) {
        Write-Host "正在停止 $($proc.Name) (PID:$($proc.Id))..." -ForegroundColor Cyan

        if ($Force) {
            $proc.Kill()
            Write-Host "  已强制终止" -ForegroundColor Red
            continue
        }

        # 尝试优雅关闭
        try {
            $proc.CloseMainWindow() | Out-Null
            $proc.WaitForExit($GracePeriodSeconds * 1000)

            if (-not $proc.HasExited) {
                Write-Host "  优雅关闭超时，强制终止..." -ForegroundColor Yellow
                $proc.Kill()
            }

            Write-Host "  已停止" -ForegroundColor Green
        } catch {
            Write-Host "  停止失败：$($_.Exception.Message)" -ForegroundColor Red
        }
    }
}

# 按端口查找并终止占用进程
function Stop-ProcessByPort {
    param([Parameter(Mandatory)][int]$Port)

    $connections = Get-NetTCPConnection -LocalPort $Port -ErrorAction SilentlyContinue
    if (-not $connections) {
        Write-Host "端口 $Port 未被占用" -ForegroundColor Green
        return
    }

    $pids = $connections | Select-Object -ExpandProperty OwningProcess -Unique
    foreach ($pid in $pids) {
        $proc = Get-Process -Id $pid -ErrorAction SilentlyContinue
        if ($proc) {
            Write-Host "端口 $Port 被占用：$($proc.Name) (PID:$pid)" -ForegroundColor Yellow
            Stop-Process -Id $pid -Force
            Write-Host "  已终止进程" -ForegroundColor Green
        }
    }
}

Stop-ProcessByPort -Port 8080
```

执行结果示例：

```
正在停止 node (PID:5234)...
  已停止
正在停止 node (PID:5456)...
  已停止
端口 8080 被占用：node (PID:6001)
  已终止进程
```

## 注意事项

1. **CPU 属性含义**：`Process.CPU` 是进程自启动以来消耗的 CPU 时间（秒），不是当前使用率。计算使用率需要两次采样
2. **管理员权限**：终止其他用户的进程或访问某些进程信息需要管理员权限
3. **进程名匹配**：`Get-Process -Name` 不含扩展名（`node` 而非 `node.exe`），且大小写不敏感
4. **僵尸进程**：`Responding` 属性检测进程是否有响应，但只适用于有窗口的进程
5. **WMI 查询**：`Get-CimInstance Win32_Process` 可以获取命令行参数和父进程信息，`Get-Process` 不能
6. **资源释放**：终止进程后，内存和网络端口可能不会立即释放，需要短暂等待
