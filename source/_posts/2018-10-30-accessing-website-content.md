---
layout: post
date: 2018-10-30 00:00:00
title: "PowerShell 技能连载 - 读取网站内容"
description: PowerTip of the Day - Accessing Website Content
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
通常情况下，通过 PowerShell 的 `Invoke-WebRequest` 命令来获取原始的 HTML 网站内容是很常见的情况。脚本可以处理 HTML 内容并对它做任意操作，例如用正则表达式从中提取信息：

```powershell
$url = "www.tagesschau.de"
$w = Invoke-WebRequest -Uri $url -UseBasicParsing
$w.Content
```

然而，有些时候一个网站的内容是通过客户端脚本代码动态创建的。那么，Invoke-WebRequest` 并不能返回浏览器中所见的完整 HTML 内容。如果仍要获取 HTML 信息，您需要借助一个真实的 WEB 浏览器。一个简单的方法是使用内置的 Internet Explorer：

```powershell
$ie = New-Object -ComObject InternetExplorer.Application
$ie.Navigate($url)
do
{
    Start-Sleep -Milliseconds 200
} while ($ie.ReadyState -ne 4)

$ie.Document.building.innerHTML
```

<!--本文国际来源：[Accessing Website Content](http://community.idera.com/powershell/powertips/b/tips/posts/accessing-website-content)-->
