---
layout: post
date: 2020-10-21 00:00:00
title: "PowerShell 技能连载 - 测试应用程序是否存在"
description: PowerTip of the Day - Test Whether Applications Exist
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
这是一段简单的单行代码，可以测试您的系统（或任何其他应用程序）上是否安装了 PowerShell 7：

```powershell
# name of application you want to test
$name = 'pwsh'

# try and find the application. Discard result and errors.
Get-Command -Name $name -ErrorAction Ignore | Out-Null

# if there was an error, the application does not exist
$exists = $?


# output result
"Does $name exist? $exists"
```

本质上，代码使用 `Get-Command` 按名称检查应用程序。 `$env:path` 中列出的文件夹中所安装的所有应用程序都将被识别出来。

如果将 PowerShell 7 安装在 "$env:path" 中列出的默认文件夹之一中，则上面的代码将返回 `$true`。如果尚未安装 PowerShell 7 或将其安装在 `Get-Command` 无法发现的某些专用文件夹中，它将返回 `$false`。

<!--本文国际来源：[Test Whether Applications Exist](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/test-whether-applications-exist)-->

