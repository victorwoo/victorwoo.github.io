---
layout: post
date: 2022-06-07 00:00:00
title: "PowerShell 技能连载 - 解析 URL"
description: PowerTip of the Day - Resolving URLs
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
URL 并不总是（直接）指向资源。通常，URL 充当始终指向最新版本的快捷方式或静态地址。PowerShell 可以揭示资源的真实URL，您可以在许多情况下使用它。

这是一个如何解析快捷链接的示例：

```powershell
# this is the URL we got:
$URLRaw = 'http://go.microsoft.com/fwlink/?LinkID=135173'
# we do not allow automatic redirection and instead read the information
# returned by the webserver ourselves:
$page = Invoke-WebRequest -Uri $URLRaw -UseBasicParsing -MaximumRedirection 0 -ErrorAction Ignore
$target = $page.Headers.Location

"$URLRaw -> $target" 
```

这是关于如何从静态链接解析产品版本的示例。最新版的 PowerShell 总是可以使用此静态 URL 获取：

[https://github.com/PowerShell/PowerShell/releases/latest](https://github.com/PowerShell/PowerShell/releases/latest)

如果您想知道最新版本的实际版本号，请尝试解析 URL：

```powershell
$URLRaw = 'https://github.com/PowerShell/PowerShell/releases/latest'
# we do not allow automatic redirection and instead read the information
# returned by the webserver ourselves:
$page = Invoke-WebRequest -Uri $URLRaw -UseBasicParsing -MaximumRedirection 0 -ErrorAction Ignore
$realURL = $page.Headers.Location
$version = Split-Path -Path $realURL -Leaf 

"PowerShell 7 latest version: $version"
```

同样的方法也适用于 PowerShell Gallery 模块：

```powershell
# name of a module published at powershellgallery.com
$ModuleName = 'ImportExcel'

$URL = "https://www.powershellgallery.com/packages/$ModuleName"
# get full URL (including latest version):
$page = Invoke-WebRequest -Uri $URL -UseBasicParsing -MaximumRedirection 0 -ErrorAction Ignore
$realURL = $page.Headers.Location
# return version only:
$latest = Split-Path -Path $realURL -Leaf
"Module $ModuleName latest version: $latest"
```

<!--本文国际来源：[Resolving URLs](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/resolving-urls-3)-->

