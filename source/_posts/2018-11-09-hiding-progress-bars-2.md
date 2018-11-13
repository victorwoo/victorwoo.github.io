---
layout: post
date: 2018-11-09 00:00:00
title: "PowerShell 技能连载 - 隐藏进度条"
description: PowerTip of the Day - Hiding Progress Bars
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
有些时候，cmdlet 自动显示一个进度条，以下是一个显示进度条的例子：

```powershell
$url = "http://www.powertheshell.com/reference/wmireference/root/cimv2/"
$page = Invoke-WebRequest -URI $url
```

`Invoke-WebRequest` 获取一个 WEB 页面的原始内容，如果获取内容消耗一定的时间，将会显示进度条。

Whenever you run a cmdlet that shows a progress bar, you can hide the progress bar by temporarily changing the $ProgressPreference variable. Just make sure you restore its original value or else, you permanently hide progress bars for the current PowerShell session:
当您运行一个会显示进度条的 cmdlet，您可以通过临时改变 `$ProgressPreference` 变量来隐藏进度条。只需要记得恢复它的初始值或是设置成其它值，这样就可以针对当前 PowerShell 会话隐藏进度条。

```powershell
$old = $ProgressPreference
$ProgressPreference = "SilentlyContinue"

$url = "http://www.powertheshell.com/reference/wmireference/root/cimv2/"
$page = Invoke-WebRequest -URI $url 

$ProgressPreference = $old
```

除了保存和恢复原始的变量内容，您还可以使用脚本块作用域：

```powershell
& {
    $ProgressPreference = "SilentlyContinue"
    $url = "http://www.powertheshell.com/reference/wmireference/root/cimv2/"
    $page = Invoke-WebRequest -URI $url 
}

$ProgressPreference
```

如您所见，当脚本块执行完之后，原始变量自动恢复原始值。

<!--more-->
本文国际来源：[Hiding Progress Bars](http://community.idera.com/database-tools/powershell/powertips/b/tips/posts/hiding-progress-bars-2)
