---
layout: post
date: 2020-06-19 00:00:00
title: "PowerShell 技能连载 - 使用断言"
description: PowerTip of the Day - Using Assertions
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
通常，您的代码需要声明某些先决条件。例如，您可能要确保给定的文件夹存在，并使用如下代码：

```powershell
# path to download files to
$OutPath = "$env:temp\SampleData"

# does it already exist?
$exists = Test-Path -Path $OutPath -PathType Container

# no, create it
if (!$exists)
{
  $null = New-Item -Path $OutPath -ItemType Directory
}
```

您可以开始使用断言函数库，而不必一遍又一遍地写代码。这是确保文件夹存在的一种：

```powershell
filter Assert-FolderExists
{
  $exists = Test-Path -Path $_ -PathType Container
  if (!$exists) {
    Write-Warning "$_ did not exist. Folder created."
    $null = New-Item -Path $_ -ItemType Directory
  }
}
```

使用此函数，您的代码将变得更加整洁。这些代码将文件夹路径分配给变量，并同时确保文件夹存在：

```powershell
# making sure a bunch of folders exist
'C:\test1', 'C:\test2' | Assert-FolderExists

# making sure the path assigned to a variable exists
($Path = 'c:\test3') | Assert-FolderExists
```

Read more about this technique here: [https://powershell.one/code/10.html](https://powershell.one/code/10.html).

在此处阅读有关此技术的更多信息：<https://powershell.one/code/10.html>。

<!--本文国际来源：[Using Assertions](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/using-assertions)-->

