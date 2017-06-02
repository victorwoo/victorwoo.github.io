---
layout: post
date: 2014-10-13 11:00:00
title: "PowerShell 技能连载 - 获取美国邮政编码"
description: PowerTip of the Day - Getting US ZIP Codes
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
_适用于 PowerShell 所有版本_

是否曾需要查找某个（美国）城市的邮政编码，或者反过来通过邮政编码查找城市的名称？

只需要简单地用 PowerShell 连接到一个免费的 Web Service 就可以获得这些信息：

    $webservice = New-WebServiceProxy -Uri 'http://www.webservicex.net/uszip.asmx?WSDL'
    $webservice.GetInfoByCity('New York').Table
    $webservice.GetInfoByZIP('10286').Table

<!--more-->
本文国际来源：[Getting US ZIP Codes](http://community.idera.com/powershell/powertips/b/tips/posts/getting-us-zip-codes)
