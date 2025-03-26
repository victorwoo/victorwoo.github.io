---
layout: post
date: 2023-01-27 06:00:50
title: "PowerShell 技能连载 - 导出 Edge 的 Cookie"
description: PowerTip of the Day - Dumping Edge Cookies
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
如果您希望查找或者导出 Edge 浏览器存储的网站 cookie，PowerShell 可以帮您导出以上信息。cookie 列表实际上存储在一个 SQLite 数据库的 "Cookies" 表中。

从 PowerShellGallery.com 安装了 "ReallySimpleDatabase" 免费模块之后，连接和读取数据库十分容易：

```powershell
#requires -Modules ReallySimpleDatabase

<#
make sure you install the required module before you run this script:
Install-Module -Name ReallySimpleDatabase -Scope CurrentUser
#>

$path = "$env:LOCALAPPDATA\Microsoft\Edge\User Data\Default\Network\Cookies"

$db = Get-Database -Path $PATH

$db.InvokeSql('select * from cookies') |
    Select-Object host_key, name
```
<!--本文国际来源：[Dumping Edge Cookies](https://blog.idera.com/database-tools/powershell/powertips/dumping-edge-cookies/)-->

