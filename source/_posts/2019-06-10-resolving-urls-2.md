---
layout: post
date: 2019-06-10 00:00:00
title: "PowerShell 技能连载 - 解析 URL"
description: PowerTip of the Day - Resolving URLs
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
经常有一种情况，URL 重定向到另一个最终的 URL。这种情况下，如果您希望知道一个指定的 URL 究竟指向哪，可以用类似这样的函数：

```powershell
function Resolve-Url
{
  [CmdletBinding()]
  param
  (
    [Parameter(Mandatory)]
    [string]
    $url
  )

  $request = [System.Net.WebRequest]::Create($url)
  $request.AllowAutoRedirect=$false
  $response = $request.GetResponse()
  $url = $response.GetResponseHeader("Location")
  $response.Close()
  $response.Dispose()

  return $url
}
```

例如，最新的 PowerShell 总是在这个 URL 发布：[https://github.com/PowerShell/PowerShell/releases/latest](https://github.com/PowerShell/PowerShell/releases/latest)

解析这个 URL，就可以获取最新的 URL。这是找到可用的最新 PowerShell 版本的快速方法：

```powershell
PS C:\> Resolve-Url -url https://github.com/PowerShell/PowerShell/releases/latest
https://github.com/PowerShell/PowerShell/releases/tag/v6.2.1

PS C:\> ((Resolve-Url -url https://github.com/PowerShell/PowerShell/releases/latest) -split '/')[-1]
v6.2.1

PS C:\> [version](((Resolve-Url -url https://github.com/PowerShell/PowerShell/releases/latest) -split '/')[-1] -replace 'v')

Major  Minor  Build  Revision
-----  -----  -----  --------
6      2      1      -1
```

<!--本文国际来源：[Resolving URLs](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/resolving-urls-2)-->

