---
layout: post
date: 2019-08-20 00:00:00
title: "PowerShell 技能连载 - 转换 HTTP 响应码"
description: PowerTip of the Day - Converting HTTP Response Codes
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
在前一个示例中我们创建了一个小的 PowerShell 函数，它能够检查 Web 网络的可用性，并 HTTP 返回码会作为测试结果的一部分返回。让我们看看如何可以轻松地将这个数字代码转换为有意义的文本消息。

以下还是那个测试网站的函数：

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

以下是典型的结果：

```powershell
PS C:\> Test-Url -Url powershellmagazine.com

host                   isitdown response_code
----                   -------- -------------
powershellmagazine.com    False           200
```

在这个示例中，响应代码是 "200"，恰好代表 "OK"。如果您希望将 HTTP 响应码转换为文本，只需要将数据类型转换为 `[System.Net.HttpStatusCode]`。这样就可以了：

```powershell
PS C:\> 200 -as [System.Net.HttpStatusCode]
OK
```

以下是包含该转换过程的版本：

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
  $response = @{
    Name = 'Response'
    Expression = {
        '{0} ({1})' -f
            ($_.Response_Code -as [System.Net.HttpStatusCode]),
            $_.Response_Code
    }
  }
  Invoke-RestMethod -Uri $callUrl |
    Select-Object -Property Host, IsItDown, $response
}
```

结果如下：

```powershell
PS C:\> Test-Url -Url powershellmagazine.com

host                   isitdown Response
----                   -------- --------
powershellmagazine.com    False OK (200)
```

请注意计算字段 "Response" 现在体现的是原始的数值型响应码和对应的友好文本。

<!--本文国际来源：[Converting HTTP Response Codes](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/converting-http-response-codes)-->

