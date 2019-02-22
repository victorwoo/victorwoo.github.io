---
layout: post
date: 2017-06-26 00:00:00
title: "PowerShell 技能连载 - 清空 DNS 缓存"
description: PowerTip of the Day - Flush DNS Cache
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
Windows 使用了 DNS 缓存技术，如果改变了 DNS 服务器，您需要刷新 DNS 缓存以使新的设置生效。PowerShell 对传统的控制台命令是有好的，所以只需要在 PowerShell 中运行这行代码：

```powershell
    PS> ipconfig /flushdns
```

<!--本文国际来源：[Flush DNS Cache](http://community.idera.com/powershell/powertips/b/tips/posts/flush-dns-cache)-->
