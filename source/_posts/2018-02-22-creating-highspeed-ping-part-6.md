---
layout: post
date: 2018-02-22 00:00:00
title: "PowerShell 技能连载 - 创建快速的 Ping（第六部分）"
description: PowerTip of the Day - Creating Highspeed Ping (Part 6)
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
这是我们迷你系列的最后一部分，向我们超快的 `Test-OnlineFast` 函数添加管道功能。您现在可以像这样将计算机名通过管道传给函数：

```powershell
PS> 1..200 | ForEach-Object { "192.168.189.$_" } | Test-OnlineFast

Address         Online DNSName                            Status
-------         ------ -------                            ------
192.168.189.200   True DESKTOP-7AAMJLF.fritz.box          Success
192.168.189.1     True fritz.box                          Success
192.168.189.65    True mbecker-netbook.fritz.box          Success
192.168.189.29    True fritz.repeater                     Success
192.168.189.64    True android-6868316cec604d25.fritz.box Success
192.168.189.112   True Galaxy-S8.fritz.box                Success
192.168.189.142   True Galaxy-S8.fritz.box                Success
192.168.189.129   True iPhonevMuzaffer.fritz.box          Success
192.168.189.10   False                                    Request Timed Out
192.168.189.100  False                                    Request Timed Out
(...)
```

当然，您也可以传递普通参数给这个函数：

```powershell
PS> Test-OnlineFast -ComputerName google.de, microsoft.com, 127.0.0.1

Address      Online DNSName         Status
-------      ------ -------         ------
127.0.0.1      True DESKTOP-7AAMJLF Success
google.de      True google.de       Success
microsoft.com  False                Request Timed Out
```

您甚至可以使用其它 cmdlet 的结果，假设您选择了希望传给该函数的属性。一下这行代码 ping 您 Active Directory 中的所有计算机（您最好稍微做一下限制，以免耗尽资源）：

```powershell
PS> Get-ADComputer -Filter * | Select-Object -ExpandProperty DnsHostName | Test-OnlineFast
```

<!--more-->
本文国际来源：[Creating Highspeed Ping (Part 6)](http://community.idera.com/powershell/powertips/b/tips/posts/creating-highspeed-ping-part-6)
