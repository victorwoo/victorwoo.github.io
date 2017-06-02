---
layout: post
date: 2017-04-10 00:00:00
title: "PowerShell 技能连载 - 请注意别名"
description: PowerTip of the Day - Beware of Aliases
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
您能指出这段代码的错误吗？

```powershell
PS C:\> function r { "This never runs" }

PS C:\> r
function r { "This never runs" }

PS C:\>
```

如果您执行函数 "r"，它只会返回函数的源代码。

错误的原因是函数名 "r" 和内置的别名冲突：

```powershell
PS C:\> Get-Alias r

CommandType     Name                                               Version    Source
-----------     ----                                               -------    ------
Alias           r -> Invoke-History


PS C:\>
```

所以请始终确保知道内置的别名——它们的优先级永远比函数或其它命令高。更好的做法是，按照最佳实践，始终用 Verb-Noum 的方式来命名您的函数。

<!--more-->
本文国际来源：[Beware of Aliases](http://community.idera.com/powershell/powertips/b/tips/posts/beware-of-aliases)
