---
layout: post
date: 2018-03-14 00:00:00
title: "PowerShell 技能连载 - 正确地对 IPv4 和 IPv6 地址排序"
description: PowerTip of the Day - Sort IPv4 and IPv6 Addresses Correctly
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
当您尝试使用 `Sort-Object` 对 IPv4 地址排序的时候，结果是错误的：

```powershell
PS> '10.1.2.3', '2.3.4.5', '1.2.3.4' | Sort-Object
1.2.3.4
10.1.2.3
2.3.4.5
```

这并不令人意外，因为数据类型是字符串型，所以 `Sort-Object` 使用的是字母排序。在前一个技能中我们介绍了如何将数据转换未 `[Version]` 类型，并且假装在排序软件版本号：

```powershell
PS> '10.1.2.3', '2.3.4.5', '1.2.3.4' | Sort-Object -Property { $_ -as [Version] }
1.2.3.4
2.3.4.5
10.1.2.3
```

然而，这种方法对 IPv6 地址行不通，因为它无法转换为版本号：

```powershell
PS> '10.1.2.3', 'fe80::532:c4e:c409:b987%13', '2.3.4.5', '2DAB:FFFF:0000:3EAE:01AA:00FF:DD72:2C4A', '1.2.3.4' | Sort-Object -Property { $_ -as [Version] }

fe80::532:c4e:c409:b987%13
2DAB:FFFF:0000:3EAE:01AA:00FF:DD72:2C4A
1.2.3.4
2.3.4.5
10.1.2.3
```

用 `-as` 操作符将 IPv6 地址转为 `[Version]` 返回的是 NULL，所以当用 `Sort-Object` 排序时，IPv6 地址会出现在列表的最顶部。

要对 IPv6 地址排序，缺省的字母排序是够用的。所以我们做一些改变，当遇到一个 IPv6 地址时，用它的字符串值来排序：

```powershell
$code = {
    $version = $_ -as [Version]
    if ($version -eq $null) { "z$_" }
    else { $version }
}

'10.1.2.3', 'fe80::532:c4e:c409:b987%13', '2.3.4.5', '2DAB:FFFF:0000:3EAE:01AA:00FF:DD72:2C4A', '1.2.3.4' | Sort-Object -Property $code
```

现在结果看起来清爽多了：

    10.1.2.3
    2.3.4.5
    1.2.3.4
    2DAB:FFFF:0000:3EAE:01AA:00FF:DD72:2C4A
    fe80::532:c4e:c409:b987%13

请注意代码中向 IPv6 的字符串开头加入字母 "z"。这是为了保证 IPv6 地址位于列表的底部。如果您希望它们位于列表的顶部，请试试这段代码：

```powershell
$code = {
    $version = $_ -as [Version]
    if ($version -eq $null) { "/$_" }
    else { $version }
}
```

由于 "/" 的 ASCII 值比 "0" 更小，所以 IPv6 地址位于列表的顶部：

    2DAB:FFFF:0000:3EAE:01AA:00FF:DD72:2C4A
    fe80::532:c4e:c409:b987%13
    1.2.3.4
    2.3.4.5
    10.1.2.3

<!--more-->
本文国际来源：[Sort IPv4 and IPv6 Addresses Correctly](http://community.idera.com/powershell/powertips/b/tips/posts/sort-ipv4-and-ipv6-addresses-correctly)
