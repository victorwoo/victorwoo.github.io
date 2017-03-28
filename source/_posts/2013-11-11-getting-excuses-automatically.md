layout: post
title: "PowerShell 技能连载 - 自动找借口的脚本"
date: 2013-11-11 00:00:00
description: PowerTip of the Day - Getting Excuses Automatically
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
> 译者注：**您没有看错！这是近期最邪恶的一个技巧，文末有译者机器上的实验效果。**

厌倦了每次自己想蹩脚的借口？以下脚本能让您每调用一次 `Get-Excuse` 就得到一个新的接口！您所需的一切只是 Internet 连接：

	function Get-Excuse
	{
	  $url = 'http://pages.cs.wisc.edu/~ballard/bofh/bofhserver.pl'
	  $ProgressPreference = 'SilentlyContinue'
	  $page = Invoke-WebRequest -Uri $url -UseBasicParsing
	  $pattern = '<br><font size = "\+2">(.+)'
	
	  if ($page.Content -match $pattern)
	  {
	    $matches[1]
	  }
	} 

如果您需要通过代理服务器或者身份认证来访问 Internet，那么请查看函数中 `Invoke-WebRequest` 的参数。您可以通过它提交代理服务器信息，例如身份验证信息。

> 译者注：以下是 `Get-Excuse` 为笔者找的“借口”，很有创意吧 ;-)

	PS >Get-Excuse
	your process is not ISO 9000 compliant
	PS >Get-Excuse
	evil hackers from Serbia.
	PS >Get-Excuse
	piezo-electric interference
	PS >Get-Excuse
	Bogon emissions
	PS >Get-Excuse
	because Bill Gates is a Jehovah's witness and so nothing can work on St. Swithin's day.
	PS >Get-Excuse
	Your cat tried to eat the mouse.
	PS >Get-Excuse
	It works the way the Wang did, what's the problem
	PS >Get-Excuse
	Telecommunications is upgrading.
	PS >Get-Excuse
	Your computer's union contract is set to expire at midnight.
	PS >Get-Excuse
	Daemon escaped from pentagram
	PS >Get-Excuse
	nesting roaches shorted out the ether cable
	PS >Get-Excuse
	We ran out of dial tone and we're and waiting for the phone company to deliver another bottle.
	PS >Get-Excuse
	Root nameservers are out of sync

<!--more-->
本文国际来源：[Getting Excuses Automatically](http://community.idera.com/powershell/powertips/b/tips/posts/getting-excuses-automatically)
