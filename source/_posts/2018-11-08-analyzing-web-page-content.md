---
layout: post
date: 2018-11-08 00:00:00
title: "PowerShell 技能连载 - 分析 WEB 页面内容"
description: PowerTip of the Day - Analyzing Web Page Content
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
PowerShell 内置了一个 WEB 客户端，它可以获取 HTML 内容。对于简单的 WEB 页面分析，使用 `-UseBasicParsing` 参数即可。该操作将原原本本地获取原始的 HTML 内容，例如，包含嵌入的链接和图像的列表：

```powershell
$url = "http://powershellmagazine.com"
$page = Invoke-WebRequest -URI $url -UseBasicParsing

$page.Content | Out-GridView -Title Content
$page.Links | Select-Object href, OuterHTML | Out-GridView -Title Links
$page.Images | Select-Object src, outerHTML | Out-GridView -Title Images
```

如果忽略了 `-UseBasicParsing` 参数，那么该 cmdlet 内部使用 Internet Explorer 文档对象模型，并返回更详细的信息：

```powershell
$url = "http://powershellmagazine.com"
$page = Invoke-WebRequest -URI $url 

$page.Links | Select-Object InnerText, href | Out-GridView -Title Links 
```

请注意 `Invoke-WebRequest` 需要您实现设置并且至少打开一次 Internet Explorer，除非您指定了 `-UseBasicParsing`。

<!--本文国际来源：[Analyzing Web Page Content](http://community.idera.com/database-tools/powershell/powertips/b/tips/posts/analyzing-web-page-content)-->
