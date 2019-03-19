---
layout: post
date: 2015-02-16 12:00:00
title: "PowerShell 技能连载 - 查找所有可停止的服务"
description: 'PowerTip of the Day - Finding All Stoppable Services '
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
_适用于 PowerShell 3.0 及以上版本_

`Get-Service` 可以列出您计算机上所有已安装的服务。不过它没有可以选择仅包含运行或停止的服务的参数。

用一个简单的 `Where-Object` 从句，您可以实现这个目的。最常见的是，您会见到类似如下的用法：

    PS> Get-Service | Where-Object Status -eq Running

基本上，`Where-Object` 可以指定对象拥有的任意属性并且允许您定义需要的条件。

If you planned to get a list of stoppable services, the above line would not work well. Some services may be running but cannot be stopped. By adjusting your filter slightly, you still get what you need. This produces a list of running services that are actually stoppable:
如果您打算获得一个可停止的服务的列表，那么上述代码不能达到您所要的目的。一些服务可能正在运行但是不能被停止。稍微调整一下过滤条件，您就可以达到所要的目的了。这段代码列出所有运行中并且可以停止的服务：

    PS> Get-Service | Where-Object CanStop

并且这种写法缩短了代码量：由于 "`CanStop`" 属性本身是个布尔值（`true` 或 `false`），所以无需使用比较运算符。

要查看这个列表的补集，即所有不可停止的服务，可使用比较运算符：

    PS> Get-Service | Where-Object CanStop -eq $false

请注意用 `Where-Object` 的简化语法，您无法取得相反的结果。以下代码**并不会**生效：

    PS> Get-Service | Where-Object !CanStop

    PS> Get-Service | Where-Object -not CanStop

要使用这些条件，或者要合并比较条件，请使用完整语法：

    PS> Get-Service | Where-Object { !$_.CanStop -and $_.Status -eq 'Running' }

<!--本文国际来源：[Finding All Stoppable Services ](http://community.idera.com/powershell/powertips/b/tips/posts/finding-all-stoppable-services)-->
