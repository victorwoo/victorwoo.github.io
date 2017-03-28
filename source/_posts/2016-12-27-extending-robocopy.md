layout: post
date: 2016-12-27 00:00:00
title: "PowerShell 技能连载 - 扩展 Robocopy"
description: PowerTip of the Day - Extending Robocopy
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
- translation
---
PowerShell 可以向原有的命令（例如 robocopy）添加值。请看以下的函数——它用 robocopy 来拷贝文件，并且当拷贝完成时，增加了“扁平拷贝”选项来打开目标文件夹：

```powershell
#requires -Version 3.0

function Copy-FileWithRobocopy
{
  param
  (
    [Parameter(Mandatory)]
    [string]$Source,

    [Parameter(Mandatory)]
    [string]$Destination,

    [string]$Filter = '*',

    [int]$RetryCount = 0,

    [string]$ExcludeDirectory = '',

    [switch]$Open,

    [switch]$FlatCopy,

    [switch]$NoRecurse 
  )

  $Recurse = '/S'
  if ($NoRecurse) { $Recurse = '' }

  robocopy.exe $Source $Destination $Filter /R:$RetryCount $Recurse /XD $ExcludeDirectory

  if ($FlatCopy)
  {
    Get-ChildItem -Path $Destination -Recurse -Filter $Filter | 
      Move-Item -Destination $Destination -Force
    Get-ChildItem -Path $Destination -Directory | 
      Remove-Item -Recurse -Force
  }

  if ($Open)
  {
    explorer $Destination
  }
}
```

这将会把 Windows 文件夹下所有子文件夹中的 log 文件拷贝到名为 `c:\\logs` 的新文件夹，并且执行扁平化拷贝：

```powershell
PS>  Copy-FileWithRobocopy -Source $env:windir -Destination c:\logs -Filter *.log -FlatCopy -Open
```

当您在生产系统使用这段代码之前，请观察 `-FlatCopy` 是如何工作的：它只是在目标文件夹中查找匹配指定的过滤器，然后将它们移到根目录，最后删除所有文件夹。

所以重复的文件将会被覆盖，而且如果目标文件夹的子文件夹中有其他数据，也会被删除。这是一个很简单的操作，适用于许多情况，但也有很多改进空间。

<!--more-->
本文国际来源：[Extending Robocopy](http://community.idera.com/powershell/powertips/b/tips/posts/extending-robocopy)
