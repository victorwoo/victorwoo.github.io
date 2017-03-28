layout: post
date: 2015-03-02 12:00:00
title: "PowerShell 技能连载 - 使用基于 JSON 的 Web Service"
description: PowerTip of the Day - Using JSON-based Web Services
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
_适用于 PowerShell 3.0 及以上版本_

Internet 有许多信息提供服务，许多返回的是 JSON 数据格式。以下是一个演示如何用 PowerShell 查询这类 Web Service，并将 JSON 结果转换为对象的例子。

这个例子使用一个德国铁路公司的 Web Service。您只要输入火车站或城市名字的一部分，就能得到包含输入信息的所有火车站名：

    # ask for part of the train station name
    $name = Read-Host 'Enter part of train station Name'
    
    # query webservice
    $url = "http://openbahnapi.appspot.com/rest/stations/list?contains=$name"
    $site = Invoke-WebRequest -Uri $url
    
    # get JSON result
    ($site.Content | ConvertFrom-Json ).value

结果看起来类似这样：

    PS> Enter part of train station name: hanno
    Hannover Hbf
    HANNOVER MESSE
    Hannoversch Münden
    Hannover-Nordstadt
    Hannover Bismarckstr.
    Hannover Karl-Wiechert-Allee
    Hannover-Ledeburg
    Hannover-Linden/Fischerhof
    Hannover-Vinnhorst
    Hannover-Leinhausen
    Hannover Anderten-Misburg
    Hannover-Bornum
    
    PS>  

这段代码并不仅限于德国铁路系统，所以如果您不是对德国铁路系统特别兴趣的话，可以调用任何基于 JSON 的 Web Service。

重要的环节是 `Invoke-WebRequest`（该命令和 Web Service 通信并返回结果），以及 `ConvertFrom-Json`（该命令接收上一步的结果并将它转换为对象）。

请注意 Web Service 的提供者可能随时改变服务的实现。示例代码中的 Web Service 只能当做学习的例子来用。

<!--more-->
本文国际来源：[Using JSON-based Web Services](http://community.idera.com/powershell/powertips/b/tips/posts/using-json-based-web-services)
