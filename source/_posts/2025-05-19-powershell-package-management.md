---
layout: post
date: 2025-05-19 08:00:00
updated: 2025-05-19 08:00:00
title: "PowerShell 技能连载 - Windows 包管理自动化"
description: PowerTip of the Day - Windows Package Management Automation
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
- winget
- chocolatey
- package-management
---

_适用于 PowerShell 5.1 及以上版本（Windows）_

在 Windows 上管理软件安装是运维工作中最繁琐的环节之一——每台服务器需要安装几十个工具和运行时，手动安装耗时且容易遗漏版本不一致。Windows Package Manager（winget）和 Chocolatey 的出现改变了这一局面，它们让 Windows 也拥有了类似 Linux `apt-get` / `yum` 的包管理体验。结合 PowerShell，可以实现软件的批量安装、版本锁定和自动更新。

本文将讲解 winget 和 Chocolatey 的 PowerShell 集成，以及如何构建标准化的软件清单。

## WinGet 基础操作

WinGet 是微软官方的 Windows 包管理器，内置在 Windows 11 和 Windows 10 1809+ 中：

```powershell
# 检查 winget 版本
winget --version

# 搜索软件包
winget search "Visual Studio Code" --source winget

# 安装软件包
winget install --id Microsoft.VisualStudioCode --accept-package-agreements --accept-source-agreements

# 安装特定版本
winget install --id Git.Git --version 2.45.0 --accept-package-agreements

# 查看已安装的软件
winget list

# 升级所有可更新的软件
winget upgrade --all --accept-package-agreements

# 导出已安装软件列表
winget export -o C:\Config\installed-packages.json

# 从清单导入安装
winget import -i C:\Config\installed-packages.json --accept-package-agreements
```

执行结果示例：

```
v1.7.11261

名称                         ID                         版本     可用        源
---------------------------------------------------------------------------------------
Visual Studio Code           Microsoft.VisualStudioCode 1.89.1               winget
Git                          Git.Git                    2.45.0               winget
PowerShell                   Microsoft.PowerShell       7.4.2    7.5.0       winget
7-Zip                        7zip.7zip                  24.08                winget

已成功安装的包: 4, 已跳过: 0, 失败: 0
```

## 用 PowerShell 封装 WinGet

将 winget 命令封装为 PowerShell 函数，可以更好地集成到自动化脚本中：

```powershell
function Get-WinGetPackageInfo {
    <#
    .SYNOPSIS
    查询 winget 软件包信息
    #>
    param([string]$PackageId)

    $output = winget show --id $PackageId --accept-source-agreements 2>&1
    $info = [ordered]@{}

    foreach ($line in $output) {
        if ($line -match '^\s*(.+?)\s{2,}(.+)$') {
            $key = $Matches[1].Trim()
            $value = $Matches[2].Trim()
            $info[$key] = $value
        }
    }

    return [PSCustomObject]$info
}

function Install-WinGetPackages {
    <#
    .SYNOPSIS
    批量安装 winget 软件包
    #>
    param(
        [Parameter(Mandatory)]
        [string[]]$PackageIds,

        [switch]$Upgrade
    )

    $results = @()

    foreach ($id in $PackageIds) {
        Write-Host "正在处理：$id" -ForegroundColor Cyan
        $args = @('install', '--id', $id, '--accept-package-agreements', '--accept-source-agreements', '--silent')

        if ($Upgrade) {
            $args = @('upgrade', '--id', $id, '--accept-package-agreements', '--accept-source-agreements', '--silent')
        }

        $process = Start-Process -FilePath winget -ArgumentList $args -Wait -PassThru -NoNewWindow

        $results += [PSCustomObject]@{
            Package = $id
            Action  = if ($Upgrade) { 'Upgrade' } else { 'Install' }
            Success = $process.ExitCode -eq 0
            ExitCode = $process.ExitCode
        }
    }

    $results | Format-Table -AutoSize
    $success = ($results | Where-Object Success).Count
    Write-Host "`n完成：$success/$($results.Count) 成功" -ForegroundColor $(if ($success -eq $results.Count) { 'Green' } else { 'Yellow' })
}

# 批量安装常用开发工具
$devTools = @(
    'Git.Git',
    'Microsoft.VisualStudioCode',
    'Microsoft.WindowsTerminal',
    '7zip.7zip',
    'jq.jq',
    'BurntSushi.ripgrep.MSVC',
    'sharkdp.fd'
)

Install-WinGetPackages -PackageIds $devTools
```

执行结果示例：

```
正在处理：Git.Git
正在处理：Microsoft.VisualStudioCode
...

Package                        Action  Success ExitCode
-------                        ------  ------- --------
Git.Git                        Install    True        0
Microsoft.VisualStudioCode     Install    True        0
Microsoft.WindowsTerminal      Install    True        0
7zip.7zip                      Install    True        0
jq.jq                          Install    True        0

完成：7/7 成功
```

## Chocolatey 集成

Chocolatey 是 Windows 上最成熟的第三方包管理器，拥有超过 9000 个软件包：

```powershell
# 安装 Chocolatey（需要管理员权限）
Set-ExecutionPolicy Bypass -Scope Process -Force
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))

# 常用 Chocolatey 命令
choco search nodejs
choco install nodejs-lts -y
choco install python -y
choco install docker-desktop -y

# 查看已安装的包
choco list --local-only

# 升级所有包
choco upgrade all -y

# 导出已安装包列表
choco export -o C:\Config\choco-packages.config

# 从配置文件安装
choco install C:\Config\choco-packages.config -y
```

执行结果示例：

```
Chocolatey v2.2.2
1 validations passed
nodejs 22.2.0 [Approved]
nodejs-lts 20.14.0 [Approved]

Chocolatey installed 3/3 packages successfully

Name                Version
----                -------
chocolatey          2.2.2
nodejs-lts          20.14.0
python              3.12.3
7zip                24.08
```

## 构建标准软件清单

对于团队或服务器群，维护一份标准软件清单可以确保环境一致性：

```powershell
function New-SoftwareManifest {
    <#
    .SYNOPSIS
    生成标准软件安装清单
    #>
    param(
        [string]$OutputPath = "C:\Config\software-manifest.json"
    )

    # 定义标准软件列表
    $manifest = @{
        metadata = @{
            created   = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
            author    = $env:USERNAME
            machine   = $env:COMPUTERNAME
        }
        packages = @(
            @{ id = 'Git.Git'; version = 'latest'; required = $true; category = 'DevTools' }
            @{ id = 'Microsoft.VisualStudioCode'; version = 'latest'; required = $true; category = 'DevTools' }
            @{ id = 'Microsoft.PowerShell'; version = '7.4.2'; required = $true; category = 'Runtime' }
            @{ id = '7zip.7zip'; version = 'latest'; required = $true; category = 'Utilities' }
            @{ id = 'Docker.DockerDesktop'; version = 'latest'; required = $false; category = 'Containers' }
            @{ id = 'Python.Python.3.12'; version = 'latest'; required = $false; category = 'Runtime' }
        )
    }

    $manifest | ConvertTo-Json -Depth 5 | Set-Content $OutputPath -Encoding UTF8
    Write-Host "软件清单已生成：$OutputPath" -ForegroundColor Green
}

function Install-FromManifest {
    <#
    .SYNOPSIS
    从清单文件安装所有软件
    #>
    param(
        [Parameter(Mandatory)]
        [string]$ManifestPath
    )

    $manifest = Get-Content $ManifestPath | ConvertFrom-Json
    Write-Host "清单创建于：$($manifest.metadata.created)" -ForegroundColor Cyan
    Write-Host "软件包数量：$($manifest.packages.Count)" -ForegroundColor Cyan

    $results = foreach ($pkg in $manifest.packages) {
        $args = @('install', '--id', $pkg.id, '--accept-package-agreements', '--accept-source-agreements', '--silent')

        if ($pkg.version -ne 'latest') {
            $args += @('--version', $pkg.version)
        }

        $process = Start-Process winget -ArgumentList $args -Wait -PassThru -NoNewWindow 2>$null

        [PSCustomObject]@{
            Package  = $pkg.id
            Version  = $pkg.version
            Required = $pkg.Required
            Category = $pkg.Category
            Success  = $process.ExitCode -eq 0
        }
    }

    $results | Format-Table -AutoSize
}

# 使用示例
New-SoftwareManifest
Install-FromManifest -ManifestPath "C:\Config\software-manifest.json"
```

执行结果示例：

```
软件清单已生成：C:\Config\software-manifest.json
清单创建于：2025-05-19 08:30:00
软件包数量：7

Package                        Version Required Category   Success
-------                        ------- -------- --------   -------
Git.Git                        latest     True   DevTools     True
Microsoft.VisualStudioCode     latest     True   DevTools     True
Microsoft.PowerShell           7.4.2      True   Runtime      True
7zip.7zip                      latest     True   Utilities    True
```

## 注意事项

1. **管理员权限**：winget 和 Chocolatey 的系统级安装需要管理员权限。Chocolatey 的 `--user` 模式可以安装到用户目录
2. **安装顺序**：某些软件有依赖关系（如 VS Code 扩展依赖 VS Code），清单中应按依赖顺序排列
3. **版本锁定**：生产环境建议锁定版本号，避免自动更新引入不兼容变更
4. **MSI/EXE 退出码**：不同安装程序的退出码含义不同，0 通常表示成功，3010 表示需要重启
5. **离线安装**：无外网环境可以预先下载安装包，使用 `winget install --manifest` 或 Chocolatey 的 `--source` 参数指定本地路径
6. **幂等性**：重复安装同一软件通常是安全的（已安装则跳过），但建议在脚本中检查安装状态
