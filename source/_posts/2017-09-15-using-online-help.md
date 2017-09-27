---
layout: post
date: 2017-09-15 00:00:00
title: "PowerShell 技能连载 - 使用在线帮助"
description: PowerTip of the Day - Using Online Help
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
PowerShell 的发行版并没有带帮助文件，而本地安装帮助文件需要管理员权限。

更简单的获取帮助的方法是访问 cmdlet 的在线帮助，类似这样：

```powershell
Get-Help -Name Get-Acl -Online
```

这将启动一个浏览器并导航到在线帮助。在线帮助通常内容更新并且更容易获得。当然，它需要 internet 连接，并且并不是每个 cmdlet 都有在线帮助版本。

<!--more-->
本文国际来源：[Using Online Help](http://community.idera.com/powershell/powertips/b/tips/posts/using-online-help)
