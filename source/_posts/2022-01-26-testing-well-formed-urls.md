---
layout: post
date: 2022-01-26 00:00:00
title: "PowerShell 技能连载 - 测试 URL 是否完整"
description: PowerTip of the Day - Testing Well Formed URLs
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
PowerShell 经常基于 API，您不需要深入正则表达式和文本模式。相反，.NET Framework 中可以使用多种专业的测试方法。困难的是找到并知道它们，而不是运行它们和进行测试。

例如，要测试 URL 是否正确，请尝试：

```powershell
$url = 'powershell.one'
$kind = [UriKind]::Absolute
[Uri]::IsWellFormedUriString($url, $kind)
```

结果将是 false ，因为 "powershell.one" 不是一个绝对的 URL。在前面添加 "https://"，结果会变为 true。

<!--本文国际来源：[Testing Well Formed URLs](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/testing-well-formed-urls)-->

