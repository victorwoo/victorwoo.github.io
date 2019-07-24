---
layout: post
date: 2019-07-15 00:00:00
title: "PowerShell 技能连载 - 提高管道速度"
description: PowerTip of the Day - Increasing Pipeline Speed
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
PowerShell 管道在处理大量元素时往往比较慢。可能需要很多时间：

```powershell
$result = 1..15000 |
ForEach-Object {
    "Line $_"
}
```

一种更快的方法是用匿名脚本块代替 `ForEach-Object`，它会带来 200 倍的速度提升：

```powershell
$result = 1..15000 |
    & { process {
        "Line $_"
    }}
```

<!--本文国际来源：[Increasing Pipeline Speed](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/increasing-pipeline-speed)-->

