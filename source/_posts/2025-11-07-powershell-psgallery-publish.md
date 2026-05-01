---
layout: post
date: 2025-11-07 08:00:00
title: "PowerShell 技能连载 - PowerShell Gallery 发布"
description: PowerTip of the Day - Publishing to PowerShell Gallery
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
- psgallery
- publishing
- module
- nuget
---

_适用于 PowerShell 5.1 及以上版本_

PowerShell Gallery（www.powershellgallery.com）是微软官方维护的 PowerShell 模块和脚本共享平台，类似于 Node.js 的 npm 或 Python 的 PyPI。通过它，你可以将自己编写的模块分发给全球的 PowerShell 用户，也可以方便地安装其他人发布的工具。对于团队协作而言，将内部通用组件发布到私有 Gallery 或公开 Gallery，能够显著提升代码复用率和团队协作效率。

本文将从模块准备、API Key 管理、发布流程以及版本更新四个环节，完整介绍如何将一个自定义 PowerShell 模块发布到 PowerShell Gallery。无论你是开源项目维护者还是企业内部工具开发者，掌握这一流程都能让你的 PowerShell 代码分发更加规范和专业。

## 准备模块清单文件

PowerShell Gallery 要求发布的模块必须包含模块清单文件（`.psd1`）。清单文件中定义了模块的元数据，包括版本号、作者、描述、依赖项等信息。其中一些字段是 Gallery 发布的必填项，缺少这些字段会导致发布失败。

使用 `New-ModuleManifest` 可以快速创建一个标准的清单文件：

```powershell
# 创建模块目录结构
$modulePath = Join-Path -Path $env:USERPROFILE -ChildPath "Documents\PowerShell\Modules\MyUtils"
if (-not (Test-Path -Path $modulePath)) {
    New-Item -Path $modulePath -ItemType Directory -Force | Out-Null
    Write-Host "已创建模块目录: $modulePath"
}

# 创建模块清单
$manifestParams = @{
    Path               = Join-Path -Path $modulePath -ChildPath "MyUtils.psd1"
    RootModule         = "MyUtils.psm1"
    ModuleVersion      = "1.0.0"
    Author             = "Your Name"
    CompanyName        = "Your Company"
    Description        = "A collection of utility functions for daily PowerShell tasks"
    PowerShellVersion  = "5.1"
    FunctionsToExport  = @("Get-SystemReport", "Invoke-HealthCheck")
    CmdletsToExport    = @()
    VariablesToExport  = @()
    AliasesToExport    = @()
    Tags               = @("Utility", "Automation", "Monitoring")
    ProjectUri         = "https://github.com/yourname/MyUtils"
    LicenseUri         = "https://github.com/yourname/MyUtils/blob/main/LICENSE"
    ReleaseNotes       = "Initial release with system report and health check functions."
}

New-ModuleManifest @manifestParams
Write-Host "模块清单已创建"
```

执行结果示例：

```text
已创建模块目录: C:\Users\admin\Documents\PowerShell\Modules\MyUtils
模块清单已创建
```

清单中 `Tags`、`ProjectUri`、`LicenseUri` 和 `ReleaseNotes` 这几个字段虽然不是 `New-ModuleManifest` 的必需参数，但 PowerShell Gallery 发布时会检查它们。缺失这些字段虽然不会阻止发布，但会严重影响模块在 Gallery 中的可发现性和用户体验。建议在发布前使用 `Test-ModuleManifest` 验证清单文件的完整性。

## 获取并配置 API Key

发布模块到 PowerShell Gallery 需要一个 API Key。你需要先在 powershellgallery.com 注册账户（支持 Microsoft 账户或 GitHub 账户登录），然后在账户设置中生成 API Key。API Key 本质上是一个 NuGet API Key，PowerShell Gallery 底层基于 NuGet 协议运行。

为了安全起见，不要将 API Key 硬编码在脚本中。推荐的做法是将 Key 保存到环境变量或凭据管理器中：

```powershell
# 检查是否已配置 API Key 环境变量
if ($env:PSGALLERY_API_KEY) {
    Write-Host "API Key 已配置，长度: $($env:PSGALLERY_API_KEY.Length) 个字符"
}
else {
    Write-Host "尚未配置 PSGALLERY_API_KEY 环境变量"
    Write-Host "请按以下步骤操作："
    Write-Host "  1. 访问 https://www.powershellgallery.com/users/account/LogOn"
    Write-Host "  2. 登录后进入 API Keys 页面"
    Write-Host "  3. 点击 Create 生成新的 API Key"
    Write-Host "  4. 将 Key 保存为环境变量:"
    Write-Host '     [Environment]::SetEnvironmentVariable("PSGALLERY_API_KEY", "your-key-here", "User")'
}

# 永久保存 API Key 到用户级环境变量（只需执行一次）
# [Environment]::SetEnvironmentVariable("PSGALLERY_API_KEY", "your-api-key", "User")
```

执行结果示例：

```text
尚未配置 PSGALLERY_API_KEY 环境变量
请按以下步骤操作：
  1. 访问 https://www.powershellgallery.com/users/account/LogOn
  2. 登录后进入 API Keys 页面
  3. 点击 Create 生成新的 API Key
  4. 将 Key 保存为环境变量:
     [Environment]::SetEnvironmentVariable("PSGALLERY_API_KEY", "your-key-here", "User")
```

API Key 生成时可以选择过期时间和作用域。建议使用最小权限原则：如果只需要推送特定模块，就创建限定到该模块名称的 Key，而不是创建全权限 Key。这样即使 Key 泄露，影响范围也可以控制。

## 发布模块到 Gallery

一切准备就绪后，使用 `Publish-Module` 命令将模块发布到 PowerShell Gallery。发布前务必在本地完整测试模块功能，因为一旦发布，版本号就不可重复使用——如果你发布了 1.0.0 版本后发现 bug，只能通过发布 1.0.1 等新版本修复，无法覆盖 1.0.0。

```powershell
# 发布前的预检查
$modulePath = Join-Path -Path $env:USERPROFILE -ChildPath "Documents\PowerShell\Modules\MyUtils"

# 验证清单文件
$manifest = Test-ModuleManifest -Path (Join-Path -Path $modulePath -ChildPath "MyUtils.psd1")
if ($manifest) {
    Write-Host "模块名称: $($manifest.Name)"
    Write-Host "版本号: $($manifest.Version)"
    Write-Host "导出函数: $($manifest.ExportedFunctions.Keys -join ', ')"
}

# 发布模块
$publishParams = @{
    Path        = $modulePath
    NuGetApiKey = $env:PSGALLERY_API_KEY
    Repository  = "PSGallery"
    Verbose     = $true
}

Publish-Module @publishParams
Write-Host "模块已成功发布到 PowerShell Gallery！"
```

执行结果示例：

```text
模块名称: MyUtils
版本号: 1.0.0
导出函数: Get-SystemReport, Invoke-HealthCheck
VERBOSE: Successfully created an API key for PSGallery.
VERBOSE: Attempting to publish module 'MyUtils' version '1.0.0' to 'PSGallery'.
VERBOSE: Successfully published module 'MyUtils' version '1.0.0' to 'PSGallery'.
模块已成功发布到 PowerShell Gallery！
```

发布成功后，模块通常在几分钟内就能在 PowerShell Gallery 上搜索到。其他用户可以通过 `Install-Module -Name MyUtils` 直接安装使用。

## 验证发布结果

发布完成后，应当验证模块在 Gallery 上的展示效果。可以通过命令行查询，也可以在浏览器中直接访问模块页面，检查描述、标签、项目链接等信息是否正确显示。

```powershell
# 通过命令行验证模块是否已上线
$published = Find-Module -Name "MyUtils" -Repository PSGallery

if ($published) {
    Write-Host "模块已上线！"
    Write-Host "  名称: $($published.Name)"
    Write-Host "  版本: $($published.Version)"
    Write-Host "  描述: $($published.Description)"
    Write-Host "  作者: $($published.Author)"
    Write-Host "  下载量: $($published.AdditionalMetadata['versionDownloadCount'])"
    Write-Host "  页面: https://www.powershellgallery.com/packages/$($published.Name)/$($published.Version)"
}
else {
    Write-Host "警告: 未在 Gallery 中找到模块，可能需要等待几分钟"
}
```

执行结果示例：

```text
模块已上线！
  名称: MyUtils
  版本: 1.0.0
  描述: A collection of utility functions for daily PowerShell tasks
  作者: Your Name
  下载量: 0
  页面: https://www.powershellgallery.com/packages/MyUtils/1.0.0
```

如果信息有误，可以在修正后发布新版本。已发布的版本无法修改或删除（除非联系 PowerShell Gallery 运维团队）。

## 更新模块版本

当模块修复了 bug 或新增功能后，需要递增版本号并重新发布。PowerShell Gallery 遵循语义化版本（SemVer）规则：主版本号.次版本号.修订号。例如，修复 bug 递增修订号（1.0.0 → 1.0.1），新增功能递增次版本号（1.0.1 → 1.1.0），不兼容的 API 变更递增主版本号（1.1.0 → 2.0.0）。

```powershell
# 更新模块版本号和发布说明
$modulePath = Join-Path -Path $env:USERPROFILE -ChildPath "Documents\PowerShell\Modules\MyUtils"
$manifestPath = Join-Path -Path $modulePath -ChildPath "MyUtils.psd1"

# 读取当前版本并递增修订号
$currentManifest = Test-ModuleManifest -Path $manifestPath
$currentVersion = $currentManifest.Version
$newVersion = [version]::new(
    $currentVersion.Major,
    $currentVersion.Minor,
    $currentVersion.Build + 1
)

Write-Host "当前版本: $currentVersion → 新版本: $newVersion"

# 更新清单中的版本号和发布说明
$updateData = @{
    ModuleVersion = $newVersion.ToString()
    ReleaseNotes  = "Fixed edge case in Get-SystemReport when WMI service is stopped."
}
Update-ModuleManifest -Path $manifestPath @updateData

# 重新发布
Publish-Module -Path $modulePath -NuGetApiKey $env:PSGALLERY_API_KEY -Repository PSGallery
Write-Host "新版本 $newVersion 已发布"
```

执行结果示例：

```text
当前版本: 1.0.0 → 新版本: 1.0.1
VERBOSE: Attempting to publish module 'MyUtils' version '1.0.1' to 'PSGallery'.
VERBOSE: Successfully published module 'MyUtils' version '1.0.1' to 'PSGallery'.
新版本 1.0.1 已发布
```

版本更新后，已安装旧版本的用户通过 `Update-Module -Name MyUtils` 即可获取最新版本。PowerShellGet 会自动处理版本比较和下载安装。

## 自动化发布流程

在 CI/CD 场景中，可以将发布流程集成到 GitHub Actions 或 Azure Pipelines 中，实现提交代码后自动发布新版本。以下是一个使用 PowerShell 脚本在 CI 环境中发布的示例：

```powershell
# 适用于 CI/CD 管道的发布脚本
# 从 git tag 中提取版本号，确保版本号与代码提交严格对应
$gitTag = git describe --tags --abbrev=0 2>$null
if (-not $gitTag) {
    Write-Error "未找到 git tag，请先创建版本标签"
    return
}

# 从 tag 名称中解析版本号（例如 v1.2.3 → 1.2.3）
$versionStr = $gitTag -replace '^v', ""
$newVersion = [version]$versionStr

Write-Host "准备发布版本: $newVersion (from tag: $gitTag)"

# 更新清单
$manifestPath = "./src/MyUtils/MyUtils.psd1"
$releaseNotes = git log --pretty=format:"- %s" ("$($gitTag)~1"..HEAD) 2>$null
if (-not $releaseNotes) {
    $releaseNotes = "Release $newVersion"
}

Update-ModuleManifest -Path $manifestPath -ModuleVersion $newVersion.ToString() -ReleaseNotes $releaseNotes

# 验证清单完整性
$requiredFields = @("Description", "Author", "Tags", "ProjectUri", "LicenseUri")
$manifest = Test-ModuleManifest -Path $manifestPath
$warnings = @()
foreach ($field in $requiredFields) {
    $value = $manifest.$field
    if (-not $value) {
        $warnings += "缺少必填字段: $field"
    }
}

if ($warnings.Count -gt 0) {
    Write-Host "发布前检查警告:"
    foreach ($w in $warnings) {
        Write-Host "  [WARN] $w"
    }
}

# 发布
Publish-Module -Path "./src/MyUtils" -NuGetApiKey $env:PSGALLERY_API_KEY -Repository PSGallery
Write-Host "CI/CD 发布完成: v$newVersion"
```

执行结果示例：

```text
准备发布版本: 1.1.0 (from tag: v1.1.0)
CI/CD 发布完成: v1.1.0
```

将 API Key 存储在 CI/CD 平台的安全变量中（如 GitHub Secrets），确保密钥不会出现在日志和代码仓库中。这种方式适合团队协作开发，每次合并代码后自动触发构建和发布。

## 注意事项

- **版本号不可复用**：PowerShell Gallery 不允许删除已发布的版本，也无法覆盖已有版本号。即使你发布了一个有严重 bug 的版本，该版本号也永久被占用。发布前务必在本地充分测试，确认无误后再推送。
- **清单必填字段**：`Description`、`Author` 是 Gallery 的强制要求字段。虽然 `Tags`、`ProjectUri`、`LicenseUri` 不阻止发布，但缺失这些字段会让模块难以被搜索和信任。建议在 `New-ModuleManifest` 阶段就完整填写所有字段。
- **API Key 安全管理**：不要将 API Key 提交到代码仓库，也不要在聊天记录或日志中明文输出。使用环境变量或 CI/CD 平台的安全变量存储，并为不同用途创建不同作用域的 Key。
- **模块大小限制**：PowerShell Gallery 对单个模块包的大小有限制（目前约 250 MB）。如果你的模块包含大量二进制文件或数据文件，考虑使用外部存储并仅在模块中提供下载脚本。
- **私有 Gallery 部署**：企业内部可以使用 PowerShell Gallery 的私有实例（如基于 NuGet Server 或 Artifactory 搭建），发布流程完全相同，只需通过 `Register-PSRepository` 注册内部仓库地址，然后在 `Publish-Module` 中指定 `-Repository` 参数即可。
- **依赖项声明**：如果模块依赖其他模块，务必在清单中通过 `RequiredModules` 字段声明。这样用户安装你的模块时，PowerShellGet 会自动解析并安装所有依赖，避免因缺少依赖导致模块加载失败。
