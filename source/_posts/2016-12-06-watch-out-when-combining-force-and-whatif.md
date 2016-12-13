layout: post
date: 2016-12-05 16:00:00
title: "PowerShell 技能连载 - 同时使用 -Force 和 -WhatIf 时请注意"
description: PowerTip of the Day - Watch Out When Combining -Force and -WhatIf!
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
`-WhatIf` 通用参数可以打开模拟模式，这样一个 cmdlet 执行的时候并不会改变任何东西，而是汇报它“将会”改变什么。它能工作得很好， 除非开发者没有正确地实现 `-WhatIf`。

有一种比较少见的情况：当您同时指定了 `-Force` 和 `-WhatIf` 参数，正确的结果是 `-WhatIf` 具有更高的优先级。有一些开发者过于关注 `-Force` 的功能，而让 `-Force` 优先级更高。例如请试试 `Remove-SmbShare`。

<!--more-->
本文国际来源：[Watch Out When Combining -Force and -WhatIf!](http://community.idera.com/powershell/powertips/b/tips/posts/watch-out-when-combining-force-and-whatif)
