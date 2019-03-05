---
layout: post
date: 2019-03-01 00:00:00
title: "PowerShell 技能连载 - 计算机名、DNS 名称，和 IP 地址"
description: PowerTip of the Day - Computer Name, DNS Name, and IP Address
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
以下是一个单行的代码，返回您计算机的当前 IP 地址和它的完整 DNS 名：

```powershell
PS> [System.Net.Dns]::GetHostEntry('')

HostName        Aliases AddressList                                
--------        ------- -----------                                
DESKTOP-7AAMJLF {}      {fe80::532:c4e:c409:b987%18, 192.168.2.129}
```

要检测一台远程的及其，只需要传入远程计算机的名字来代替空白字符串即可：

```powershell
PS> [System.Net.Dns]::GetHostEntry('microsoft.com')

HostName      Aliases AddressList                                                   
--------      ------- -----------                                                   
microsoft.com {}      {40.113.200.201, 40.76.4.15, 104.215.148.63, 13.77.161.179...}
```

如果你只希望获取绑定的 IP 地址列表，请试试以下代码：

```powershell
PS> [System.Net.Dns]::GetHostEntry('microsoft.com').AddressList.IPAddressToString
40.113.200.201
40.76.4.15
104.215.148.63
13.77.161.179
40.112.72.205 
```

今日知识点：

* `System.Net.Dns` 类包含许多有用的 DNS 相关方法。`GetHostEntry()` 非常有用，因为它既可以接受计算机名称也可以接受 IP 地址，并返回对应的 DNS 名和 IP 地址。
* 传入空白字符串可以查看本机的设置。

<!--本文国际来源：[Computer Name, DNS Name, and IP Address](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/computer-name-dns-name-and-ip-address)-->
