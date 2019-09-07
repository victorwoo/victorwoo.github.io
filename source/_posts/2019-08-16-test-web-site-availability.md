---
layout: post
date: 2019-08-16 00:00:00
title: "PowerShell 技能连载 - 测试网站的可用性"
description: PowerTip of the Day - Test Web Site Availability
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
当一个网站不可用时，通常的问题是仅仅您不能访问该网站，还是其他所有人都不能访问。PowerShell 可以调用一个 Web Service 为您检查 web 站点的可用性。下面是一个简单的包装函数:

```powershell
function Test-Url
{
  param
  (
    [Parameter(Mandatory,ValueFromPipeline)]
    [string]
    $Url
  )

  Add-Type -AssemblyName System.Web

  $check = "https://isitdown.site/api/v3/"
  $encoded = [System.Web.HttpUtility]::UrlEncode($url)
  $callUrl = "$check$encoded"

  Invoke-RestMethod -Uri $callUrl |
    Select-Object -Property Host, IsItDown, Response_Code
}
```

它将调用一个 RESTful API 并且通过 URL 参数进行检查。这是为什么待测试的 URL 需要进行 URL 编码，这段代码调用 `Invoke-RestMethod` 并且以一个对象的形式接收测试结果。

```powershell
PS C:\> Test-Url -Url powershellmagazine.com

host                   isitdown response_code
----                   -------- -------------
powershellmagazine.com    False           200
```

请注意这个示例中使用的 Web Service 是免费的，并且不需要注册或 API 密钥。缺点是该 Web Service 是限流的它可能会返回一个异常，提示您提交了太多请求。当这种情况发生时，只需要等待一阵子再重试。

<!--本文国际来源：[Test Web Site Availability](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/test-web-site-availability)-->

