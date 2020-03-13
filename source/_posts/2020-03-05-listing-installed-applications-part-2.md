---
layout: post
date: 2020-03-05 00:00:00
title: "PowerShell 技能连载 - 列出安装的应用程序（第 2 部分）"
description: PowerTip of the Day - Listing Installed Applications (Part 2)
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
在上一个技能中，我们读取了注册表，以查找可以启动的应用程序的路径。这种方法效果很好，但存在两个缺陷：首先，列表不包含应用程序的友好名称，其次，列表不完整。仅列出已注册的程序。

让我们获得完整的应用程序列表，并使用三个技巧来克服这些限制：

* 使用 generic list 作为结果，以便能够将更多信息快速添加到列表中
* 将 `Get-Command` 的结果合并到 PowerShell 已知的应用程序中
* 读取扩展文件信息得到应用程序友好名称

我们从这里开始：从注册表中注册的应用程序列表：

```powershell
$key = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\*",
    "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\*"

[System.Collections.Generic.List[string]]$list =
Get-ItemProperty -Path $key |
Select-Object -ExpandProperty '(Default)' -ErrorAction Ignore

$list
```

现在，我们将 `Get-Command` 已知的应用程序添加到列表中：

```powershell
[System.Collections.Generic.List[string]]$commands =
    Get-Command -CommandType Application |
    Select-Object -ExpandProperty Source

$list.AddRange($commands)
```

最后，删除引号，空的和重复的项目来清理列表：

```powershell
$finalList = $list |
    Where-Object { $_ } |
    ForEach-Object { $_.Replace('"','').Trim().ToLower() } |
    Sort-Object -Unique
```

现在，通过读取每个文件的扩展信息，将列表变成具有应用程序名称、描述和绝对路径的对象。这也消除了所有不存在的路径。以下是完整的代码：

```powershell
$key = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\*",
    "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\*"

[System.Collections.Generic.List[string]]$list =
Get-ItemProperty -Path $key |
Select-Object -ExpandProperty '(Default)' -ErrorAction Ignore

[System.Collections.Generic.List[string]]$commands = Get-Command -CommandType Application |
                Select-Object -ExpandProperty Source

$list.AddRange($commands)

$finalList = $list |
    Where-Object { $_ } |
    ForEach-Object { $_.Replace('"','').Trim().ToLower() } |
    Sort-Object -Unique |
    ForEach-Object {
        try {
            $file = Get-Item -Path $_ -ErrorAction Ignore
            [PSCustomObject]@{
                Name = $file.Name
                Description = $file.VersionInfo.FileDescription
                Path = $file.FullName
            }
        } catch {}
    } |
    Sort-Object -Property Name -Unique

$finalList | Out-GridView -PassThru
```

结果类似这样：

```powershell
PS> $finalList

Name                                           Description
----                                           -----------
7zfm.exe                                       7-Zip File Manager
accicons.exe                                   Microsoft Office component
acrord32.exe                                   Adobe Acrobat Reader DC
agentservice.exe                               AgentService EXE
aitstatic.exe                                  Application Impact Telemetry...
```

<!--本文国际来源：[Listing Installed Applications (Part 2)](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/listing-installed-applications-part-2)-->

