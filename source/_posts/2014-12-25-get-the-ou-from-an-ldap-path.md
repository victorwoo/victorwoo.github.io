layout: post
date: 2014-12-25 12:00:00
title: "PowerShell 技能连载 - 从 LDAP 路径获取 OU"
description: PowerTip of the Day - Get the OU from an LDAP Path
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

要从原始字符串从截取特定的部分，您常常需要使用一系列文本分割和取子串的命令。

例如，要从一个 LDAP 陆军中截取最后一个 OU 的名字，一下是一种办法：

    $dn = 'OU=Test,OU=People,CN=Testing,OU=Everyone,DC=Company,DC=com'
    
    ($dn.Split(',') -like 'OU=*' ).Substring(3)[0]

这段代码将返回该 LDAP 路径（LDAP 路径是从右往左读的，所以最后一个 OU 是字符串中的第一个 OU），而且稍作修改就可以读取其它部分。例如，将下标从 0 改为 -1 就可以读取路径中的第一个 OU。

<!--more-->
本文国际来源：[Get the OU from an LDAP Path](http://powershell.com/cs/blogs/tips/archive/2014/12/25/get-the-ou-from-an-ldap-path.aspx)
