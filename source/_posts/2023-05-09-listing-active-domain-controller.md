---
layout: post
date: 2023-05-09 00:00:37
title: "PowerShell 技能连载 - 列出活动的域控制器"
description: PowerTip of the Day - Listing Active Domain Controller
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
如果您的计算机连接到域，您可以使用 PowerShell 来识别您所连接的域控制器。可以使用以下命令：

```powershell
Get-ADDomainController -Discover
```

或者，简单地查找 "LOGONSERVER" 环境变量：

```powershell
$env:LOGONSERVER
```

它会列出您登录的计算机名称。如果它等于自己的计算机名称（不带反斜杠），则表示已本地登录而非加入域：

```powershell
if ($env:LOGONSERVER.TrimStart('\') -eq $env:COMPUTERNAME)
{
    "local"
}
else
{
    "logged on to $env:LOGONSERVER"
}
```
<!--本文国际来源：[Listing Active Domain Controller](https://blog.idera.com/database-tools/powershell/powertips/listing-active-domain-controller/)-->

