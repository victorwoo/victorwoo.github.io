---
layout: post
date: 2018-11-12 00:00:00
title: "PowerShell 技能连载 - 下载 PowerShell 代码"
description: PowerTip of the Day - Downloading PowerShell Code
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
在之前的技能中我们介绍了如何用 `Invoke-WebRequest` 下载任意网页的 HTML 内容。这也可以用来下载 PowerShell 代码。`Invoke-WebRequest` 可以下载任意 WEB 服务器提供的内容，所以以下示例代码可以下载一段 PowerShell 脚本：

```powershell
$url = "http://bit.ly/e0Mw9w"
$page = Invoke-WebRequest -Uri $url
$code = $page.Content
$code | Out-GridView
```

如果您信任这段代码，您可以方便地下载和运行它：

```powershell
Invoke-Expression -Command $code
```

这段代码适用于 PowerShell 控制台，您将见到一个“跳舞的 Rick Ascii 艺术”并听到有趣的音乐，如果在另一个编辑器中运行以上代码，您的 AV 可能会阻止该调用并且将它识别为一个严重的威胁。这是因为下载的代码会检测它运行的环境，由于它需要在控制台中运行，所以如果在其它地方运行它，将会启动一个 PowerShell 控制台。这个操作是由杀毒引擎控制的，随后会被系统阻止。

<!--more-->
本文国际来源：[Downloading PowerShell Code](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/downloading-powershell-code)
