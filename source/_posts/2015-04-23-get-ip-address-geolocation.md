layout: post
date: 2015-04-23 11:00:00
title: "PowerShell 技能连载 - 获取 IP 地址的地理信息"
description: PowerTip of the Day - Get IP Address Geolocation
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
您希望知道某个公网 IP 地址位于什么地方吗？假设您有 Internet 连接，您可以查询公共信息服务来获得。

这个例子将获取某个 IP 地址的地理信息。请确认您将示例 IP 地址替换为了实际存在的公网 IP 地址。请打开类似 [https://www.whatismyip.com/](https://www.whatismyip.com/) 这样的网站来查看您自己的 IP 地址。如果您使用的是一个内网 IP 地址，该 WEB 服务将无法准确地报告地理信息数据。

    #requires -Version 3
    
    $ipaddress = '93.212.237.11'
    $infoService = "http://freegeoip.net/xml/$ipaddress"
    
    $geoip = Invoke-RestMethod -Method Get -URI $infoService
    
    $geoip.Response

<!--more-->
本文国际来源：[Get IP Address Geolocation](http://powershell.com/cs/blogs/tips/archive/2015/04/23/get-ip-address-geolocation.aspx)
