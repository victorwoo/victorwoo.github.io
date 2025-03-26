---
layout: post
date: 2025-01-07 08:00:00
title: "PowerShell 技能连载 - 文件系统操作技巧"
description: PowerTip of the Day - PowerShell File System Operations Tips
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
在 PowerShell 中处理文件系统操作是一项基础但重要的任务。本文将介绍一些实用的文件系统操作技巧。

首先，让我们看看文件系统的基本操作：

```powershell
# 创建目录结构
$basePath = "C:\Projects\MyApp"
$directories = @(
    "src",
    "src\components",
    "src\utils",
    "tests",
    "docs"
)

foreach ($dir in $directories) {
    $path = Join-Path $basePath $dir
    New-Item -ItemType Directory -Path $path -Force
    Write-Host "创建目录：$path"
}
```

文件复制和移动：

```powershell
# 批量复制文件
$sourceDir = "C:\SourceFiles"
$targetDir = "D:\Backup"
$filePattern = "*.docx"

# 获取文件列表
$files = Get-ChildItem -Path $sourceDir -Filter $filePattern -Recurse

foreach ($file in $files) {
    # 保持目录结构
    $relativePath = $file.FullName.Substring($sourceDir.Length)
    $targetPath = Join-Path $targetDir $relativePath
    
    # 创建目标目录
    $targetDirPath = Split-Path -Parent $targetPath
    New-Item -ItemType Directory -Path $targetDirPath -Force
    
    # 复制文件
    Copy-Item -Path $file.FullName -Destination $targetPath
    Write-Host "已复制：$($file.Name) -> $targetPath"
}
```

文件内容处理：

```powershell
# 批量处理文件内容
$sourceFiles = Get-ChildItem -Path "C:\Logs" -Filter "*.log"

foreach ($file in $sourceFiles) {
    # 读取文件内容
    $content = Get-Content -Path $file.FullName -Raw
    
    # 处理内容（示例：替换特定文本）
    $newContent = $content -replace "ERROR", "错误"
    $newContent = $newContent -replace "WARNING", "警告"
    
    # 保存处理后的内容
    $newPath = Join-Path $file.Directory.FullName "processed_$($file.Name)"
    $newContent | Set-Content -Path $newPath -Encoding UTF8
}
```

文件系统监控：

```powershell
# 创建文件系统监控函数
function Watch-FileSystem {
    param(
        [string]$Path,
        [string]$Filter = "*.*",
        [int]$Duration = 300
    )
    
    $watcher = New-Object System.IO.FileSystemWatcher
    $watcher.Path = $Path
    $watcher.Filter = $Filter
    $watcher.IncludeSubdirectories = $true
    $watcher.EnableRaisingEvents = $true
    
    Write-Host "开始监控目录：$Path"
    Write-Host "监控时长：$Duration 秒"
    
    # 定义事件处理
    $action = {
        $event = $Event.SourceEventArgs
        $changeType = $event.ChangeType
        $name = $event.Name
        $path = $event.FullPath
        
        Write-Host "`n检测到变化："
        Write-Host "类型：$changeType"
        Write-Host "文件：$name"
        Write-Host "路径：$path"
    }
    
    # 注册事件
    Register-ObjectEvent -InputObject $watcher -EventName Created -Action $action
    Register-ObjectEvent -InputObject $watcher -EventName Changed -Action $action
    Register-ObjectEvent -InputObject $watcher -EventName Deleted -Action $action
    Register-ObjectEvent -InputObject $watcher -EventName Renamed -Action $action
    
    # 等待指定时间
    Start-Sleep -Seconds $Duration
    
    # 清理
    $watcher.EnableRaisingEvents = $false
    $watcher.Dispose()
}
```

一些实用的文件系统操作技巧：

1. 文件压缩和解压：
```powershell
# 压缩文件
$sourcePath = "C:\Data"
$zipPath = "C:\Archive\data.zip"

# 创建压缩文件
Compress-Archive -Path "$sourcePath\*" -DestinationPath $zipPath -Force

# 解压文件
$extractPath = "C:\Extracted"
Expand-Archive -Path $zipPath -DestinationPath $extractPath -Force
```

2. 文件权限管理：
```powershell
# 设置文件权限
$filePath = "C:\Sensitive\data.txt"
$acl = Get-Acl -Path $filePath

# 添加新的访问规则
$rule = New-Object System.Security.AccessControl.FileSystemAccessRule(
    "Domain\Users",
    "Read",
    "Allow"
)
$acl.SetAccessRule($rule)

# 应用新的权限
Set-Acl -Path $filePath -AclObject $acl
```

3. 文件系统清理：
```powershell
# 清理临时文件
$tempPaths = @(
    $env:TEMP,
    "C:\Windows\Temp",
    "C:\Users\$env:USERNAME\AppData\Local\Temp"
)

foreach ($path in $tempPaths) {
    Write-Host "`n清理目录：$path"
    $files = Get-ChildItem -Path $path -Recurse -File | 
        Where-Object { $_.LastWriteTime -lt (Get-Date).AddDays(-7) }
    
    foreach ($file in $files) {
        try {
            Remove-Item -Path $file.FullName -Force
            Write-Host "已删除：$($file.Name)"
        }
        catch {
            Write-Host "删除失败：$($file.Name) - $_"
        }
    }
}
```

这些技巧将帮助您更有效地处理文件系统操作。记住，在进行文件系统操作时，始终要注意数据安全性和权限管理。同时，建议在执行批量操作前先进行备份。 