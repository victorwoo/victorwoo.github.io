---
layout: post
date: 2018-11-13 00:00:00
title: "PowerShell 技能连载 - Invoke-WebRequest vs. Invoke-RestMethod"
description: PowerTip of the Day - Invoke-WebRequest vs. Invoke-RestMethod
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
`Invoke-WebRequest` 只是简单地从任意的网站下载内容。接下来读取内容并分析它，是您的工作。在前一个技能中我们解释了如何下载 PowerShell 代码，并且执行它：

```powershell
$url = "http://bit.ly/e0Mw9w"
$page = Invoke-WebRequest -Uri $url
$code = $page.Content
$sb = [ScriptBlock]::Create($code)
& $sb
```

（请注意：请在 PowerShell 控制台中运行以上代码。如果在 PowerShell ISE 等编辑器中运行，杀毒引擎将会阻止运行）

类似地，如果数据是以 XML 格式返回的，您可以将它转换为 XML。并且做进一步处理，例如从银行获取当前的汇率：

```powershell
$url = "http://www.ecb.europa.eu/stats/eurofxref/eurofxref-daily.xml"
$page = Invoke-WebRequest -Uri $url
$data = $page.Content -as [xml]
$data.Envelope.Cube.Cube.Cube
```

作为对比，`Invoke-RestMethod` 不仅仅下载数据，而且遵循数据的类型。您会自动得到正确的数据。以下是上述操作的简化版本，用的是 `Invoke-RestMethod` 来代替 `Invoke-WebRequest`：

调用 `Rick-Ascii`（从 PowerShell 控制台运行）：

```powershell
$url = "http://bit.ly/e0Mw9w"
$code = Invoke-RestMethod -Uri $url
$sb = [ScriptBlock]::Create($code)
& $sb
```

获取货币汇率：

```powershell
$url = "http://www.ecb.europa.eu/stats/eurofxref/eurofxref-daily.xml"
$data = Invoke-RestMethod -Uri $url
$data.Envelope.Cube.Cube.Cube
```

<!--more-->
本文国际来源：[Invoke-WebRequest vs. Invoke-RestMethod](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/invoke-webrequest-vs-invoke-restmethod)
