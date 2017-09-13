---
layout: post
date: 2017-09-01 00:00:00
title: "PowerShell 技能连载 - 注册缺省的 PowerShell 源"
description: PowerTip of the Day - Registering Default PowerShell Repository
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
如果您使用 PowerShellGet 模块（默认随着 Windows 10 和 Server 2016 分发），您可以方便地下载和安装共享的 PowerShell 脚本和模块：

```powershell
    PS> Find-Module -Tag Security

    Version    Name              Repository    Description
    -------    ----              ----------    -----------
    2.5.0      Carbon            PSGallery     Carbon is a PowerShell module for automating t...
    0.8.1      ACMESharp         PSGallery     Client library for the ACME protocol, which is...
    2.22       DSInternals       PSGallery     The DSInternals PowerShell Module exposes seve...
    1.2.0.0    DSCEA             PSGallery     DSCEA is a scanning engine for processing Test...
```

不过有些时候，机器上缺失了缺省的 PSGallery 源，要还原缺省设置，请使用以下代码：

```powershell
    PS> Register-PSRepository -Default
```

<!--more-->
本文国际来源：[Registering Default PowerShell Repository](http://community.idera.com/powershell/powertips/b/tips/posts/registering-default-powershell-repository)
