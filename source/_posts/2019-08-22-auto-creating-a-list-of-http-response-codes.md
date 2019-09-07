---
layout: post
date: 2019-08-22 00:00:00
title: "PowerShell 技能连载 - 自动创建 HTTP 响应码清单"
description: PowerTip of the Day - Auto-Creating a List of HTTP Response Codes
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
在前一个示例中我们学习了如何自动将数值型的 HTTP 响应码转换为描述性的文本，只需要将它们转换为 `System.Net.HttpStatusCode` 即可。

```powershell
PS> [System.Net.HttpStatusCode]500
InternalServerError
```

这是因为 `System.Net.HttpStatusCode` 是一个所谓的“枚举”，其作用类似于“查找表”。您可以轻松地转储枚举的所有成员，例如创建一个 HTTP 响应代码表：

```powershell
[Enum]::GetValues([System.Net.HttpStatusCode]) |
  ForEach-Object {
    [PSCustomObject]@{
        Code = [int]$_
        Description = $_.toString()
    }
  }
```

以上是创建一个最常见的 HTTP 响应码所需要的所有代码。

    Code Description
    ---- -----------
     100 Continue
     101 SwitchingProtocols
     200 OK
     201 Created
     202 Accepted
     203 NonAuthoritativeInformation
     204 NoContent
     205 ResetContent
     206 PartialContent
     300 MultipleChoices
     300 MultipleChoices
     301 MovedPermanently
     301 MovedPermanently
     302 Redirect
     302 Redirect
     303 SeeOther
     303 SeeOther
     304 NotModified
     305 UseProxy
     306 Unused
     307 TemporaryRedirect
     307 TemporaryRedirect
     400 BadRequest
     401 Unauthorized
     402 PaymentRequired
     403 Forbidden
     404 NotFound
     405 MethodNotAllowed
     406 NotAcceptable
     407 ProxyAuthenticationRequired
     408 RequestTimeout
     409 Conflict
     410 Gone
     411 LengthRequired
     412 PreconditionFailed
     413 RequestEntityTooLarge
     414 RequestUriTooLong
     415 UnsupportedMediaType
     416 RequestedRangeNotSatisfiable
     417 ExpectationFailed
     426 UpgradeRequired
     500 InternalServerError
     501 NotImplemented
     502 BadGateway
     503 ServiceUnavailable
     504 GatewayTimeout
     505 HttpVersionNotSupported

这种方法适用于您可能遇到的任何枚举。只需更改枚举数据类型的名称即可。这个例子转储可用的控制台颜色代码：

```powershell
[Enum]::GetValues([System.ConsoleColor]) |
  ForEach-Object {
    [PSCustomObject]@{
        Code = [int]$_
        Description = $_.toString()
    }
  }



Code Description
---- -----------
    0 Black
    1 DarkBlue
    2 DarkGreen
    3 DarkCyan
    4 DarkRed
    5 DarkMagenta
    6 DarkYellow
    7 Gray
    8 DarkGray
    9 Blue
  10 Green
  11 Cyan
  12 Red
  13 Magenta
  14 Yellow
  15 White
```

<!--本文国际来源：[Auto-Creating a List of HTTP Response Codes](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/auto-creating-a-list-of-http-response-codes)-->

