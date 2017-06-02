---
layout: post
date: 2014-10-09 11:00:00
title: "PowerShell 技能连载 - 查找文件以及错误信息"
description: PowerTip of the Day - Finding Files plus Errors
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
_适用于 PowerShell 所有版本_

当您使用 `Get-ChildItem` 在目录中递归查找文件时，您有时候会遇到一些权限不足的文件夹。为了禁止错误信息，您可能会使用 `-ErrorAction SilentlyContinue` 的方法。

这是个不错的实践，但是您也许还希望得到一份权限不足的文件夹的清单。

以下是一段在 Windows 文件夹中搜索所有 PowerShell 脚本的脚本。它将这些文件保存在 `$PSScripts` 变量中。同时，它将所有的错误信息记录在 `$ErrorList` 变量中，并列出所有不可存取的文件夹。

    $PSScripts = Get-ChildItem -Path c:\windows -Filter *.ps1 -Recurse -ErrorAction SilentlyContinue -ErrorVariable ErrorList
    
    $ErrorList | ForEach-Object {
      Write-Warning ('Access denied: ' + $_.CategoryInfo.TargetName)
    }

<!--more-->
本文国际来源：[Finding Files plus Errors](http://community.idera.com/powershell/powertips/b/tips/posts/finding-files-plus-errors)
