---
layout: post
date: 2018-08-10 00:00:00
title: "PowerShell 技能连载 - 自动获取借口"
description: PowerTip of the Day - Getting Excuses Automatically
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
`Invoke-WebRequest` 可以从网页获取 HTML 信息，并且可以用正则表达式来提取这些页面中的信息。

以下是一些可以获取英文的借口的代码：

```powershell
$ProgressPreference = 'SilentlyContinue'

$url = "http://pages.cs.wisc.edu/~ballard/bofh/bofhserver.pl?$(Get-Random)"
$page = Invoke-WebRequest -Uri $url -UseBasicParsing
$pattern = '(?s)<br><font\ size\ =\ "\+2">(.{1,})</font'
if ($page.Content -match $pattern)
{
  $matches[1].Trim() -replace '\n', '' -replace '\r', ''
}
```

以下代码将获取英语和德语混合的借口：

```powershell
$page= Invoke-WebRequest "http://www.netzmafia.de/cgi-bin/bofhserver.cgi"
$pattern='(?s)<B>(.*?)</B>'
if ($page.Content -match $pattern)
{
  $matches[1].Trim() -replace '\n', '' -replace '\r', ''
}
```

<!--more-->
本文国际来源：[Getting Excuses Automatically](http://community.idera.com/powershell/powertips/b/tips/posts/getting-excuses-automatically-pt1)
