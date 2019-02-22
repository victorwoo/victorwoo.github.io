---
layout: post
date: 2018-03-05 00:00:00
title: "PowerShell 技能连载 - 还原短网址"
description: PowerTip of the Day - Uncover Tiny URLs
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
类似 "http://bit.ly/e0Mw9w" 这样的网址十分短小，并且使用起来很方便。但它们往往屏蔽了原始的信息。

PowerShell 查找它们真实指向的地址，来还原短网址：

```powershell
$url = "http://bit.ly/e0Mw9w"

$request = [System.Net.WebRequest]::Create($url)
$request.AllowAutoRedirect=$false
$response=$request.GetResponse()
$trueUrl = $response.GetResponseHeader("Location")
"$url -> $trueUrl"
```

以下是使用结果：

    http://bit.ly/e0Mw9w -> http://www.leeholmes.com/projects/ps_html5/Invoke-PSHtml5.ps1


<!--本文国际来源：[Uncover Tiny URLs](http://community.idera.com/powershell/powertips/b/tips/posts/uncover-tiny-urls)-->
