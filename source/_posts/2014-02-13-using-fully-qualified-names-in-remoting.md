layout: post
title: "PowerShell 技能连载 - 在 Remoting 中使用完整限定名"
date: 2014-02-13 00:00:00
description: PowerTip of the Day - Using Fully Qualified Names in Remoting
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
当您尝试使用 PowerShell Remoting 时，您也许会因为您使用的机器名不是完整限定名而导致连接错误。Kerberos 验证可能需要也可能不需要使用完整限定名，这取决于您的 DNS 配置。

所以也许您使用如下方式连接的时候会发生错误：

	Enter-PSSession -ComputerName storage1

当发生错误的时候，请向 DNS 查询完整限定名：

	[System.Net.Dns]::GetHostByName('storage1').HostName

然后，用查出的名字来代替主机名。如果主机启用了 Remoting 并且正确地配置了，您现在应该可以连上了。

<!--more-->
本文国际来源：[Using Fully Qualified Names in Remoting](http://community.idera.com/powershell/powertips/b/tips/posts/using-fully-qualified-names-in-remoting)
