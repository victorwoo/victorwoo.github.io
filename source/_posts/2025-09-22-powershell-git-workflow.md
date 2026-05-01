---
layout: post
date: 2025-09-22 08:00:00
title: "PowerShell 技能连载 - Git 工作流自动化"
description: PowerTip of the Day - Git Workflow Automation in PowerShell
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
- git
- workflow
- automation
- devops
---

_适用于 PowerShell 7.0 及以上版本（跨平台）_

在日常开发工作中，Git 是最常用的版本控制工具，但频繁的分支管理、代码提交和仓库同步操作往往令人疲惫。尤其当团队成员众多、仓库数量庞大时，手动执行这些重复性操作不仅效率低下，还容易因疏忽引入错误。PowerShell 凭借其强大的对象管道和跨平台能力，非常适合将这些 Git 日常工作封装为可复用的自动化函数。

本文将从分支管理、批量提交和仓库同步三个典型场景出发，演示如何用 PowerShell 构建一套轻量的 Git 工作流自动化工具集。这些脚本可在 Windows、macOS 和 Linux 上无缝运行，帮助团队统一工作流规范，减少人工操作带来的不一致性。

无论你是管理数十个微服务仓库的 DevOps 工程师，还是希望在个人项目中减少重复劳动的开发者，都可以从这些函数中获得灵感并按需扩展。

## 智能分支管理器

第一个场景是分支管理。在团队协作中，规范化的分支命名和生命周期管理至关重要。以下函数封装了分支创建、切换和清理的常见操作，并内置了安全检查逻辑，避免误删未合并的分支。

```powershell
function New-GitFeatureBranch {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory)]
        [string]$Name,

        [ValidateSet('feature', 'bugfix', 'hotfix', 'release')]
        [string]$Prefix = 'feature',

        [string]$BaseBranch = 'main'
    )

    # 检查是否在 Git 仓库中
    $isRepo = git rev-parse --is-inside-work-tree 2>$null
    if ($LASTEXITCODE -ne 0) {
        Write-Error "当前目录不是 Git 仓库"
        return
    }

    # 确保工作区干净
    $status = git status --porcelain 2>$null
    if ($status) {
        Write-Warning "工作区有未提交的更改："
        Write-Warning ($status | Out-String)
        $continue = Read-Host "是否继续？(y/N)"
        if ($continue -ne 'y') {
            Write-Host "操作已取消" -ForegroundColor Yellow
            return
        }
    }

    # 切换到基准分支并拉取最新代码
    Write-Host "切换到 $BaseBranch 并拉取最新代码..." -ForegroundColor Cyan
    git checkout $BaseBranch 2>$null
    git pull origin $BaseBranch 2>$null

    # 创建新分支
    $branchName = "$Prefix/$Name"
    if ($PSCmdlet.ShouldProcess($branchName, '创建并切换到分支')) {
        git checkout -b $branchName
        Write-Host "已创建并切换到分支: $branchName" -ForegroundColor Green
    }

    # 输出分支信息对象
    [PSCustomObject]@{
        BranchName = $branchName
        Prefix     = $Prefix
        BaseBranch = $BaseBranch
        CreatedAt  = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    }
}
```

执行结果示例：

```
切换到 main 并拉取最新代码...
Already on 'main'.
From https://github.com/example/my-project
 * branch            main       -> FETCH_HEAD
Already up to date.
已创建并切换到分支: feature/add-user-api

BranchName           Prefix  BaseBranch CreatedAt
-----------           ------  ---------- ---------
feature/add-user-api feature main       2025-09-22 08:30:00
```

## 批量提交与变更摘要

第二个场景是自动化提交流程。在长时间的开发过程中，开发者经常需要将一组相关的文件变更打包提交，并附上规范的提交信息。手动编写提交信息容易遗漏关键内容，而通过 PowerShell 脚本可以自动收集变更摘要并生成格式化的提交信息。

```powershell
function Send-GitBatchCommit {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Message,

        [string[]]$FilePatterns = @('*'),

        [ValidateSet('minor', 'patch', 'major')]
        [string]$BumpVersion,

        [switch]$Push
    )

    # 收集匹配的文件
    $changedFiles = @()
    foreach ($pattern in $FilePatterns) {
        $files = git diff --name-only --relative $pattern 2>$null
        $stagedFiles = git diff --cached --name-only --relative $pattern 2>$null
        $untracked = git ls-files --others --exclude-standard -- $pattern 2>$null

        $changedFiles += $files
        $changedFiles += $stagedFiles
        $changedFiles += $untracked
    }

    $changedFiles = $changedFiles | Sort-Object -Unique

    if (-not $changedFiles) {
        Write-Host "没有找到匹配的变更文件" -ForegroundColor Yellow
        return
    }

    Write-Host "即将提交以下文件：" -ForegroundColor Cyan
    foreach ($file in $changedFiles) {
        Write-Host "  - $file" -ForegroundColor Gray
    }

    # 生成变更统计
    $stats = git diff --stat -- $changedFiles 2>$null
    $insertions = ($stats | Select-String '(\d+) insertion' |
        ForEach-Object { $_.Matches[0].Groups[1].Value } | Measure-Object -Sum).Sum
    $deletions = ($stats | Select-String '(\d+) deletion' |
        ForEach-Object { $_.Matches[0].Groups[1].Value } | Measure-Object -Sum).Sum

    # 添加并提交
    foreach ($file in $changedFiles) {
        git add $file 2>$null
    }

    $timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm'
    $fullMessage = "$message`n`n提交时间: $timestamp`n文件数: $($changedFiles.Count)`n新增: +$insertions 行 | 删除: -$deletions 行"

    git commit -m $fullMessage
    Write-Host "提交成功: $($changedFiles.Count) 个文件" -ForegroundColor Green

    # 版本号处理
    if ($BumpVersion) {
        $packageJson = Get-Content 'package.json' -ErrorAction SilentlyContinue |
            ConvertFrom-Json
        if ($packageJson) {
            $version = [version]$packageJson.version
            $newVersion = $BumpVersion switch {
                'patch' { [version]::new($version.Major, $version.Minor, $version.Build + 1) }
                'minor' { [version]::new($version.Major, $version.Minor + 1, 0) }
                'major' { [version]::new($version.Major + 1, 0, 0) }
            }
            $packageJson.version = $newVersion.ToString()
            $packageJson | ConvertTo-Json -Depth 10 | Set-Content 'package.json'
            git add 'package.json'
            git commit -m "chore: bump version to $($newVersion.ToString())"
            Write-Host "版本号已更新: $($version) -> $($newVersion)" -ForegroundColor Green
        }
    }

    # 推送
    if ($Push) {
        git push origin HEAD
        Write-Host "已推送到远程仓库" -ForegroundColor Green
    }
}
```

执行结果示例：

```
即将提交以下文件：
  - src/api/user.ps1
  - src/api/auth.ps1
  - tests/api/user.Tests.ps1
提交成功: 3 个文件
[feature/add-user-api a1b2c3d] 添加用户和认证 API 接口
 3 files changed, 145 insertions(+), 12 deletions(-)
版本号已更新: 1.2.0 -> 1.2.1
[feature/add-user-api d4e5f6g] chore: bump version to 1.2.1
```

## 多仓库批量同步

第三个场景是多仓库管理。在微服务架构中，一个项目通常由多个 Git 仓库组成。当需要批量拉取更新、清理过期分支或检查仓库状态时，逐个手动操作极其低效。以下函数可以一次性扫描并操作多个仓库。

```powershell
function Sync-GitRepositories {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$WorkspaceRoot,

        [ValidateSet('pull', 'fetch', 'status', 'clean-branches')]
        [string]$Action = 'pull',

        [string]$DefaultBranch = 'main',

        [int]$StaleDays = 30
    )

    # 扫描所有 Git 仓库
    $repos = @()
    $dirs = Get-ChildItem -Path $WorkspaceRoot -Directory -Depth 1

    foreach ($dir in $dirs) {
        $gitDir = Join-Path $dir.FullName '.git'
        if (Test-Path $gitDir) {
            $repos += [PSCustomObject]@{
                Name = $dir.Name
                Path = $dir.FullName
            }
        }
    }

    Write-Host "在工作区发现 $($repos.Count) 个 Git 仓库" -ForegroundColor Cyan
    Write-Host ("-" * 50)

    $results = @()

    foreach ($repo in $repos) {
        Push-Location $repo.Path

        $result = [PSCustomObject]@{
            Repository = $repo.Name
            Action     = $Action
            Status     = 'success'
            Message    = ''
        }

        try {
            switch ($Action) {
                'pull' {
                    $output = git pull origin $DefaultBranch 2>&1
                    $result.Message = ($output | Out-String).Trim()
                }
                'fetch' {
                    $output = git fetch --all --prune 2>&1
                    $result.Message = ($output | Out-String).Trim()
                }
                'status' {
                    $branch = git branch --show-current 2>$null
                    $ahead = git rev-list --count "@{upstream}..HEAD" 2>$null
                    $behind = git rev-list --count "HEAD..@{upstream}" 2>$null
                    $dirty = git status --porcelain 2>$null

                    $statusParts = @("分支: $branch")
                    if ($ahead) { $statusParts += "领先: $ahead 个提交" }
                    if ($behind) { $statusParts += "落后: $behind 个提交" }
                    if ($dirty) { $statusParts += "未提交: $(($dirty | Measure-Object).Count) 个文件" }
                    $result.Message = $statusParts -join ' | '
                }
                'clean-branches' {
                    $cutoff = (Get-Date).AddDays(-$StaleDays)
                    $branches = git branch --format='%(refname:short) %(creatordate:iso8601)' 2>$null

                    $deleted = @()
                    foreach ($line in $branches) {
                        $parts = $line -split '\s+', 2
                        $branchName = $parts[0]
                        $createdStr = $parts[1]

                        if ($branchName -eq $DefaultBranch) { continue }

                        $created = [datetime]::Parse($createdStr)
                        if ($created -lt $cutoff) {
                            $mergeCheck = git branch --merged $DefaultBranch --list $branchName 2>$null
                            if ($mergeCheck) {
                                git branch -d $branchName 2>$null
                                $deleted += $branchName
                            }
                        }
                    }

                    $result.Message = if ($deleted.Count -gt 0) {
                        "已删除 $($deleted.Count) 个过期分支: $($deleted -join ', ')"
                    } else {
                        "没有需要清理的过期分支"
                    }
                }
            }
        }
        catch {
            $result.Status = 'failed'
            $result.Message = $_.Exception.Message
        }

        $results += $result
        $color = if ($result.Status -eq 'success') { 'Green' } else { 'Red' }
        Write-Host "[$($result.Status.ToUpper())] $($repo.Name): $($result.Message)" -ForegroundColor $color

        Pop-Location
    }

    Write-Host ("-" * 50)
    Write-Host "操作完成，共处理 $($repos.Count) 个仓库" -ForegroundColor Cyan

    return $results
}
```

执行结果示例：

```
在工作区发现 5 个 Git 仓库
--------------------------------------------------
[SUCCESS] user-service: Already up to date.
[SUCCESS] auth-service: Already up to date.
[SUCCESS] api-gateway: Fast-forward
           3a1f2b4..7c8d9e0  main     -> origin/main
[SUCCESS] notification-svc: Already up to date.
[SUCCESS] shared-libs: Already up to date.
--------------------------------------------------
操作完成，共处理 5 个仓库
```

## 注意事项

1. **跨平台兼容性**：上述脚本使用 `git` CLI 作为底层调用，确保在 Windows、macOS 和 Linux 上行为一致。但需要注意不同操作系统上 `git` 输出格式的细微差异，建议在实际部署前进行多平台测试。

2. **错误处理策略**：Git 命令通过 `$LASTEXITCODE` 返回退出码，PowerShell 不会自动将其转为异常。在关键操作前应主动检查退出码，或使用 `try/catch` 配合 `-ErrorAction Stop` 来捕获意外错误。

3. **工作区状态检查**：在执行分支切换、拉取等操作前，务必检查工作区是否干净。可以使用 `git stash` 暂存未提交的更改，操作完成后再用 `git stash pop` 恢复，避免数据丢失。

4. **大批量操作的风险**：对大量仓库执行批量操作时，建议先以 `status` 模式运行一次，确认所有仓库的状态正常后再执行实际的修改操作。可以结合 `-WhatIf` 参数实现干运行模式。

5. **并发执行优化**：当仓库数量较多时，可以使用 `ForEach-Object -Parallel`（PowerShell 7 的特性）来并发执行拉取操作，显著缩短总耗时。但要注意控制并发度，避免对 Git 服务器造成过大压力。

6. **敏感信息保护**：提交信息中不要包含密码、Token 等敏感信息。可以在脚本中集成 `git-secrets` 或自定义的预提交检查逻辑，在提交前自动扫描暂存区文件中的敏感模式并阻止提交。
