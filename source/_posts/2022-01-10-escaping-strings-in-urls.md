---
layout: post
date: 2022-01-10 00:00:00
title: "PowerShell 技能连载 - 转义 URL 字符串"
description: PowerTip of the Day - Escaping Strings in URLs
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
将字符串信息添加到 URL 时，即要构造用于调用 REST Web 服务的请求时，重要的一环是要转义特殊字符。`[Uri]` 类型为 URL 提供了转义与反转义方法：

```powershell
$Text = 'SOS Save me please!'
$Escaped = [Uri]::EscapeUriString($Text)
$Escaped
```

结果如下所示：

    SOS%20Save%20me%20please!

现在，您可以安全地将转义的字符串数据发送到 RESTful Web 服务。以下代码将文本转换为摩尔斯码：

```powershell
$Text = 'SOS Save me please!'
$url = "https://api.funtranslations.com/translate/morse.json?text=$Text"

$Escaped = [Uri]::EscapeUriString($url)


$result = Invoke-RestMethod -Uri $url
$result.contents.translated
```

结果现在看起来像这样：

    ... --- ...     ... .- ...- .     -- .     .--. .-.. . .- ... . ---.

有些时候，使用此方法转义字符串可能会破坏某些查询字符串。要解决这个问题，请查看明天的技能。

<!--本文国际来源：[Escaping Strings in URLs](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/escaping-strings-in-urls)-->

