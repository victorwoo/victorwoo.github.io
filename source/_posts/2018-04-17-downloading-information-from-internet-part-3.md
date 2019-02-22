---
layout: post
date: 2018-04-17 00:00:00
title: "PowerShell 技能连载 - 从 Internet 下载信息（第 3 部分）"
description: PowerTip of the Day - Downloading Information from Internet (Part 3)
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
在前一个技能中，我们演示了如何使用 `Invoke-WebRequest` 从网页下载数据，并且处理 JSON 或 XML 格式的数据。然而，多数网页包含的是纯 HTML 数据。您可以使用正则表达式来从纯 HTML 中提取信息。

以下是获得网页内容的方法：

```powershell
$url = 'http://pages.cs.wisc.edu/~ballard/bofh/bofhserver.pl'
$page = Invoke-WebRequest -Uri $url -UseBasicParsing
$page.Content
```

这个例子中的网页提供随机的借口。要获得最终的借口，得先创建正则表达式模式：

```powershell
$url = 'http://pages.cs.wisc.edu/~ballard/bofh/bofhserver.pl'
$page = Invoke-WebRequest -Uri $url -UseBasicParsing
$content = $page.Content

$pattern = '(?s)<br><font size\s?=\s?"\+2">(.+)</font'

if ($page.Content -match $pattern)
{
    $matches[1]
}
```

当您运行这段代码时，它可以提供一个新的借口。我们在此不深入讨论正则表达式。该正则表达式的基本原理是查找 `)<br><font size\s?=\s?"\+2">` 这样的静态文本，然后取出之后的任何文本 (`(.+)`)，直到结尾的静态文本 (`</font`)。`$matches[1]` 的值就是正则表达式中的第一个模式代表的内容，在这里就是我们要提取的借口。

<!--本文国际来源：[Downloading Information from Internet (Part 3)](http://community.idera.com/powershell/powertips/b/tips/posts/downloading-information-from-internet-part-3)-->
