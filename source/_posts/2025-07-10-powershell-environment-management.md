---
layout: post
date: 2025-07-10 08:00:00
updated: 2025-07-10 08:00:00
title: "PowerShell 技能连载 - 环境变量管理"
description: PowerTip of the Day - Environment Variable Management in PowerShell
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
- system-management
- config-management
---

_适用于 PowerShell 5.1 及以上版本_

环境变量是操作系统级别的配置机制，几乎影响所有程序的行为——PATH 决定命令搜索路径、JAVA_HOME 指定 Java 运行时、HTTP_PROXY 配置代理。在运维场景中，合理管理环境变量可以控制程序行为、隔离开发/测试/生产环境配置、管理工具链路径。PowerShell 对环境变量的操作比 CMD 更加强大和直观。

本文将讲解 PowerShell 中环境变量的读取、设置、持久化，以及实用的配置管理技巧。

<!-- more -->

## 环境变量基础

```powershell
# 读取环境变量
Write-Host "计算机名：$env:COMPUTERNAME"
Write-Host "用户名：$env:USERNAME"
Write-Host "系统路径：$env:PATH"
Write-Host "临时目录：$env:TEMP"
Write-Host "处理器架构：$env:PROCESSOR_ARCHITECTURE"
Write-Host "PowerShell 版本：$($PSVersionTable.PSVersion)"

# .NET 方式读取（可指定默认值）
$dbServer = [System.Environment]::GetEnvironmentVariable("DB_SERVER")
if (-not $dbServer) {
    $dbServer = "localhost"
}
Write-Host "数据库服务器：$dbServer"

# 列出所有环境变量
Get-ChildItem Env: | Sort-Object Name | Format-Table Name, Value -AutoSize

# 搜索环境变量
Get-ChildItem Env: | Where-Object { $_.Name -match "JAVA|PYTHON|NODE" } |
    Format-Table Name, Value -AutoSize

# 设置临时环境变量（仅当前会话）
$env:MYAPP_ENV = "development"
$env:MYAPP_DEBUG = "true"
Write-Host "已设置 MYAPP_ENV=$env:MYAPP_ENV"

# 删除环境变量
Remove-Item Env:MYAPP_DEBUG
Write-Host "MYAPP_DEBUG 已删除：'$env:MYAPP_DEBUG'"
```

执行结果示例：

```
计算机名：WORKSTATION01
用户名：admin
系统路径：C:\Windows\system32;C:\Windows;C:\Program Files\PowerShell\7
临时目录：C:\Users\admin\AppData\Local\Temp
处理器架构：AMD64
PowerShell 版本：7.4.2
数据库服务器：localhost

Name                        Value
----                        -----
COMPUTERNAME                WORKSTATION01
JAVA_HOME                   C:\Program Files\Java\jdk-17
NODE_PATH                   C:\Program Files\nodejs
PATH                        C:\Windows\system32;C:\Windows;...
PYTHONPATH                  C:\Python312
已设置 MYAPP_ENV=development
MYAPP_DEBUG 已删除：''
```

## 持久化环境变量

```powershell
# 持久化到用户级别（注册表 HKCU\Environment）
[System.Environment]::SetEnvironmentVariable("MYAPP_HOME", "C:\MyApp", "User")

# 持久化到系统级别（需要管理员权限）
# [System.Environment]::SetEnvironmentVariable("MYAPP_HOME", "C:\MyApp", "Machine")

# 验证持久化
$persistent = [System.Environment]::GetEnvironmentVariable("MYAPP_HOME", "User")
Write-Host "持久化值：$persistent"

# 读取所有用户级环境变量
$userVars = [System.Environment]::GetEnvironmentVariables("User")
$userVars.GetEnumerator() | Sort-Object Key |
    Format-Table @{N='Name';E={$_.Key}}, @{N='Value';E={$_.Value}} -AutoSize

# 设置后同步到当前会话
function Set-EnvPersistent {
    param(
        [Parameter(Mandatory)][string]$Name,
        [Parameter(Mandatory)][string]$Value,
        [ValidateSet("User", "Machine")]
        [string]$Scope = "User"
    )

    [System.Environment]::SetEnvironmentVariable($Name, $Value, $Scope)

    # 同步到当前会话
    Set-Item -Path "Env:$Name" -Value $Value

    Write-Host "已设置 $Name=$Value ($Scope)" -ForegroundColor Green
}

Set-EnvPersistent -Name "APP_LOG_LEVEL" -Value "Debug" -Scope User

# 删除持久化变量
[System.Environment]::SetEnvironmentVariable("APP_LOG_LEVEL", $null, "User")
Write-Host "已删除 APP_LOG_LEVEL"
```

执行结果示例：

```
持久化值：C:\MyApp

Name            Value
----            -----
APP_LOG_LEVEL   Debug
HOME            C:\Users\admin
MYAPP_HOME      C:\MyApp
PATH            C:\Users\admin\bin;C:\Python312\Scripts

已设置 APP_LOG_LEVEL=Debug (User)
已删除 APP_LOG_LEVEL
```

## PATH 管理

```powershell
# 安全的 PATH 管理
function Add-ToPath {
    param(
        [Parameter(Mandatory)]
        [string]$Directory,

        [ValidateSet("User", "Machine")]
        [string]$Scope = "User"
    )

    # 验证目录存在
    if (-not (Test-Path $Directory)) {
        Write-Host "目录不存在：$Directory" -ForegroundColor Red
        return
    }

    $currentPath = [System.Environment]::GetEnvironmentVariable("PATH", $Scope)
    $paths = $currentPath -split ';' | Where-Object { $_ }

    # 检查是否已存在
    if ($paths -contains $Directory) {
        Write-Host "已在 PATH 中：$Directory" -ForegroundColor Yellow
        return
    }

    # 添加并持久化
    $newPath = $paths + $Directory
    [System.Environment]::SetEnvironmentVariable("PATH", ($newPath -join ';'), $Scope)

    # 同步当前会话
    $env:PATH = $newPath -join ';'

    Write-Host "已添加到 PATH：$Directory" -ForegroundColor Green
}

function Remove-FromPath {
    param(
        [Parameter(Mandatory)]
        [string]$Directory,

        [ValidateSet("User", "Machine")]
        [string]$Scope = "User"
    )

    $currentPath = [System.Environment]::GetEnvironmentVariable("PATH", $Scope)
    $paths = $currentPath -split ';' | Where-Object { $_ -ne $Directory }

    [System.Environment]::SetEnvironmentVariable("PATH", ($paths -join ';'), $Scope)
    $env:PATH = $paths -join ';'

    Write-Host "已从 PATH 移除：$Directory" -ForegroundColor Green
}

# 清理 PATH 中不存在的目录
function Repair-Path {
    param([ValidateSet("User", "Machine")][string]$Scope = "User")

    $currentPath = [System.Environment]::GetEnvironmentVariable("PATH", $Scope)
    $paths = $currentPath -split ';' | Where-Object { $_ }

    $validPaths = @()
    $removed = @()

    foreach ($p in $paths) {
        if (Test-Path $p) {
            $validPaths += $p
        } else {
            $removed += $p
        }
    }

    if ($removed.Count -gt 0) {
        [System.Environment]::SetEnvironmentVariable("PATH", ($validPaths -join ';'), $Scope)
        $env:PATH = $validPaths -join ';'
        Write-Host "清理了 $($removed.Count) 个无效路径：" -ForegroundColor Yellow
        $removed | ForEach-Object { Write-Host "  [已移除] $_" -ForegroundColor DarkGray }
    } else {
        Write-Host "PATH 无需清理" -ForegroundColor Green
    }
}

Repair-Path -Scope User
```

执行结果示例：

```
已在 PATH 中：C:\Python312
已从 PATH 移除：C:\OldTool\bin
清理了 3 个无效路径：
  [已移除] C:\DeletedApp\bin
  [已移除] D:\NoLongerExists\tools
  [已移除] C:\Temp\scripts
```

## 环境配置文件管理

```powershell
# .env 文件加载器
function Import-DotEnv {
    param(
        [Parameter(Mandatory)]
        [string]$Path,

        [switch]$Persist
    )

    if (-not (Test-Path $Path)) {
        throw ".env 文件不存在：$Path"
    }

    $lines = Get-Content $Path -ErrorAction Stop
    $loaded = 0

    foreach ($line in $lines) {
        # 跳过注释和空行
        if ($line -match '^\s*#' -or $line -match '^\s*$') { continue }

        if ($line -match '^\s*([A-Za-z_][A-Za-z0-9_]*)\s*=\s*(.+)\s*$') {
            $name = $Matches[1]
            $value = $Matches[2].Trim('"').Trim("'")

            Set-Item -Path "Env:$name" -Value $value
            if ($Persist) {
                [System.Environment]::SetEnvironmentVariable($name, $value, "User")
            }

            $loaded++
        }
    }

    Write-Host "从 $Path 加载了 $loaded 个环境变量" -ForegroundColor Green
}

# .env 文件示例
$envContent = @"
# 数据库配置
DB_HOST=prod-db01.example.com
DB_PORT=5432
DB_NAME=myapp_production
DB_USER=app_user

# 应用配置
APP_ENV=production
APP_DEBUG=false
APP_PORT=8080

# 日志配置
LOG_LEVEL=Warning
LOG_PATH=C:\Logs\MyApp
"@

$envContent | Set-Content "C:\MyApp\.env" -Encoding UTF8
Import-DotEnv -Path "C:\MyApp\.env"

# 验证加载
Write-Host "数据库：$env:DB_HOST`:$env:DB_PORT/$env:DB_NAME"
Write-Host "环境：$env:APP_ENV"

# 导出当前环境变量到 .env 文件
function Export-DotEnv {
    param(
        [string]$Path = ".env",
        [string[]]$Prefixes = @("MYAPP_", "DB_", "APP_")
    )

    $lines = @("# 自动生成 $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')")

    Get-ChildItem Env: | Where-Object {
        $name = $_.Name
        $Prefixes | ForEach-Object { $name -like "$_*" } | Where-Object { $_ }
    } | Sort-Object Name | ForEach-Object {
        $lines += "$($_.Name)=$($_.Value)"
    }

    $lines | Set-Content $Path -Encoding UTF8
    Write-Host "已导出 $($lines.Count - 1) 个变量到 $Path" -ForegroundColor Green
}
```

执行结果示例：

```
从 C:\MyApp\.env 加载了 8 个环境变量
数据库：prod-db01.example.com:5432/myapp_production
环境：production
```

## 注意事项

1. **作用域优先级**：Machine < User < Process，后者覆盖前者。`$env:VAR` 修改的是 Process 级别
2. **会话隔离**：`$env:VAR` 的修改只在当前会话生效，新开窗口不会看到变化
3. **PATH 分隔符**：Windows 用 `;`，Linux/macOS 用 `:`，跨平台脚本注意区分
4. **敏感信息**：不要将密码、Token 存入环境变量后再持久化到注册表。使用凭据管理器或密钥库
5. **特殊变量**：`PATH`、`PATHEXT`、`PSModulePath` 等系统变量修改需谨慎，建议先备份原值
6. **环境继承**：子进程继承父进程的环境变量快照，修改不会双向传播
