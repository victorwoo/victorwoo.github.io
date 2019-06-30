---
layout: post
date: 2019-06-28 00:00:00
title: "PowerShell 技能连载 - 啤酒挑战结果：最短的密码分析代码"
description: 'PowerTip of the Day - Beer Challenge Results: Shortest Code for Password Analysis'
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
最近在 psconf.eu 上有一个挑战，用最短的代码来检查以前密码被入侵的频率。以下是结果（感谢 Daniel Rothgänger）：

```powershell
[Net.ServicePointManager]::SecurityProtocol='Tls12''P@ssw0rd'|sc p -N;$a,$b=(FileHash p -A SHA1|% h\*)-split'(?<=^.{5})';((irm api.pwnedpasswords.com/range/$a)-split"$b`:(\d+)")[1]
```

您可以用这段代码做为思维游戏来了解它的功能，或者简单地使用它：它接受一个密码（在我们的示例中是“P@ssw0rd”）并返回一个数字。这个数字是这个特定密码在以前的攻击中出现的频率。任何被看到的密码都被认为是不安全的。只有不返回数字的密码才是安全的。

<!--本文国际来源：[Beer Challenge Results: Shortest Code for Password Analysis](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/beer-challenge-results-shortest-code-for-password-analysis)-->

