---
layout: post
date: 2019-05-21 00:00:00
title: "PowerShell 技能连载 - 用聪明的方法指定位标志"
description: PowerTip of the Day - Specifying Bit Flags Smart
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
在前一个技能中我们学习了如何在 PowerShell 中启用所有的 SSL 安全协议来连接到 Web Service 和 网站：

```powershell
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Ssl3 -bor [Net.SecurityProtocolType]::Tls -bor [Net.SecurityProtocolType]::Tls11 -bor [Net.SecurityProtocolType]::Tls12
```

有趣的是，可以用一行更短的代码来代替：

```powershell
[Net.ServicePointManager]::SecurityProtocol = 'Ssl3, Tls, Tls11, Tls12'
```

以下是它的原因：

由于 `SecurityProtocol` 是 `Net.SecurityProtocolType` 类型的，所以当您传入字符串数据，它可以自动转换：

```powershell
PS> [Net.ServicePointManager]::SecurityProtocol.GetType().FullName
System.Net.SecurityProtocolType
```

与其用 `SecurityProtocolType` 枚举并且用 -bor 操作符来连接，您还可以用比特标志位的名称组成的逗号分隔的字符串。两者是相同的：

```powershell
$a = [Net.SecurityProtocolType]::Ssl3 -bor [Net.SecurityProtocolType]::Tls -bor [Net.SecurityProtocolType]::Tls11 -bor [Net.SecurityProtocolType]::Tls12
$b = [Net.SecurityProtocolType]'Ssl3, Tls, Tls11, Tls12'



PS> $a -eq $b
True
```

<!--本文国际来源：[Specifying Bit Flags Smart](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/specifying-bit-flags-smart)-->

