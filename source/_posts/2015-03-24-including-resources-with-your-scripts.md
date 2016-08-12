layout: post
date: 2015-03-24 11:00:00
title: "PowerShell 技能连载 - 在脚本中包含资源"
description: PowerTip of the Day - Including Resources with Your Scripts
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
_适用于 PowerShell 3.0 及以上版本_

如果您的脚本需要额外的资源，比如说服务器名列表，图片文件，或是其它内容，那么请确保您的脚本可随处使用。

千万别使用绝对路径来定位资源文件。应使用 PowerShell 3.0 开始提供的 `$PSScriptRoot`（在 PowerShell 2.0 中，`$PSScriptRoot` 只能在模块中使用）。

    $picture = "$PSScriptRoot\Resources\picture.png"
    Test-Path -Path $picture
    
    $data = "$PSScriptRoot\Resources\somedata.txt"
    Get-Content -Path $data

`$PSScriptRoot` 总是指向脚本所在的目录（所以如果脚本尚未保存或是以交互式查询该变量，得到的结果是空）。

<!--more-->
本文国际来源：[Including Resources with Your Scripts](http://powershell.com/cs/blogs/tips/archive/2015/03/24/including-resources-with-your-scripts.aspx)
