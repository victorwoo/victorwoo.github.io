---
layout: post
date: 2016-10-21 00:00:00
title: "PowerShell 技能连载 - PowerShell Remoting and HTTP 403 Error"
description: PowerTip of the Day - PowerShell Remoting and HTTP 403 Error
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
如果您在使用 PowerShell 远程操作时遇到“HTTP 403”错误，一个潜在的原因可能是代理服务器影响了请求。

不过，要禁用代理服务器很容易。只需要在您的呼叫中增加一个 session 选项并且将 `ProxyAccessType` 设置为“`NoProxyServer`”即可：

```powershell
# you are connecting to this computer
# the computer in $destinationcomputer needs to have 
# PowerShell remoting enabled
$DestinationComputer = 'server12'

$option = New-PSSessionOption -ProxyAccessType NoProxyServer

Invoke-Command -ScriptBlock { "Connected to $env:computername" } -ComputerName $DestinationComputer -SessionOption $option
```

<!--more-->
本文国际来源：[PowerShell Remoting and HTTP 403 Error](http://community.idera.com/powershell/powertips/b/tips/posts/powershell-remoting-and-http-403-error)
