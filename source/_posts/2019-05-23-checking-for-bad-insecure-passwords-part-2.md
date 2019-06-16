---
layout: post
date: 2019-05-23 00:00:00
title: "PowerShell 技能连载 - 检查坏（不安全的）密码（第 2 部分）"
description: PowerTip of the Day - Checking for Bad (Insecure) Passwords (Part 2)
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
在前一个技能中我们解释了如何用 Web Service 来安全地检测密码并且查明它们是否已被泄漏。

信息安全有关的代码有时经过压缩后看起来是否“有趣”，所以在第一步分钟我们分享了优美的而且可读的代码。而以下是考虑“信息安全”的变体，它展示 PowerShell 代码可以被压缩到什么程度并且可以自动混淆。这段代码返回一个指定的密码被暴露了多少次（如果未曾发现被暴露过，返回 `null`）。

```powershell
$p = 'P@ssw0rd'[Net.ServicePointManager]::SecurityProtocol = 'Tls12'$a,$b = (Get-FileHash -A 'SHA1' -I ([IO.MemoryStream]::new([Text.Encoding]::UTF8.GetBytes($p)))).Hash -split '(?<=^.{5})'(((irm "https://api.pwnedpasswords.com/range/$a" -UseB) -split '\r\n' -like "$b*") -split ':')[-1
```

<!--本文国际来源：[Checking for Bad (Insecure) Passwords (Part 2)](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/checking-for-bad-insecure-passwords-part-2)-->

