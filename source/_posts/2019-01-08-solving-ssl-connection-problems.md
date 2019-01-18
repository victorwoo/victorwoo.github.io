---
layout: post
date: 2019-01-08 00:00:00
title: "PowerShell 技能连载 - 解决 SSL 连接问题"
description: PowerTip of the Day - Solving SSL Connection Problems
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
有些时候当您尝试连接 WEB 服务时，PowerShell 可能会弹出无法设置安全的 SSL 通道提示。

让我们来深入了解一下这个问题。以下是一段调用德国铁路系统 WEB 服务的代码。它应该返回指定城市的火车站列表：

```powershell
$city = "Hannover"
$url = "https://rit.bahn.de/webservices/rvabuchung?WSDL"

$object = New-WebServiceProxy -Uri $url -Class db -Namespace test

$request = [test.SucheBahnhoefeAnfrage]::new()
$request.bahnhofsname = $city
$response = $object.sucheBahnhoefe($request)
$response.bahnhoefe
```

不过，它弹出了一系列关于 SSL 连接问题的异常。通常，这些错误源于两种情况：

* 该 WEB 网站用于确立 SSL 连接的 SSL 证书非法、过期，或不被信任。
* 该 SSL 连接需要某种协议，而该协议没有启用。

要解决这些情况，只需要运行以下代码：

```powershell
# ignore invalid SSL certificates
[System.Net.ServicePointManager]::ServerCertificateValidationCallback = {$true}

# allowing SSL protocols
$AllProtocols = [Net.SecurityProtocolType]'Ssl3,Tls,Tls11,Tls12'
[Net.ServicePointManager]::SecurityProtocol = $AllProtocols
```

只要执行一次，对当前的 PowerShell 会话都有效。以上代码现在能够正常返回 Hannover 地区的车站信息。而且如果深入地了解该对象的模型，您甚至可以通过 PowerShell 订火车票。

    name                  nummer
    ----                  ------
    Hannover Hbf         8000152
    Hannover-Linden/Fi.  8002586
    Hannover-Nordstadt   8002576
    Hannover Bismarckstr 8002580
    Hannover-Ledeburg    8002583
    Hannover-Vinnhorst   8006089
    Hannover-Leinhausen  8002585
    Hannover Wiech-Allee 8002591
    Hannover Ander.Misb. 8000578
    Hannover Flughafen   8002589
    Hannover-Kleefeld    8002584
    Hannover-Bornum      8002581
    Hann Münden          8006707
    HannoverMesseLaatzen 8003487

<!--more-->
本文国际来源：[Solving SSL Connection Problems](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/solving-ssl-connection-problems)
