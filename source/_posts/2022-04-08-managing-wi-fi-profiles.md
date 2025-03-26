---
layout: post
date: 2022-04-08 00:00:00
title: "PowerShell 技能连载 - 管理 Wi-Fi 配置文件"
description: PowerTip of the Day - Managing Wi-Fi Profiles
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
在Windows上，你可以使用旧的控制台命令来发现Wi-Fi配置文件：

```powershell
PS> netsh wlan show profiles
```

从这里开始，您甚至可以查看个人配置文件的详细信息，并获得高速缓存的明文密码。然而，所有这些都是基于控制台的，所以它不是面向对象的，需要大量的字符串操作，当概要文件使用特殊字符或您的计算机使用不同的区域设置时，可能会返回意外的信息。

一个更好的方法是使用本地Windows API。在PowerShell图库上有一个可以使用的公共模块。这样安装：

```powershell
PS> Install-Module -Name WifiProfileManagement -Scope CurrentUser
```

其余的都是微不足道的。要转储所有保存的Wi-Fi配置文件（包括名称中有特殊字符的文件），请使用Get-WiFiProfile：

```powershell
PS C:\> Get-WiFiProfile

ProfileName               ConnectionMode Authentication Encryption Password
-----------               -------------- -------------- ---------- --------
HOTSPLOTS_WR_Muehlenberg  manual         open           none
Zudar06_Gast              auto           WPA2PSK        AES
management                auto           WPA3SAE        AES
MagentaWLAN-X5HZ          auto           WPA3SAE        AES
Alando-Whg.17             auto           WPA2PSK        AES
internet-cafe             auto           WPA2PSK        AES
Training                  manual         WPA2PSK        AES
QSC-Guest                 auto           open           none
ibisbudget                manual         open           none
Leonardo                  auto           open           none
ROOMZ-GUEST               auto           open           none
Freewave                  auto           open           none
PS Saturday               auto           WPA2PSK        AES
WIFIonICE                 manual         open           none
Airport Hotel             auto           WPA2PSK        AES
```

并且，要查看缓存的Wi-Fi密码，只需添加-ClearKey参数。高速缓存的密码现在将以明文形式出现在“密码”列中。

如果您有兴趣直接在您自己的代码中使用此功能，只需查看模块中的源代码即可。它是高度复杂的，但本地的电源外壳。任何正在寻找直接与Wi-Fi子系统对话的原生API方式的人都应该深入研究这些代码。

<!--本文国际来源：[Managing Wi-Fi Profiles](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/managing-wi-fi-profiles)-->
