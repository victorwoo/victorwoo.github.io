---
layout: post
date: 2025-07-01 08:00:00
title: "PowerShell 技能连载 - 语义版本管理"
description: PowerTip of the Day - Semantic Versioning Management in PowerShell
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
- semver
- versioning
- release
---

_适用于 PowerShell 5.1 及以上版本_

版本号管理看似简单，实际在团队协作中经常引发混乱——构建号怎么递增、预发布版本怎么标记、依赖版本范围怎么声明。语义化版本（Semantic Versioning，SemVer）提供了一套清晰的规则：`主版本号.次版本号.修订号`，再加上可选的预发布标记和构建元数据。PowerShell 模块本身使用版本号管理，掌握 SemVer 的操作技巧，对模块发布、依赖管理和发布流程自动化都很重要。

本文将讲解如何在 PowerShell 中解析、比较、操作语义化版本号，以及自动化版本管理的实用技巧。

## 版本号解析

```powershell
# PowerShell 原生版本对象
$version = [version]"1.2.3"
Write-Host "主版本：$($version.Major)"
Write-Host "次版本：$($version.Minor)"
Write-Host "修订号：$($version.Build)"

# 比较版本
$v1 = [version]"1.2.3"
$v2 = [version]"1.10.0"
Write-Host "$v1 < $v2 : $($v1 -lt $v2)"

# 解析完整语义化版本号（含预发布标记）
function Parse-SemVer {
    param([Parameter(Mandatory)][string]$VersionString)

    $pattern = '^(?<major>\d+)\.(?<minor>\d+)\.(?<patch>\d+)(?:-(?<prerelease>[a-zA-Z0-9.]+))?(?:\+(?<build>[a-zA-Z0-9.]+))?$'

    if ($VersionString -notmatch $pattern) {
        throw "无效的语义版本号：$VersionString"
    }

    return [PSCustomObject]@{
        Original   = $VersionString
        Major      = [int]$Matches.major
        Minor      = [int]$Matches.minor
        Patch      = [int]$Matches.patch
        PreRelease = $Matches.prerelease
        Build      = $Matches.build
        IsStable   = -not $Matches.prerelease
    }
}

# 测试解析
$versions = @("1.0.0", "2.1.3-alpha", "3.0.0-beta.2", "1.0.0+build.123")
foreach ($v in $versions) {
    $parsed = Parse-SemVer $v
    Write-Host "$($parsed.Original) => Major=$($parsed.Major) Minor=$($parsed.Minor) Patch=$($parsed.Patch) PreRelease=$($parsed.PreRelease) Stable=$($parsed.IsStable)"
}
```

执行结果示例：

```
主版本：1
次版本：2
修订号：3
1.2.3 < 1.10.0 : True
1.0.0 => Major=1 Minor=0 Patch=0 PreRelease= Stable= True
2.1.3-alpha => Major=2 Minor=1 Patch=3 PreRelease=alpha Stable= False
3.0.0-beta.2 => Major=3 Minor=0 Patch=0 PreRelease=beta.2 Stable= False
1.0.0+build.123 => Major=1 Minor=0 Patch=0 PreRelease= Stable= True
```

## 版本号递增

```powershell
function Step-SemVer {
    <#
    .SYNOPSIS
    递增语义化版本号
    #>
    param(
        [Parameter(Mandatory)]
        [string]$Version,

        [Parameter(Mandatory)]
        [ValidateSet("Major", "Minor", "Patch")]
        [string]$Level,

        [string]$PreRelease
    )

    $semver = Parse-SemVer $Version

    switch ($Level) {
        "Major" {
            $semver.Major++
            $semver.Minor = 0
            $semver.Patch = 0
        }
        "Minor" {
            $semver.Minor++
            $semver.Patch = 0
        }
        "Patch" {
            $semver.Patch++
        }
    }

    $newVersion = "$($semver.Major).$($semver.Minor).$($semver.Patch)"
    if ($PreRelease) {
        $newVersion += "-$PreRelease"
    }

    return $newVersion
}

# 递增示例
$current = "1.2.3"
Write-Host "当前版本：$current"
Write-Host "Patch 递增：$(Step-SemVer $current Patch)"
Write-Host "Minor 递增：$(Step-SemVer $current Minor)"
Write-Host "Major 递增：$(Step-SemVer $current Major)"
Write-Host "带预发布：$(Step-SemVer $current Minor -PreRelease 'beta.1')"
```

执行结果示例：

```
当前版本：1.2.3
Patch 递增：1.2.4
Minor 递增：1.3.0
Major 递增：2.0.0
带预发布：1.3.0-beta.1
```

## 模块版本管理

```powershell
function Update-ModuleVersion {
    <#
    .SYNOPSIS
    更新 PowerShell 模块的版本号
    #>
    param(
        [Parameter(Mandatory)]
        [string]$ModuleManifestPath,

        [Parameter(Mandatory)]
        [ValidateSet("Major", "Minor", "Patch")]
        [string]$Level
    )

    if (-not (Test-Path $ModuleManifestPath)) {
        throw "模块清单文件不存在：$ModuleManifestPath"
    }

    $content = Get-Content $ModuleManifestPath -Raw

    # 提取当前版本号
    if ($content -notmatch 'ModuleVersion\s*=\s*[''"]([^''"]+)[''"]') {
        throw "无法从模块清单中提取版本号"
    }

    $currentVersion = $Matches[1]
    $newVersion = Step-SemVer $currentVersion $Level

    # 替换版本号
    $newContent = $content -replace "(ModuleVersion\s*=\s*)[''"][^''"]+[''"]", "`$1'$newVersion'"
    Set-Content -Path $ModuleManifestPath -Value $newContent -NoNewline

    Write-Host "版本更新：$currentVersion => $newVersion" -ForegroundColor Green

    # 同时更新 CHANGELOG
    $changelogPath = Join-Path (Split-Path $ModuleManifestPath -Parent) "CHANGELOG.md"
    if (Test-Path $changelogPath) {
        $changelog = Get-Content $changelogPath -Raw
        $date = Get-Date -Format "yyyy-MM-dd"
        $header = "## [$newVersion] - $date"
        $newChangelog = $changelog -replace "(## \[Unreleased\])", "`$1`n`n$header`n- "
        Set-Content $changelogPath -Value $newChangelog -NoNewline
        Write-Host "CHANGELOG 已更新" -ForegroundColor Green
    }

    return $newVersion
}

# 更新模块版本
Update-ModuleVersion -ModuleManifestPath "C:\Modules\MyUtils\MyUtils.psd1" -Level Minor
```

执行结果示例：

```
版本更新：1.2.0 => 1.3.0
CHANGELOG 已更新
```

## Git 标签与发布

```powershell
function Publish-ModuleRelease {
    <#
    .SYNOPSIS
    自动化模块发布流程
    #>
    param(
        [string]$ModulePath = ".",
        [ValidateSet("Major", "Minor", "Patch")]
        [string]$Bump = "Patch",
        [string]$ReleaseNote
    )

    # 检查工作目录状态
    $status = git status --porcelain
    if ($status) {
        Write-Host "存在未提交的更改，请先提交" -ForegroundColor Red
        return
    }

    # 获取最新标签
    $lastTag = git describe --tags --abbrev=0 2>$null
    if (-not $lastTag) {
        $lastTag = "0.0.0"
    }
    $lastTag = $lastTag -replace '^v', ''

    # 递增版本
    $newVersion = Step-SemVer $lastTag $Bump
    $tagName = "v$newVersion"

    Write-Host "发布版本：$lastTag => $newVersion ($Bump)" -ForegroundColor Cyan

    # 更新模块清单
    $manifest = Get-ChildItem $ModulePath -Filter "*.psd1" | Select-Object -First 1
    if ($manifest) {
        Update-ModuleVersion -ModuleManifestPath $manifest.FullName -Level $Bump | Out-Null
    }

    # 提交更改
    git add -A
    $commitMsg = if ($ReleaseNote) { "Release $tagName`: $ReleaseNote" } else { "Release $tagName" }
    git commit -m $commitMsg

    # 创建标签
    git tag -a $tagName -m "Release $tagName"

    Write-Host "发布准备完成：$tagName" -ForegroundColor Green
    Write-Host "使用以下命令推送：" -ForegroundColor Yellow
    Write-Host "  git push && git push --tags" -ForegroundColor Yellow
}

Publish-ModuleRelease -Bump Minor -ReleaseNote "新增 AI 集成功能"
```

执行结果示例：

```
发布版本：1.2.0 => 1.3.0 (Minor)
版本更新：1.2.0 => 1.3.0
发布准备完成：v1.3.0
使用以下命令推送：
  git push && git push --tags
```

## 版本范围检测

```powershell
function Test-VersionRange {
    <#
    .SYNOPSIS
    检查版本号是否在指定范围内
    #>
    param(
        [Parameter(Mandatory)]
        [string]$Version,

        [Parameter(Mandatory)]
        [string]$Range
    )

    $v = Parse-SemVer $Version

    # 解析范围表达式（支持 >=1.0.0 <2.0.0 格式）
    $constraints = $Range -split '\s+' | Where-Object { $_ }
    $satisfied = $true

    foreach ($constraint in $constraints) {
        if ($constraint -match '^(>=|<=|>|<|=)(.+)$') {
            $op = $Matches[1]
            $target = Parse-SemVer $Matches[2]
            $cmp = Compare-SemVer -Version1 $v -Version2 $target

            $ok = switch ($op) {
                ">=" { $cmp -ge 0 }
                "<=" { $cmp -le 0 }
                ">"  { $cmp -gt 0 }
                "<"  { $cmp -lt 0 }
                "="  { $cmp -eq 0 }
            }

            if (-not $ok) { $satisfied = $false; break }
        }
    }

    return $satisfied
}

function Compare-SemVer {
    param($Version1, $Version2)

    if ($Version1.Major -ne $Version2.Major) { return $Version1.Major - $Version2.Major }
    if ($Version1.Minor -ne $Version2.Minor) { return $Version1.Minor - $Version2.Minor }
    return $Version1.Patch - $Version2.Patch
}

# 测试版本范围
$tests = @(
    @{ Version = "1.5.0"; Range = ">=1.0.0 <2.0.0" },
    @{ Version = "2.0.0"; Range = ">=1.0.0 <2.0.0" },
    @{ Version = "1.9.9"; Range = ">=1.0.0 <2.0.0" },
    @{ Version = "3.1.0"; Range = ">=3.0.0" }
)

foreach ($test in $tests) {
    $result = Test-VersionRange -Version $test.Version -Range $test.Range
    Write-Host "$($test.Version) 满足 $($test.Range) : $result" -ForegroundColor $(if ($result) { "Green" } else { "Red" })
}
```

执行结果示例：

```
1.5.0 满足 >=1.0.0 <2.0.0 : True
2.0.0 满足 >=1.0.0 <2.0.0 : False
1.9.9 满足 >=1.0.0 <2.0.0 : True
3.1.0 满足 >=3.0.0 : True
```

## 注意事项

1. **版本比较陷阱**：字符串比较 `"1.10.0" -lt "1.2.0"` 返回 True，务必使用 `[version]` 类型或自定义比较函数
2. **预发布排序**：SemVer 规范中预发布版本低于同版本的正式版（`1.0.0-alpha` < `1.0.0`），排序时需要特殊处理
3. **模块清单**：PowerShell 模块清单（`.psd1`）的 `ModuleVersion` 只支持三段式版本号，不支持预发布标记
4. **Git 标签**：使用 `v` 前缀的标签（`v1.2.3`）是常见约定，解析时记得去除前缀
5. **破坏性变更**：递增 Major 版本号意味着存在不兼容的 API 变更，确保同步更新文档和迁移指南
6. **自动化发布**：版本递增、标签创建、推送发布应在 CI/CD 流水线中完成，避免手动操作遗漏步骤
