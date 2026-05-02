---
layout: post
date: 2025-11-12 08:00:00
updated: 2025-11-12 08:00:00
title: "PowerShell 技能连载 - VS Code 扩展开发"
description: PowerTip of the Day - VS Code Extension Development in PowerShell
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
- vscode
- extension
- development
- editor
---

_适用于 PowerShell 7.0 及以上版本_

VS Code 的扩展生态极其丰富，但当现有扩展无法满足需求时，我们就需要自己动手开发。虽然 VS Code 扩展通常用 TypeScript 编写，但 PowerShell 在扩展开发的工程化管理中扮演着不可或缺的角色——从脚手架生成、依赖安装、构建打包到发布上线，整个生命周期都可以用 PowerShell 自动化。特别是在团队协作中，统一的构建和发布脚本能大幅降低出错概率。

本文将介绍如何利用 PowerShell 自动化 VS Code 扩展开发的完整流程，包括环境准备、项目初始化、构建打包和版本发布，帮助你在扩展开发中事半功倍。

<!-- more -->

## 环境准备与检查

开发 VS Code 扩展需要 Node.js、npm 以及 Yeoman 生成器等工具。在正式开始之前，先用 PowerShell 脚本检查当前环境是否满足要求，缺少的依赖自动安装。

```powershell
# 检查 VS Code 扩展开发环境
function Test-VSCodeDevEnvironment {
    $requirements = @(
        @{ Name = "Node.js"; Command = "node"; VersionArg = "--version" }
        @{ Name = "npm"; Command = "npm"; VersionArg = "--version" }
        @{ Name = "VS Code CLI"; Command = "code"; VersionArg = "--version" }
        @{ Name = "yo (Yeoman)"; Command = "yo"; VersionArg = "--version" }
        @{ Name = "vsce (VS Code Extension Manager)"; Command = "vsce"; VersionArg = "--version" }
    )

    $results = @()
    foreach ($req in $requirements) {
        $cmd = Get-Command $req.Command -ErrorAction SilentlyContinue
        if ($cmd) {
            $version = & $req.Command $req.VersionArg 2>$null | Select-Object -First 1
            $status = "OK"
        }
        else {
            $version = "未安装"
            $status = "MISSING"
        }
        $results += [PSCustomObject]@{
            Component = $req.Name
            Status    = $status
            Version   = $version
        }
    }

    $results | Format-Table -AutoSize
    $missing = $results | Where-Object { $_.Status -eq "MISSING" }
    if ($missing) {
        Write-Host "`n缺少以下组件：" -ForegroundColor Yellow
        foreach ($m in $missing) {
            Write-Host "  - $($m.Component)" -ForegroundColor Red
        }
    }
    else {
        Write-Host "`n所有组件已就绪！" -ForegroundColor Green
    }
}

Test-VSCodeDevEnvironment
```

执行结果示例：

```text
Component                       Status Version
---------                       ------ -------
Node.js                         OK     v20.11.0
npm                             OK     10.2.4
VS Code CLI                     OK     1.87.0
yo (Yeoman)                     MISSING 未安装
vsce (VS Code Extension Manager) MISSING 未安装

缺少以下组件：
  - yo (Yeoman)
  - vsce (VS Code Extension Manager)
```

当检测到缺少组件时，可以一键安装。Yeoman 和 generator-code 用于生成扩展脚手架，`vsce` 用于打包和发布。

```powershell
# 一键安装缺失的开发依赖
function Install-VSCodeDevDependencies {
    param(
        [switch]$Force
    )

    $packages = @("yo", "generator-code", "@vscode/vsce")

    foreach ($pkg in $packages) {
        $installed = npm list -g $pkg 2>$null | Select-String $pkg
        if ($Force -or -not $installed) {
            Write-Host "正在安装 $pkg ..." -ForegroundColor Cyan
            npm install -g $pkg
        }
        else {
            Write-Host "$pkg 已安装，跳过" -ForegroundColor Gray
        }
    }

    Write-Host "`n依赖安装完成" -ForegroundColor Green
}

Install-VSCodeDevDependencies
```

执行结果示例：

```text
正在安装 yo ...
added 1 package in 3s
正在安装 generator-code ...
added 1 package in 2s
正在安装 @vscode/vsce ...
added 1 package in 4s

依赖安装完成
```

## 项目初始化与脚手架生成

Yeoman 的 VS Code 扩展生成器需要交互式输入。在自动化场景中，我们可以通过 PowerShell 预设所有参数，然后以非交互方式生成项目，实现"一键创建扩展项目"。

```powershell
# 自动化生成 VS Code 扩展脚手架
function New-VSCodeExtension {
    param(
        [Parameter(Mandatory)]
        [string]$Name,

        [string]$DisplayName = $Name,
        [string]$Description = "A VS Code extension",
        [ValidateSet("typescript", "javascript")]
        [string]$Language = "typescript",
        [string]$OutputPath = (Get-Location).Path
    )

    $extensionDir = Join-Path $OutputPath $Name
    if (Test-Path $extensionDir) {
        Write-Host "目录已存在: $extensionDir" -ForegroundColor Red
        return
    }

    # 创建临时目录用于 yo 生成
    $tempDir = Join-Path $env:TEMP "vscode-ext-$Name-$(Get-Random)"
    New-Item -ItemType Directory -Path $tempDir -Force | Out-Null
    Push-Location $tempDir

    try {
        # 构造 yo 的非交互式输入
        # yo code 参数顺序: name, display name, description, git init, pkg manager, language
        $inputs = @(
            $Name,
            $DisplayName,
            $Description,
            "Y",     # 初始化 Git 仓库
            "npm",   # 包管理器
            $Language
        )

        $inputString = $inputs -join "`n"
        Write-Host "正在生成扩展项目: $Name ..." -ForegroundColor Cyan

        $proc = Start-Process -FilePath "yo" `
            -ArgumentList "code" `
            -NoNewWindow -Wait -PassThru `
            -RedirectStandardInput (Write-Output $inputString | Out-File -FilePath "$tempDir\input.txt" -Encoding utf8; "$tempDir\input.txt")

        # 将生成的项目移动到目标位置
        $generated = Get-ChildItem $tempDir -Directory | Select-Object -First 1
        if ($generated) {
            Move-Item $generated.FullName $extensionDir
            Write-Host "扩展项目已创建: $extensionDir" -ForegroundColor Green

            # 安装依赖
            Push-Location $extensionDir
            npm install
            Pop-Location

            Write-Host "`n项目结构:" -ForegroundColor Cyan
            Get-ChildItem $extensionDir -Depth 1 | ForEach-Object {
                $indent = if ($_.PSIsContainer) { "[DIR]  " } else { "[FILE] " }
                Write-Host "  $indent $($_.Name)"
            }
        }
    }
    finally {
        Pop-Location
        if (Test-Path $tempDir) {
            Remove-Item $tempDir -Recurse -Force -ErrorAction SilentlyContinue
        }
    }
}

New-VSCodeExtension -Name "my-hello-extension" `
    -DisplayName "My Hello Extension" `
    -Description "A simple hello world extension"
```

执行结果示例：

```text
正在生成扩展项目: my-hello-extension ...

added 156 packages in 8s

扩展项目已创建: /home/user/my-hello-extension

项目结构:
  [DIR]  src
  [FILE] .gitignore
  [FILE] .vscodeignore
  [FILE] CHANGELOG.md
  [FILE] LICENSE
  [FILE] README.md
  [FILE] package.json
  [FILE] tsconfig.json
  [FILE] vsc-extension-quickstart.md
```

生成的 `package.json` 是扩展的核心配置文件。我们可以用 PowerShell 读取并修改其中的关键字段，比如自动更新版本号或添加贡献点。

## 构建与打包自动化

VS Code 扩展在开发和发布阶段有不同的构建需求。开发时需要编译 TypeScript 并在本地调试，发布时需要用 `vsce` 打包为 `.vsix` 文件。下面的脚本封装了完整的构建流程。

```powershell
# VS Code 扩展构建与打包
function Build-VSCodeExtension {
    param(
        [Parameter(Mandatory)]
        [string]$ProjectPath,

        [ValidateSet("dev", "prod")]
        [string]$Mode = "dev",

        [string]$OutputPath
    )

    if (-not (Test-Path $ProjectPath)) {
        Write-Host "项目路径不存在: $ProjectPath" -ForegroundColor Red
        return
    }

    Push-Location $ProjectPath
    try {
        # 读取 package.json 获取扩展信息
        $pkg = Get-Content "package.json" -Raw | ConvertFrom-Json
        Write-Host "扩展: $($pkg.displayName) v$($pkg.version)" -ForegroundColor Cyan
        Write-Host "构建模式: $Mode`n"

        # 清理旧的构建产物
        if (Test-Path "out") {
            Remove-Item "out" -Recurse -Force
        }

        # 编译 TypeScript
        Write-Host "[1/3] 编译 TypeScript..." -ForegroundColor Yellow
        npm run compile 2>&1 | ForEach-Object { Write-Host "  $_" }
        if ($LASTEXITCODE -ne 0) {
            Write-Host "编译失败！" -ForegroundColor Red
            return
        }

        # 运行测试（仅 dev 模式）
        if ($Mode -eq "dev") {
            Write-Host "[2/3] 运行测试..." -ForegroundColor Yellow
            npm test 2>&1 | ForEach-Object { Write-Host "  $_" }
        }
        else {
            Write-Host "[2/3] 跳过测试（prod 模式）" -ForegroundColor Gray
        }

        # 打包为 .vsix（仅 prod 模式）
        if ($Mode -eq "prod") {
            Write-Host "[3/3] 打包 .vsix 文件..." -ForegroundColor Yellow
            $vsixOutput = vsce package 2>&1
            $vsixOutput | ForEach-Object { Write-Host "  $_" }

            $vsixFile = Get-ChildItem -Path "." -Filter "*.vsix" |
                Sort-Object LastWriteTime -Descending |
                Select-Object -First 1

            if ($vsixFile -and $OutputPath) {
                $dest = Join-Path $OutputPath $vsixFile.Name
                Move-Item $vsixFile.FullName $dest -Force
                Write-Host "`n已输出: $dest" -ForegroundColor Green
            }
            elseif ($vsixFile) {
                Write-Host "`n已生成: $($vsixFile.FullName)" -ForegroundColor Green
                Write-Host "文件大小: $([math]::Round($vsixFile.Length / 1KB, 2)) KB" -ForegroundColor Gray
            }
        }
        else {
            Write-Host "[3/3] 开发构建完成，跳过打包" -ForegroundColor Gray
        }

        Write-Host "`n构建成功！" -ForegroundColor Green
    }
    finally {
        Pop-Location
    }
}

Build-VSCodeExtension -ProjectPath "./my-hello-extension" -Mode prod
```

执行结果示例：

```text
扩展: My Hello Extension v0.0.1
构建模式: prod

[1/3] 编译 TypeScript...
  src/extension.ts -> out/extension.js
[2/3] 跳过测试（prod 模式）
[3/3] 打包 .vsix 文件...
  DONE  Packaged: my-hello-extension-0.0.1.vsix (3.14 KB)

已生成: /home/user/my-hello-extension/my-hello-extension-0.0.1.vsix
文件大小: 3.14 KB

构建成功！
```

## 版本管理与发布

扩展的版本管理需要遵循语义化版本规范。以下脚本实现了版本号自动递增、Git 打标签、打包并发布到 VS Code Marketplace 的完整流程。

```powershell
# VS Code 扩展版本管理与发布
function Publish-VSCodeExtension {
    param(
        [Parameter(Mandatory)]
        [string]$ProjectPath,

        [Parameter(Mandatory)]
        [ValidateSet("patch", "minor", "major")]
        [string]$VersionBump,

        [string]$PersonalAccessToken,

        [switch]$DryRun
    )

    Push-Location $ProjectPath
    try {
        $pkg = Get-Content "package.json" -Raw | ConvertFrom-Json
        $oldVersion = $pkg.version
        $parts = $oldVersion.Split(".")
        $major = [int]$parts[0]
        $minor = [int]$parts[1]
        $patch = [int]$parts[2]

        switch ($VersionBump) {
            "patch" { $patch++ }
            "minor" { $minor++; $patch = 0 }
            "major" { $major++; $minor = 0; $patch = 0 }
        }

        $newVersion = "$major.$minor.$patch"
        Write-Host "版本变更: $oldVersion -> $newVersion" -ForegroundColor Cyan

        if ($DryRun) {
            Write-Host "[DryRun] 仅显示操作，不执行" -ForegroundColor Yellow
            Write-Host "  - 更新 package.json 版本号"
            Write-Host "  - Git commit & tag v$newVersion"
            Write-Host "  - vsce publish"
            return
        }

        # 更新 package.json 中的版本号
        $pkg.version = $newVersion
        $pkg | ConvertTo-Json -Depth 10 | Set-Content "package.json" -Encoding UTF8
        Write-Host "[1/4] 已更新 package.json" -ForegroundColor Green

        # 更新 CHANGELOG
        $changelogPath = "CHANGELOG.md"
        $date = Get-Date -Format "yyyy-MM-dd"
        $newEntry = "## [$newVersion] - $date`n`n- Updated extension`n"
        if (Test-Path $changelogPath) {
            $content = Get-Content $changelogPath -Raw
            $content = $content -replace "(## \[Unreleased\]|^#)", "`$0`n$newEntry"
            Set-Content $changelogPath $content -Encoding UTF8
        }
        Write-Host "[2/4] 已更新 CHANGELOG.md" -ForegroundColor Green

        # Git 提交和打标签
        git add package.json CHANGELOG.md
        git commit -m "chore: bump version to $newVersion"
        git tag "v$newVersion"
        Write-Host "[3/4] Git commit & tag 完成" -ForegroundColor Green

        # 发布到 Marketplace
        if ($PersonalAccessToken) {
            $env:VSCE_PAT = $PersonalAccessToken
        }
        vsce publish $newVersion 2>&1 | ForEach-Object { Write-Host "  $_" }
        Write-Host "[4/4] 发布完成！" -ForegroundColor Green

        Write-Host "`n扩展 $newVersion 已发布到 VS Code Marketplace" -ForegroundColor Green
    }
    finally {
        Pop-Location
    }
}

# 预演模式：查看操作但不执行
Publish-VSCodeExtension -ProjectPath "./my-hello-extension" `
    -VersionBump patch -DryRun

# 正式发布（需要提供 PAT）
# Publish-VSCodeExtension -ProjectPath "./my-hello-extension" `
#     -VersionBump patch `
#     -PersonalAccessToken "your-pat-here"
```

执行结果示例：

```text
版本变更: 0.0.1 -> 0.0.2
[DryRun] 仅显示操作，不执行
  - 更新 package.json 版本号
  - Git commit & tag v0.0.2
  - vsce publish
```

去掉 `-DryRun` 并提供 Personal Access Token 后，脚本将自动完成版本递增、Git 打标签和 Marketplace 发布。

## 注意事项

- **Node.js 版本兼容性**：VS Code 扩展开发推荐使用 LTS 版本的 Node.js（v18 或 v20）。过高或过低的版本可能导致编译失败或运行时不兼容。使用 `nvm` 或 `fnm` 管理多版本 Node.js 是比较好的实践。
- **vsce 安全性**：发布扩展时需要提供 Personal Access Token（PAT）。切勿将 PAT 硬编码在脚本中，应通过环境变量、Azure Key Vault 或交互式提示获取。PAT 应设置最小权限和有效期。
- **TypeScript 严格模式**：建议在 `tsconfig.json` 中开启 `strict: true`。VS Code 扩展 API 的类型定义非常完善，严格模式可以在编译阶段捕获大量潜在问题，减少运行时错误。
- **扩展清单校验**：发布前务必检查 `package.json` 中的必填字段（`name`、`displayName`、`description`、`version`、`engines.vscode`、`categories`、`keywords`、`icon`）。缺少这些字段可能导致 Marketplace 审核不通过或扩展显示异常。
- **.vscodeignore 配置**：正确配置 `.vscodeignore` 文件，排除 `src/`、`tsconfig.json`、`.eslintrc.*` 等开发文件，只打包编译后的 `out/` 目录和必要资源，可以有效减小 `.vsix` 文件体积。
- **CI/CD 集成**：将构建和发布脚本集成到 GitHub Actions 或 Azure Pipeline 中，可以实现提交代码后自动编译、测试、打包。发布操作建议设置为手动触发，避免误操作将未就绪的版本推送到 Marketplace。
