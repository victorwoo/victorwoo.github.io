---
layout: post
date: 2025-06-02 08:00:00
title: "PowerShell 技能连载 - Git 版本控制集成"
description: PowerTip of the Day - Git Version Control Integration in PowerShell
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
- git
- version-control
- devops
---

_适用于 PowerShell 5.1 及以上版本，需安装 Git_

版本控制是现代软件开发和运维的基石。Git 不仅用于代码管理，也广泛应用于基础设施即代码（IaC）、配置管理、文档版本控制等场景。PowerShell 与 Git 的深度集成可以实现自动化的提交、分支管理、变更检测和 CI/CD 触发，将版本控制纳入运维自动化的闭环。

本文将讲解 PowerShell 调用 Git 命令的技巧、常用操作的封装，以及 Git 自动化工作流的构建。

## Git 状态查询

通过 PowerShell 封装 Git 命令，可以获得更好的输出格式：

```powershell
# 查看仓库状态
git status --porcelain | ForEach-Object {
    $status = $_.Substring(0, 2).Trim()
    $file = $_.Substring(3)
    [PSCustomObject]@{
        Status = switch ($status) {
            'M'  { 'Modified' }
            'A'  { 'Added' }
            'D'  { 'Deleted' }
            'R'  { 'Renamed' }
            '??' { 'Untracked' }
            default { $status }
        }
        File = $file
    }
} | Format-Table -AutoSize

# 查看分支列表
git branch -a | ForEach-Object {
    $line = $_.Trim()
    $isCurrent = $line.StartsWith('*')
    $name = $line -replace '^\*\s+', '' -replace '^remotes/', ''
    [PSCustomObject]@{
        Current = $isCurrent
        Branch  = $name
        Type    = if ($name -match '^remotes/') { 'Remote' } else { 'Local' }
    }
} | Format-Table -AutoSize

# 查看最近的提交
git log --oneline -15 | ForEach-Object {
    $parts = $_ -split ' ', 2
    [PSCustomObject]@{
        Hash    = $parts[0]
        Message = $parts[1]
    }
} | Format-Table -AutoSize
```

执行结果示例：

```
Status    File
------    ----
Modified  source/_posts/2025-06-01-example.md
Added     source/_posts/2025-06-02-new-article.md
Untracked config/local.json

Current Branch            Type
------- ------            ----
  True  source            Local
        main              Local
        remotes/origin/main Remote

Hash    Message
44693e3 新增 18 篇 PowerShell 技能连载博客
24535d6 重写 6 篇博客
44d4df0 补充遗漏的安全基线审计文章
```

## 自动化提交函数

将常用的 Git 操作封装为 PowerShell 函数：

```powershell
function Submit-GitChanges {
    <#
    .SYNOPSIS
    自动暂存并提交变更
    #>
    param(
        [Parameter(Mandatory)]
        [string]$Message,

        [string[]]$Path,
        [switch]$All,
        [switch]$Push
    )

    # 检查是否在 Git 仓库中
    $isRepo = git rev-parse --is-inside-work-tree 2>$null
    if ($isRepo -ne 'true') {
        Write-Error "当前目录不是 Git 仓库"
        return
    }

    # 检查是否有变更
    $status = git status --porcelain
    if (-not $status) {
        Write-Host "没有需要提交的变更" -ForegroundColor Yellow
        return
    }

    # 暂存文件
    if ($Path) {
        git add @Path
        Write-Host "已暂存：$($Path -join ', ')" -ForegroundColor Cyan
    } elseif ($All) {
        git add -A
        Write-Host "已暂存所有变更" -ForegroundColor Cyan
    } else {
        git add -u
        Write-Host "已暂存已跟踪文件的变更" -ForegroundColor Cyan
    }

    # 提交
    git commit -m $message
    if ($LASTEXITCODE -eq 0) {
        Write-Host "已提交：$message" -ForegroundColor Green
    } else {
        Write-Host "提交失败" -ForegroundColor Red
        return
    }

    # 可选推送
    if ($Push) {
        $branch = git rev-parse --abbrev-ref HEAD
        git push origin $branch
        Write-Host "已推送到 origin/$branch" -ForegroundColor Green
    }
}

# 示例：提交新文章
Submit-GitChanges -Message "新增 6 月博客文章" -Path @("source/_posts/2025-06-02-*.md") -Push
```

执行结果示例：

```
已暂存：source/_posts/2025-06-02-*.md
[source abc1234] 新增 6 月博客文章
 2 files changed, 400 insertions(+)
已提交：新增 6 月博客文章
已推送到 origin/source
```

## 分支管理

```powershell
function New-GitFeatureBranch {
    param(
        [Parameter(Mandatory)]
        [string]$Name,
        [string]$BaseBranch = 'main'
    )

    # 确保本地分支信息是最新的
    git fetch origin

    # 创建并切换到新分支
    git checkout -b $Name "origin/$BaseBranch"
    Write-Host "已从 $BaseBranch 创建分支：$Name" -ForegroundColor Green
}

function Merge-GitBranch {
    param(
        [Parameter(Mandatory)]
        [string]$Branch,

        [string]$TargetBranch = 'main',
        [switch]$DeleteAfterMerge
    )

    $currentBranch = git rev-parse --abbrev-ref HEAD

    # 切换到目标分支
    git checkout $TargetBranch
    git pull origin $TargetBranch

    # 合并
    git merge $Branch --no-ff -m "Merge branch '$Branch' into $TargetBranch"

    if ($LASTEXITCODE -eq 0) {
        Write-Host "已合并 $Branch 到 $TargetBranch" -ForegroundColor Green

        if ($DeleteAfterMerge) {
            git branch -d $Branch
            Write-Host "已删除本地分支：$Branch" -ForegroundColor Yellow
        }
    } else {
        Write-Host "合并冲突，请手动解决" -ForegroundColor Red
        Write-Host "运行 'git mergetool' 或手动编辑冲突文件"
    }
}

# 创建功能分支
New-GitFeatureBranch -Name "feature/blog-june" -BaseBranch "source"
```

执行结果示例：

```
已从 source 创建分支：feature/blog-june
```

## 变更检测与差异分析

```powershell
function Get-GitDiffSummary {
    <#
    .SYNOPSIS
    生成变更摘要报告
    #>
    param(
        [string]$Since = 'HEAD~1',
        [string]$Path
    )

    $args = @('diff', '--stat', $Since)
    if ($Path) { $args += @('--', $Path) }

    $diffStat = git @args
    $diffStat

    # 详细变更列表
    $args = @('diff', '--name-status', $Since)
    if ($Path) { $args += @('--', $Path) }

    $changes = git @args | ForEach-Object {
        $parts = $_ -split "`t"
        [PSCustomObject]@{
            Status = $parts[0]
            File   = $parts[1]
        }
    }

    $summary = $changes | Group-Object Status | ForEach-Object {
        [PSCustomObject]@{
            Type  = $_.Name
            Count = $_.Count
            Files = ($_.Group.File -join ', ')
        }
    }

    Write-Host "`n变更摘要：" -ForegroundColor Cyan
    $summary | Format-Table -AutoSize
}

# 查看最近一次提交的变更
Get-GitDiffSummary -Since 'HEAD~1' -Path 'source/_posts/'

# 查看两个分支之间的差异
Get-GitDiffSummary -Since 'main..feature/new-api'
```

执行结果示例：

```
 source/_posts/2025-06-01-example.md | 200 +++++++++++++
 source/_posts/2025-06-02-new.md     | 185 +++++++++++++
 2 files changed, 385 insertions(+)

变更摘要：
Type Count Files
---- ----- -----
A      2    source/_posts/2025-06-01-example.md, source/_posts/2025-06-02-new.md
```

## Git Hooks 自动化

利用 Git Hooks 可以在提交和推送时自动执行 PowerShell 脚本：

```powershell
# 创建 pre-commit hook（提交前运行 lint）
$hookPath = ".git/hooks/pre-commit"
$hookContent = @'
#!/bin/sh
# Pre-commit hook: 运行 markdownlint 检查

# 获取暂存的 .md 文件
FILES=$(git diff --cached --name-only --diff-filter=ACM '*.md')

if [ -n "$FILES" ]; then
    echo "检查 Markdown 文件..."
    for FILE in $FILES; do
        markdownlint "$FILE" 2>&1
        if [ $? -ne 0 ]; then
            echo "Lint 失败：$FILE"
            exit 1
        fi
    done
fi

exit 0
'@

Set-Content -Path $hookPath -Value $hookContent
# 设置可执行权限
if ($IsLinux -or $IsMacOS) {
    chmod +x $hookPath
}
Write-Host "Pre-commit hook 已安装" -ForegroundColor Green
```

执行结果示例：

```
Pre-commit hook 已安装
```

## 注意事项

1. **编码问题**：Git 默认使用 UTF-8，但 Windows 上的 PowerShell 可能使用其他编码。确保 `core.quotepath` 设为 `false` 以正确显示中文文件名
2. **大文件管理**：使用 Git LFS（Large File Storage）管理大型二进制文件，避免仓库膨胀
3. **敏感信息**：不要提交密码、API Key 等敏感信息。使用 `.gitignore` 排除配置文件，敏感数据存放在环境变量或密钥管理服务中
4. **提交信息规范**：遵循 Conventional Commits 规范（如 `feat:`, `fix:`, `docs:`），便于自动生成变更日志
5. **分支策略**：团队协作时使用 Git Flow 或 GitHub Flow 等分支策略，避免直接推送到主分支
6. **子模块管理**：使用 `git submodule` 管理依赖的外部仓库，注意初始化和更新命令
