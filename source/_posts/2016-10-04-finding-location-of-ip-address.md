---
layout: post
date: 2016-10-04 00:00:00
title: "PowerShell 技能连载 - 查找 IP 地址的地理位置"
description: PowerTip of the Day - Finding Location of IP Address
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
大多数 IP 地址可以用 Web Service 定位到物理地址。以下是一个很简单的函数，能够输入一个 IP 地址并返回它的物理地址：

```powershell
#requires -Version 3.0

function Get-IPLocation([Parameter(Mandatory)]$IPAddress)
{
    Invoke-RestMethod -Method Get -Uri "http://geoip.nekudo.com/api/$IPAddress" |
      Select-Object -ExpandProperty Country -Property City, IP, Location 
}
```

这个例子能够演示如何用 `Select-Object` 配合 `-Property` 和 `-ExpandProperty` 参数将一些嵌套的属性移到上一层。

让我们查找 Google DNS 服务器位于什么位置：

```
PS C:\> Get-IPLocation -IPAddress 8.8.8.8

name     : United States
code     : US
city     : Mountain View
ip       : 8.8.8.8
location : @{accuracy_radius=1000; latitude=37,386; longitude=-122,0838; time_zone=America/Los_Angeles} 
```

And here is how you can resolve any hostname to an IP address, for example, the famous powershellmagazine.com:
以下是如何将任意主机名解析成 IP 地址的代码，例如知名的 powershellmagazine.com：

```powershell
PS> [Net.Dns]::GetHostByName('powershellmagazine.com').AddressList.IPAddressToString
104.131.21.239
```

所以如果您想知道该 IP 地址位于哪里，请加上这段代码：

```
PS> Get-IPLocation -IPAddress 104.131.21.239

name     : United States
code     : US
city     : New York
ip       : 104.131.21.239
location : @{accuracy_radius=1000; latitude=40,7143; longitude=-74,006; 
           time_zone=America/New_York}
```

(of course this is just where the server sits, not Aleksandar or Ravi or all the other fine editors 
（当然这只代表了服务器的所在地，而不是 Aleksandar or Ravi 及其它知名编辑的位置 ![](/img/2016-10-04-finding-location-of-ip-address-001.png)）

<!--本文国际来源：[Finding Location of IP Address](http://community.idera.com/powershell/powertips/b/tips/posts/finding-location-of-ip-address)-->
